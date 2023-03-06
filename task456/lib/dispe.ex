defmodule Disp123 do

  defstruct cur_left: 0, cur_right: 768, sol: %{}, lst: [], dir: :left, pid: nil
  def start(aod) do
    pid = ServoKit.init_standard_servo()
    DispHelper.start(pid)
    sol = Helpers.main_helper(aod)
    %Disp123{pid: pid, sol: sol}
  end

  def p0(lst, dir, state) do
    state = %Disp123{state | lst: lst, dir: dir}
    p1(state)
  end

  def p1(state) do
    if state.lst == [] do
      p2(state)
    else
      p3(state)
    end
  end

  def p2(state) do
    # IO.puts "terminate"
    state
  end

  def p3(state) do
    [h | t] = state.lst
    state = %Disp123{state | lst: t}
    p5(state, h)
  end

  def p5(state, h) do
    map = state.sol
    lst = Map.get(map, h)
    [h1 | t1] = lst
    map = Map.put(map, h, t1)
    state = %Disp123{state | sol: map}
    p6(state, h1)
  end

  def p6(state, pos) do
    if state.dir == :left do
      a = state.cur_left - pos
      if a == 0 do
        p13(state)
      else
        if a > 0 do
          cur_right = Integer.mod(pos + 768, 1536)
          state = %Disp123{state | cur_right: cur_right, cur_left: pos}
          p8(state, a)
        else
          cur_right = Integer.mod(pos + 768, 1536)
          state = %Disp123{state | cur_right: cur_right, cur_left: pos}
          p7(state, -a)
        end
      end
    else
      a = state.cur_right - pos
      if a == 0 do
        p13(state)
      else
        if a > 0 do
          cur_left = Integer.mod(pos + 768, 1536)
          state = %Disp123{state | cur_left: cur_left, cur_right: pos}
          p8(state, a)
        else
          cur_left = Integer.mod(pos + 768, 1536)
          state = %Disp123{state | cur_left: cur_left, cur_right: pos}
          p7(state, -a)
        end
      end
    end
  end

  def p8(state, a) when a > 768 do
    rotate(1536 - a, -1, state)
  end

  def p8(state, a) when a <= 768 do
    rotate(a, 1, state)
  end

  def p7(state, a) when a > 768 do
    rotate(1536 - a, 1, state)
  end

  def p7(state, a) when a <= 768 do
    rotate(a, -1, state)
  end

  def rotate(a, dir, state) do
    # IO.puts "rotate #{a} #{dir}"
    DispHelper.move_n_steps(a, dir)
    p13(state)
  end

  def p13(state) do
    if state.dir == :left do
      # IO.puts "Opening left"
      DispHelper.open_slow(state.pid, :left)
      :timer.sleep(1000)
      DispHelper.close_slow(state.pid, :left)
      p1(state)
    else
      # IO.puts "Opening right"
      DispHelper.open_slow(state.pid, :right)
      :timer.sleep(1000)
      DispHelper.close_slow(state.pid, :right)
      p1(state)
    end
  end
end

defmodule DispHelper do
  alias Pigpiox.{GPIO, Pwm}
  @dir 9
  @step 10

  @servo [left: 1, right: 0]

  @open_angle [left: 55, right: 45]
  @close_angle [left: 17, right: 11]

  def start(pid) do
    GPIO.set_mode(@dir, :output)
    GPIO.set_mode(@step, :output)
    ServoKit.set_angle(pid, @servo[:left], @close_angle[:left])
    ServoKit.set_angle(pid, @servo[:right], @close_angle[:right])
    :ok
  end

  def open(pid, side) do
    ServoKit.set_angle(pid, @servo[side], @open_angle[side])
    :ok
  end

  def close(pid, side) do
    ServoKit.set_angle(pid, @servo[side], @close_angle[side])
    :ok
  end

  def open_slow(pid, side) do
    init_ = @close_angle[side]
    fin_ = @open_angle[side]
    Enum.map(init_..fin_, fn x ->
      ServoKit.set_angle(pid, @servo[side], x)
      :timer.sleep(10)
    end)
  end

  def close_slow(pid, side) do
    init_ = @open_angle[side]
    fin_ = @close_angle[side]
    Enum.map(init_..fin_, fn x ->
      ServoKit.set_angle(pid, @servo[side], x)
      :timer.sleep(10)
    end)
  end

  def move_n_steps(n, dir) do
    if dir > 0 do
      GPIO.write(@dir, 1)
    else
      GPIO.write(@dir, 0)
    end
    Enum.map(1..n, fn _ ->
      GPIO.write(@step, 1)
      :timer.sleep(1)
      GPIO.write(@step, 0)
      :timer.sleep(1)
    end)
    GPIO.write(@step, 0)
    GPIO.write(@dir, 0)
  end

  def move_angle(angle, dir) do
    n = round(angle * (48*32)/360)
    move_n_steps(n, dir)
  end
end
