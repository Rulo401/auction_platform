defmodule AuctionSystem.Supervisors.SystemSupervisor do
  use Supervisor
  alias AuctionSystem.Supervisors.{MarketSupervisor,CreditSupervisor}
  alias AuctionSystem.Servers.UserServer
  alias AuctionSystem.Jobs.Paymaster

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      {UserServer, []},
      {Paymaster, []},
      {MarketSupervisor, []},
      {CreditSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
