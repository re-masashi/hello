defmodule HelloWeb.ChatRoomLive do
  use HelloWeb, :live_view
  alias Hello.{Room, Repo, Message, Presence}

  alias Phoenix.LiveView.JS
  alias Phoenix.PubSub
  import Ecto.Query
  import Ecto.Changeset

  def subscribe(room) do
    PubSub.subscribe(Hello.PubSub, "room:"<>room)
  end

  def notify({:ok, message}, event, room) do
    PubSub.broadcast(Hello.PubSub, "room:"<>room, {event, message})
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
    <div class="bg-black w-full h-11/12">
      <div class="w-full h-full bg-black" id="app">
        <div class="flex h-full">
          <div class="flex-1 bg-black w-full h-full">
            <div class="main-body container m-auto w-full flex flex-col">
              <div class="flex-2 flex flex-row">
                <div class="flex-1">
                  <span
                    class="lg:hidden inline-block text-gray-700 hover:text-gray-900 align-bottom"
                    id="sidebarbtn"
                    data-show={show_sidebar()}
                    data-hide={hide_sidebar()}
                    data-hidden='true'
                    onclick="toggleSidebar()"
                  >
                    <span class="block h-6 w-6 p-1 rounded-full hover:bg-gray-400">
                      <svg
                        class="w-4 h-4"
                        fill="none"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path d="M4 6h16M4 12h16M4 18h16"></path>
                      </svg>
                    </span>
                  </span>
                  <span
                    class="lg:hidden inline-block ml-8 text-gray-700 hover:text-gray-900 align-bottom"
                    id="onlinebtn"
                    data-show={show_online()}
                    data-hide={hide_online()}
                    data-hidden='true'
                    onclick="toggleOnline()"
                  > 
                  <%!-- Social Icon --%>
                    <span class="block h-6 w-6 p-1 rounded-full hover:bg-gray-400"
                    >
                      <svg
                        class="h-4 w-4"
                        fill="none"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                        ></path>
                      </svg>
                    </span>
                  </span>
                </div>
              </div>
              <div class="main flex-1 flex flex-col">

                <div class="flex-1 flex h-full">
                  <div class="sidebar hidden lg:flex w-1/4 flex-2 flex-col pr-6 my-4">
                    <div class="search flex-2 px-2 pt-6">
                      <input
                        type="text"
                        class="outline-none block py-2 w-full bg-zinc-900 border-none rounded"
                        placeholder="Search"
                        phx-keyup="search_room"
                      />
                    </div>
                    <div class="flex-1 h-full overflow-auto px-2">
                      <div class="bg-gray-950 rounded p-4 w-full flex flex-row my-2">
                        <h4 class="text-zinc-200"><span class="font-black text-white">Admin: </span>hewwo</h4>
                        <span class="rounded-full px-2 py-1 bg-red-400 ml-auto font-bold">10</span>
                      </div>
                    </div>
                  </div>
                  <div
                    id="chat-area"
                    class="h-[90vh] chat-area flex-1 flex flex-col"
                  >
                    <div class="flex-3">
                      <h2
                        class="text-xl mb-8 border-b-2 border-purple-500 text-gray-300"
                      >
                        Room: <b><%= @room %></b>

                        <small class="text-sm" id="typing">
                              <%= if @typing !=nil do %>
                                <%= @typing %> is typing
                                
                              <% end %>
                        </small>
                      </h2>
                    </div>
                    <div
                      id="message-list"
                      class="overflow-y-auto overscroll-contain h-64 messages flex-1"
                      phx-update="append"
                    >
                      <%= for msg <- @messages do %>
                        <div 
                          class={"message p-2 mb-4 animate-fade-down animate-once rounded-3xl #{if msg.user.id === @current_user.id, do: ""}
                            #{if msg.user.id === @current_user.id, do: "bg-purple-800 text-white ml-20", else: "bg-gray-800 text-gray-300 mr-20"}"}
                          id={"message-item#{msg.id}"}
                        >
                          <div class={"w-full flex flex-row align-middle 
                            #{if msg.user.id === @current_user.id, do: "", else: ""}"}
                          >
                            <%= if msg.user.id == @current_user.id do%>
                            <div class="text-center self-center mx-4 text-md font-sans break-all whitespace-break-spaces"><%= msg.text %></div>
                            <%end%>
                            <div class={"text-lg font-mono flex flex-col #{if msg.user.id == @current_user.id, do: "ml-auto pr-3", else: "pl-3"}"}>
                                  <div class="text-gray-200 py-1 font-black"><%= msg.user.username %> </div>
                                  <img src={
                                    if msg.user.id === @current_user.id, do: @current_user.pfp||"https://placehold.co/600x600", else: msg.user.pfp||"https://placehold.co/600x600"
                                  } class="rounded-full h-10 w-10"/>
                            </div>
                            <%= if msg.user.id != @current_user.id do%>
                              <div class=" text-center self-center px-4 text-md font-sans break-all"><%= msg.text %></div>
                            <%end%>
                          </div>
                        </div>

                      <% end %>
                    </div>

                    <form class="sticky flex-2 pb-20" 
                      id="message_form"
                      phx-hook="MessageForm"
                      data-phx-cb={
                        JS.push("message", value: %{"message"=>"msgplaceholder"})
                      }
                    >
                      <div class="write bg-zinc-900 shadow flex rounded-lg">
                        <div
                          class="flex-3 flex content-center items-center text-center p-4 pr-0"
                        ></div>
                        <div class="flex-1">
                          <input
                            phx-change="typing"
                            autocomplete="off"
                            name="message"
                            class="w-full block outline-none py-4 px-4 bg-transparent"
                            rows="1"
                            placeholder="Type a message..."
                            autofocus
                          />
                        </div>
                        <div
                          class="flex-2 w-32 p-2 flex content-center items-center"
                        >
                          <div class="flex-1 text-center" id="upload">
                            <span class="text-gray-400 hover:text-gray-800">
                              <span class="inline-block align-text-bottom">
                                <svg
                                  fill="none"
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  stroke="currentColor"
                                  viewBox="0 0 24 24"
                                  class="w-6 h-6"
                                >
                                  <path
                                    d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"
                                  ></path>
                                </svg>
                              </span>
                            </span>
                          </div>
                          <div class="flex-1">
                            <!--Submit btn-->
                            <button
                              id="submit"
                              class="bg-blue-400 w-10 h-10 rounded-full inline-block"
                            >
                              <span class="inline-block align-text-bottom">
                                <svg
                                  fill="none"
                                  stroke="currentColor"
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  viewBox="0 0 24 24"
                                  class="w-4 h-4 text-white"
                                >
                                  <path d="M5 13l4 4L19 7"></path>
                                </svg>
                              </span>
                            </button>
                          </div>
                        </div>
                      </div>
                    </form>
                  </div>
                  <div class="online hidden lg:flex w-1/8 flex-2 flex-col pl-6 p-1 my-6">
                    <div class="search flex-2 px-2">
                      <input
                        type="text"
                        class="outline-none py-2 block w-full bg-zinc-900 border-none rounded"
                        placeholder="Search who's online"
                        phx-keyup="search_online"
                      />
                    </div>
                    <div class="flex-1 h-full overflow-auto px-2">

                      <div class="text-white px-4 font-mono pt-1">
                        <%= users_online(length(@users)) %>
                      </div>
                      <%= for user <- @users do %>
                        <div class="bg-gray-950 rounded my-2 p-4 w-full flex ">
                          <img src={user.pfp||"https://placehold.co/600x600"} class="rounded-full h-8 w-8"/>
                          <span class="relative flex h-3 w-3">
                            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                            <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                          </span>
                          <h4 class="text-zinc-200 px-4 py-1"><span class="font-black text-white"><%= user.name%> </span></h4>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <script type="text/javascript">
        window.addEventListener("phx:message_sent", (e) => {
          let el = document.querySelector("#message-list")
          el.scrollTop = el.scrollHeight
        })

        window.addEventListener("phx:typing", (e) => {
          let type_text;
          if("<%= @current_user.username %>"==e.detail.user){
            type_text="You are typing..."
          }else{
            type_text=e.detail.user+" is typing..."
          }
          document.getElementById('typing').innerHTML=type_text;
          setTimeout((()=>{document.getElementById('typing').innerHTML="";}), 2000)
        })

      </script>
    </div>
    """
  end

  def mount(%{"room"=>room},  _session, socket) do
    if connected?(socket), do: subscribe(room)

    room_struct = Repo.get_by(Room, name: room)|>Repo.preload([:users])
    if room_struct == nil do
      raise HelloWeb.NoRoom
    else
      messages = Message
        |>preload([:user])
        |> order_by(desc: :inserted_at)
        |>limit(70)
        |>where([m], m.room_id == ^room_struct.id)
        |>Repo.all()
        |>Enum.reverse()

      if socket.assigns.current_user.unreads|>Map.has_key?(room) do
        Repo.update(change(socket.assigns.current_user, %{unreads: %{}}))
      end


      {:ok, _} = Presence.track(self(), "room_presence:"<>room, socket.assigns.current_user.id, %{
        name: socket.assigns.current_user.username,
        joined_at: :os.system_time(:seconds),
        pfp: socket.assigns.current_user.pfp
      })
      Phoenix.PubSub.subscribe(Hello.PubSub, "room_presence:"<>room)
      {
        :ok,
        assign(socket, 
          room: room, 
          messages: messages,
          room_struct: room_struct,
          typing: nil,
          users: [],
          temporary_assigns: [messages: [], users: []]
        )
      }
    end
  end

  def handle_event("typing", _params, socket) do
    notify({:ok, socket.assigns.current_user.username}, :typing, socket.assigns.room)
    {:noreply, socket}
  end

  def handle_event("message", %{"message"=>msg}, socket) do
    IO.puts(socket.assigns.current_user.username<>" sent "<>"\""<>msg<>"\" ")
    if msg=="" do
      {:noreply, socket}
    else
      msg_= Repo.insert(
        %Message{text: msg, user: socket.assigns.current_user, room_id: socket.assigns.room_struct.id}
      )
      # for user <- socket.assigns.room_struct.users do
      #   unr = Map.put(user.unreads, socket.assigns.room, %{"count"=>user.unreads.count+1, "last"=>msg})
      #   Repo.update(change(user, %{unreads: unr}))
      # end
      notify(msg_, :message_incoming, socket.assigns.room)
      {:noreply, socket}
    end
  end

  def handle_event("search_room", _params, socket) do
    IO.puts(socket.assigns.current_user.username<>" is searching")
    {:noreply, socket}
  end

  def handle_info({:message_incoming, message}, socket) do
    messages = [message]
    {:noreply, assign(socket, messages: messages)|> push_event("message_sent", %{})}
  end

  def handle_info({:typing, user}, socket) do
    IO.puts("tye")
    {
      :noreply, 
      socket
      |>push_event("typing", %{"user"=>user})
    }
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    IO.puts(socket.assigns.current_user.username)
    users =
      Presence.list("room_presence:"<>socket.assigns.room)
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
    |> JS.hide(to: ".online")
    |> JS.add_class("absolute w-11/12", to: ".sidebar")
  end

  def hide_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(to: ".sidebar")
    |> JS.show(to: "#chat-area")
    |> JS.remove_class("absolute w-11/12", to: ".sidebar")
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
    |> JS.remove_class("absolute w-w-5/6 h-screen bg-black p-4", to: ".online")
  end

end
