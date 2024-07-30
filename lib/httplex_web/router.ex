defmodule HTTPlexWeb.Router do
  use HTTPlexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HTTPlexWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  scope "/", HTTPlexWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:httplex, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HTTPlexWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", HTTPlexWeb do
    pipe_through :api
    get "/hello", APIController, :index
    get "/ip", APIController, :ip
    get "/user-agent", APIController, :user_agent
    get "/headers", APIController, :headers
    get "/get", APIController, :get
    post "/post", APIController, :post
    put "/put", APIController, :put
    patch "/patch", APIController, :patch
    delete "/delete", APIController, :delete
    get "/status/:code", APIController, :status
    get "/delay/:n", APIController, :delay
    get "/base64/:value", APIController, :decode_base64
    get "/bytes/:n", APIController, :random_bytes
    get "/cookies", APIController, :cookies
    post "/cookies/set", APIController, :set_cookies
    get "/image/:format", APIController, :image
    get "/image", APIController, :image
    get "/json", APIController, :json_response
    get "/xml", APIController, :xml_response
    post "/forms/post", APIController, :forms_post
    get "/redirect/:n", APIController, :redirectx
    get "/stream/:n", APIController, :stream
    get "/*path", APIController, :anything
  end
end
