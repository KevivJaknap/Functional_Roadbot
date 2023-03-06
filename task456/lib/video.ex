# defmodule Foo do
#   def open_slow(pid) do
#     for i <- 0..30 do
#       ServoKit.set_angle(pid, 0, i)
#       :timer.sleep(100)
#     end
#     :ok
#   end
#   def close(pid) do
#     ServoKit.set_angle(pid, 0, 0)
#   end
#   def foo() do
#     pid = ServoKit.init_standard_servo()
#     Dispenser.move(-1)
#     open_slow(pid)
#     :timer.sleep(2000)
#     close(pid)
#     Dispenser.move(-1)
#     open_slow(pid)
#     :timer.sleep(2000)
#     close(pid)
#     Dispenser.move(-1)
#     open_slow(pid)
#     :timer.sleep(2000)
#     close(pid)
#   end
# end
