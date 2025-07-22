defmodule AshObjectIds.Type do
  @moduledoc false

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
    case decode_object_id(input, prefix) do
      {:ok, uuid} ->
        # This doesn't just call `uuid_type.dump_to_native` because
        # Ecto.UUID.dump doesn't support the 128bit uuid, so it would
        # succeed for Ash.Type.UUIDv7, but fail for Ash.Type.UUID.
        # So only deal with it in case of custom UUID types.
        case uuid_type do
          Ash.Type.UUID -> uuid
          Ash.Type.UUIDv7 -> uuid
          _ -> uuid_type.dump_to_native(uuid, constraints)
        end

      _ ->
        :error
    end

    with {:error, _} <- decode_object_id(input, prefix) do
      :error
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
