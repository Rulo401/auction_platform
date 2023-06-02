defmodule AuctionSystem.Supervisors.CreditSupervisor do
  use Supervisor
  alias AuctionSystem.Servers.CreditServer

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(_) do
    Supervisor.start_link(__MODULE__, name: __MODULE__)
  end

  @impl true
  @spec init(any) :: {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec()]}}
  def init(_) do
    children = [
      {DynamicSupervisor, name: :balance_ds, strategy: :one_for_one, max_children: 250},
      {CreditServer, [self()]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
