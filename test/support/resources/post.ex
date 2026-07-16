defmodule AshObjectIds.Test.Resources.Post do
  @moduledoc false

  use Ash.Resource,
    domain: AshObjectIds.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  use AshObjectIds, prefix: "post", uuid_type: :uuid_v7

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:title], update: [:title]])

    action :id_in_arg, :string do
      argument(:post_id, Id, allow_nil?: false)

      run(fn input, _context ->
        {:ok, input.arguments.post_id}
      end)
    end
  end

  attributes do
    object_id_primary_key()

    attribute(:title, :string, public?: true)
  end

  relationships do
    has_many(:comments, AshObjectIds.Test.Resources.Comment)
  end
end
