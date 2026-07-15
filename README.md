# AshObjectIds

An extension for Ash for working with [object IDs](https://dev.to/stripe/designing-apis-for-humans-object-ids-3o5a).

``` elixir
defmodule App.Blog.Post do
  use Ash.Resource,
    domain: App.Blog,
    data_layer: Ash.DataLayer.AshPostgres

  defmodule Id do
    use AshObjectIds.Type, prefix: "p", uuid_type: :uuid_v7
  end

  # .. data layer stuff

  actions do
    defaults([:read, :destroy, create: [:title], update: [:title]])
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
    # ... other attributes
  end
end

# Example:
%Post{id: "p_Cd4XsS9R7QseqGnYf3eZb"} =
  Post
  |> Ash.Changeset.for_create(:create, %{title: "Hello world"})
  |> Ash.create!()
```

For more detailed information, read the `AshObjectIds` moduledoc.
