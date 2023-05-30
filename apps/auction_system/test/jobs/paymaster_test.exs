defmodule AuctionSystemTest.Jobs.PaymasterTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Jobs.Paymaster
  alias AuctionSystem.Schemas.{Auction,Category,User}
  alias AuctionSystem.Repo
  doctest Paymaster

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
                (1, 'UserTest2', 0.0, 27.2),
                (2, 'UserTest3', 50.5, 0.5);"
    ins_auc = "INSERT INTO AUCTIONS
  VALUES (0, 0, 0, 1, 25.0, 27.2, '2023-05-29', FALSE),
                (1, 0, 1, NULL, 50.0, NULL, '2023-05-29', FALSE),
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

  test "pay_now" do
    {status, _} = Paymaster.pay_now()
    assert status == :ok

    seller = User |> Repo.get(0)
    assert seller.balance == 27.2
    assert seller.freezed == 0.0

    bidder1 = User |> Repo.get(1)
    assert bidder1.balance == 0
    assert bidder1.freezed == 0

    bidder2 = User |> Repo.get(2)
    assert bidder2.balance == 50.5
    assert bidder2.freezed == 0.5

    auc1 = Auction |> Repo.get(0)
    assert auc1.bidder_id == 1
    assert auc1.bid == 27.2
    assert auc1.paid

    auc2 = Auction |> Repo.get(1)
    assert is_nil(auc2.bidder_id)
    assert is_nil(auc2.bid)
    refute auc2.paid

    auc3 = Auction |> Repo.get(2)
    assert auc3.bidder_id == 2
    refute auc3.paid
  end

end
