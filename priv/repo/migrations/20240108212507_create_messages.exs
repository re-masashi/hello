defmodule Hello.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :text, :string, null: false
      add :user_id, references(:users)
      add :room_id, references(:rooms)

      timestamps(type: :utc_datetime)
    end
  end
end
