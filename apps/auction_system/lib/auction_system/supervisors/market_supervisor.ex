defmodule AuctionSystem.Supervisors.MarketSupervisor do
  use Supervisor
  alias AuctionSystem.Supervisors.BidSupervisor
  alias AuctionSystem.Servers.MarketServer

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec init(:ok) :: {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec()]}}
  def init(:ok) do
    children = [
      {MarketServer, [self()]},
      {DynamicSupervisor, name: :task_ds, strategy: :one_for_one, max_children: 500},
      {BidSupervisor,[]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
