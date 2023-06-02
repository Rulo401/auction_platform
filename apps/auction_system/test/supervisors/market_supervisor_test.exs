defmodule AuctionSystemTest.Supervisors.MarketSupervisorTest do
  use AuctionSystem.RepoCase
  alias AuctionSystem.Servers.MarketServer
  alias AuctionSystem.Supervisors.MarketSupervisor
  alias AuctionSystem.Repo
  alias AuctionSystem.Schemas.{Auction, Item}
  doctest MarketSupervisor

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
    VALUES (0, 'Ak-47', 2),
                                (1, 'M4A4', 2),
                                (2, 'AWP', 2),
                                (3, 'Karambit', 0);"
    ins_ski ="INSERT INTO SKINS
      VALUES (0, 0, 453, 'Vulcan', 0.1, 0.4),
                    (1, 0, 58, 'Redline', 0.01, 0.7);"
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

    MarketSupervisor.start_link([])
    :ok
  end

  test "List Categories" do
    assert GenServer.call(MarketServer, :list_category) == {:ok, [{0,"Knives"}, {1,"Gloves"}, {2,"Rifles"}, {3,"Pistols"}]}
  end

  test "List Weapons" do
    #List all weapons from category 2
    assert GenServer.call(MarketServer, {:list_weapons, 2}) == {:ok, [{0,"Ak-47"}, {1,"M4A4"}, {2,"AWP"}]}
    #List all weapons from category 5 that doesnt exist
    assert GenServer.call(MarketServer, {:list_weapons, 5}) == {:error, "Invalid category or No weapons for that category"}
  end

  test "List Skins" do
    #List all skins from weapon 0
    assert GenServer.call(MarketServer, {:list_skins, 0}) == {:ok, [{0, "Vulcan"}, {1, "Redline"}]}
    #List all skins from weapon 4 that doesnt exist
    assert GenServer.call(MarketServer, {:list_skins, 4}) == {:error, "Invalid weapon or No skins for that weapon"}
  end

  ## Tests de listar subastas
  test "List all auctions" do
    assert GenServer.call(MarketServer, {:list_auctions, :all}) == {:ok,[2]}
  end

  test "List auctions by category" do
    assert GenServer.call(MarketServer, {:list_auctions, :category, 2}) == {:ok,[2]}
    assert GenServer.call(MarketServer, {:list_auctions, :category, 4}) == {:error, "Invalid category or No auctions listed for that category"}
  end

  test "List auctions by weapon" do
    assert GenServer.call(MarketServer, {:list_auctions, :weapon, 0}) == {:ok,[2]}

    assert GenServer.call(MarketServer, {:list_auctions, :weapon, 7}) == {:error, "Invalid weapon or No auctions listed for that weapon"}
  end

  test "List auctions by skin" do
    assert GenServer.call(MarketServer, {:list_auctions, :skin, 1}) == {:ok,[2]}

    assert GenServer.call(MarketServer, {:list_auctions, :skin, 3}) == {:error, "Invalid skin or No auctions listed for that skin"}
  end

  test "Auction item: Invalid queries" do
    #Invalid duration
    item = %{skin_id: 0, seed: 20, sfloat: 0.13}
    assert GenServer.call(MarketServer, {:auction_item, 0, item, "1"}) == {:error, "Duration days must be a positive integer"}

    assert GenServer.call(MarketServer, {:auction_item, 0, item, 0}) == {:error, "Duration days must be a positive integer"}

    #Invalid minBid
    assert GenServer.call(MarketServer, {:auction_item, 0, item, 2, "five"}) == {:error, "The min bid must be float and greater than or equal to 0.1"}

    assert GenServer.call(MarketServer, {:auction_item, 0, item, 2, 0.09}) == {:error, "The min bid must be float and greater than or equal to 0.1"}

    #Invalid item definition
    item = %{skin_id: 0, seed: "20", sfloat: 0.13}
    assert GenServer.call(MarketServer, {:auction_item, 0, item, 2, 5.0}) == {:error, "Invalid item definition"}

    item = %{skin_id: 0, seed: 20, sfloat: :fl}
    assert GenServer.call(MarketServer, {:auction_item, 0, item, 2, 1.0}) == {:error, "Invalid item definition"}

    #Invalid float for skin
    item = %{skin_id: 0, seed: 20, sfloat: 0.09}
    assert GenServer.call(MarketServer, {:auction_item, 0, item, 2, 5.0}) == {:error, "Item float value is lower than the minimum accepted for this skin"}

    item = %{skin_id: 0, seed: 20, sfloat: 0.42}
    assert GenServer.call(MarketServer, {:auction_item, 0, item, 2, 1.0}) == {:error, "Item float value is higher than the maximum accepted for this skin"}
  end

  test "Auction item: Valid query" do
    item = %{skin_id: 0, seed: 20, sfloat: 0.13}
    {status, _} = GenServer.call(MarketServer, {:auction_item, 0, item, 2, 1.0})
    assert status == :ok
    assert length(Auction |> Repo.all) == 4
    assert length(Item |> Repo.all) == 4
  end

  test "Get auction data" do
    item = %{skin_id: 0, seed: 20, sfloat: 0.13}
    {status, au_id} = GenServer.call(MarketServer, {:auction_item, 0, item, 2})
    assert status == :ok

    assert length(Auction |> Repo.all) == 4
    assert length(Item |> Repo.all) == 4

    {status, map} = GenServer.call(MarketServer, {:auction_data, au_id})
    assert status == :ok
    assert map.weapon == "Ak-47"
    assert map.skin == "Vulcan"
    assert map.seed == 20
    assert map.skinFloat == 0.13
    assert map.bid == 0.1
  end

end
