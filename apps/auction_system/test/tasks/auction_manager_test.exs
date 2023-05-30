defmodule AuctionSystemTest.Tasks.AuctionManagerTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Tasks.AuctionManager
  alias AuctionSystem.Servers.UserServer
  alias AuctionSystem.Schemas.{User, Auction, Item}
  alias AuctionSystem.Repo
  import Ecto.Query
  doctest AuctionManager

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
    ins_use = "INSERT INTO USERS
  VALUES (0, 'UserTest1', 0.0, 0.0),
                (1, 'UserTest2', 0.0, 0.0),
                (2, 'UserTest3', 50.5, 0);"

    {:ok, _} = Repo.query(trunc)
    {:ok, _} = Repo.query(ins_cat)
    {:ok, _} = Repo.query(ins_wea)
    {:ok, _} = Repo.query(ins_ski)
    {:ok, _} = Repo.query(ins_use)

    :ok
  end

  test "Auction item: Invalid duration" do
    pid = self()
    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.13},"1") end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "Duration days must be a positive integer"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 0

    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.13}, 0) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "Duration days must be a positive integer"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 0
  end

  test "Auction item: Invalid minBid" do
    pid = self()
    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.13}, 2, "five") end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "The min bid must be float and greater than or equal to 0.1"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 0

    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.13}, 2, 0.09) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "The min bid must be float and greater than or equal to 0.1"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end
  end

  test "Auction item: Invalid item definition" do
    pid = self()
    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: "20", sfloat: 0.13}, 2, 5.0) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "Invalid item definition"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 0
    assert length(Item |> Repo.all) == 0

    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: :fl}, 2, 1.0) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "Invalid item definition"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 0
    assert length(Item |> Repo.all) == 0
  end

  test "Auction item: Invalid float for skin" do
    pid = self()
    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.09}, 2, 5.0) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "Item float value is lower than the minimum accepted for this skin"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 0
    assert length(Item |> Repo.all) == 0

    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.42}, 2, 1.0) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        assert response == {:error, "Item float value is higher than the maximum accepted for this skin"}
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 0
    assert length(Item |> Repo.all) == 0
  end

  test "Auction item: Valid query" do
    pid = self()
    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.13}, 1) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        {status, _} = response
        assert status == :ok
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
    end

    assert length(Auction |> Repo.all) == 1
    assert length(Item |> Repo.all) == 1

    auc = Auction
    |> first
    |> Repo.one()
    |> Repo.preload(:item)
    assert auc.seller_id == 0
    assert auc.item.skin_id == 0
    assert auc.item.seed == 20
    assert auc.item.skinFloat == 0.13
    assert is_nil(auc.bidder_id)
    assert NaiveDateTime.compare(auc.end, NaiveDateTime.utc_now()) == :gt
    assert NaiveDateTime.compare(auc.end, NaiveDateTime.add(NaiveDateTime.utc_now(), 1, :day)) == :lt
    assert auc.minBid == 0.1
  end

  test "Get auction data" do
    pid = self()

    spawn(fn -> AuctionManager.auction_item(pid, :test, 0, %{skin_id: 0, seed: 20, sfloat: 0.13}, 1) end)

    au_id = receive do
      {:market, cid, response} ->
        assert cid == :test
        {status, au_id} = response
        assert status == :ok
        au_id
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
        nil
    end

    assert length(Auction |> Repo.all) == 1
    assert length(Item |> Repo.all) == 1

    spawn(fn -> AuctionManager.get_auction_data(pid, :test, au_id) end)

    receive do
      {:market, cid, response} ->
        assert cid == :test
        {status, map} = response
        assert status == :ok
        assert map.weapon == "WeaponTest"
        assert map.skin == "Skin1"
        assert map.seed == 20
        assert map.skinFloat == 0.13
        assert map.bid == 0.1
      after 5000 ->
        refute "TIMEOUT" == "TIMEOUT"
        nil
    end
  end
end
