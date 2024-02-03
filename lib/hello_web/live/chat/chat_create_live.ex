defmodule HelloWeb.ChatCreateLive do
  use HelloWeb, :live_view

  def render(assigns) do
    ~H"""
    <main class="bg-gray-800 max-w-lg mx-auto p-8 md:p-12 my-10 rounded-lg shadow-2xl hover:bg-gray-900 transition">
      <section>
        <h3 class="font-bold text-2xl text-white">Create a Room</h3>
        <p class="text-gray-300 pt-2">Start Your Journey</p>
      </section>

      <section class="mt-10 ">
        <.form for={@form} phx-submit="save" class="flex flex-col " phx-change="validate">
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>
          <div class="mb-6 pt-3 rounded bg-gray-500">
            <label class="block text-gray-200 text-sm font-bold mb-2 ml-3" for="name">Name</label>
            <.input field={@form[:name]} type="text" required />
          </div>
          <div class="mb-6 pt-3 rounded bg-gray-500">
            <label class="block text-gray-200 text-sm font-bold mb-2 ml-3" for="password">
              Password
            </label>
            <.input field={@form[:pass]} type="password" required />
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
          <button phx-disable-with="Creating account..." class="w-full bg-gray-500">
            Create a room
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
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

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
