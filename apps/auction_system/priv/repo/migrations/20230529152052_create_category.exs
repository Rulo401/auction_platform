defmodule AuctionSystem.Repo.Migrations.CreateCategory do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
    end

    create unique_index(:categories, [:name], name: :index_cat_dup_entries)
  end
end
