defmodule AuctionSystem.Repo.Migrations.CreateSkin do
  use Ecto.Migration

  def change do
    create table(:skins) do
      add :weapon_id, references(:weapons), null: false
      add :paint, :integer, null: false
      add :minFloat, :float, null: false
      add :maxFloat, :float, null: false
    end

    create unique_index(:skins, [:weapon_id, :paint], name: :index_skins_dup_entries)
  end
end
