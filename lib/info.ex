defmodule AshObjectIds.Info do
  use Spark.InfoGenerator, extension: AshObjectIds, sections: [:object_id]
end
