defmodule AuctionSystemTest.Servers.CreditServerTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Tasks.FilterList
  alias AuctionSystem.Schemas.Category
  doctest FilterList

  setup do
    trunc = "TRUNCATE TABLE CATEGORIES,
    WEAPONS,
    SKINS,
    ITEMS,
    USERS,
    AUCTIONS;"

    ins_cat = "INSERT INTO CATEGORIES
  VALUES (0, 'Knives'),
                (1, 'Gloves'),
                (2, 'Rifles'),
                (3, 'Pistols');"
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

    #Insert data into the DB
    {:ok, _} = Repo.query(trunc)
    {:ok, _} = Repo.query(ins_cat)
    {:ok, _} = Repo.query(ins_wea)
    {:ok, _} = Repo.query(ins_ski)
    {:ok, _} = Repo.query(ins_ite)
    {:ok, _} = Repo.query(ins_use)
    {:ok, _} = Repo.query(ins_auc)

    :ok
  end

  #Lists all categories in the DB
  test "Category" do
    spawn(fn -> FilterList.list_categories(self(), :test))

    receive do
      {:market, :test, response} ->
        assert response == [{0,"Knives"},{1,"Gloves"},{2,"Rifles"},{3,"Pistols"}]

    end
  end
end
