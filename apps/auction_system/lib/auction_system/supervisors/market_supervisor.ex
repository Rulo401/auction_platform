defmodule AuctionSystem.Supervisors.MarketSupervisor do
  use Supervisor
  alias AuctionSystem.Supervisors.BidSupervisor
  alias AuctionSystem.Servers.MarketServer

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      {MarketServer, [self()]},
      {DynamicSupervisor, name: :task_ds, strategy: :one_for_one, max_children: 500},
      {BidSupervisor,[]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
