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
