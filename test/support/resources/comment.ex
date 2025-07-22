defmodule AshObjectIds.Test.Resources.Comment do
  @moduledoc false

  alias AshObjectIds.Test.Resources.Post

  use Ash.Resource,
    domain: AshObjectIds.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshObjectIds]

  object_id do
    prefix "c"
  end

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:body, :post_id], update: [:body]])
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:body, :string, public?: true)
  end

  relationships do
    belongs_to(:post, Post, attribute_type: Post.ObjectId)
  end
end
