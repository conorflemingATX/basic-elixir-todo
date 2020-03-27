defmodule Todo do
  alias Todo.Repo
  alias Todo.Item

  import Ecto.Query, only: [from: 2]

  # Display/ List methods
  def list_all do
    from(i in Item, order_by: i.inserted_at)
    |> Repo.all()
  end

  def list_todo do
    from(i in Item, where: [done: false], order_by: i.inserted_at)
    |> Repo.all()
  end

  def list_complete do
    from(i in Item, where: [done: true], order_by: i.inserted_at)
    |> Repo.all()
  end

  # Main Crud Methods
  def new(title, description) do
      %Item{title: title, description: description}
      |> Item.changeset()
      |> Repo.insert()
      |> handle_ecto_response()
    end

    def delete(id) do
      Repo.get(Item, id)
      |> make_deletion()
    end

  def update(id, params \\ []) do
    Repo.get(Item, id)
    |> make_update(params)
  end

  def mark_as_done(id) do
    update(id, done: true)
  end

  # CRUD private helpers

  defp make_update(item = %Item{}, params) do
    params = kw_to_map(params)
    item
    |> Item.changeset(params)
    |> Repo.update()
    |> handle_ecto_response()
  end

  defp make_update(nil, _) do
    {:error, :no_item}
  end

  defp make_deletion(nil) do
    {:error, :no_item}
  end

  defp make_deletion(item = %Item{}) do
    item
    |> Repo.delete()
    |> handle_ecto_response()
  end

  # Response Handling helpers

  # Extract relevant data for use in string formatter in cli.
  defp handle_ecto_response({:error, changeset}) do
    map_changeset_errors(changeset)
  end

  defp handle_ecto_response({:ok, item}), do: {:ok, nil, item}

  defp map_changeset_errors(changeset) do
   err = changeset.errors
    |> Enum.map(fn {field, {message, _ }} -> {field, message} end)
    {:error, :validation_error, err}
  end

  defp kw_to_map(kw) do
    Enum.reduce(kw, %{}, fn ({k, v}, acc) -> Map.put(acc, k, v) end)
  end
end
