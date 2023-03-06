defmodule LowPassFilter do

  defstruct prev: [0, 0, 0, 0, 0], a: 0.5, calibrate: :true, filter: :true
  use GenServer
  def start_link(a \\ 0.5, calibrate \\ :true, filter \\ :true) do
    GenServer.start_link(__MODULE__, {calibrate, filter, a}, name: __MODULE__)
  end

  def get_val(values) do
    GenServer.call(__MODULE__, {:get_val, values})
  end

  def cal(values, cal_) when cal_ == :true do
    Line3.calibrate(values)
  end

  def cal(values, _) do
    values
  end

  def filt(values, prev, a, filt_) when filt_ == :true do
    filter(values, prev, a)
  end

  def filt(values, _prev, _a, _) do
    values
  end

  def pos_(val, i) when (val < (2000 + i)) and (val > (2000 - i)) do
    2000
  end

  def pos_(val, _) do
    val
  end

  def handle_call({:get_val, values}, _from, state) do
    prev = state.prev
    a = state.a
    cal_ = state.calibrate
    filt_ = state.filter
    values = values |> cal(cal_) |> filt(prev, a, filt_)
    sensor_avg = Enum.with_index(values) |> Enum.map(fn {x, i} -> x * i * 1000 end) |> Enum.sum()
    sensor_sum = Enum.sum(values)
    IO.puts sensor_avg
    IO.puts sensor_sum
    position = round(sensor_avg/sensor_sum) |> pos_(250)
    {:reply, {position, sensor_sum}, %__MODULE__{prev: values, a: a, calibrate: :true, filter: :true}}
  end

  def init({calibrate, filter, a}) do
    {:ok, %__MODULE__{a: a, calibrate: calibrate, filter: filter}}
  end

  def filter(curr, prev, alpha) do
    prev
    |> Enum.zip(curr)
    |> Enum.map(fn {p, c} -> alpha * p + (1 - alpha) * c end)
  end
end
