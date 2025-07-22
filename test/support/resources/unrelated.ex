defmodule AshObjectIds.Test.Resources.Unrelated do
  @moduledoc false

  use Ash.Resource,
    domain: AshObjectIds.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshObjectIds]

  object_id do
    # Duplicate with comment
    prefix "c"
  end

  ets do
    private?(true)
  end

  attributes do
    uuid_primary_key(:id)
  end
end
