defmodule AuctionSystemTest.Supervisors.BidSupervisorTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Servers.BidServer
  alias AuctionSystem.Supervisors.BidSupervisor
  alias AuctionSystem.Repo
  doctest BidSupervisor

  setup do
    trunc = "TRUNCATE TABLE CATEGORIES,
      WEAPONS,
      SKINS,
      ITEMS,
      USERS,
      AUCTIONS;"

    ins_cat = "INSERT INTO CATEGORIES
    VALUES (0, 'CategoryTest');"
    ins_wea ="INSERT INTO WEAPONS
    VALUES (0, 'WeaponTest', 0);"
      ins_ski ="INSERT INTO SKINS
    VALUES (0, 0, 453, 'Skin1', 0.1, 0.4),
                  (1, 0, 58, 'Skin2', 0.01, 0.7);"
    ins_ite = "INSERT INTO ITEMS
    VALUES (0, 0, 30, 0.2),
                  (1, 0, 67, 0.399),
                  (2, 1, 11, 0.65);"
    ins_use = "INSERT INTO USERS
    VALUES (0, 'UserTest1', 0.0, 0.0),
                  (1, 'UserTest2', 1.0, 0.0),
                  (2, 'UserTest3', 49.6, 0.5);"
    ins_auc = "INSERT INTO AUCTIONS
    VALUES (0, 0, 0, 1, 25.0, 27.2, '2023-05-29', TRUE),
                  (1, 0, 1, NULL, 50.0, NULL, '2024-05-29', FALSE),
                  (2, 0, 2, 2, 0.2, 0.5, '2024-05-29', FALSE);"

    {:ok, _} = Repo.query(trunc)
    {:ok, _} = Repo.query(ins_cat)
    {:ok, _} = Repo.query(ins_wea)
    {:ok, _} = Repo.query(ins_ski)
    {:ok, _} = Repo.query(ins_ite)
    {:ok, _} = Repo.query(ins_use)
    {:ok, _} = Repo.query(ins_auc)

    BidSupervisor.start_link([])
    :ok
  end

  test "Pujar una cantidad mayor al balance" do
    assert GenServer.call(BidServer, {1, 2, 1.1}) == {:error, "User balance is not enough to bid the amount"}
  end

  test "Pujar en una subasta cerrada" do
    assert GenServer.call(BidServer, {2, 0, 10.0}) == {:error, "Auction is closed or does not exist"}
  end

  test "Pujar una cantidad menor a la puja minima" do
    assert GenServer.call(BidServer, {1, 1, 0.4}) == {:error, "Bid must be higher than the current one"}
  end

  test "Pujar una cantidad menor a la puja actual" do
    assert GenServer.call(BidServer, {1, 2, 0.4})  == {:error, "Bid must be higher than the current one"}
  end

  test "Pujar correctamente" do
    assert GenServer.call(BidServer,{1, 2, 0.6}) == {:ok, 0.4}

    assert GenServer.call(BidServer, {2, 1, 50.1}) == {:ok, 0.0}
  end
end
