defmodule HelloWeb.UserSettingsLive do
  use HelloWeb, :live_view

  alias Hello.Accounts

  import Ecto.Changeset

  def render(assigns) do
    ~H"""
    <.header class="text-center pt-10">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 lg:px-32 px-2">
      <div class="lg:px-32 pt-2">
        <div class="flex justify-center ">
          <img src={@current_user.pfp||"https://placehold.co/600x600"} class="rounded-full h-40 w-40"/>
        </div>
        <form id="upload-pfp" phx-change="validate" phx-submit="save" class="text-white flex flex-col justify-center p-4" >
          <div class="flex items-center justify-center p-4">
              <label class="w-42 flex flex-col items-center px-6 py-6 bg-zinc-900 text-white rounded-lg shadow-lg tracking-wide uppercase cursor-pointer hover:text-white">
                  <span class="mt-2 text-base leading-normal font-black">
                    Select a file
                  </span>
                  <span class="normal-case"><%= if @pfp_filename != "" do %>File: <%=@pfp_filename%> <%end%></span>

                  <.live_file_input upload={@uploads.pfp} 
                    required hidden/>
              </label>
          </div>
          <button type="submit" class="p-2 bg-purple-900 rounded-full">Upload</button>
        </form>
      </div>
      <div class=" lg:px-32">
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
          class=""
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing... " 
              class="rounded">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div class=" lg:px-32">
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing..."
            class="rounded">
            Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    _pfp_changeset = Accounts.User.pfp_changeset(user, %{})

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:uploaded_files, [])
      |> allow_upload(:pfp, accept: ~w(.jpg .jpeg .png), max_entries: 1)
      |> assign(:pfp_filename, "")
      |> assign(:trigger_submit, false)
      

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate", _params, socket) do
    entry = socket.assigns.uploads.pfp.entries|>List.first()
    socket = assign(socket, pfp_filename: entry.client_name)
    IO.inspect socket.assigns.pfp_filename
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :pfp, fn %{path: path}, entry ->
        dest = Path.join([:code.priv_dir(:hello), "static", "uploads", Path.basename(path)])
        IO.inspect entry.client_name

        # The `static/uploads` directory must exist for `File.cp!/2`
        # and MyAppWeb.static_paths/0 should contain uploads to work,.
        File.cp!(
          path, 
          dest#<>(socket.assigns.pfp|>String.split('.')|>List.last())
        )
        {:ok, "/uploads/" <> Path.basename(dest)}
      end)
    route= List.first(uploaded_files)
    #User |> update(set: [name: "new name"]) |> where(id: socket.assigns.current_user.id)
    u = Hello.Repo.get(Hello.Accounts.User, socket.assigns.current_user.id)
    Hello.Repo.update(change(u, %{pfp: route}))
    {:noreply, socket|>put_flash(:info, "PFP updated successfully!!")|>push_navigate(to: ~p"/users/settings")}
  end
  # def handle_progress(:pfp, entry, socket) do
  #   {if entry.done? do
  #         File.mkdir_p!(@uploads_dir)
    
  #         [{dest, _paths}] =
  #           consume_uploaded_entries(socket, :pfp, fn %{path: path}, _entry ->
  #             {:ok, [{:zip_comment, []}, {:zip_file, first, _, _, _, _} | _]} =
  #               :zip.list_dir(~c"#{path}")
    
  #             dest_path = Path.join(@uploads_dir, Path.basename(to_string(first)))
  #             {:ok, paths} = :zip.unzip(~c"#{path}", cwd: ~c"#{@uploads_dir}")
  #             {:ok, {dest_path, paths}}
  #           end)
    
  #         {:noreply, assign(socket, status: "\"#{Path.basename(dest)}\" uploaded!")}
  #       else
  #         {:noreply, assign(socket, status: "uploading...")}
  #       end}
  # end

end
