defmodule AshObjectIds.Test.Resources.Comment do
  @moduledoc false

  use AshObjectIds, prefix: "c", uuid_type: :uuid

  use Ash.Resource,
    domain: AshObjectIds.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  alias AshObjectIds.Test.Resources.Post

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:body, :post_id], update: [:body]])
  end

  attributes do
    object_id_primary_key()

    attribute(:body, :string, public?: true)
  end

  relationships do
    belongs_to(:post, Post, attribute_type: Post.Id)
  end
end
