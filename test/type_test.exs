defmodule AshObjectIds.TypeTest do
  use ExUnit.Case, async: true

  alias AshObjectIds.Type

  for type <- [Ash.Type.UUID, Ash.Type.UUIDv7] do
    test "cast_input with #{inspect(type)}" do
      assert {:ok, nil} = Type.cast_input(unquote(type), "user", nil, [])

      assert {:ok, "user_CWzLBdFy2f1XhrtesFferY"} =
               Type.cast_input(unquote(type), "user", "user_CWzLBdFy2f1XhrtesFferY", [])

      assert {:error, "incorrect object prefix"} =
               Type.cast_input(unquote(type), "post", "user_CWzLBdFy2f1XhrtesFferY", [])
    end

    test "cast_stored with #{inspect(type)}" do
      assert {:ok, nil} = Type.cast_stored(unquote(type), "user", nil, [])
      id = unquote(type).generator([]) |> Enum.take(1) |> hd()
      assert {:ok, "user_" <> _} = Type.cast_stored(unquote(type), "user", id, [])
    end
  end
end
