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

    get "/cache", APIController, :cache
    get "/cache/:value", APIController, :cache_control
    get "/etag/:etag", APIController, :etag
    get "/response-headers", APIController, :response_headers
    post "/response-headers", APIController, :response_headers

    get "/basic-auth/:user/:passwd", APIController, :basic_auth
    get "/bearer", APIController, :bearer
    get "/digest-auth/:qop/:user/:passwd", APIController, :digest_auth
    get "/digest-auth/:qop/:user/:passwd/:algorithm", APIController, :digest_auth
    get "/digest-auth/:qop/:user/:passwd/:algorithm/:stale_after", APIController, :digest_auth
    get "/hidden-basic-auth/:user/:passwd", APIController, :hidden_basic_auth

    get "/status/:code", APIController, :status
    get "/delay/:delay", APIController, :delay
    post "/delay/:delay", APIController, :delay
    put "/delay/:delay", APIController, :delay
    patch "/delay/:delay", APIController, :delay
    delete "/delay/:delay", APIController, :delay

    get "/base64/:value", APIController, :decode_base64
    get "/bytes/:n", APIController, :random_bytes
    get "/drip", APIController, :drip
    get "/links/:n/:offset", APIController, :links
    get "/range/:numbytes", APIController, :range
    get "/stream-bytes/:n", APIController, :stream_bytes
    get "/stream/:n", APIController, :stream_json
    get "/uuid", APIController, :uuid

    get "/cookies", APIController, :cookies
    post "/cookies/set", APIController, :set_cookies

    get "/image/:format", APIController, :image
    get "/image", APIController, :image

    get "/brotli", APIController, :brotli
    get "/deflate", APIController, :deflate
    get "/deny", APIController, :deny
    get "/encoding/utf8", APIController, :encoding_utf8
    get "/gzip", APIController, :gzip
    get "/html", APIController, :html_response
    get "/json", APIController, :json_response
    get "/robots.txt", APIController, :robots_txt
    get "/xml", APIController, :xml
    post "/forms/post", APIController, :forms_post

    get "/absolute-redirect/:n", APIController, :absolute_redirect
    get "/redirect/:n", APIController, :redirectx
    get "/relative-redirect/:n", APIController, :relative_redirect
    delete "/redirect-to", APIController, :redirect_to
    get "/redirect-to", APIController, :redirect_to
    patch "/redirect-to", APIController, :redirect_to
    post "/redirect-to", APIController, :redirect_to
    put "/redirect-to", APIController, :redirect_to

    match :*, "/anything", APIController, :anything
    match :*, "/anything/*anything", APIController, :anything
  end

end
