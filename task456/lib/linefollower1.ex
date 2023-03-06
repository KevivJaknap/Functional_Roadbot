defmodule LineFollowerNow do
  use GenServer
  @lst [[3, 8, 1, 2], [7, 5]]
  alias Pigpiox.{GPIO, Pwm}
  @opts [path: [1, 2, 3, 6]]
  @max_speed 80
  @max_speed_left 40
  @max_speed_right 40
  @min_speed 15
  @motor_pins [lf: 12, lb: 13, rf: 20, rb: 21]
  @pwm_pins [left: 6, right: 26]
  @motion_list [forward:  [0, 1, 0, 1],
                backward: [1, 0, 1, 0],
                left:     [0, 1, 1, 0],
                right:    [1, 0, 0, 1],
                stop:     [0, 0, 0, 0]]

  ### Helper Functions

  def init_motor() do
    Enum.map(@motor_pins, fn {_atom, pin} -> GPIO.set_mode(pin, :output) end)
    Enum.map(@pwm_pins, fn {_atom, pin_no} -> Pwm.gpio_pwm(pin_no, 0) end)
    :ok
  end

  def motor_action(motion) do
    @motor_pins |> Enum.zip(@motion_list[motion]) |> Enum.each(fn {{_atom, pin_no}, value} -> GPIO.write(pin_no, value) end)
  end
  def clamp(val, min, max) do
    min(max, max(min, val))
  end

  def pid_init(state) do
    kp = Enum.at(state, 0)
    ki = Enum.at(state, 1)
    kd = Enum.at(state, 2)
    PID_.start_link(kp, ki, kd)
  end


  def get_pwm_helper(error) when error < 0 do     #actually the - error term was not here
    rpwm = @max_speed_right + error
    lpwm = @max_speed_left - error
    {lpwm, rpwm}
  end
  def get_pwm_helper(error) when error >= 0 do
    rpwm = @max_speed_right + error             #similarly the + error term was not here
    lpwm = @max_speed_left - error
    {lpwm, rpwm}
  end
  def get_pwm(_, sum) when sum == 0 do
    {0, 0}
  end
  def get_pwm(_, sum) when sum > 3500 do
    {@max_speed_left, @max_speed_right}
  end
  def get_pwm(pos, sum) when sum <= 3500 do
    x = PID_.control(pos)
    IO.puts "PID returned #{x}"
    {lpwm, rpwm} = get_pwm_helper(x)
    IO.puts "Left PWM: #{lpwm}"
    IO.puts "Right PWM: #{rpwm}"
    {round(clamp(lpwm, @min_speed, @max_speed)), round(clamp(rpwm, @min_speed, @max_speed))}
  end

  def check(values) do
    arr = Logic.direction(values)
    lr = Enum.at(arr, 0)
    straight = Enum.at(arr, 1)
    if (lr != "ok") do
      IO.puts "direction found #{lr}"
      motor_action(:stop)
      if straight == "straight" do
        IO.puts "straight found #{straight}"
        IO.puts "Junction found"
      end
      :timer.sleep(2000)
    end
  end

  def check2logic(val, i) when (val > 2 and i == 1) do
    IO.puts "Connect Node found"
    motor_action(:stop)
    :timer.sleep(5000)
    rem(i+1, 2)
  end
  def check2logic(val, i) when (val > 2 and i == 0) do
    IO.puts "Drop Node found"
    motor_action(:stop)
    :timer.sleep(5000)
    rem(i+1, 2)
  end
  def check2logic(_, i) do
    i
  end
  def check2(values, i) do
    vals = Enum.map(values, fn x -> if x > 900 do 1 else 0 end end)
    val = Enum.count(vals, fn x -> x == 1 end)

    check2logic(val, i)
  end
  def move(sensor_ref) do
    values = WLF_sensor.get_lfa_readings([0, 1, 2, 3, 4], sensor_ref)
    # {pos, sum} = Line3.get_attr(values)
    {pos, sum} = LowPassFilter.get_val(values)
    # {pos, sum} = MovAvgFilter.get_val(values)
    {lpwm, rpwm} = get_pwm(pos, sum)
    motor_action(:forward)
    Pwm.gpio_pwm(@pwm_pins[:left], lpwm)
    Pwm.gpio_pwm(@pwm_pins[:right], rpwm)
    IO.inspect "lpwm: #{lpwm}"
    IO.inspect "rpwm: #{rpwm}"
    # check_box()
    # ret = check3(values)
    # if ret == :left do
    #   IO.puts "moving left"
    #   move_left()
    # end
    # if ret == :right do
    #   IO.puts "moving right"
    #   move_right()
    # end
    # if ret == :end do
    #   IO.puts "moving end"
    #   move_end()
    # end
    move(sensor_ref)
  end


  def move_end() do
    IO.puts "done moving"
    FB_HardwareTesting.test_buzzer()
    motor_action(:stop)
    :timer.sleep(5000)
    move_end()
  end
  def check3(values) do
    val = Enum.map(values, fn x -> if x > 900 do 1 else 0 end end)
    |> Enum.count(fn x -> x == 1 end)
    if val > 2 do
      k = Robot.found()
      IO.puts "Here K is #{k}"
      k
    else
      :continue
    end
  end

  def check_box() do
    lst = FB_HardwareTesting.test_ir()
    [l, r] = Enum.slice(lst, 2..-1)
    IO.puts "Left: #{l}"
    IO.puts "Right: #{r}"
    disp_sub(l, r)
  end

  def disp_sub(l, _r) when l == 1 do
    DispLock.update(:unlocked)
    ret = DispLock.get()
    if ret == :locked do
      :ok
    else
      motor_action(:stop)
      DispLock.update(:locked)
      DispLock.lock(15)
      state = get_state()
      lst = Enum.at(@lst, state)
      IO.puts "List is #{lst}"
      Dispenser.drop(lst, :left)
    end
  end
  def disp_sub(_, _) do
    :ok
  end
  def move_main() do
    sensor_ref = WLF_sensor.init_wlf_sensor()
    move(sensor_ref)
  end

  def move_front() do
    motor_action(:forward)
    Pwm.gpio_pwm(@pwm_pins[:left], 80)
    Pwm.gpio_pwm(@pwm_pins[:right], 80)
    :timer.sleep(1000)
    motor_action(:stop)
  end
  def move_left() do
    motor_action(:forward)
    Pwm.gpio_pwm(@pwm_pins[:left], 0)
    Pwm.gpio_pwm(@pwm_pins[:right], 80)
    :timer.sleep(600)
    motor_action(:stop)
    :ok
  end
  def move_right() do
    motor_action(:forward)
    Pwm.gpio_pwm(@pwm_pins[:left], 80)
    Pwm.gpio_pwm(@pwm_pins[:right], 0)
    :timer.sleep(600)
    motor_action(:stop)
    :ok
  end
  ### Client API
  ## give values as a list of 5 elements, and single value of "a"
  def start_link(k_vals, a, opts \\ {:true, :false}) do
    GenServer.start_link(__MODULE__, {k_vals, a, opts}, name: __MODULE__)
  end

  def state_checker() do
    GenServer.call(__MODULE__, :get_state)
  end

  def increment() do
    GenServer.call(__MODULE__, :increment)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  ### Server Callbacks

  def init(k_vals) do
    pid_init(k_vals)
    init_motor()
    IR.start_link()
    Robot.start_link()
    DispLock.start_link(:unlocked)
    Dispenser.start_link()
    sensor_ref = WLF_sensor.init_wlf_sensor()
    state = 0
    {:ok, state}
  end
  def init({k_vals, a, {cal, filt}}) do
    pid_init(k_vals)
    init_motor()
    IR.start_link()
    Robot.start_link(@opts)
    DispLock.start_link(:unlocked)
    Dispenser.start_link()
    LowPassFilter.start_link(a, cal, filt)
    # MovAvgFilter.start_link(a)
    sensor_ref = WLF_sensor.init_wlf_sensor()
    state = 0
    {:ok, state}
  end
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  def handle_call(:increment, _from, state) do
    {:reply, :ok, state + 1}
  end
end
