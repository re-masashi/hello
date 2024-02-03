defmodule HelloWeb.ChatJoinLive do
  use HelloWeb, :live_view
  alias Hello.{Room, Repo, Message}

  import Ecto.Query
  import Ecto.Changeset

  def render(assigns) do
    ~H"""
    <main class="max-w-lg mx-auto p-8 md:p-12 my-10 rounded-lg shadow-2xl bg-zinc-900">
      <section>
        <h3 class="font-bold text-2xl text-white">Join a Room</h3>
        <p class="text-gray-300 pt-2">Continue Your Journey</p>
      </section>

      <section class="mt-10 ">
        <.form for={@form} phx-submit="save" class="flex flex-col ">
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>
          <div class=" pt-3 rounded bg-zinc-900">
            <label class="block text-zinc-200 text-sm font-bold mb-2 ml-3" for="name">Name</label>
            <.input field={@form[:name]} type="text" phx-change="search_room" id="name" required />
            <%!-- <%= if @matches !=[] do %>
              <ul class="max-h-48 w-full my-3 p-2 overflow-y-scroll" id="rooms_list">
                <%= for room <- @matches do %>
                  <li class="my-1 p-4 border-2 bg-zinc-500 rounded-md border-zinc-800 relative cursor-pointer hover:text-gray-900">
                    <button
                      class="h-full w-full text-md font-bold"
                      onclick={"document.querySelector('#name').value=`#{room.name}`"}
                    >
                      <%= room.name %>
                    </button>
                  </li>
                <% end %>
              </ul>
            <% end %> --%>
          </div>
          <div class="mb-6 pt-3 rounded bg-zinc-900">
            <label class="block text-zinc-200 text-sm font-bold mb-2 ml-3" for="password">
              Password
            </label>
            <.input field={@form[:pass]} type="password" />
          </div>
          <%!-- 
          <label
            class="block text-gray-200 text-sm font-bold mb-2 ml-3"
            for="name"
            >Name</label>
          <.input type="text" field={@form[:name]}
            class="bg-gray-500 rounded w-full text-gray-700 focus:outline-none border-none px-3 pb-3"/>
          <label
            class="block text-gray-200 text-sm font-bold mb-2 ml-3"
            for="name"
            >Password</label>
          <.input type="password" field={@form[:pass]}
           class="bg-gray-500 rounded w-full text-gray-700 focus:outline-none border-none px-3 pb-3"/> --%>
          <button phx-disable-with="Joining room..." class="w-full bg-gray-500 p-1 rounded-md">
            Join a room
          </button>
        </.form>
      </section>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Hello.Room.changeset(%Hello.Room{}, %{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false, matches: [])
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("search_room", %{"_target" => _, "room" => %{"name" => name}}, socket) do
    like = "%#{name}%"

    matches =
      Room
      |> where([r], like(r.name, ^like))
      |> Repo.all()

    {:noreply, assign(socket, matches: matches)}
  end

  def handle_event("save", %{"room" => %{"name" => name, "pass" => passwd}}, socket) do
    room =
      Repo.get_by(Room, name: name)
      |> Repo.preload([:users])

    if room == nil do
      {
        :noreply,
        socket
        |> put_flash(:error, "No such room " <> name)
        |> assign(check_errors: false)
      }
    else
      # todo: change this
      if room.pass == passwd do
        u =
          Repo.get(Hello.Accounts.User, socket.assigns.current_user.id)
          |> Repo.preload([:rooms])

        if Enum.find(u.rooms, fn i -> i.name == room.name end) do
          {
            :noreply,
            socket
            |> put_flash(:info, "Welcome back to " <> name <> "!")
            |> redirect(to: "/chat/" <> name)
          }
        else
          user_to_room_add(u, room, socket)

          {
            :noreply,
            socket
            |> put_flash(:info, "Room " <> name <> " joined successfully!")
            |> redirect(to: "/chat/" <> name)
          }
        end
      else
        {
          :noreply,
          socket
          |> put_flash(:error, "Invalid password " <> name)
          |> assign(check_errors: false)
        }
      end
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

  def user_to_room_add(u, room, socket) do
    Repo.update(
      change(u, %{
        unreads: Map.put(u.unreads, room.name, %{"count" => 0, "last" => ""})
      })
    )

    Repo.update(
      change(room)
      |> put_assoc(:users, room.users++[u])
    )
  end
end
