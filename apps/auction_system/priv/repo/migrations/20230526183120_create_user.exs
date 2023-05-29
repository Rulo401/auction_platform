defmodule AuctionSystem.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :nickname, :string, null: false
      add :balance, :float, default: 0.0
      add :freezed, :float, default: 0.0
    end

    create unique_index(:users, [:nickname], name: :index_user_dup_entries)
  end
end
