defmodule Line3 do

  def clamp(val, min, max) do
    min(max, max(min, val))
  end
  def cal_helper(values, min, max, i) do
    min_ = Enum.at(min, i)
    max_ = Enum.at(max, i)
    value_ = Enum.at(values, i)
    (value_ - min_)*1000/(max_ - min_)
  end
  def calibrate(values, min\\[500,500,500,500,500], max\\[1000, 1000, 1000, 1000, 1000]) do
    values
    |> Enum.with_index()
    |> Enum.map(fn {_x, i} -> cal_helper(values, min, max, i) end)
    |> Enum.map(fn x -> clamp(x, 1, 1000) end)
  end
  def get_attr(values) when length(values) == 5 do
    values = calibrate(values)
    sensor_avg = Enum.with_index(values) |> Enum.map(fn {x, i} -> x * i * 1000 end) |> Enum.sum()
    sensor_sum = Enum.sum(values)
    IO.puts "sensor_avg: #{sensor_avg}"
    IO.puts "sensor_sum: #{sensor_sum}"
    position = round(sensor_avg/sensor_sum)
    IO.puts "position: #{position}"
    {position, sensor_sum}
  end

  def get_attr(_values) do
    {2000, 3500}
  end
end
