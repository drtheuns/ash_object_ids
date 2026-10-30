defmodule AshObjectIds.TypeTest do
  use ExUnit.Case, async: true

  alias AshObjectIds.Type

  for type <- [Ash.Type.UUID, Ash.Type.UUIDv7] do
    test "cast_input with #{inspect(type)}" do
      assert {:ok, nil} = Type.cast_input(unquote(type), "user", nil, [])
      id = Type.generate(unquote(type), "user", [])

      assert {:ok, ^id} =
               Type.cast_input(unquote(type), "user", id, [])

      assert {:error, "incorrect object prefix"} =
               Type.cast_input(unquote(type), "post", id, [])
    end

    test "cast_stored with #{inspect(type)}" do
      assert {:ok, nil} = Type.cast_stored(unquote(type), "user", nil, [])
      id = unquote(type).generator([]) |> Enum.take(1) |> hd()
      assert {:ok, "user_" <> _} = Type.cast_stored(unquote(type), "user", id, [])
    end

    # A uuid column yields 16 raw bytes; a uuid inside JSON (a map expression,
    # a value cast to text) yields the 36-character text. Both are the same
    # uuid and must give the same object id, which dumps back to the bytes.
    test "cast_stored encodes the bytes and the text form of a uuid alike with #{inspect(type)}" do
      text = unquote(type).generator([]) |> Enum.take(1) |> hd()
      {:ok, bytes} = Ecto.UUID.dump(text)

      assert {:ok, id} = Type.cast_stored(unquote(type), "user", bytes, [])
      assert {:ok, ^id} = Type.cast_stored(unquote(type), "user", text, [])
      assert {:ok, ^bytes} = Type.dump_to_native(unquote(type), "user", id, [])
      assert :error = Type.cast_stored(unquote(type), "user", "not a uuid", [])
    end
  end

  test "cannot pass correctly formatted ID from another UUID type" do
    id = Type.generate(Ash.Type.UUID, "user", [])

    assert :error = Type.cast_input(Ash.Type.UUIDv7, "user", id, [])
  end
end
