defmodule Logic do

  def helper(ones) when ones == [1, 1, 1, 0, 0] do
    "left"
  end

  def helper(ones) when ones == [0, 0, 1, 1, 1] do
    "right"
  end
  def helper(ones) when ones == [1, 1, 1, 1, 1] do
    "leftright"
  end
  def helper(ones) when ones == [1, 1, 1, 1, 0] do
    "leftright"
  end
  def helper(ones) when ones == [0, 1, 1, 1, 1] do
    "leftright"
  end
  def helper(_ones) do
    "ok"
  end
  def decide(mid) when mid == 0 do
    "straight"
  end
  def decide(mid) when mid == 1 do
    "not_straight"
  end
  def straight do
    ir_vals = FB_HardwareTesting.test_ir()
    mid = Enum.at(ir_vals, 0)
    decide(mid)
  end
  def direction(values) do
    ones = Enum.map(values, fn x -> if x > 850 do 1 else 0 end end)
    [helper(ones), straight()]
  end
end
