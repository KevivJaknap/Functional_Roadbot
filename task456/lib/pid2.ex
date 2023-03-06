defmodule PIDLIB do
  use GenServer

  def start_link(kp, ki, kd) do
    GenServer.start_link(__MODULE__, {kp, ki, kd})
  end

  def control(input) do
    GenServer.call(__MODULE__, {:control, input})
  end

  def init({kp, ki, kd}) do
    controller = PidController.new(kp: kp, ki: ki, kd: kd)
    |> PidController.set_setpoint(2000)
    {:ok, controller}
  end

  def handle_call({:control, input}, _from, controller) do
    {:ok, output, controller} = PidController.output(input, controller)
    {:reply, output, controller}
  end
end
