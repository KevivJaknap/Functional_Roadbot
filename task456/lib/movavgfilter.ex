defmodule MovAvgFilter do
  use GenServer

  def start_link(win_size) do
    GenServer.start_link(__MODULE__, {[0, 0, 0, 0, 0], win_size}, name: __MODULE__)
  end

  def get_val(values) do
    GenServer.call(__MODULE__, {:get_val, values})
  end

  def handle_call({:get_val, values}, _from, {lst, win_size}) do
    {pos, sum} = Line3.get_attr(values)
    lst = [pos | lst] |> Enum.slice(0, win_size)
    {:reply, {Enum.sum(lst) / win_size, sum}, {lst, win_size}}
  end

  def init(state) do
    {:ok, state}
  end
end
