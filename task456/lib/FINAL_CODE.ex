defmodule FSA do

  # This is a finite state automata that will be used to control the robot
  # Each state will be an independent function
  @aod [7,9,5,6,7,6,3,6,2]
  @cell_map %{ 1 => [2],
  2 => [1, 3, 5],
  3 => [2, 6],
  4 => [7],
  5 => [2, 6, 8],
  6 => [3,5],
  7 => [4,8],
  8 => [5, 7, 9],
  9 => [8]
  }
  @matrix_of_sum [[14, "na", "na"], ["na", 12, 10], [15, "na", "na"]]
  defstruct paths: [], stops: [], drops: [], curr: 1, orientation: 1, sensor_ref: nil, i: 1, disp: nil
  def start(aod \\ @aod, cell_map \\ @cell_map, matrix_of_sum \\ @matrix_of_sum) do
    LockHelper.start()
    LineFollowerUlt.start()
    disp = Disp123.start(aod)
    paths = Helpers.path_cleaner(cell_map, matrix_of_sum)
    drops = Helpers.drop_cleaner(aod, matrix_of_sum)
    stops = Locations.get_loc(matrix_of_sum)
    sensor_ref = WLF_sensor.init_wlf_sensor()
    # IO.puts "Starting"
    # IO.puts "Paths are:"
    IO.inspect paths
    state = %FSA{paths: paths, drops: drops, stops: stops, sensor_ref: sensor_ref, disp: disp}
    s1(state)
  end

  # This is the start state
  # We extract the first path from the list of paths
  # We then call the next state
  def s1(state) do
    # # IO.puts "s1"
    [path | rest] = state.paths
    state = %FSA{state | paths: rest}
    # IO.puts "Path is:"
    IO.inspect path
    s2(path, state)
    [curr | restops] = state.stops
    state = %FSA{state | stops: restops, curr: curr}
    s3(state)
  end

  # This is the state that will be called for each path
  def s2(path, state) do
    # IO.puts "s2"
    # IO.puts "Current state is:"
    IO.inspect state.paths
    q1(path, state)
  end

  # This is the state that will be called for finding direction in which to drop the RCMs
  def s3(state) do
    # IO.puts "s3"
    dir = find_dir()
    # IO.puts "Found box on #{dir}"
    s4(state, dir)
  end

  # This is the state that will be called for dropping the RCMs
  def s4(state, dir) do
    # IO.puts "s4"
    [drop | rest] = state.drops
    {ind, lst} = drop
    # IO.puts "Dropping box at #{ind} on side #{dir}"
    FooLock.master_lock(2000)
    disp = Disp123.p0(lst, dir, state.disp)
    FooLock.master_lock(2000)
    # :timer.sleep(1500)
    # IO.puts "Contents are:"
    IO.inspect lst
    state = %FSA{state | drops: rest, disp: disp}
    s5(state)
  end

  # This is the state that will be called for checking if there are any more paths to follow
  # If there are no more paths, we terminate the program
  def s5(state) do
    # IO.puts "s5"
    paths = state.paths
    # IO.puts "Paths are:"
    IO.inspect paths
    if paths == [] do
      terminate()
    end
    s1(state)
  end

  # This is the start state for path following
  def q1([h | t], state) do
    # IO.puts "q1"
    # IO.puts h
    case h do
      :left -> q3left(state, t)
      :right -> q4right(state, t)
      :straight -> q2straight(state, t)
      :back -> q5back(state, t)
      :end -> qstop(state, t)
    end
  end

  def qstop(state, t) do
    # IO.puts "Reached end of path"
    LineFollowerUlt.stop_move()
    s3(state)
  end

  def q2straight(state, path) do
    # IO.puts "Moving straight"
    values = WLF_sensor.get_lfa_readings([0, 1, 2, 3, 4], state.sensor_ref)
    if LineFollowerUlt.check(values) == :found do
      q10(state, path)
    end
    LineFollowerUlt.move_straight(values)
    q2straight(state, path)
  end

  def q3left(state, path) do
    IO.puts "Moving left"
    LineFollowerUlt.move_left()
    q2straight(state, path)
  end

  def q4right(state, path) do
    IO.puts "Moving right"
    LineFollowerUlt.move_right()
    q2straight(state, path)
  end

  def q5back(state, path) do #######incomplete
    IO.puts "Moving back"
    LineFollowerUlt.reverse(750)
    q2straight(state, path)
  end

  def q10(state, path) do
    # IO.puts "q10"
    if LockHelper.check_lock() == :unlocked do
      q6(state, path)
    end
    q2straight(state, path)
  end

  def q6(state, path) do
    IO.puts "Unlocked found"
    IO.puts "q6"
    FooLock.update(:locked)
    FooLock.lock(2)
    i = (state.i + 1) |> rem(2)
    state = %FSA{state | i: i}
    q8(state, path)
  end

  def q8(state, path) do
    # IO.puts "q8"
    if state.i == 1 do
      q2straight(state, path)
    else
      q1(path, state)
    end
  end


  def terminate() do
    # IO.puts "Terminated"
    FB_HardwareTesting.test_buzzer()
    :timer.sleep(1000)
    terminate()
  end

  def find_dir() do
    :right
  end
end

defmodule LineFollowerUlt do
  alias Pigpiox.{GPIO, Pwm}
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
                stop:     [0, 0, 0, 0],
                reverse:  [0, 1, 1, 0]
              ]

  @pid_vals [0.3, 0, 2]
  ### Helper Functions

  def start() do
    pid_init(@pid_vals)
    init_motor()
    LowPassFilter.start_link(0.5, :false, :false)
    :ok
  end

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
    # IO.puts "PID returned #{x}"
    {lpwm, rpwm} = get_pwm_helper(x)
    # IO.puts "Left PWM: #{lpwm}"
    # IO.puts "Right PWM: #{rpwm}"
    {round(clamp(lpwm, @min_speed, @max_speed)), round(clamp(rpwm, @min_speed, @max_speed))}
  end

  def move_straight(values) do
    motor_action(:forward)
    {pos, sum} = LowPassFilter.get_val(values)
    {lpwm, rpwm} = get_pwm(pos, sum)
    Pwm.gpio_pwm(@pwm_pins[:left], lpwm)
    Pwm.gpio_pwm(@pwm_pins[:right], rpwm)
    IO.inspect "lpwm: #{lpwm}, rpwm: #{rpwm}"
    IO.inspect "pos: #{pos}, sum: #{sum}"
    :timer.sleep(1)
  end

  def reverse(time) do
    motor_action(:reverse)
    Pwm.gpio_pwm(@pwm_pins[:left], 80)
    Pwm.gpio_pwm(@pwm_pins[:right], 80)
    :timer.sleep(time)
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

  def stop_move() do
    motor_action(:stop)
    :ok
  end

  def check(values) do
    val = values
    |> Enum.map(fn x -> if x > 900 do 1 else 0 end end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
    if val > 2 do
      :found
    else
      :not_found
    end
  end
end


defmodule LockHelper do

  def start() do
    FooLock.start_link(:locked)
  end
  def check_lock() do
    FooLock.update(:unlocked)
    FooLock.get()
  end
end

defmodule Disper do
  @ir_pins [l: 22, r: 27]
  def get do
    Enum.map(@ir_pins, fn {_atom, pin_no} -> Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup) end)
    |> Enum.map(fn {_, ref_no} -> Circuits.GPIO.read(ref_no) end)
    |> label
  end

  def label(arr) when arr == [1, 0] do
    :left
  end

  def label(arr) when arr == [0, 1] do
    :right
  end

  def label(_) do
    :left
  end
end
