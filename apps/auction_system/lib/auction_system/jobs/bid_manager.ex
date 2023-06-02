defmodule AuctionSystem.Jobs.BidManager do
  alias AuctionSystem.Tasks.Auctioneer

  @spec child_spec(Supervisor.supervisor()) :: Supervisor.child_spec()
  def child_spec(supervisor) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, supervisor},
      restart: :permanent
    }
  end

  @spec start_link(Supervisor.supervisor()) :: {:ok, pid}
  def start_link(supervisor) do
    {:ok, spawn_link(fn () -> manage_bids(%{supervisor: supervisor, map: MapSet.new()}) end)}
  end

  @spec manage_bids(%{
          :map => MapSet.t(),
          :supervisor => Supervisor.supervisor(),
          optional(any) => any
        }) :: no_return
  def manage_bids(state) do
    map = update_map(state.map)
    list = Supervisor.which_children(state.supervisor)
    fifo = Enum.find_value(list, fn x -> find_fifo(x) end)
    ds = Enum.find_value(list, fn x -> find_ds(x) end)
    map = case GenServer.call(fifo,{:pull_backfilling, &(!MapSet.member?(map, &1))}) do
      {:ok, {from, {user_id, auction_id, bid}}} ->
        pid = self()
        DynamicSupervisor.start_child(ds, %{ id: Auctioneer, start: {Auctioneer, :bid, [from, pid, {user_id, auction_id, bid}]}, restart: :temporary})
        MapSet.put(map, auction_id)
      _ ->
        case DynamicSupervisor.count_children(ds).workers do
          0 ->
            MapSet.new()
          _ ->
            map
        end
    end
    manage_bids(Map.replace(state,:map, map))
  end

  defp update_map(map) do
    receive do
      {:free, auction_id} ->
        update_map(MapSet.delete(map, auction_id))
      after 1 ->
        map
    end
  end

  defp find_fifo(x) do
    case x do
      {Fifo, child, :worker, _} ->
        child
      _ ->
        false
    end
  end

  defp find_ds(x) do
    case x do
      {:auctioneer_ds, child, :supervisor, _} ->
        child
      _ ->
        false
    end
  end

end
