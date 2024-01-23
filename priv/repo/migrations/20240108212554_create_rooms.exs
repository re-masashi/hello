defmodule Hello.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :pass, :string
      add :messages, references(:messages, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:rooms, [:messages])
    create unique_index(:rooms, [:name])
  end
end
