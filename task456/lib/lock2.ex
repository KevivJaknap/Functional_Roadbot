defmodule DispLock do
  use GenServer
  defstruct data: :nil, period: 0, timestamp: 0, lock: false

  def start_link(atom) do
    GenServer.start_link(__MODULE__, atom, name: __MODULE__)
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  @spec update(any) :: :ok
  def update(atom) do
    timestamp = :os.system_time(:millisecond)
    GenServer.cast(__MODULE__, {:update, atom, timestamp})
  end
  def lock(time_period) do
    timestamp = :os.system_time(:millisecond)
    GenServer.call(__MODULE__, {:lock, time_period*1000, timestamp})
  end

  def handle_call(:get, _from, state) do
    {:reply, state.data, state}
  end

  def handle_call({:lock, time_period, timestamp}, _from, state) do
      {:reply, :locked, %__MODULE__{data: state.data, period: time_period, timestamp: timestamp, lock: true}}
  end

  def handle_cast({:update, atom, timestamp}, state) do
    if state.lock do
      if timestamp - state.timestamp > state.period do
        {:noreply, %__MODULE__{data: atom, period: state.period, timestamp: timestamp, lock: false}}
      else
        {:noreply, state}
      end
    else
      {:noreply, %__MODULE__{data: atom, period: state.period, timestamp: timestamp, lock: false}}
    end

    # if state.period == 0 do
    #   {:noreply, %__MODULE__{data: atom, period: state.period, timestamp: timestamp}}
    # else
    #   if timestamp - state.timestamp > state.period do
    #     {:noreply, %__MODULE__{data: atom, period: state.period, timestamp: timestamp}}
    #   else
    #     {:noreply, state}
    #   end
    # end
  end
  def init(atom) do
    {:ok, %__MODULE__{data: atom}}
  end
end
