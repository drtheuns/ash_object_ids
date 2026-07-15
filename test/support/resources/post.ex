defmodule AshObjectIds.Test.Resources.Post do
  @moduledoc false

  defmodule Id do
    use AshObjectIds.Type, prefix: "post", uuid_type: :uuid_v7
  end

  use Ash.Resource,
    domain: AshObjectIds.Test.Domain,
    data_layer: Ash.DataLayer.Ets

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
    attribute :id, Id do
      primary_key?(true)
      public?(true)
      writable?(false)
      default(&Id.generate/0)
      allow_nil?(false)
    end

    attribute(:title, :string, public?: true)
  end

  relationships do
    has_many(:comments, AshObjectIds.Test.Resources.Comment)
  end
end
