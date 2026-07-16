defmodule AshObjectIds do
  @moduledoc """
  A helper library for working with object IDs in Ash.

  Object IDs are identifiers that are prefixed with the resource they identify.
  A more detailed explanation can be found in the ["Designing APIs for
  humans"](https://dev.to/stripe/designing-apis-for-humans-object-ids-3o5a) blog post.

  This library provides an implementation for Ash, where the IDs are
  base58-encoded UUIDs with a prefix:

      defmodule App.Blog.Post do
        use Ash.Resource,
          domain: App.Blog,
          data_layer: Ash.DataLayer.AshPostgres,

        # This generates a __MODULE__.Id module that's an Ash.Type.
        use AshObjectIds, prefix: "p", uuid_type: :uuid_v7

        attributes do
          object_id_primary_key()
          # ... other attributes
        end
      end

  Alternatively, if you want to control the module generation (or want to define
  it outside of the resource), then you can `use AshObjectIds.Type`:

      defmodule App.Blog.Post.Id do
        use AshObjectIds.Type, prefix: "p", uuid_type: :uuid_v7
      end
  """

  alias AshObjectIds.Type

  defmacro __using__(opts) do
    quote do
      require AshObjectIds
      import AshObjectIds, only: [object_id_primary_key: 0, object_id_primary_key: 1]

      defmodule Id do
        use AshObjectIds.Type, unquote(opts)
      end
    end
  end

  @doc """
  Generates an object ID primary key.

  This macro passes along the `opts` parameter to the `attribute` DSL.

  Additionally, it accepts the following:

    - `:name`: The attribute name of the field. Defaults to `:id`.
    - `:type`: The name of the object ID module. Defaults to the calling
      module's `__MODULE__.Id`.
  """
  defmacro object_id_primary_key(opts \\ []) do
    opts =
      opts
      |> Keyword.put_new_lazy(:type, fn -> Module.concat(__CALLER__.module, Id) end)
      |> Keyword.put_new(:primary_key?, true)
      |> Keyword.put_new(:public?, true)
      |> Keyword.put_new(:writable?, true)
      |> Keyword.put_new(:allow_nil?, false)
      |> Keyword.put_new(:name, :id)

    {type, opts} = Keyword.pop(opts, :type)
    {name, opts} = Keyword.pop(opts, :name)

    opts = Keyword.put_new(opts, :default, {type, :generate, []})

    quote do
      attribute(unquote(name), unquote(type), unquote(Macro.escape(opts)))
    end
  end

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
