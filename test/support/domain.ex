defmodule AshObjectIds.Test.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshObjectIds.Test.Resources.Post)
    resource(AshObjectIds.Test.Resources.Comment)
    resource(AshObjectIds.Test.Resources.Unrelated)
  end
end
