defmodule HelloWeb.ChatRoomLive do
  use HelloWeb, :live_view
  alias Hello.{Room, Repo, Message, Presence}

  alias Phoenix.LiveView.JS
  alias Phoenix.PubSub
  use Phoenix.HTML
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
                    data-hidden="true"
                    onclick="toggleSidebar()"
                  >
                    <span class="block h-6 w-6 px-1 rounded-full hover:bg-gray-400">
                      <.icon name="hero-bars-3" />
                    </span>
                  </span>
                  <span
                    class="lg:hidden inline-block ml-8 text-gray-700 hover:text-gray-900 align-bottom"
                    id="onlinebtn"
                    data-show={show_online()}
                    data-hide={hide_online()}
                    data-hidden="true"
                    onclick="toggleOnline()"
                  >
                    <%!-- Social Icon --%>
                    <span class="block h-6 w-6 rounded-full hover:bg-gray-400">
                      <.icon name="hero-user-group" />
                    </span>
                  </span>
                </div>
              </div>
              <div class="main flex-1 flex flex-col">
                <div class="flex-1 flex h-full">
                  <div class="sidebar hidden lg:flex w-1/8 flex-2 flex-col pl-6 p-1 my-6">
                    <div class="search flex-2 px-2 pt-6">
                      <input
                        type="text"
                        class="outline-none block py-2 w-full bg-zinc-900 border-none rounded"
                        placeholder="Search"
                        phx-keyup="search_room"
                      />
                    </div>
                    <div class="flex-1 h-64 px-2 overflow-y-auto overscroll-contain">
                      <%= for room <- @user_rooms do %>
                        <div class="bg-gray-950 rounded p-4 flex flex-col my-2">
                          <h1 class="text-white font-black text-lg"><%= room.name %></h1>
                          <h4 class="text-zinc-200 text-ellipsis">
                            <span class="font-mono text-white"><%= room.last_sender %>: </span><%= room.last_text %>
                            <%!-- <span class="rounded-full px-2 py-1 bg-fuchsia-600 font-bold ml-auto">2</span>
                            unread --%>
                          </h4>
                        </div>
                      <% end %>
                    </div>
                  </div>
                  <div id="chat-area" class="h-[90vh] chat-area flex-1 flex flex-col">
                    <div class="flex-3">
                      <div class="text-xl mb-8 border-b-2 border-purple-500 text-gray-300 flex">
                        <div class="px-1">Room: <b><%= @room %></b></div>
                        <small class="text-sm" id="typing">
                          <%= if @typing !=nil do %>
                            <%= @typing %> is typing
                          <% end %>
                        </small>
                        <div class="ml-auto px-2">
                          <.link navigate={~p"/chat/vid-con/#{@room}/"}>
                            <.icon name="hero-phone" class="w-6 h-6"/>
                          </.link>
                          <.link navigate={~p"/chat/notes/#{@room}"}>
                            <.icon name="hero-pencil-square" class="w-6 h-6"/>
                          </.link>
                        </div>
                      </div>
                    </div>
                    <div
                      id="message-list"
                      class="overflow-y-auto overscroll-contain h-64 sm:h-full messages flex-1"
                      phx-update="append"
                    >

                      <%= for {"messages-"<>itemnum, msg} <- @streams.messages do %>
                        <% {itemnum, ""}=Integer.parse(itemnum) %>
                        <%!-- <div
                          class={"message p-2 mb-4 rounded-3xl
                          #{if msg.user.id === @current_user.id, do: "animate-flyin-r", else: "animate-flyin-l"}
                          #{if msg.user.id === @current_user.id, do: "bg-purple-800 text-white ml-20", else: "bg-gray-800 text-gray-300 mr-20"}"
                        }
                          ondblclick={"setReply(#{msg.id})"}
                          id={"message-item#{msg.id}"}
                        >
                          <div class={"w-full flex flex-row align-middle 
                            #{if msg.user.id === @current_user.id, do: "text-left", else: ""}"}>
                            <%= if msg.user.id == @current_user.id do %>
                              <div class="mx-4 text-md font-sans break-all">
                                <%= raw msg.text %>
                              </div>
                            <% end %>
                            <div class={"text-lg font-mono flex flex-col #{if msg.user.id == @current_user.id, do: "ml-auto pr-3", else: "pl-3"}"}>
                              <div class="text-gray-200 py-1 font-black">
                                <%= msg.user.username %>
                              </div>
                              <img
                                src={
                                  if msg.user.id === @current_user.id,
                                    do: @current_user.pfp || "https://placehold.co/600x600",
                                    else: msg.user.pfp || "https://placehold.co/600x600"
                                }
                                class="rounded-full h-10 w-10"
                              />
                              <small class="text-gray-200 text-xs py-1">
                                <%= msg.inserted_at.day %>/<%= msg.inserted_at.month %>/<%= msg.inserted_at.year %>
                                <br>
                                <%= msg.inserted_at.hour %>:<%= msg.inserted_at.minute %>
                              </small>
                            </div>
                            <%= if msg.user.id != @current_user.id do %>
                              <div class=" self-center px-4 text-md font-sans break-all">
                                <%= msg.text %>
                              </div>
                            <% end %>
                          </div>
                           --%>
                        <%!-- <div id={"tooltip-item#{msg.id}"} role="tooltip">My tooltip</div> --%>
                      <div
                          class={"message p-2 mb-4 animate-fade-down animate-once rounded-3xl grid grid-cols-4 text-white"}
                          id={"message-item#{msg.id}"}
                          ondblclick={"setReply(#{msg.id})"}
                      >
                      <%= 
                         if true do
                       %>
                        <div class={"text-lg font-mono flex flex-col"}>
                          <div class="text-gray-200 py-1 font-black">
                            <%= msg.user.username %>
                          </div>
                          <img
                            src={
                              if msg.user.id === @current_user.id,
                                do: @current_user.pfp || "https://placehold.co/600x600",
                                else: msg.user.pfp || "https://placehold.co/600x600"
                            }
                            class="rounded-full h-10 w-10"
                          />
                          <small class="text-gray-200 text-xs py-2">
                            <%= msg.inserted_at.day %>/<%= msg.inserted_at.month %>/<%= msg.inserted_at.year %>
                            <%= msg.inserted_at.hour %>:<%= msg.inserted_at.minute %>
                          </small>
                        </div>
                      <%= else %>
                        <div></div>
                      <% end %>
                        <div class=" self-center px-4 text-md font-sans break-all col-span-3 font-regular mt-4">
                          <%= raw msg.text %>
                        </div>
                      </div>
                      <% end %>
                      
                    </div>

                    <form
                      class="sticky flex-2 pb-20"
                      id="message_form"
                      phx-hook="MessageForm"
                      data-phx-cb={JS.push("message", value: %{"message" => "msgplaceholder", "reply"=>"replyplaceholder"})}
                    >
                      <div id="replyprev" class="
                        px-3 bg-zinc-900 flex flex-col
                        rounded-t-lg translate-y-1 font-semibold hidden pb-2" data-phx-isset="0">
                        <div class="flex flex-row">
                          <div id="replyuser" class="text-gray-100">
                            Replying to ZYX
                          </div>
                          <button class="ml-auto text-white" type="button" 
                            phx-click={
                              JS.add_class("hidden", to: "#replyprev")
                            }>
                            <.icon name="hero-x-mark"/>
                          </button>
                        </div>
                        <div id="replyval" class="
                          text-sm text-gray-300 border-l-2 
                          border-purple-500 pl-2 py-1 overflow-auto break-all bg-zinc-800">
                          IEATORANGES
                        </div>
                      </div>
                      <div class="write bg-zinc-900 shadow flex rounded-lg">
                        <div class="flex-3 flex content-center items-center text-center p-4 pr-0">
                        </div>
                        <div class="flex-1">
                          <input
                            phx-change="typing"
                            autocomplete="off"
                            name="message"
                            class="w-full block outline-none py-4 px-4 bg-transparent text-white"
                            rows="1"
                            placeholder="Type a message..."
                            autofocus
                          />
                        </div>
                        <div class="flex-2 w-32 p-2 flex content-center items-center">
                          <div class="flex-1 text-center " id="upload">
                            <span class="text-gray-300 hover:text-gray-800 ">
                              <.icon name="hero-photo" class="h-8 w-8"/>
                            </span>
                          </div>
                          <div class="flex-1">
                            <!--Submit btn-->
                            <button
                              id="submit"
                              class="bg-purple-700 w-10 h-10 rounded-full inline-block"
                            >
                              <span class="inline-block align-text-bottom text-white">
                                <.icon name="hero-paper-airplane"/>
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
                        phx-keydown={JS.push("replyset",value: %{"a"=>1})}
                      />
                    </div>
                    <div class="flex-1 h-full overflow-auto px-2">
                      <div class="text-white px-4 font-mono pt-1">
                        <%= users_online(length(@users)) %>
                      </div>
                      <%= for user <- @room_struct.users do %>
                        <%= if Enum.find(@users, fn u -> u.name == user.username end) != nil do %>  
                          <div class="bg-gray-950 rounded my-2 p-4 w-full flex ">
                            <img
                              src={user.pfp || "https://placehold.co/600x600"}
                              class="rounded-full h-8 w-8"
                            />
                            <span class="relative flex h-3 w-3">
                              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75">
                              </span>
                              <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500">
                              </span>
                            </span>
                            <h4 class="text-zinc-200 px-4 py-1">
                              <span class="font-black text-white"><%= user.username %></span>
                            </h4>
                          </div>
                        <% end %>
                      <% end %>
                      <hr/>
                      <%= for user <- @room_struct.users do %>
                        <%= if Enum.find(@users, fn u -> u.name == user.username end) == nil do %>  
                          <div class="bg-gray-950 rounded my-2 p-4 w-full flex ">
                            <img
                              src={user.pfp || "https://placehold.co/600x600"}
                              class="rounded-full h-8 w-8"
                            />
                            <span class="relative flex h-3 w-3">
                              <span class="relative inline-flex rounded-full h-3 w-3 bg-gray-500">
                              </span>
                            </span>
                            <h4 class="text-zinc-200 px-4 py-1">
                              <span class="font-black text-white"><%= user.username %></span>
                            </h4>
                          </div>
                        <% end %>
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
        let msglist = document.querySelector("#message-list")
        msglist.scrollTop = msglist.scrollHeight;

        window.addEventListener("phx:message_sent", (e) => {
          msglist.scrollTop = msglist.scrollHeight
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

        window.addEventListener("phx:reply", (e) => {
          document.querySelector("#replyuser").innerHTML = "Replying to "+e.detail.user
          document.querySelector("#replyval").innerHTML = e.detail.text
          console.log(e.detail)
        })

        let setReply = (id) =>{
          document.querySelector("#replyprev").setAttribute('data-phx-isset',"1")
          let ev = `[
            ["push",
              {
                "event":"replyset",
                "value": {
                  "id": ${id}
                }
              }
            ],
            [
              "remove_class",
              {
                "time": 200,
                "names": ["hidden"],
                "to": "#replyprev",
                "transition": [[], [], []]
              }
            ]
          ]`
          console.log(id)
          liveSocket.execJS(document.querySelector(`#message-item${id}`), ev)        
        }

        let hideReply =()=> {
          let ev = `[
            [
              "add_class",
              {
                "time": 200,
                "names": ["hidden"],
                "to": "#replyprev",
                "transition": [[], [], []]
              }
            ]
          ]`
          document.querySelector("#replyprev").setAttribute('data-phx-isset',"0")
          liveSocket.execJS(document.querySelector(`#replyprev`), ev)     
        }
      </script>
    </div>
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
          |> where([m], m.room_id == ^i.id)
          |> Repo.all()
          |> List.first()

          %{
            name: i.name,
            last_sender: String.slice(m.user.username, 0..10),
            last_text: String.slice(m.text, 0..10)
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
          room_struct: room_struct,
          typing: nil,
          users: [],
          user_rooms: user_rooms,
        )
        |>stream(:messages, messages)
      }
    end
  end

  def handle_event("typing", _params, socket) do
    notify({:ok, socket.assigns.current_user.username}, :typing, socket.assigns.room)
    {:noreply, socket}
  end

  def handle_event("message", %{"message" => msg, "reply"=>reply}, socket) do
    IO.puts(socket.assigns.current_user.username <> " sent " <> "\"" <> msg <> "\" ")
    IO.puts(reply)

    is_reply = if reply != "" do  true else false end

    if msg == "" do
      {:noreply, socket}
    else
      text = HtmlSanitizeEx.html5(msg)
      IO.inspect text

      text = if is_reply do " 
                  <div class='
                    text-sm text-gray-300 border-l-2 
                    border-purple-900 pl-2 py-1 pr-1 break-all bg-zinc-800 w-full'>
                    #{reply}
                  </div>
                  #{text}
                " else text end
      msg_ =
        Repo.insert(%Message{
          text: text,
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

  def handle_event("replyset", %{"id"=>value}, socket) do
    IO.puts(socket.assigns.current_user.username <> " wanna reply")
    {
      :noreply,
      socket
      |> push_event("reply", %{
        "user" => socket.assigns.current_user.username, 
        "value"=> value,
        "text"=>Repo.get(Message, value).text
      })
    }
  end

  def handle_info({:message_incoming, message}, socket) do
    {
      :noreply,
      socket
      |> push_event("message_sent", %{})
      |> stream_insert(:messages, message)
    }
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
    |> JS.hide(to: "#chat-area")
    |> JS.add_class("absolute w-11/12 h-screen", to: ".online")
  end

  def hide_online(js \\ %JS{}) do
    js
    |> JS.hide(to: ".online")
    |> JS.show(to: "#chat-area")
    |> JS.remove_class("absolute w-11/12 h-screen", to: ".online")
  end

  def grpmsgs(remainder, grpdlist, last) do
    #IO.inspect({remainder, grpdlist})
    #IO.puts "\n\n\n\n\n\n\n"
    if remainder == [] do
      grpdlist # return a val
    else
      [curr|remainder] = remainder
      if curr.user.id == last.user.id do
        grpdlistlast = List.last(grpdlist) ++ [curr]
        grpdlist = grpdlist
            |> List.replace_at(-1, grpdlistlast)
        Grp.grpmsgs(remainder, grpdlist, curr)
      else
        Grp.grpmsgs(remainder, grpdlist++[[curr]], curr)
      end
    end
    # IO.inspect Enum.take_while(remainder, fn m->m.userid==msg.userid end)
    # [_curr| remainder] = remainder
    # IO.inspect(remainder)
  end

end
