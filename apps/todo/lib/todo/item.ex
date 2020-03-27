defmodule Todo.Item do
  use Ecto.Schema

  schema "items" do
    field :title, :string
    field :description, :string
    field :done, :boolean, default: false

    timestamps()
  end

  def changeset(item, params \\ %{}) do
    item
    |> Ecto.Changeset.cast(params, [:title, :description, :done])
    |> Ecto.Changeset.validate_required([:title, :description])
  end
end
