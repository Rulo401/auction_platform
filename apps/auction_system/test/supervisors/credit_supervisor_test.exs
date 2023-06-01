defmodule AuctionSystemTest.Supervisors.CreditSupervisorTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Supervisors.CreditSupervisor
  alias AuctionSystem.Servers.CreditServer
  doctest CreditSupervisor

  setup do
    trunc = "TRUNCATE TABLE CATEGORIES,
      WEAPONS,
      SKINS,
      ITEMS,
      USERS,
      AUCTIONS;"

    ins_use = "INSERT INTO USERS
      VALUES (0, 'UserTest1', 0.0, 0.0),
                    (1, 'UserTest2', 1.0, 0.0),
                    (2, 'UserTest3', 49.6, 0.5);"

    {:ok, _} = Repo.query(trunc)
    {:ok, _} = Repo.query(ins_use)

    CreditSupervisor.start_link([])
    :ok
  end

  test "Balance" do
    assert GenServer.call(CreditServer, {:balance, 3}) == {:error, "User not found"}
    assert GenServer.call(CreditServer, {:balance, 2}) == {:ok, 49.6}
    assert GenServer.call(CreditServer, {:balance, 0}) == {:ok, 0}
  end

  test "Deposit" do
    assert GenServer.call(CreditServer, {:deposit, 2, 10}) == {:ok, 59.6}
    assert GenServer.call(CreditServer, {:balance, 2}) == {:ok, 59.6}
    assert GenServer.call(CreditServer, {:deposit, 0, -1}) == {:error, "Deposit amount must be a positive float"}
    assert GenServer.call(CreditServer, {:balance, 0}) == {:ok, 0.0}
    assert GenServer.call(CreditServer, {:deposit, 0, 1.2}) == {:ok, 1.2}
    assert GenServer.call(CreditServer, {:balance, 0}) == {:ok, 1.2}
  end

  test "Withdraw" do
    assert GenServer.call(CreditServer, {:withdraw, 1, -0.5}) == {:error, "Withdraw amount must be a positive float"}
    assert GenServer.call(CreditServer, {:withdraw, 1, 1.5}) == {:error, "Insufficient balance"}
    assert GenServer.call(CreditServer, {:withdraw, 1, 1.0}) == {:ok, 0.0}
    assert GenServer.call(CreditServer, {:balance, 1}) == {:ok, 0}
    assert GenServer.call(CreditServer, {:withdraw, 2, 30.1}) == {:ok, 19.5}
    assert GenServer.call(CreditServer, {:balance, 2}) == {:ok, 19.5}
  end
end
