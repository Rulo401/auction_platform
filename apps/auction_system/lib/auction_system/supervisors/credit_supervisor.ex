defmodule AuctionSystem.Supervisors.CreditSupervisor do
  use Supervisor
  alias AuctionSystem.Servers.CreditServer

  def start_link(_) do
    Supervisor.start_link(__MODULE__, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      {DynamicSupervisor, name: :balance_ds, strategy: :one_for_one, max_children: 250},
      {CreditServer, [self()]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
