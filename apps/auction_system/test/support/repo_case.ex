defmodule AuctionSystem.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias AuctionSystem.Repo

      import Ecto
      import Ecto.Query
      import AuctionSystem.RepoCase

    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(AuctionSystem.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(AuctionSystem.Repo, {:shared, self()})
    end

    :ok
  end
end
