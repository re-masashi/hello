defmodule HelloWeb.Router do
  use HelloWeb, :router

  import HelloWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HelloWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/token", TokenController, :index

  end

  # scope "/chat", HelloWeb do
  #   pipe_through [:browser, :require_authenticated_user]

  #   live_session :authenticated, on_mount: [{HelloWeb.UserAuth, :ensure_authenticated}] do
  #     live "/", ChatJoinLive
  #     live "/create", ChatCreateLive
  #     live "/join", ChatJoinLive
  #     live "/:room", ChatRoomLive
  #     live "/vid-con/:room", ChatVideoLive
  #   end
  # end


  live_session :authenticated, on_mount: [{HelloWeb.UserAuth, :ensure_authenticated}] do

    scope "/listen", HelloWeb do
      pipe_through [:browser, :require_authenticated_user]

      live "/search", ChatJoinLive
      live "/song/:id", ChatJoinLive
      live "/album/:id", ChatJoinLive
      live "/playlist/:id", ChatJoinLive
      live "/favourites", ChatJoinLive
      live "/history", ChatJoinLive
    end

    scope "/chat", HelloWeb do
      pipe_through [:browser, :require_authenticated_user]

      live "/", ChatJoinLive
      live "/create", ChatCreateLive
      live "/join", ChatJoinLive
      live "/:room", ChatRoomLive
      live "/vid-con/:room", ChatVideoLive
      live "/notes/:room", ChatNotesLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:hello, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HelloWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HelloWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{HelloWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", HelloWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{HelloWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HelloWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{HelloWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
