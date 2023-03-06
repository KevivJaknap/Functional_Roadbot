defmodule Task3aOptimalSubsets do
  # Function that generates the list for array_of_digits randomly
  def random_list_generator do
    for _n <- 1..Enum.random(6..9), do: Enum.random(1..9)
  end

  # Function that generates the 2d matrix for matrix_of_sum randomly
  def random_matrix_generator do
    list_of_na = for _n <- 1..9, do: "na"

    recurse(list_of_na, Enum.random(3..5))
    |> Enum.chunk_every(3)
  end

  # Helper function for `random_matrix_generator()`
  def recurse(list_of_na, 0), do: list_of_na

  def recurse(list_of_na, num_of_sum) do
    recurse(List.replace_at(list_of_na, Enum.random(0..8), Enum.random(11..20)), num_of_sum - 1)
  end

  @doc """
  #Function name:
        valid_sum
  #Inputs:
        matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
        List of all vallid sums from the given 2d matrix
  #Details:
        Finds the valid sum values from the given 2d matrix
  """
  def valid_sum(matrix_of_sum \\ random_matrix_generator()) do
    IO.inspect(matrix_of_sum, label: "matrix_of_sum")
    ### Write your code here ###
    Task1aSumOfSubsets.valid_sum(matrix_of_sum)
  end

  @doc """
  #Function name:
        sum_of_one
  #Inputs:
        array_of_digits : Array containing single digit numbers to satisty sum
        sum_val         : Any 2 digit value for which subsets are to be created
  #Output:
        List of list of all possible subsets
  #Details:
        Finds the all possible subsets from given array of digits for a 2 digit value
  """

  def sum_of_one(array_of_digits \\ random_list_generator(), sum_val \\ Enum.random(11..20)) do
    IO.inspect(array_of_digits, label: "array_of_digits")
    IO.inspect(sum_val, label: "sum_val")
    ### Write your code here ###
    Task1aSumOfSubsets.sum_of_one(array_of_digits, sum_val)
  end

  @doc """
  #Function name:
        sum_of_all
  #Inputs:
        array_of_digits : Array containing single digit numbers to satisty sum
        matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
        Map of each sum value and it's respective subsets
  #Details:
        Finds the all possible subsets from given array of digits for all valid sums elements of given 2d matrix
  """
  def sum_of_all(
        array_of_digits \\ random_list_generator(),
        matrix_of_sum \\ random_matrix_generator()
      ) do
    IO.inspect(array_of_digits, label: "array_of_digits")
    IO.inspect(matrix_of_sum, label: "matrix_of_sum")
    ### Write your code here ###
    Task1aSumOfSubsets.sum_of_all(array_of_digits, matrix_of_sum)
  end

  @doc """
  #Function name:
        get_optimal_subsets
  #Inputs:
        array_of_digits : Array containing single digit numbers to satisty sum
        matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
        Map containing the sums and corresponding subset as keys & values respectively
  #Details:
        Function that takes matrix_of_sum and array_of_digits as argument and select single subset for each sum optimally to satisfy maximum sums
  #Example call:
      Check Task 3A Document
  """
  def get_optimal_subsets(
        array_of_digits \\ random_list_generator(),
        matrix_of_sum \\ random_matrix_generator()
      ) do
    IO.inspect(array_of_digits, label: "array_of_digits")
    IO.inspect(matrix_of_sum, label: "matrix_of_sum")
    ### Write your code here ###
    Main_.sub_main(array_of_digits, matrix_of_sum)
  end
end

