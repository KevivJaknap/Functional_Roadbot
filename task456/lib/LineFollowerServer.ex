defmodule Task4c.LineFollower do
  @moduledoc """
    A server module implementing line following logic for Alphabot
    """
  #--------------------
  use GenServer
  #--------------------
  # EXAMPLE USAGE;
  # iex(2)> {:ok, pid} = Task4c.LineFollower.start_link()
  # {:ok, #PID<0.180.0>}
  # iex(3)> Task4c.LineFollower.state_checker(pid)
  # [0, 0, 0, 0, 0]
  # iex(4)> Task4c.LineFollower.lfa_updater(pid)
  # :ok
  # iex(5)> Task4c.LineFollower.state_checker(pid)
  # [134, 124, 156, 653, 735]
  # iex(6)>
  #--------------------

  # NOTE: The functions provided in the boilerplate are for your reference,
  # you’re still free to change arity/arguments of the functions, add new functions,
  # callbacks and add/modify state of GenServer as required by your implementation.

  #----------------HELPERS------------------

  def readCalibrated(feedback_state) do
    # Just an example. Do normalizaton with respect to Min-Max values of your sensor.
    normalized_state = feedback_state

    # NOTE: You can do the Calibration Manually beforehand and add values here.
                            # OR
    # You may calibrate dynamically everytime the robot runs
    normalized_state
  end

  def calculatePID(average) do
    # Refer: https://www.waveshare.com/wiki/Tracker_Sensor#Part_3:_PID_control
    # Tune the constants of PID
    kp = 0
    ki = 0
    kd = 0
    # Apply PID algorithm to generate required power difference between two motors, in order to follow the line's curvature
    power_difference = 0 # Apply your equation here
    power_difference
  end

  def calculateAvg(feedback_state) do
    # Refer : https://www.waveshare.com/wiki/Tracker_Sensor#Part_2:_Weighted_average
  end

  #----------------Wrappers-------------------
  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def lfa_updater(pid) do
    GenServer.cast(pid,{:get_lfa_readings, pid})
    # lfa_updater(pid)
  end

  def state_checker(pid) do
    GenServer.call(pid, :check_state)
  end

  def move_to_next_node(pid) do
    GenServer.cast(pid,:move_to_next_node)
  end

  #----------------Callbacks--------------------

  def init(state) do
    # Initialize motor directions and speeds
    # Initialize Line Follower Array
    state = [0,0,0,0,0]
    {:ok, state}
  end

  def handle_cast({:get_lfa_readings,pid}, feedback_state) do
    # Get feedback readings from camera or linefollower array here and update state
    dummy_val = Enum.at(feedback_state, 0) + 1
    new_state = [dummy_val,124,156,653,735]

    # Normalize readings with respecct to Calibrated Minimum and Maximum values that your sensors give.
    normalized_state = readCalibrated(new_state)

    GenServer.cast(pid,{:get_lfa_readings,pid})
    {:noreply, normalized_state}
  end

  def handle_call(:check_state,_from, feedback_state) do
    # Get feedback readings from camera or linefollower array here and update state
    return_val = feedback_state
    {:reply, return_val, feedback_state}
  end

  def handle_cast(:move_to_next_node, feedback_state) do
    # Main goal of the function: Use feedback and apply actuation to maintain and follow line
    # (until a node is detected)

    # Use Weighted Averages and PID algorithm to make decision about actuation of motors
    average = calculateAvg(feedback_state)
    power_difference = calculatePID(average)

    # Apply PWM to motors accordingly

    {:noreply, feedback_state}
  end

  end
