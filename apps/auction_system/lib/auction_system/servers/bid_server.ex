defmodule AuctionSystem.Servers.BidServer do
  use GenServer

  def start_link([supervisor]) do
    GenServer.start_link(__MODULE__, supervisor, name: __MODULE__)
  end

  @impl true
  def init(supervisor) do
    {:ok, supervisor}
  end

  @impl true
  def handle_call({user_id, auction_id, bid}, from, supervisor) do
    list = Supervisor.which_children(supervisor)
    fifo = Enum.find_value(list, fn x -> find_fifo(x) end)
    GenServer.cast(fifo, {:push, {from, {user_id, auction_id, bid}}})
    {:noreply, supervisor}
  end

  defp find_fifo(x) do
    case x do
      {Fifo, child, :worker, _} ->
        child
      _ ->
        false
    end
  end
end
