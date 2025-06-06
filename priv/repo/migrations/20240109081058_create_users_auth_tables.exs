defmodule Hello.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false, collate: :nocase
      add :username, :string, null: false, collate: :nocase
      add :name, :string
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :pfp, :string
      add :unreads, :map, null: false, default: %{}
      
      timestamps(type: :utc_datetime)
    end


    create unique_index(:users, [:email])
    create unique_index(:users, [:username])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
