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
