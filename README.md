# AshObjectIds

An extension for Ash for working with [object IDs](https://dev.to/stripe/designing-apis-for-humans-object-ids-3o5a).

``` elixir
defmodule App.Blog.Post do
  use Ash.Resource,
    domain: App.Blog,
    data_layer: Ash.DataLayer.AshPostgres,
    extensions: [AshObjectIds]

  object_id do
    prefix "p"
  end

  # .. data layer stuff

  actions do
    defaults([:read, :destroy, create: [:title], update: [:title]])
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, public?: true)
    # ... other attributes
  end
end

# Example:
%Post{id: "p_CWzLBdFy2f1XhrtesFferY"} =
  Post
  |> Ash.Changeset.for_create(:create, %{title: "Hello world"})
  |> Ash.create!()
```

For more detailed information, read the `AshObjectIds` moduledoc.
