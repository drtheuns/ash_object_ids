defmodule AshObjectIds.Test.Resources.Unrelated do
  @moduledoc false

  use Ash.Resource,
    domain: AshObjectIds.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  # Duplicate with comment
  use AshObjectIds, prefix: "c", uuid_type: :uuid

  ets do
    private?(true)
  end

  attributes do
    object_id_primary_key(public?: false)
  end
end
