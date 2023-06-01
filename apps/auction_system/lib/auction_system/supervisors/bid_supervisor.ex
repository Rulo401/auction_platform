defmodule AuctionSystem.Supervisors.BidSupervisor do
  use Supervisor
  alias AuctionSystem.Jobs.BidManager
  alias AuctionSystem.Servers.BidServer

  def start_link(_) do
    Supervisor.start_link(__MODULE__, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      {BidServer, [self()]},
      {Fifo, name: :fifo},
      {DynamicSupervisor, name: :auctioneer_ds, strategy: :one_for_one, max_children: 1000},
      {BidManager,[self()]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
