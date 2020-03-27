defmodule Todo.Repo.Migrations.CreateTodoItem do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :title, :string, null: false
      add :description, :string, null: false
      add :done, :boolean

      timestamps()
    end
  end
end
