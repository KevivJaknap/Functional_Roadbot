defmodule IR do

  defstruct ir_values: [], ir_ref: []
  use GenServer
  @ir_pins [dl: 19] #dr 16

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def update_get() do
    GenServer.call(__MODULE__, :update_get)
  end
  def init(_) do
    ir_ref = Enum.map(@ir_pins, fn {_atom, pin_no} -> Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup) end)
    {:ok, %__MODULE__{ir_ref: ir_ref}}
  end

  def handle_call(:update_get, _from, state) do
    ir_ref = state.ir_ref
    ir_values = Enum.map(ir_ref,fn {_, ref_no} -> Circuits.GPIO.read(ref_no) end)
    {:reply, ir_values, %__MODULE__{ir_ref: ir_ref, ir_values: ir_values}}
  end
end
