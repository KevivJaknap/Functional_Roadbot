defmodule PID_State do
  defstruct setpoint: 2000, kp: 0, ki: 0, kd: 0, integral: 0, prev_error: 0
end

defmodule PID_ do
  use GenServer

  def start_link(kp, ki, kd) do
    state = %PID_State{kp: kp, ki: ki, kd: kd}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def control(cur_state) do
    GenServer.call(__MODULE__, {:control_, cur_state})
  end
  def init(state) do
    {:ok, state}
  end

  def handle_call({:control_, cur_state}, _from, %PID_State{setpoint: setpoint, kp: kp, ki: ki, kd: kd, integral: integral, prev_error: prev_error}) do
    error = setpoint - cur_state
    integral = integral + error
    derivative = error - prev_error
    output = kp * error + ki * integral + kd * derivative
    {:reply, output, %PID_State{setpoint: setpoint, kp: kp, ki: ki, kd: kd, integral: integral, prev_error: error}}
  end
end
