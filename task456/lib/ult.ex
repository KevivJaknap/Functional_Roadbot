# defmodule Robot do
#   use GenServer
#   defstruct path: [], facing: 1, current: 0, path_taken: [], path_dir: [], int_node: 0

#   #node = 0 for connect node
#   #node = 1 for drop node

#   def start_link(opts \\ []) do
#     GenServer.start_link(__MODULE__, opts, name: __MODULE__)
#   end

#   def found() do
#     GenServer.call(__MODULE__, :found)
#   end

#   def get_current() do
#     GenServer.call(__MODULE__, :get_current)
#   end

#   def handle_call(:get_current, _from, state) do
#     {:reply, [state.current, state.path_dir], state}
#   end

#   def handle_call(:found, _from, state) do
#     FooLock.update(:unlocked)
#     if FooLock.get() == :locked do
#       {:reply, :locked, state}
#     else
#       FooLock.update(:locked)
#       FooLock.lock(5)
#       int_node = rem(state.int_node + 1, 2)
#       if int_node == 0 do
#         {:reply, :connect_node, %{state | int_node: int_node}}
#       else
#         [cur_dir | rest_dir] = state.path_dir
#         if rest_dir == [] do
#           {:reply, :end, %{state | int_node: int_node}}
#         else
#           {:reply, cur_dir, %__MODULE__{int_node: int_node, path: [], facing: cur_dir, current: cur, path_taken: [], path_dir: rest_dir}}
#         end
#       end
#       # {:reply, :found, %__MODULE__{int_node: rem(state.int_node+1, 2), path: state.path, facing: state.facing, current: state.current, path_taken: [state.current | state.path_taken], path_dir: state.path_dir}}
#       # [cur | rest] = state.path
#       # [cur_dir | rest_dir] = state.path_dir
#       # {:reply, :found, %__MODULE__{int_node: rem(state.int_node+1, 2), path: rest, facing: cur_dir, current: cur, path_taken: [cur | state.path_taken], path_dir: rest_dir}}
#     end
#   end

#   def init(opts) do
#     FooLock.start_link(:locked)
#     path_dir = YOhello.get_paths(opts[:path], 1)
#     {:ok, %__MODULE__{facing: 1, current: 0, path_taken: [], path: opts[:path], path_dir: path_dir}}
#   end
# end