defmodule Main_ do
  def ret_map(arr, mat) do
    Task1aSumOfSubsets.sum_of_all(arr, mat)
  end

  def find_subsets(arr, sum) do
    Task1aSumOfSubsets.sum_of_one(arr, sum)
  end

  def combinations(0, _), do: [[]]
  def combinations(_, []), do: []

  def combinations(size, [head | tail]) do
    for(elem <- combinations(size - 1, tail), do: [head | elem]) ++ combinations(size, tail)
  end

  def get_score_helper(sum, l) do
    Enum.reduce(l, 0, fn x, acc ->
      if Enum.sum(x) == sum do
        acc + 1
      else
        acc
      end
    end)
  end

  def get_score(d) do
    # filter out elements from map whose value is []
    d = Enum.filter(d, fn {_, v} -> v != [] end)

    Enum.reduce(d, 0, fn {k, v}, acc ->
      acc + get_score_helper(k, v)
    end)
  end

  def filter_helper([], _), do: true

  def filter_helper([h | t], main_lst) do
    if Enum.member?(main_lst, h) do
      main_lst = List.delete(main_lst, h)
      filter_helper(t, main_lst)
    else
      false
    end
  end

  def filter_(lst, main_lst) do
    new_list = List.flatten(lst)
    filter_helper(new_list, main_lst)
  end

  def return_combs(lst, k, kd, i) do
    ele = Enum.at(k, i)
    subsets = find_subsets(lst, ele)
    combs = combinations(Map.get(kd, ele), subsets)
    Enum.filter(combs, fn x -> filter_(x, lst) end)
  end

  def compare_and_save(ans, pid) do
    best = Agent.get(pid, fn x -> x end)

    if get_score(ans) > get_score(best) do
      Agent.update(pid, fn _x -> ans end)
    end
  end

  def delete_sublist(lst, sublst) do
    Enum.reduce(sublst, lst, fn x, acc ->
      List.delete(acc, x)
    end)
  end

  def add_list(lst, sublst) do
    Enum.reduce(sublst, lst, fn x, acc ->
      List.insert_at(acc, 0, x)
    end)
  end

  def func(_lst, k, _kd, i, _ans, _pid) when i == length(k) do
    :ok
  end

  def func(lst, k, kd, i, ans, pid) do
    possible_combs = return_combs(lst, k, kd, i)

    Enum.each(possible_combs, fn j ->
      ans = Map.put(ans, Enum.at(k, i), j)
      compare_and_save(ans, pid)
      sub_lst = List.flatten(j)
      new_lst = delete_sublist(lst, sub_lst)
      func(new_lst, k, kd, i + 1, ans, pid)
      ans = Map.put(ans, Enum.at(k, i), [])
    end)
  end

  def func_ret_val(lst, k, kd, pid) do
    # {:ok, pid} = Agent.start_link(fn -> %{} end)
    # func(lst, k, kd, 0, %{}, pid)
    # ret = Agent.get(pid, fn x -> x end)
    # Agent.stop(pid)
    # ret
    Agent.update(pid, fn _x -> %{} end)
    func(lst, k, kd, 0, %{}, pid)
    Agent.get(pid, fn x -> x end)

  end

  def knapsack(_, 0), do: []
  def knapsack([], _), do: []

  def knapsack([h | t], cap) when h > cap do
    knapsack(t, cap)
  end

  def knapsack([h | t], cap) do
    use_it = knapsack(t, cap - h)
    lose_it = knapsack(t, cap)

    if Enum.sum(use_it) + h > Enum.sum(lose_it) do
      [h | use_it]
    else
      lose_it
    end
  end

  def assign([], _, m) do
    m
  end

  def assign(caps, lst, m) do
    cap = Enum.at(caps, 0)
    k = knapsack(lst, cap)
    lst = delete_sublist(lst, k)
    m = Map.put(m, cap, [k])
    assign(List.delete_at(caps, 0), lst, m)
  end

  def counter(lst) do
    Map.new(lst, fn x ->
      {x, Enum.count(lst, fn y -> y == x end)}
    end)
  end

  def sub_main(aod, mat) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    lst = get_lst(mat)
    kd = counter(lst)
    k = Map.keys(kd)
    m = func_ret_val(aod, k, kd, pid)
    list_to_delete = List.flatten(Map.values(m))
    aod_ = delete_sublist(aod, list_to_delete)

    keys_not_assigned =
      Enum.filter(k, fn x ->
        not Enum.member?(Map.keys(m), x)
      end)

    ret = assign(keys_not_assigned, aod_, m)
    Agent.stop(pid)
    ret
  end

  def get_lst(mat) do
    List.flatten(mat)
    |> Enum.filter(fn x -> x != "na" end)
  end
