defmodule YOhello do
  @orientation %{0 => :straight, 1 => :left, 2 => :back, 3 => :right}
  @map %{
    [1, 2] => 1,
    [1, 4] => 0,
    [2, 1] => 3,
    [2, 3] => 1,
    [2, 5] => 0,
    [3, 2] => 3,
    [3, 6] => 0,
    [4, 1] => 2,
    [4, 5] => 1,
    [4, 7] => 0,
    [5, 2] => 2,
    [5, 4] => 3,
    [5, 6] => 1,
    [5, 8] => 0,
    [6, 3] => 2,
    [6, 5] => 3,
    [6, 9] => 0,
    [7, 4] => 2,
    '\a\b' => 1,
    [8, 5] => 2,
    '\b\a' => 3,
    '\b\t' => 1,
    [9, 6] => 2,
    '\t\b' => 3
  }
  def get_paths_helper([cur | rest], prev, init_pos) do
    y = Map.get(@map, [prev, cur])
    k = Integer.mod(y - init_pos, 4)
    [Map.get(@orientation, k) | get_paths_helper(rest, cur, y)]
  end
  def get_paths_helper([], _, _) do
    [:end]
  end
  def get_paths([cur | rest], init_pos) do
    get_paths_helper(rest, cur, init_pos)
  end

  def or_helper(lst) when lst == [1] do
    1
  end

  def or_helper(lst) do
    last2 = Enum.slice(lst, -2, 2)
    Map.get(@map, last2)
  end
  def with_orientation(lst) do
    or_helper(lst)
  end
  def yo do
    :yo
  end
end
defmodule Hello do
  def hello1 do
    :hello1
  end
  def hello2 do
    YOhello.yo()
  end
end
