defmodule AshObjectIds.Test.Resources.Comment do
  @moduledoc false

  defmodule Id do
    use AshObjectIds.Type, prefix: "c", uuid_type: :uuid
  end

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
    attribute :id, Id do
      primary_key?(true)
      public?(true)
      writable?(false)
      default(&Id.generate/0)
      allow_nil?(false)
    end

    attribute(:body, :string, public?: true)
  end

  relationships do
    belongs_to(:post, Post, attribute_type: Post.Id)
  end
end