end

defmodule BigFoo do
  def solve(list, s, ans \\ [], pid)

  def solve(list, s, ans, pid) when length(list) > 0 and s > 0 do
    [head | tail] = list
    ans = ans ++ [head]
    solve(tail, s - head, ans, pid)
    ans = List.delete_at(ans, -1)
    solve(tail, s, ans, pid)
  end

  def solve(_list, s, ans, pid) when s == 0 do
    Agent.update(pid, fn x -> [ans | x] end)
    ans
  end

  def solve(list, s, _ans, _pid) when s < 0 or length(list) == 0 do
    :ok
  end

  def main_solve(list, s) do
    {:ok, pid} = Agent.start_link(fn -> [] end)
    solve(list, s, [], pid)
    ret = Agent.get(pid, fn x -> x end)
    Agent.stop(pid)
    ret
  end
end

# defmodule Stack do
#   use GenServer

#   # Client

#   def start_link(initial_stack) do
#     GenServer.start_link(__MODULE__, initial_stack, name: __MODULE__)
#   end

#   def push(item) do
#     GenServer.cast(__MODULE__, {:push, item})
#   end

#   def pop do
#     GenServer.call(__MODULE__, :pop)
#   end

#   def view do
#     GenServer.call(__MODULE__, :view)
#   end

#   def clear do
#     GenServer.cast(__MODULE__, :clear)
#   end

#   def stop do
#     GenServer.cast(__MODULE__, :stop)
#   end

#   # Server
#   def init(initial_stack) do
#     {:ok, initial_stack}
#   end

#   def handle_call(:pop, _from, [head | tail]) do
#     {:reply, head, tail}
#   end

#   def handle_call(:view, _from, state) do
#     {:reply, state, state}
#   end

#   def handle_cast({:push, value}, state) do
#     state = [value | state]
#     {:noreply, state}
#   end

#   def handle_cast(:clear, _state) do
#     {:noreply, []}
#   end

#   def handle_cast(:stop, _state) do
#     {:stop, :normal, []}
#   end

#   def format_status(_reason, [_pdict, state]) do
#     [data: [{'State', "My current state is #{inspect(state)}"}]]
#   end
# end

