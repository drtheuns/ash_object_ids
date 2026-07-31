defmodule AshObjectIds.Type do
  @moduledoc """
  Helper to define the object ID as `Ash.Type`.
  """

  defmacro __using__(opts) do
    prefix = Keyword.fetch!(opts, :prefix)
    uuid_type = Keyword.get(opts, :uuid_type, :uuid) |> Ash.Type.get_type()

    quote do
      use Ash.Type

      def __object_id_info__, do: [prefix: unquote(prefix), uuid_type: unquote(uuid_type)]

      if Code.ensure_loaded?(AshTypescript) do
        def typescript_type_name, do: "string"
        defoverridable typescript_type_name: 0
      end

      @impl Ash.Type
      defdelegate storage_type(constraints), to: unquote(uuid_type)

      @impl Ash.Type
      def cast_input(input, constraints) do
        AshObjectIds.Type.cast_input(unquote(uuid_type), unquote(prefix), input, constraints)
      end

      @impl Ash.Type
      def cast_stored(input, constraints) do
        AshObjectIds.Type.cast_stored(
          unquote(uuid_type),
          unquote(prefix),
          input,
          constraints
        )
      end

      @impl Ash.Type
      def dump_to_native(input, constraints) do
        AshObjectIds.Type.dump_to_native(
          unquote(uuid_type),
          unquote(prefix),
          input,
          constraints
        )
      end

      @impl Ash.Type
      def dump_to_embedded(value, constraints) do
        cast_input(value, constraints)
      end

      @impl Ash.Type
      def matches_type?(value, constraints) do
        case cast_input(value, constraints) do
          {:ok, _} -> true
          _ -> false
        end
      end

      @impl Ash.Type
      def cast_atomic(new_value, constraints) do
        unquote(uuid_type).cast_atomic(new_value, constraints)
      end

      @impl Ash.Type
      def generator(constraints) do
        AshObjectIds.Type.generator(unquote(uuid_type), unquote(prefix), constraints)
      end

      def generate(constraints \\ []) do
        AshObjectIds.Type.generate(unquote(uuid_type), unquote(prefix), constraints)
      end
    end
  end

  def cast_input(_uuid_type, _prefix, nil, _constraints), do: {:ok, nil}

  def cast_input(uuid_type, prefix, input, constraints) do
    with {:ok, uuid_bin} <- decode_object_id(input, prefix),
         {:ok, _uuid} <- uuid_type.cast_input(uuid_bin, constraints) do
      # Keep the value in object id form
      {:ok, input}
    end
  end

  def cast_stored(_uuid_type, _prefix, nil, _constraints), do: {:ok, nil}

  def cast_stored(uuid_type, prefix, input, constraints) do
    with {:ok, uuid} when is_binary(uuid) <- uuid_type.cast_stored(input, constraints) do
      {:ok, encode_uuid(input, prefix)}
    end
  end

  def dump_to_native(_uuid_type, _prefix, nil, _constraints), do: {:ok, nil}

  def dump_to_native(uuid_type, prefix, input, constraints) do
    with {:ok, binary_uuid} <- decode_object_id(input, prefix),
         {:ok, _} <- uuid_type.cast_stored(binary_uuid, constraints) do
      {:ok, binary_uuid}
    end
  end

  def encode_uuid(binary_uuid, prefix) do
    "#{prefix}_#{:base58.binary_to_base58(binary_uuid)}"
  end

  def decode_object_id(input, prefix) do
    case decode_object_id(input) do
      {:ok, ^prefix, uuid} -> {:ok, uuid}
      {:ok, _other, _uuid} -> {:error, "incorrect object prefix"}
      _ -> :error
    end
  end

  def decode_object_id(input) when is_binary(input) do
    case String.split(input, "_") do
      [prefix, slug] ->
        case :base58.base58_to_binary(to_charlist(slug)) do
          uuid when is_binary(uuid) and byte_size(uuid) == 16 -> {:ok, prefix, uuid}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def decode_object_id(_), do: :error

  def generator(uuid_type, prefix, constraints) do
    StreamData.repeatedly(fn ->
      generate(uuid_type, prefix, constraints)
    end)
  end

  def generate(uuid_type, prefix, constraints) do
    case uuid_type do
      Ash.Type.UUID ->
        Ecto.UUID.bingenerate()

      Ash.Type.UUIDv7 ->
        Ash.UUIDv7.bingenerate()

      _ ->
        # Generic implementation (for possibly custom UUID types)
        {:ok, bin} = uuid_type.generator(constraints) |> Enum.take(1) |> hd() |> Ecto.UUID.dump()
        bin
    end
    |> encode_uuid(prefix)
  end
end
