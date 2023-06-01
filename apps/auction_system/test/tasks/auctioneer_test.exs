defmodule AuctionSystemTest.Tasks.AuctioneerTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Tasks.Auctioneer
  alias AuctionSystem.Schemas.{User,Auction}
  doctest Auctioneer

  describe "Testing wrong calls" do
    test "Invalid pids" do
      assert {:error, "Invalid manager pid"} == Auctioneer.bid(:from, "pid", nil)
      assert {:error, "Invalid manager pid"} == Auctioneer.bid(:from, :wrong_pid, nil)
    end

    test "Invalid ids" do
      pid = self()

      spawn(fn -> Auctioneer.bid(pid, pid, {"0", 1, 10.0}) end)

      receive do
        {:free, id} ->
          assert id == 1
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "User_id and auction_id must be integers"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end

      spawn(fn -> Auctioneer.bid(pid, pid, {0, "1", 10.0}) end)

      receive do
        {:free, id} ->
          assert id == "1"
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "User_id and auction_id must be integers"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
    end

    test "Invalid bids" do
      pid = self()

      spawn(fn -> Auctioneer.bid(pid, pid, {0, 1, "10.0"}) end)

      receive do
        {:free, id} ->
          assert id == 1
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "Bid must be a positive float"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end

      spawn(fn -> Auctioneer.bid(pid, pid, {0, 1, -1.2}) end)

      receive do
        {:free, id} ->
          assert id == 1
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "Bid must be a positive float"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end

      spawn(fn -> Auctioneer.bid(pid, pid, {0, 2, 0.0}) end)

      receive do
        {:free, id} ->
          assert id == 2
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "Bid must be a positive float"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
    end
  end

  describe "Valid calls" do
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

      :ok
    end

    test "Pujar una cantidad mayor al balance" do
      pid = self()

      spawn(fn -> Auctioneer.bid(pid, pid, {1, 2, 1.1}) end)

      receive do
        {:free, id} ->
          assert id == 2
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "User balance is not enough to bid the amount"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
    end

    test "Pujar en una subasta cerrada" do
      pid = self()

      spawn(fn -> Auctioneer.bid(pid, pid, {2, 0, 10.0}) end)

      receive do
        {:free, id} ->
          assert id == 0
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "Auction is closed or does not exist"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
    end

    test "Pujar una cantidad menor a la puja minima" do
      pid = self()

      spawn(fn -> Auctioneer.bid(pid, pid, {1, 1, 0.4}) end)

      receive do
        {:free, id} ->
          assert id == 1
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "Bid must be higher than the current one"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
    end

    test "Pujar una cantidad menor a la puja actual" do
      pid = self()

      spawn(fn -> Auctioneer.bid(pid, pid, {1, 2, 0.4}) end)

      receive do
        {:free, id} ->
          assert id == 2
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:error, "Bid must be higher than the current one"}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
    end

    test "Pujar correctamente" do
      pid = self()

      spawn(fn -> Auctioneer.bid(pid, pid, {1, 2, 0.6}) end)

      receive do
        {:free, id} ->
          assert id == 2
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:ok, 0.4}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end

      auc2 = Auction |> Repo.get(2) |> Repo.preload(:bidder)

      assert auc2.seller_id == 0
      assert auc2.item_id == 2
      assert auc2.bidder_id == 1
      assert auc2.bid == 0.6
      refute auc2.paid

      assert auc2.bidder.balance == 0.4
      assert auc2.bidder.freezed == 0.6

      user2 = User |> Repo.get(2)

      assert user2.balance == 50.1
      assert user2.freezed == 0.0

      spawn(fn -> Auctioneer.bid(pid, pid, {2, 1, 50.1}) end)

      receive do
        {:free, id} ->
          assert id == 1
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end
      receive do
        {:test, response} ->
          assert response == {:ok, 0.0}
        after 5000 ->
          refute "TIMEOUT" == "TIMEOUT"
      end

      auc1 = Auction |> Repo.get(1) |> Repo.preload(:bidder)

      assert auc1.seller_id == 0
      assert auc1.item_id == 1
      assert auc1.bidder_id == 2
      assert auc1.bid == 50.1
      refute auc1.paid

      assert auc1.bidder.balance == 0.0
      assert auc1.bidder.freezed == 50.1
    end
  end
end
