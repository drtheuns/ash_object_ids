defmodule AshObjectIds do
  @moduledoc """
  A helper library for working with object IDs in Ash.

  Object IDs are identifiers that are prefixed with the resource they identify.
  A more detailed explanation can be found in the ["Designing APIs for
  humans"](https://dev.to/stripe/designing-apis-for-humans-object-ids-3o5a) blog post.

  This library provides an implementation for Ash:

      defmodule App.Blog.Post do
        use Ash.Resource,
          domain: App.Blog,
          data_layer: Ash.DataLayer.AshPostgres,

        defmodule Id do
          use AshObjectIds.Type, prefix: "p", uuid_type: :uuid_v7
        end

        attributes do
          attribute :id, Id do
            primary_key?(true)
            public?(true)
            writable?(false)
            default(&Id.generate/0)
            allow_nil?(false)
          end

          # ... other attributes
        end
      end

  The IDs are base58-encoded UUIDs with a prefix.
  """

  alias AshObjectIds.Type

  @doc """
  Decodes the given object ID into a string version of the UUID.

  ## Examples

      iex> decode_object_id("user_Cd4WBXFmobLLv7gfB4MuH")
      {:ok, "5d446d08-df6a-404d-a1e5-decc78429b3d"}

      iex> decode_object_id("something else")
      :error
  """
  @spec decode_object_id(binary()) :: {:ok, String.t()} | :error
  def decode_object_id(id) do
    case Type.decode_object_id(id) do
      {:ok, _prefix, uuid_bin} -> Ecto.UUID.load(uuid_bin)
      :error -> :error
    end
  end

  @doc """
  Searches the given domains for the resource that matches the given object ID
  prefix.

  You can get the domains through `Application.get_env(:my_otp_app, :ash_domains, [])`

  ## Examples

      iex> find_resource_for_prefix(domains, "user")
      MyApp.Accounts.User

      iex> find_resource_for_prefix(domains, "florb")
      nil
  """
  def find_resource_for_prefix(domains, prefix) when is_binary(prefix) and is_list(domains) do
    Enum.find_value(domains, fn domain ->
      domain
      |> Ash.Domain.Info.resources()
      |> Enum.find_value(fn resource ->
        resource
        |> Ash.Resource.Info.primary_key()
        |> Enum.find_value(fn attr_name ->
          attribute = Ash.Resource.Info.attribute(resource, attr_name)
          # Force loading the module with a cheap function call
          attribute.type.ecto_type()

          if function_exported?(attribute.type, :__object_id_info__, 0) &&
               attribute.type.__object_id_info__()[:prefix] == prefix do
            resource
          end
        end)
      end)
    end)
  end

  @doc """
  Same as `find_resource_for_prefix/2` but accepts a (valid) object ID.

  ## Examples

      iex> find_resource_for_id(domains, "user_CWzLBdFy2f1XhrtesFferY")
      MyApp.Accounts.User

      iex> find_resource_for_id(domains, "florb_CWzLBdFy2f1XhrtesFferY")
      nil
  """
  @spec find_resource_for_id([module()], String.t()) :: module() | nil
  def find_resource_for_id(domains, id) when is_list(domains) and is_binary(id) do
    case Type.decode_object_id(id) do
      {:ok, prefix, _uuid} -> find_resource_for_prefix(domains, prefix)
      _ -> nil
    end
  end

  @doc """
  Create a map of prefixes to the resources that use that prefix.
  """
  @spec map_prefixes_to_resources([module()]) :: %{String.t() => [module()]}
  def map_prefixes_to_resources(domains) do
    Enum.reduce(domains, %{}, fn domain, mapping ->
      domain
      |> Ash.Domain.Info.resources()
      |> Enum.reduce(mapping, fn resource, mapping ->
        resource
        |> Ash.Resource.Info.primary_key()
        |> Enum.reduce(mapping, fn attr_name, mapping ->
          attribute = Ash.Resource.Info.attribute(resource, attr_name)
          # Force loading the module with a cheap function call
          attribute.type.ecto_type()

          if function_exported?(attribute.type, :__object_id_info__, 0) do
            prefix = attribute.type.__object_id_info__()[:prefix]
            Map.update(mapping, prefix, [resource], &[resource | &1])
          else
            mapping
          end
        end)
      end)
    end)
  end

  @doc """
  Same as `map_prefixes_to_resources`, but returns only the entries that
  contain more than resource for the given prefix.

  This function can be used to warn whenever duplicate prefixes are present in
  your modules. For example, in a test:

      test "there are no duplicate object id prefixes" do
        domains = Application.fetch_env!(:my_otp_app, :ash_domains)
        assert AshObjectIds.find_duplicate_prefixes(domains) == %{}
      end
  """
  @spec find_duplicate_prefixes([module()]) :: %{String.t() => [module()]}
  def find_duplicate_prefixes(domains) do
    domains
    |> map_prefixes_to_resources()
    |> Map.filter(fn
      {_key, [_]} -> false
      _ -> true
    end)
  end
end
