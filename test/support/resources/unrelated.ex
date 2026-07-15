defmodule AshObjectIds.Test.Resources.Unrelated do
  @moduledoc false

  defmodule Id do
    # Duplicate with comment
    use AshObjectIds.Type, prefix: "c", uuid_type: :uuid
  end

  use Ash.Resource,
    domain: AshObjectIds.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  attributes do
    attribute :id, Id do
      primary_key?(true)
      public?(true)
      writable?(false)
      default(&Id.generate/0)
      allow_nil?(false)
    end
  end
end