defmodule Task1aSumOfSubsets do
  @moduledoc """
  A module that implements functions for getting
  sum of subsets from a given 2d matrix and array of digits
  """

  @doc """
  #Function name:
         valid_sum
  #Inputs:
         matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
         List of all vallid sums from the given 2d matrix
  #Details:
         Finds the valid sum values from the given 2d matrix
  #Example call:
    if given 2d matrix is as follows:
      matrix_of_sum = [
                        [21 ,"na", "na", "na", 12],
                        ["na", "na", 12, "na", "na"],
                        ["na", "na", "na", "na", "na"],
                        [17, "na", "na", "na", "na"],
                        ["na", 22, "na", "na", "na"]
                      ]

      iex(1)> matrix_of_sum = [
      ...(1)>       [21 ,"na", "na", "na", 12],
      ...(1)>       ["na", "na", 12, "na", "na"],
      ...(1)>       ["na", "na", "na", "na", "na"],
      ...(1)>       [17, "na", "na", "na", "na"],
      ...(1)>       ["na", 22, "na", "na", "na"]
      ...(1)>     ]
      iex(2)> Task1aSumOfSubsets.valid_sum(matrix_of_sum)
      [21, 12, 12, 17, 22]
  """
  def valid_sum(matrix_of_sum) do
    a = Enum.map(matrix_of_sum, fn x -> Enum.filter(x, &is_number/1) end)
    Enum.reduce(a, [], fn x, acc -> acc ++ x end)
  end

  @doc """
  #Function name:
         sum_of_one
  #Inputs:
         array_of_digits : Array containing single digit numbers to satisty sum
         sum_val         : Any 2 digit value for which subsets are to be created
  #Output:
         List of list of all possible subsets
  #Details:
         Finds the all possible subsets from given array of digits for a 2 digit value
  #Example call:
    if given array of digits is as follows:
      array_of_digits = [3, 5, 2, 7, 4, 2, 3]
      and sum_val = 10

      iex(1)> array_of_digits = [3, 5, 2, 7, 4, 2, 3]
      iex(2)> Task1aSumOfSubsets.sum_of_one(array_of_digits, 10)
      [[3, 7],[3, 2, 5],[3, 2, 5],[3, 4, 3],[7, 3],[3, 2, 2, 3],[2, 5, 3],[2, 5, 3]]
  """
  def sum_of_one(_array_of_digits, sum_val) when sum_val == 0 do
    []
  end

  def sum_of_one(array_of_digits, sum_val) do
    # {:ok, _pid} = Stack.start_link([])
    ans = BigFoo.main_solve(array_of_digits, sum_val)
    # Stack.stop()
    ans
  end

  @doc """
  #Function name:
         sum_of_all
  #Inputs:
         array_of_digits : Array containing single digit numbers to satisty sum
         matrix_of_sum   : A 2d matrix containing two digit numbers for which subsebts are to be created
  #Output:
         Map of each sum value and it's respective subsets
  #Details:
         Finds the all possible subsets from given array of digits for all valid sums elements of given 2d matrix
  #Example call:
    if given array of digits is as follows:
      array_of_digits = [3, 5, 2, 7, 4, 2, 3]
    and if given 2d matrix is as follows:
      matrix_of_sum = [
                        [21 ,"na", "na", "na", 12],
                        ["na", "na", 12, "na", "na"],
                        ["na", "na", "na", "na", "na"],
                        [17, "na", "na", "na", "na"],
                        ["na", 22, "na", "na", "na"]
                      ]

      iex(1)> array_of_digits = [3, 5, 2, 7, 4, 2, 3]
      iex(2)> matrix_of_sum = [
      ...(2)>                   [21 ,"na", "na", "na", 12],
      ...(2)>                   ["na", "na", 12, "na", "na"],
      ...(2)>                   ["na", "na", "na", "na", "na"],
      ...(2)>                   [17, "na", "na", "na", "na"],
      ...(2)>                   ["na", 22, "na", "na", "na"]
      ...(2)>                 ]
      iex(3)> Task1aSumOfSubsets.sum_of_all(array_of_digits, matrix_of_sum)
      %{
        12 => [[3, 2, 7],[3, 7, 2],[3, 4, 5],[7, 5],[3, 2, 2, 5],[3, 2, 4, 3],[2, 7, 3],[3, 4, 2, 3],[7, 2, 3],[4, 5, 3],[2, 2, 5, 3]],
        17 => [[3, 2, 7, 5],[3, 7, 2, 5],[3, 4, 7, 3],[3, 2, 7, 2, 3],[3, 2, 4, 5, 3],[2, 7, 5, 3],[3, 4, 2, 5, 3],[7, 2, 5, 3]],
        21 => [[3, 2, 4, 7, 5],[3, 4, 7, 2, 5],[3, 2, 4, 7, 2, 3],[2, 4, 7, 5, 3],[4, 7, 2, 5, 3]],
        22 => [[3, 4, 7, 5, 3], [3, 2, 7, 2, 5, 3]]
      }
  """
  def sum_of_all(array_of_digits, matrix_of_sum) do
    a = valid_sum(matrix_of_sum)
    # {:ok, _pid} = Stack.start_link([])
    ans = Map.new(a, fn x -> {x, BigFoo.main_solve(array_of_digits, x)} end)
    # Stack.stop()
    ans
  end
end
