defmodule AshObjectIds do
  @moduledoc """
  An extension for working with object IDs.

  Object IDs are identifiers that are prefixed with the resource they identify.
  A more detailed explanation can be found in the ["Designing APIs for
  humans"](https://dev.to/stripe/designing-apis-for-humans-object-ids-3o5a) blog post.

  This library provides an implementation for Ash:

      defmodule App.Blog.Post do
        use Ash.Resource,
          domain: App.Blog,
          data_layer: Ash.DataLayer.AshPostgres,
          extensions: [AshObjectIds]

        object_id do
          prefix "p"
        end

        attributes do
          uuid_primary_key(:id)
          # ... other attributes
        end
      end

  `AshObjectIds` replaces the `:id` primary key with an object ID (prefixed by "p").
  The underlying UUID implementation will be used, so it works with both UUID
  and UUIDv7. The IDs are stored as regular UUIDs in the database.

  Each resource will have a generated `<resource>.ObjectId` module which is the
  `Ash.Type` for that ID. This can then be used with `belongs_to` relationships:

      relationships do
        belongs_to :post, App.Blog.Post, attribute_type: App.Blog.Post.ObjectId
      end
  """

  alias AshObjectIds.Type

  @persisters [
    AshObjectIds.Persisters.DefineType
  ]

  @object_id %Spark.Dsl.Section{
    name: :object_id,
    describe: "Use object ID for identifier of a resource",
    examples: [
      """
      object_id do
        prefix "u"
      end
      """
    ],
    schema: [
      prefix: [
        type: :string,
        doc: "The prefix to use for the given resource",
        required: true
      ]
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@object_id],
    persisters: @persisters

  @doc """
  Decodes the given object ID into a string version of the UUID.

  ## Examples

      iex> decode_object_id("user_CWzLBdFy2f1XhrtesFferY")
      {:ok, "5d446d08-df6a-404d-a1e5-decc78429b3d"}

      iex> decode_object_id("florb_CWzLBdFy2f1XhrtesFferY")
      :error

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
        case AshObjectIds.Info.object_id_prefix(resource) do
          {:ok, ^prefix} -> resource
          _ -> nil
        end
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
        case AshObjectIds.Info.object_id_prefix(resource) do
          {:ok, prefix} -> Map.update(mapping, prefix, [resource], &[resource | &1])
          _ -> mapping
        end
      end)
    end)
  end

  @doc """
  Same as `map_prefixes_to_resources`, but returns only the entries that
  contain more than resource for the given prefix.

  This function can be used to warn whenever duplicate prefixes are present in
  your modules.
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
