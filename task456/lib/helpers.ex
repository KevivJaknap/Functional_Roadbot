defmodule Helpers do
  def path_cleaner(cell_map, mat) do
    lst =  Locations.get_loc(mat)
    sol = [[1]] ++ Find.find_main(lst, cell_map)
    IO.inspect sol
    ors = [1] ++ Enum.map(sol, fn x -> YOhello.with_orientation(x) end)
    paths = Enum.with_index(sol)
    |> Enum.map(fn {ele, ind} -> pc_helper(ele, Enum.at(ors, ind)) end)
    i = [:straight, :end]
    [h | t] = paths
    [i | t]
  end

  def pc_helper(lst, orient) do
    YOhello.get_paths(lst, orient)
  end

  def drop_cleaner(aod, mat) do
    map = Main_.sub_main(aod, mat)
    mat
    |> List.flatten
    |> Enum.with_index
    |> Enum.filter(fn {ele, _ind} -> ele != "na" end)
    |> Enum.map(fn {ele, ind} -> {ind + 1, Enum.at(Map.get(map, ele), 0)} end)
  end

  def main_helper(lst) do
    vals = Enum.map(0..8, fn x -> round(48*32*40*x/360) end)
    vals = Enum.zip(lst, vals)
    Enum.reduce(vals, %{}, fn {key, val}, map -> sub_helper(key, val, map) end)
  end

  def sub_helper(key, val, map) do
    if Map.has_key?(map, key) do
      lst = Map.get(map, key)
      lst = lst ++ [val]
      Map.put(map, key, lst)
    else
      Map.put(map, key, [val])
    end
  end
end
