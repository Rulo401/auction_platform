defmodule AuctionSystem.Repo.Migrations.CreateWeapon do
  use Ecto.Migration

  def change do
    create table(:weapons) do
      add :name, :string, null: false
      add :category_id, references(:categories), null: false
    end

    create unique_index(:weapons, [:name], name: :index_weapon_duplicate_entries)
  end
end
