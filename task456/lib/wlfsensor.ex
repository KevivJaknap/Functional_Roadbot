defmodule WLF_sensor do
  @moduledoc """
  Documentation for `FB_HardwareTesting`.
  Different functions provided for testing components of Alpha Bot.
  test_buzzer       - to test Buzzer
  test_wlf_sensors  - to test white line sensors
  test_ir           - to test IR proximity sensors
  test_motion       - to test Motion of the Robot
  test_pwm          - to test Speed of the Robot
  test_servo_a      - to test Servo motor a
  test_servo_b      - to test Servo motor a
  """

  require Logger
  use Bitwise
  alias Pigpiox.{GPIO, Pwm}

  @level [high: 1, low: 0, on: 1, off: 0]

  @buzzer_pin [buz: 4]
  @sensor_pins [cs: 5, clock: 25, address: 24, dataout: 23]
  @ir_pins [dr: 16, dl: 19]
  @motor_pins [lf: 12, lb: 13, rf: 20, rb: 21]
  @pwm_pins [left: 6, right: 26]

  @ref_atoms [:cs, :clock, :address, :dataout]
  @lf_sensor_data %{sensor0: 0, sensor1: 0, sensor2: 0, sensor3: 0, sensor4: 0, sensor5: 0}
  @lf_sensor_map %{0 => :sensor0, 1 => :sensor1, 2 => :sensor2, 3 => :sensor3, 4 => :sensor4, 5 => :sensor5}

  @motion_list [forward:  [0, 1, 0, 1],
                backward: [1, 0, 1, 0],
                left:     [0, 1, 1, 0],
                right:    [1, 0, 0, 1],
                stop:     [0, 0, 0, 0]]

  @duty_cycle 100
  @pwm_frequency 50

  #-------------------------------------------------------------------

  def init_wlf_sensor do
    sensor_ref = Enum.map(@sensor_pins, fn {atom, pin_no} -> configure_sensor({atom, pin_no}) end)
    sensor_ref = Enum.map(sensor_ref, fn{_atom, ref_id} -> ref_id end)
    sensor_ref = Enum.zip(@ref_atoms, sensor_ref)
    sensor_ref
  end



  @doc """
  Supporting function for test_wlf_sensors
  Configures sensor pins as input or output
  [cs: output, clock: output, address: output, dataout: input]
  """
  defp configure_sensor({atom, pin_no}) do
    if (atom == :dataout) do
      Circuits.GPIO.open(pin_no, :input, pull_mode: :pullup)
    else
      Circuits.GPIO.open(pin_no, :output)
    end
  end

  @doc """
  Supporting function for test_wlf_sensors
  Reads the sensor values into an array. "sensor_list" is used to provide list
  of the sesnors for which readings are needed
  The values returned are a measure of the reflectance in abstract units,
  with higher values corresponding to lower reflectance (e.g. a black
  surface or void)
  """
  def get_lfa_readings(sensor_list, sensor_ref) do
    append_sensor_list = sensor_list ++ [5]
    temp_sensor_list = [5 | append_sensor_list]
    [_ | sensor_data] = append_sensor_list
        |> Enum.with_index
        |> Enum.map(fn {sens_num, sens_idx} ->
              analog_read(sens_num, sensor_ref, Enum.fetch(temp_sensor_list, sens_idx))
              end)
    Enum.each(0..5, fn _n -> provide_clock(sensor_ref) end)
    Circuits.GPIO.write(sensor_ref[:cs], 1)
    # Process.sleep(1)
    sensor_data
  end

  @doc """
  Supporting function for test_wlf_sensors
  """
  defp analog_read(sens_num, sensor_ref, {_, sensor_atom_num}) do

    Circuits.GPIO.write(sensor_ref[:cs], 0)
    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
    Enum.reduce(0..9, @lf_sensor_data, fn n, acc ->
                                          read_data(n, acc, sens_num, sensor_ref, sensor_atom_num)
                                          |> clock_signal(n, sensor_ref)
                                        end)[sensor_atom]
  end

  @doc """
  Supporting function for test_wlf_sensors
  """
  defp read_data(n, acc, sens_num, sensor_ref, sensor_atom_num) do
    if (n < 4) do

      if (((sens_num) >>> (3 - n)) &&& 0x01) == 1 do
        Circuits.GPIO.write(sensor_ref[:address], 1)
      else
        Circuits.GPIO.write(sensor_ref[:address], 0)
      end
      Process.sleep(1)
    end

    %{^sensor_atom_num => sensor_atom} = @lf_sensor_map
    if (n <= 9) do
      Map.update!(acc, sensor_atom, fn sensor_atom -> ( sensor_atom <<< 1 ||| Circuits.GPIO.read(sensor_ref[:dataout]) ) end)
    end
  end

  @doc """
  Supporting function for test_wlf_sensors used for providing clock pulses
  """
  defp provide_clock(sensor_ref) do
    Circuits.GPIO.write(sensor_ref[:clock], 1)
    Circuits.GPIO.write(sensor_ref[:clock], 0)
  end

  @doc """
  Supporting function for test_wlf_sensors used for providing clock pulses
  """
  defp clock_signal(acc, n, sensor_ref) do
    Circuits.GPIO.write(sensor_ref[:clock], 1)
    Circuits.GPIO.write(sensor_ref[:clock], 0)
    acc
  end

end
