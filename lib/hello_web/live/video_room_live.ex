defmodule HelloWeb.ChatVideoLive do
  use HelloWeb, :live_view
  alias Hello.{Room, Repo, Message, Presence}

  alias Phoenix.LiveView.JS
  alias Phoenix.PubSub
  import Ecto.Query
  import Ecto.Changeset

  def subscribe(room) do
    PubSub.subscribe(Hello.PubSub, "room:" <> room)
  end

  def notify({:ok, message}, event, room) do
    PubSub.broadcast(Hello.PubSub, "room:" <> room, {event, message})
  end

  def notify({:error, reason}, _event, _room), do: {:error, reason}

  def users_online(0) do
    "No one's online"
  end

  def users_online(1) do
    "One user online"
  end

  def users_online(n) do
    "#{n} users online"
  end

  def render(assigns) do
    
    ~H"""
    <div>
      <div id="videochat-error" class="VideoChatError" style="display: none;"> </div>
      <div id="videochat" class="">
          <template id="video-feed-template">
              <div name="video-feed" class="relative bg-gray-900 shadow rounded-md overflow-hidden h-full w-full ratio-video">
                  <audio></audio>
                  <video class="w-full"></video>
                  <div name="video-label" class="absolute text-white text-shadow-lg bottom-0 left-0 p-2">Placeholder</div>
              </div>
          </template>
          <div class="flex flex-col justify-center items-center">
              <div id="videos-grid" class="grid grid-cols-2 grid-flow-row gap-4 justify-items-center"></div>
          </div>
      </div>
      <%!-- <div class="w-full h-[80%] absolute rounded-xl grid grid-cols-2 grid-rows-2 gap-2"> --%>
        <%!-- <div class="relative border-2 border-black rounded-xl bg-gray-600 animate-pulse">
          <img src="https://placehold.co/600x600" class="w-full h-full relative"/>
        </div>
        <div class="relative border-2 border-black rounded-xl bg-gray-600 animate-pulse">
          <img src="https://placehold.co/600x600" class="w-full h-full"/>
        </div>
        <div class="relative border-2 border-black rounded-xl bg-gray-600 animate-pulse">
          <img src="https://placehold.co/600x600" class="w-full h-full"/>
        </div>
        <div class="relative border-2 border-black rounded-xl bg-gray-600 animate-pulse">
          <img src="https://placehold.co/600x600" class="w-full h-full"/>
        </div> --%>
        <%!-- <div class="streams">
          <%= for uuid <- @joinees do %>
            <video id={"video-remote-#{uuid}"} data-user-uuid={uuid} playsinline autoplay phx-hook="InitUser"></video>
          <% end %>
        </div> --%>
      <%!-- </div> --%>
      <div id="room" class="flex flex-col h-screen relative" data-room-id={@room}>
          <!-- mb-14 to keep disconnect with absolute value above the videos-->
          <div id="participants-list"></div>
          <section class="flex flex-col max-h-screen mb-14">
              <div id="videochat" class="px-2 md:px-20 overflow-y-auto">
                  <template id="video-feed-template">
                      <div name="video-feed" class="relative bg-gray-900 shadow rounded-md overflow-hidden h-full w-full ratio-video">
                          <audio></audio>
                          <video class="w-full"></video>
                          <div name="video-label" class="absolute text-white text-shadow-lg bottom-0 left-0 p-2">Placeholder</div>
                      </div>
                  </template>
                  <div class="flex flex-col justify-center items-center">
                      <div id="videos-grid" class="grid grid-cols-2 grid-flow-row gap-4 justify-items-center"></div>
                  </div>
              </div>
              <div class="h-20"></div>
          </section>
          <div id="controls", class="flex-none flex justify-center h-8 pb-2 absolute inset-x-0 bottom-2">
              <button id="disconnect" class="text-white text-2xl font-normal hover:text-gray-400">Disconnect</button>
          </div>
      </div>

      <div class="w-64 h-32 bg-zinc-600 bottom-20 right-2 absolute rounded-xl z-20 cursor-grab " 
        id="mycam" 
      >
        <video class="transform -scale-x-100 relative rounded-xl" id="myvid" autoplay playsinline></video>
      </div>
      <div class="z-40 bottom-0 absolute fixed bg-zinc-950 text-white w-full flex flex-row justify-center">
        <div class="mr-auto">
          <button class="p-4 m-2 rounded-full bg-zinc-700">
            <.icon name="hero-microphone"/>
          </button>
          <button class="p-4 m-2 rounded-full bg-zinc-700">
            <.icon name="hero-video-camera"/>
          </button>
        </div>
        <button class="p-4 m-2 rounded-full bg-fuchsia-600">Accept</button>
        <button class="p-4 m-2 rounded-full bg-red-700">Decline</button>
      </div>
    </div>
    <script>
       // Make the DIV element draggable:
      dragElement(document.getElementById("mycam"));

      function dragElement(elmnt) {
        var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
        
        elmnt.onmousedown = dragMouseDown;
        

        function dragMouseDown(e) {
          e = e || window.event;
          e.preventDefault();
          // get the mouse cursor position at startup:
          pos3 = e.clientX;
          pos4 = e.clientY;
          document.onmouseup = closeDragElement;
          // call a function whenever the cursor moves:
          document.onmousemove = elementDrag;
        }

        function elementDrag(e) {
          e = e || window.event;
          e.preventDefault();
          // calculate the new cursor position:
          pos1 = pos3 - e.clientX;
          pos2 = pos4 - e.clientY;
          pos3 = e.clientX;
          pos4 = e.clientY;
          // set the element's new position:
          elmnt.style.top = (elmnt.offsetTop - pos2) + "px";
          elmnt.style.left = (elmnt.offsetLeft - pos1) + "px";
        }

        function closeDragElement() {
          // stop moving when mouse button is released:
          document.onmouseup = null;
          document.onmousemove = null;
        }
      }
    </script>
    """
  end

  def mount(%{"room" => room}, _session, socket) do
    if connected?(socket), do: subscribe(room)

    room_struct = Repo.get_by(Room, name: room) |> Repo.preload([:users])

    if room_struct == nil do
      raise HelloWeb.NoRoom
    else
      filter = Enum.filter(room_struct.users, fn i -> i.id == socket.assigns.current_user.id end)
      # not a member
      if filter == [] do
        raise HelloWeb.RoomUnauthorized
      end

      messages =
        Message
        |> preload([:user])
        |> order_by(desc: :inserted_at)
        |> limit(70)
        |> where([m], m.room_id == ^room_struct.id)
        |> Repo.all()
        |> Enum.reverse()

      if socket.assigns.current_user.unreads |> Map.has_key?(room) do
        Repo.update(change(socket.assigns.current_user, %{unreads: %{}}))
      end

      user_w_rooms = socket.assigns.current_user 
        |> Repo.preload([:rooms]) 
      user_rooms = user_w_rooms.rooms|> Enum.map(
        fn i -> (
          m = Message
          |> preload([:user])
          |> order_by(desc: :inserted_at)
          |> limit(1)
          |> where([m], m.room_id == ^room_struct.id)
          |> Repo.all()
          |>List.first()
          %{
            name: i.name,
            last_sender: String.slice(m.user.username, 0..10),
            last_text: String.slice("HEHEHHEHEHEHEHEHEHEHHEEH", 0..10)
          }
        ) end
      )

      {:ok, _} =
        Presence.track(self(), "room_presence:" <> room, socket.assigns.current_user.id, %{
          name: socket.assigns.current_user.username,
          joined_at: :os.system_time(:seconds),
          pfp: socket.assigns.current_user.pfp
        })

      Phoenix.PubSub.subscribe(Hello.PubSub, "room_presence:" <> room)

      {
        :ok,
        assign(socket,
          room: room,
          messages: messages,
          room_struct: room_struct,
          typing: nil,
          users: [],
          temporary_assigns: [
            messages: [],
          ],
          user_rooms: user_rooms,
          joinees: []
        )
      }
    end
  end

  def handle_event("typing", _params, socket) do
    notify({:ok, socket.assigns.current_user.username}, :typing, socket.assigns.room)
    {:noreply, socket}
  end

  def handle_event("message", %{"message" => msg}, socket) do
    IO.puts(socket.assigns.current_user.username <> " sent " <> "\"" <> msg <> "\" ")

    if msg == "" do
      {:noreply, socket}
    else
      msg_ =
        Repo.insert(%Message{
          text: msg,
          user: socket.assigns.current_user,
          room_id: socket.assigns.room_struct.id
        })

      # for user <- socket.assigns.room_struct.users do
      #   unr = Map.put(user.unreads, socket.assigns.room, %{"count"=>user.unreads.count+1, "last"=>msg})
      #   Repo.update(change(user, %{unreads: unr}))
      # end
      notify(msg_, :message_incoming, socket.assigns.room)
      {:noreply, socket}
    end
  end

  def handle_event("search_room", _params, socket) do
    IO.puts(socket.assigns.current_user.username <> " is searching")
    {:noreply, socket}
  end

  def handle_info({:message_incoming, message}, socket) do
    messages = [message]
    {:noreply, assign(socket, messages: messages) |> push_event("message_sent", %{})}
  end

  def handle_info({:typing, user}, socket) do
    {
      :noreply,
      socket
      |> push_event("typing", %{"user" => user})
    }
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    IO.puts(socket.assigns.current_user.username)

    users =
      Presence.list("room_presence:" <> socket.assigns.room)
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    {:noreply, assign(socket, users: users)}
  end

  def show_sidebar(js \\ %JS{}) do
    js
    |> JS.show(to: ".sidebar")
    |> JS.hide(to: "#chat-area")
    |> JS.add_class("absolute w-11/12 h-screen", to: ".sidebar")
  end

  def hide_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(to: ".sidebar")
    |> JS.show(to: "#chat-area")
    |> JS.remove_class("absolute w-11/12 h-screen", to: ".sidebar")
  end

  def show_online(js \\ %JS{}) do
    js
    |> JS.show(to: ".online")
    |> JS.remove_class("pl-6", to: ".online")
    |> JS.add_class("absolute w-5/6 h-screen bg-black p-4", to: ".online")
  end

  def hide_online(js \\ %JS{}) do
    js
    |> JS.hide(to: ".online")
    |> JS.add_class("pl-6", to: ".online")
    |> JS.remove_class("absolute w-5/6 h-screen bg-black p-4", to: ".online")
  end
end
