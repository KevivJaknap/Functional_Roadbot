defmodule Locations do
  def get_loc(matrix) do
    List.flatten(matrix)
    |>
    Enum.with_index(fn ele, ind ->
      {ele, ind+1}
    end)
    |>
    Enum.filter(fn {ele, _ind} ->
      ele != "na"
    end)
    |>
    Enum.map(fn {_ele, ind} ->
      ind
    end)
  end
end
defmodule Find do
  def find_dist(cell_map, src, [head | tail]) when length(tail) == 0 do
    Main.distance(cell_map, src, head)
  end
  def find_dist(cell_map, src, [head | tail]) do
    Main.distance(cell_map, src, head) + find_dist(cell_map, head, tail)
  end
  def find(cell_map, [head | tail]) do
    all_set = Permutations.of(tail)
    Enum.min_by(all_set, fn x -> find_dist(cell_map, head, x) end)
  end
  def find_path(cell_map, src, [head | tail]) when length(tail) == 0 do
    [Main.path(cell_map, src, head)]
  end
  def find_path(cell_map, src, [head | tail]) do
    [Main.path(cell_map, src, head)] ++ find_path(cell_map, head, tail)
  end
  def find_main([src | arr], cell_map) do
    new_arr = find(cell_map, [src | arr])
    find_path(cell_map, src, new_arr)
  end
end
defmodule Permutations do
  def of([]) do
    [[]]
  end

  def of(list) do
    for h <- list, t <- of(list -- [h]), do: [h | t]
  end
end
defmodule Main do
  def init_single_source(d, s) do
    keys = Map.keys(d)
    prev = Map.new(keys, fn x -> {x, :none} end)
    dist = Map.new(keys, fn x -> {x, :inf} end)

    dist = Map.replace(dist, s, 0)
    {dist, prev}
  end

  def relax(u, v, dist, prev) do
    dist_u = Map.get(dist, u)
    dist_v = Map.get(dist, v)
    {:ok, pid} = Agent.start_link(fn -> {dist, prev} end)
    if dist_v > dist_u + 1 do
      obj = {Map.replace(dist, v, dist_u + 1), Map.replace(prev, v, u)}
      Agent.update(pid, fn _x -> obj end)
    end
    ret = Agent.get(pid, fn x -> x end)
    :ok = Agent.stop(pid)
    ret
  end

  def dijkstra(d, s) do
    {dist, prev} = init_single_source(d, s)
    q = Map.keys(d)
    recur_d(q, dist, prev, d)
  end

  def recur_d(q, dist, prev, _d) when length(q) == 0 do
    {dist, prev}
  end

  def recur_d(q, dist, prev, d) do
    u = Enum.min_by(q, fn x ->
      Map.get(dist, x)
    end)
    q = List.delete(q, u)
    list = Map.get(d, u)
    {dist, prev} = Enum.reduce(list, {dist, prev}, fn x, {dist, prev} ->
      relax(u, x, dist, prev)
    end)
    recur_d(q, dist, prev, d)
  end

  def return_path(_prev, s, v) when v == s do
    [s]
  end

  def return_path(prev, s, v) do
    return_path(prev, s, Map.get(prev, v)) ++ [v]
  end

  def path(d, src, dest) do
    {_dist, prev} = dijkstra(d, src)
    return_path(prev, src, dest)
  end
  
  def distance(d, src, dest) do
    {dist, _prev} = dijkstra(d, src)
    Map.get(dist, dest)
  end
end
defmodule Task2PathTraversal do
@moduledoc """
  A module that implements functions for
  path planning algorithm and travels the path
  """

  @cell_map %{ 1 => [4],
                2 => [3, 5],
                3 => [2],
                4 => [1, 7],
                5 => [2, 6, 8],
                6 => [5, 9],
                7 => [4, 8],
                8 => [5, 7],
                9 => [6]
  }

  @matrix_of_sum [
    ["na","na", 15],
    ["na", "na", 12],
    ["na", 10, "na"]
  ]

  @doc """
  #Function name:
          get_locations
  #Inputs:
          A 2d matrix namely matrix_of_sum containing two digit numbers
  #Output:
          List of locations of the valid_sum which should be in ascending order
  #Details:
          To find the cell locations containing valid_sum in the matrix
  #Example call:
          Check Task 2 Document
  """
  def get_locations(matrix_of_sum \\ @matrix_of_sum) do
        Locations.get_loc(matrix_of_sum)
  end

  @doc """
  #Function name:
          cell_traversal
  #Inputs:
          cell_map which contains all paths as well as the start and goal locations
  #Output:
          List containing the path from start to goal location
  #Details:
          To find the path from start to goal location
  #Example call:
          Check Task 2 Document
  """
  def cell_traversal(cell_map \\ @cell_map, start, goal) do
        Main.path(cell_map, start, goal)
  end

  @doc """
  #Function name:
          traverse
  #Inputs:
          a list (this will be generated in grid_traversal function) and the cell_map
  #Output:
          List of lists containing paths starting from the 1st cell and visiting every cell containing valid_sum
  #Details:
          To find shortest path from first cell to all valid_sum’s locations
  #Example call:
          Check Task 2 Document
  """
  def traverse(list, cell_map) do
        Find.find_main(list, cell_map)
  end

  @doc """
  #Function name:
          grid_traversal
  #Inputs:
          cell_map and matrix_of_sum
  #Output:
          List of keyword lists containing valid_sum locations along with paths obtained from traverse function
  #Details:
          Driver function which calls the get_locations and traverse function and returns the output in required format
  #Example call:
          Check Task 2 Document
  """
  def grid_traversal(cell_map \\ @cell_map,matrix_of_sum \\ @matrix_of_sum) do
    [1] ++ get_locations(matrix_of_sum)
    |> traverse(cell_map)
    |> Enum.map(fn path_list ->
        [{ Enum.at(path_list, -1)
           |> Integer.to_string()
           |> String.to_atom(), path_list}]
        end)
  end

end

