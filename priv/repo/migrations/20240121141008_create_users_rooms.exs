defmodule Hello.Repo.Migrations.CreateUsersRooms do
  use Ecto.Migration

  def change do
    create table(:users_rooms, primary_key: false) do
      add :room_id, references(:rooms)
      add :user_id, references(:users)
    end

    create index(:users_rooms, [:room_id, :user_id])
  end
end
