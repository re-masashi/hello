defmodule HelloWeb.ChatNotesLive do
  use HelloWeb, :live_view
  alias Hello.{Room, Repo, Message, Presence, Note}

  import Ecto.Query
  import Ecto.Changeset

  def render(assigns) do
    ~H"""
    <main class="bg-gray-800 w-full mx-auto p-8 md:p-12 my-10 rounded-lg shadow-2xl hover:bg-gray-900 transition text-wrap">
      <link rel="stylesheet" href="//unpkg.com/@catppuccin/highlightjs@0.1.4/css/catppuccin-macchiato.css">
      <%= for  {_, note} <- [1, 2] do %>
      <div class="flex flex-row justify-center text-white font-black p-4">
        <.link class="font-semibold p-4" navigate={"/notes/"<>""}>&lt; <%= note.text %> &gt;</.link>
      </div>
      <% end %>
  <div class="grid grid-cols-2 grid-rows-1 p-4 font-extrabold text-white">
    <button>EDITOR</button>
    <button>PREVIEW</button>
  </div>
  <div class="grid grid-cols-2 grid-rows-1 gap-2">
    <textarea
      id="editor"
      class="w-full rounded-lg prose max-w-none text-zinc-400 leading-6 rounded-b-md shadow-sm border border-gray-900 p-5 bg-gray-800 overflow-y-auto"
      onkeyup="document.querySelector(`#preview`).innerHTML = marked.parse(document.querySelector(`#editor`).value)"
    ></textarea>
    <div id="preview" class="w-full rounded-lg prose max-w-none prose-indigo text-zinc-400 leading-6 rounded-b-md shadow-sm border border-gray-900 p-5 bg-gray-800 overflow-y-auto" ></div>
  </div>

    </main>
    """
  end

  def mount(%{"room" => room}, _session, socket) do
    changeset = Hello.Room.changeset(%Hello.Room{}, %{})

    room_struct = Repo.get_by(Room, name: room) |> Repo.preload([:users])

    socket =
      socket
      |> assign(notes:
        Note
        |> preload([:user])
        |> order_by(desc: :inserted_at)
        |> limit(70)
        |> where([m], m.room_id == ^room_struct.id)
        |> Repo.all()
        |> Enum.reverse()
      )

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("validate", %{"room" => room_params}, socket) do
    changeset = Hello.Room.changeset(%Hello.Room{}, room_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("save", %{"room" => %{"name" => name, "pass" => passwd}}, socket) do
    changeset = Hello.Room.changeset(%Hello.Room{}, %{"name" => name, "pass" => passwd})

    if changeset.valid? do
      Hello.Repo.insert(%Hello.Room{
        name: name,
        pass: passwd,
        users: [socket.assigns.current_user]
      })

      {
        :noreply,
        socket
        |> put_flash(:info, "Room " <> name <> " created successfully!")
        |> redirect(to: "/chat/" <> name)
      }
    else
      {
        :noreply,
        socket
        |> assign(check_errors: false)
        |> assign_form(changeset)
      }
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "room")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
