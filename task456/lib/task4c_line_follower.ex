defmodule Task4c.Main do
@moduledoc """
  A client module implementing line following logic for Alphabot
  """

  def main() do
    {:ok, pid} = Task4c.LineFollower.start_link()
    #{:ok, #PID<0.180.0>}
    feedback = Task4c.LineFollower.state_checker(pid)
    #[0, 0, 0, 0, 0]
    success = Task4c.LineFollower.lfa_updater(pid)
    #:ok
    feedback = Task4c.LineFollower.state_checker(pid)
    #[134, 124, 156, 653, 735]
    IO.inspect(feedback, label: "Feedback")

    feedback = Task4c.LineFollower.state_checker(pid)
    #[134, 124, 156, 653, 735]
    IO.inspect(feedback, label: "Feedback")
  end

end
