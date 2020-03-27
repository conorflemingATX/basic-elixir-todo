defmodule TodoCli.State do
  alias __MODULE__

  defstruct input: [], map: %{}

  def add_to_input_list(input, state = %State{}) do
    {
      input,
      %{state | input: [input | state.input]}
    }
  end
end
