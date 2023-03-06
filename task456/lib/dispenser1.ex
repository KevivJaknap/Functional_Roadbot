defmodule Dispenser do
  defstruct state: [3, 8, 7, 1, 5, 2], lsts: [[7, 5, 2], [3, 8, 1]], cur_pos: 0, servo_pid: []
  use GenServer
  alias Pigpiox.{GPIO, Pwm}
  @dir 9
  @step 10

  @servo [left: 1, right: 0]

  @state [3, 8, 7, 1, 5, 2]
  @lsts [[7, 5, 2], [3, 8, 1]]

  @open_angle [left: 50, right: 45]
  @close_angle [left: 18, right: 12]

  def move_n(n, dir) do
    Enum.map(1..n, fn _ -> move_unit(dir) end)
  end
  def move_to(pos) do
    cur_pos = state_checker().cur_pos
    if pos > cur_pos do
      move_n(pos-cur_pos, 1)
    else
      move_n(cur_pos-pos, -1)
    end
  end
  def drop(lst, side) do
    vals = Enum.with_index(@state)
    |> Enum.filter(fn {x, _} -> x in lst end)
    |> Enum.map(fn {_, i} -> i end)
    |> Enum.sort()

    cur_pos = state_checker().cur_pos
    Enum.map(vals, fn x ->
      if x > cur_pos do
        move_n(x-cur_pos, 1)
      else
        move_n(cur_pos-x, -1)
      end
      open_servo(side)
      :timer.sleep(100)
      close_servo(side)
      update_pos(x)
    end)
  end
  def init_servo() do
    pid = ServoKit.init_standard_servo()
    ServoKit.set_angle(pid, @servo[:left], @close_angle[:left])
    ServoKit.set_angle(pid, @servo[:right], @close_angle[:right])
    pid
  end
  def open_servo(servo) do
    pid = state_checker().servo_pid
    ServoKit.set_angle(pid, @servo[servo], @open_angle[servo])
  end

  def update_pos(pos) do
    GenServer.cast(__MODULE__, {:update_pos, pos})
  end
  def close_servo(servo) do
    pid = state_checker().servo_pid
    ServoKit.set_angle(pid, @servo[servo], @close_angle[servo])
  end
  def move_step(steps, dir) do
    motor_init()
    if dir > 0 do
      GPIO.write(@dir, 1)
    else
      GPIO.write(@dir, 0)
    end
    for i <- 0..steps do
      IO.puts i
      GPIO.write(@step, 1)
      :timer.sleep(1)
      GPIO.write(@step, 0)
      :timer.sleep(1)
    end
    GPIO.write(@dir, 0)
    GPIO.write(@step, 0)
    :ok
  end
  def move_unit(dir) do
    motor_init()
    if dir > 0 do
      GPIO.write(@dir, 1)
    else
      GPIO.write(@dir, 0)
    end
    for i <- 0..170 do
      IO.puts i
      GPIO.write(@step, 1)
      :timer.sleep(1)
      GPIO.write(@step, 0)
      :timer.sleep(1)
    end
    GPIO.write(@dir, 0)
    GPIO.write(@step, 0)
    :ok
  end

  def open_slow(side) do
    pid = state_checker().servo_pid
    for i <- @open_angle[side]..@close_angle[side] do
      ServoKit.set_angle(pid, @servo[side], i)
      :timer.sleep(100)
    end
    :ok
  end
  def close(pid) do
    ServoKit.set_angle(pid, 0, 0)
  end
  def shake_stepper() do
    for i <- 0..10 do
      GPIO.write(@dir, rem(i, 2))
      GPIO.write(@step, 1)
      :timer.sleep(1)
      GPIO.write(@step, 0)
      :timer.sleep(1)
    end
    GPIO.write(@dir, 0)
    GPIO.write(@step, 0)
  end
  def move_continuosly(dir) do
    # motor_init()
    if dir > 0 do
      GPIO.write(@dir, 1)
    else
      GPIO.write(@dir, 0)
    end
    GPIO.write(@step, 1)
    :timer.sleep(1)
    GPIO.write(@step, 0)
    :timer.sleep(1)
    move_continuosly(dir)
  end
  def motor_init do
    GPIO.set_mode(@dir, :output)
    GPIO.set_mode(@step, :output)
  end
  def start_link() do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def state_checker do
    GenServer.call(__MODULE__, :get_state)
  end

  def init(_state) do
    motor_init()
    {:ok, %__MODULE__{servo_pid: init_servo()}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update_pos, pos}, state) do
    {:noreply, %{state | cur_pos: pos}}
  end
end
