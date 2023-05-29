defmodule AuctionSystem.Repo.Migrations.CreateItem do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :skin_id, references(:skins), null: false
      add :seed, :integer, null: false
      add :skinFloat, :float, null: false
    end
  end
end
