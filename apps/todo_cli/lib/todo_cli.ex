defmodule TodoCli do
  alias TodoCli.State

  @messages %{
    help: """
      ***
    * add     -- Create a new todo item.
    * finish  -- Mark a todo item as complete.
    * list    -- Show a list of items left to do on your todo list.
    * all     -- Show a list of all items, including complete items.
    * done    -- Show a list of all complete items.
    * delete  -- Remove an item from the list.
    * edit    -- Update the Title or Description of an item.
    * quit    -- Exit the application.
      ***
    """,
    init: """
    Please enter a command:
    """,
    add_title: """
    Please enter the title of the item you want to add:
    """,
    add_description: """
    Please enter a description of the item:
    """,
    finish: """
    Please enter the number of the item you would like to mark as complete:
    """,
    list: """
    TODO:
    """,
    all: """
    All Items:
    """,
    done: """
    Complete:
    """,
    delete: """
    Please enter the number of the item you would like to remove:
    """,
    edit: """
    Please enter the number of the item you would like to edit:
    """,
    which_field: """
    What is the number of the field you would like to edit:
    1) Title
    2) Description
    """,
    enter_update: """
    Please enter what you would like the updated field to be:
    """
  }

  @updates %{
    1 => :title,
    2 => :description
  }

  def start(_, _) do
    IO.puts("Welcome to the todo app!")
    continue({:init, %State{}})
  end

  defp continue({:init, state}) do
    IO.gets(@messages[:init])
    |> parse_input_to_atom()
    |> (fn inp -> continue({inp, state}) end).()
  end

  defp continue({:help, state}) do
    IO.puts(@messages[:help])
    continue({:init, state})
  end

  defp continue({:add, state}) do
    title = IO.gets("Please enter a title: ")
    description = IO.gets("Please enter a description: ")

    case Todo.new(title, description) do
      {:ok, _, _item} ->
        IO.puts("New Item added successfully!")
        continue({:list, state})

      {:error, :validation_error, errs} ->
        IO.puts("Sorry, but your todo item contained the following errors: ")
        print_errors(errs)
        continue({:init, state})

      _ ->
        IO.puts("That was wierd..")
        continue({:init, state})
    end
  end

  defp continue({:list, state}) do
    items = Todo.list_todo()

    case items do
      [] ->
        IO.puts("There are no items on your list yet! Use the add command to add one.");
        continue({:init, state})
      items ->
        {_map, list} = printable_table_and_id_map(items)
        Scribe.print(list)
        continue({:init, state})
    end
  end

  defp continue({:all, state}) do
    items = Todo.list_all()

    case items do
      [] ->
        IO.puts("There are no items on your list yet! Use the add command to add one.");
        continue({:init, state})
      items ->
        {_map, list} = printable_table_and_id_map(items)
        Scribe.print(list)
        continue({:init, state})
    end
  end

  defp continue({:done, state}) do
    items = Todo.list_complete()

    case items do
      [] ->
        IO.puts("There are no items on your list yet! Use the add command to add one.");
        continue({:init, state})
      items ->
        {_map, list} = printable_table_and_id_map(items)
        Scribe.print(list)
        continue({:init, state})
    end
  end

  defp continue({:delete, state}) do
    items = Todo.list_all()

    case items do
      [] ->
        IO.puts("There are no items on your list yet! Use the add command to add one.");
        continue({:init, state})
      items ->
        {map, list} = printable_table_and_id_map(items)
        Scribe.print(list)

        IO.gets("Which item would you like to delete? Indicate by number: ")
        |> parse_input_to_num()
        |> handle_delete(%{state | map: map})
    end
  end

  defp continue({:edit, state}) do
    items = Todo.list_all()

    case items do
      [] ->
        IO.puts("I can't find any todo Items. Try using \"add\" to add one.")
        continue({:init, state})
      items ->
        {map, lst} = printable_table_and_id_map(items)
        Scribe.print(lst)
        IO.gets("\n Which item would you like to edit?")
        |> parse_input_to_num()
        |> handle_update(%{state | map: map})
    end
  end

  defp continue({:finish, state}) do
    items = Todo.list_todo()

    case items do
      [] ->
        IO.puts("You don't have any items left to do on your list. Try adding one.")
        continue({:init, state})
      items ->
        {map, lst} = printable_table_and_id_map(items)
        Scribe.print(lst)
        IO.gets("\n Which item would you like to mark as complete? ")
        |> parse_input_to_num()
        |> handle_update_done(%{state | map: map})
    end
  end

  defp continue({:quit, _}) do
    IO.puts("Bye!")
    System.stop(0)
  end

  defp continue({_, state}) do
    IO.puts("You must enter a valid command, enter help to see a list of commands.")
    continue({:init, state})
  end

  defp handle_delete(:error, state) do
    IO.puts("You must input a valid number to select an item.")
    continue({:init, %{state | map: []}})
  end

  defp handle_delete(n, state = %State{map: map}) do
    res = map[n]

    case res do
      nil ->
        IO.puts("That number does not correspond to an item.")

      res ->
        {msg, _, _} = Todo.delete(res)
        if msg == :ok do
          IO.puts("Your item has been deleted successfully.")
          continue({:all, state})
        else
          IO.puts("Your item could not be deleted. Try again.")
          continue({:init, state})
        end
    end
  end

  defp handle_update(:error, state) do
    IO.puts("You must input a valid number to select an item.")
    continue({:init, %{state | map: []}})
  end

  defp handle_update({:error, :no_item, _}, state) do
    IO.puts("That number does not correspond with an item!")
    continue({:init, %{state | map: []}})
  end

  defp handle_update({:error, :validation_error, errs}, state) do
    IO.puts("The item couldn't be updated due to validation errors. The following errors occurred.")
    print_errors(errs)
    continue({:init, %{state | map: []}})
  end

  defp handle_update({:ok, _, _}, state) do
    IO.puts("The item was updated successfully!")
    continue({:all, %{state | map: []}})
  end

  defp handle_update(n, state = %{map: map}) do
    res = map[n]

    case res do
      nil ->
        IO.puts("That number does not correspond with an item.")
        continue({:init, %{state | map: []}})
      res ->
        field = IO.gets("Would you like to change 1) the Title, or 2) the Description? Indicate '1' or '2': ")
        {parsed_field, _} = field |> String.trim() |> Integer.parse()
        if parsed_field in [1, 2] do
          x = IO.gets("What would you like the new value to be? ")
          Todo.update(res, [{@updates[parsed_field], x}])
          |> handle_update(state)
        else
          IO.puts("That is not a valid option.")
          handle_update(n, state)
        end
    end
  end

  defp handle_update_done(:error, state) do
    IO.puts("You must input a valid number to select an item.")
    continue({:init, %{state | map: []}})
  end

  defp handle_update_done(n, state = %{map: map}) do
    res = map[n] |> Todo.mark_as_done()

    case res do
      {:error, :no_item} ->
        IO.puts("That item wasn't found. You must input a valid item to update.")
        continue({:init, %{state | map: []}})

      {:error, :validation_error, errs} ->
        IO.puts("That item couldn't be updated, for the following reason: ")
        print_errors(errs)
        continue({:init, %{state | map: []}})

      {:ok, _, item} ->
        IO.puts("Great! The item has been marked as complete.")
        todo_to_printable(item, n) |> Scribe.print()
        continue({:init, %{state | map: []}})
    end

  end

  defp print_errors(errs) do
    errs
    |> Enum.reduce("", fn {field, message}, acc -> "#{Atom.to_string(field)} #{message}\n#{acc}" end)
    |> IO.puts()
  end

  # Maps over the list of Todo Items gotten from the Repo, assigns them numbers for identification by user.
  # At the same time, it creates a new list of maps which have the information we would like to be printed by Scribe.
  # It returns a tuple of a map which allows look up of an item's id, from its position in the table, and the printable table.
  defp printable_table_and_id_map(item_list) do
    item_list
    |> Enum.with_index(1)
    |> Enum.reduce({%{}, []}, fn {item, i}, {map, lst} ->
      {
        Map.put(map, i, item.id),
        [todo_to_printable(item, i) | lst]
      }
    end)
  end

  # I could have simply done this within the Scribe.print data attribute, but I didn't see it.
  defp todo_to_printable(%Todo.Item{title: title, description: description, done: done, inserted_at: added}, i) do
    %{
      number: i,
      title: title,
      description: description,
      done: done,
      added: added
    }
  end

  defp parse_input_to_atom(input) do
    input
    |> String.trim()
    |> String.downcase()
    |> String.to_atom()
  end

  defp parse_input_to_num(input) do
    input
    |> String.trim()
    |> String.downcase()
    |> Integer.parse()
    |> return_int()
  end

  defp return_int(:error), do: :error
  defp return_int({i, _}), do: i
end
