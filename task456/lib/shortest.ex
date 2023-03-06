defmodule Main do
  def init_single_source(d, s) do
    keys = Map.keys(d)
    prev = Map.new(keys, fn x -> {x, :none} end)
    dist = Map.new(keys, fn x -> {x, :inf} end)

    dist = Map.replace(dist, s, 0)
    {dist, prev}
  end

  def relax(u, v, dist, prev) do
    dist_u = Map.get(dist, u)
    dist_v = Map.get(dist, v)
    {:ok, pid} = Agent.start_link(fn -> {dist, prev} end)
    if dist_v > dist_u + 1 do
      obj = {Map.replace(dist, v, dist_u + 1), Map.replace(prev, v, u)}
      Agent.update(pid, fn _x -> obj end)
    end
    ret = Agent.get(pid, fn x -> x end)
    :ok = Agent.stop(pid)
    ret
  end

  def dijkstra(d, s) do
    {dist, prev} = init_single_source(d, s)
    q = Map.keys(d)
    recur_d(q, dist, prev, d)
  end

  def recur_d(q, dist, prev, _d) when length(q) == 0 do
    {dist, prev}
  end

  def recur_d(q, dist, prev, d) do
    u = Enum.min_by(q, fn x ->
      Map.get(dist, x)
    end)
    q = List.delete(q, u)
    list = Map.get(d, u)
    {dist, prev} = Enum.reduce(list, {dist, prev}, fn x, {dist, prev} ->
      relax(u, x, dist, prev)
    end)
    recur_d(q, dist, prev, d)
  end

  def return_path(_prev, s, v) when v == s do
    [s]
  end

  def return_path(prev, s, v) do
    return_path(prev, s, Map.get(prev, v)) ++ [v]
  end

  def path(d, src, dest) do
    {_dist, prev} = dijkstra(d, src)
    return_path(prev, src, dest)
  end
  
  def distance(d, src, dest) do
    {dist, _prev} = dijkstra(d, src)
    Map.get(dist, dest)
  end
end
