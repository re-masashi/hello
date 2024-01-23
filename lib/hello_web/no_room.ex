defmodule HelloWeb.NoRoom do
	defexception message: "Invalid or non-existent room.", plug_status: 404
end