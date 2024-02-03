defmodule HelloWeb.RoomUnauthorized do
  defexception message: "Unauthorized.", plug_status: 405
end
