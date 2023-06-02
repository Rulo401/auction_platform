defmodule AuctionSystem.Supervisors.BidSupervisor do
  use Supervisor
  alias AuctionSystem.Jobs.BidManager
  alias AuctionSystem.Servers.BidServer

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, name: __MODULE__)
  end

  @impl true
  @spec init(any) :: {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec()]}}
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
