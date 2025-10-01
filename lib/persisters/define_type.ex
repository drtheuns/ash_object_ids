defmodule AshObjectIds.Persisters.DefineType do
  @moduledoc false
  use Spark.Dsl.Transformer

  def transform(dsl) do
    prefix = AshObjectIds.Info.object_id_prefix!(dsl)
    module = Spark.Dsl.Transformer.get_persisted(dsl, :module)

    {dsl, uuid_type} =
      case Ash.Resource.Info.primary_key(dsl) do
        [pk] ->
          attr = Ash.Resource.Info.attribute(dsl, pk)
          example = attr.type.generator(attr.constraints) |> Enum.take(1) |> hd()

          if Ecto.UUID.cast(example) == :error do
            raise Spark.Error.DslError,
              module: module,
              message: "Expected a UUID type for the primary key",
              path: [:attributes, pk]
          end

          uuid_type = attr.type
          new_type = Module.concat(module, ObjectId)

          attr = %{
            attr
            | type: new_type,
              default: {AshObjectIds.Type, :generate, [uuid_type, prefix, attr.constraints]}
          }

          dsl =
            Spark.Dsl.Transformer.replace_entity(dsl, [:attributes], attr, fn record ->
              record.__struct__ == attr.__struct__ && record.name == attr.name
            end)

          {dsl, uuid_type}

        [] ->
          raise Spark.Error.DslError,
            module: module,
            message: "Missing UUID primary key attribute",
            path: [:attributes]

        _ ->
          raise Spark.Error.DslError,
            module: module,
            message: "Expected only a single primary key UUID attribute.",
            path: [:attributes]
      end

    {:ok,
     Spark.Dsl.Transformer.eval(
       dsl,
       [
         uuid_type: uuid_type,
         prefix: prefix
       ],
       quote do
         defmodule ObjectId do
           use Ash.Type

           @impl Ash.Type
           defdelegate storage_type(constraints), to: unquote(uuid_type)

           @impl Ash.Type
           def cast_input(input, constraints) do
             AshObjectIds.Type.cast_input(unquote(uuid_type), unquote(prefix), input, constraints)
           end

           @impl Ash.Type
           def cast_stored(input, constraints) do
             AshObjectIds.Type.cast_stored(
               unquote(uuid_type),
               unquote(prefix),
               input,
               constraints
             )
           end

           @impl Ash.Type
           def dump_to_native(input, constraints) do
             AshObjectIds.Type.dump_to_native(
               unquote(uuid_type),
               unquote(prefix),
               input,
               constraints
             )
           end

           @impl Ash.Type
           def dump_to_embedded(value, constraints) do
             cast_input(value, constraints)
           end

           @impl Ash.Type
           def matches_type?(value, constraints) do
             case cast_input(value, constraints) do
               {:ok, _} -> true
               _ -> false
             end
           end

           @impl Ash.Type
           def cast_atomic(new_value, constraints) do
             unquote(uuid_type).cast_atomic(new_value, constraints)
           end

           @impl Ash.Type
           def generator(constraints) do
             AshObjectIds.Type.generator(unquote(uuid_type), unquote(prefix), constraints)
           end
         end
       end
     )}
  end
end
