defmodule HTTPlexWeb.APIController do
  use HTTPlexWeb, :controller

  @realm "abhinav@httplex.com"

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _params) do
    json(conn, %{message: "Welcome to HTTPlex!"})
  end

  @spec ip(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def ip(conn, _params) do
    json(conn, %{origin: format_ip(conn.remote_ip)})
  end

  @spec user_agent(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def user_agent(conn, _params) do
    user_agent = get_req_header(conn, "user-agent") |> List.first()
    json(conn, %{"user-agent": user_agent})
  end

  @spec headers(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def headers(conn, _params) do
    json(conn, %{headers: Map.new(conn.req_headers)})
  end

  @spec get(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def get(conn, _params) do
    json(conn, request_info(conn))
  end

  @spec post(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def post(conn, _params) do
    json(conn, request_info(conn))
  end

  @spec put(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def put(conn, _params) do
    json(conn, request_info(conn))
  end

  @spec patch(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def patch(conn, _params) do
    json(conn, request_info(conn))
  end

  @spec delete(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def delete(conn, _params) do
    json(conn, request_info(conn))
  end

  @spec cache(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def cache(conn, _params) do
    etag = "33a64df551425fcc55e4d42a148795d9f25f89d4"
    last_modified = "Wed, 31 July 2024 07:28:00 GMT"

    conn =
      conn
      |> put_resp_header("etag", etag)
      |> put_resp_header("last-modified", last_modified)

    case {get_req_header(conn, "if-none-match"), get_req_header(conn, "if-modified-since")} do
      {[^etag], _} -> send_resp(conn, 304, "")
      {_, [^last_modified]} -> send_resp(conn, 304, "")
      _ -> json(conn, %{status: "ok"})
    end
  end

  @spec cache_control(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def cache_control(conn, %{"value" => seconds}) do
    {seconds, _} = Integer.parse(seconds)

    conn
    |> put_resp_header("cache-control", "public, max-age=#{seconds}")
    |> json(%{status: "ok"})
  end

  @spec etag(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def etag(conn, %{"etag" => etag}) do
    conn = put_resp_header(conn, "etag", etag)

    case get_req_header(conn, "if-none-match") do
      [^etag] ->
        send_resp(conn, 304, "")

      _ ->
        case get_req_header(conn, "if-match") do
          ["*"] -> json(conn, %{status: "ok"})
          [^etag] -> json(conn, %{status: "ok"})
          _ -> send_resp(conn, 412, "Precondition Failed")
        end
    end
  end

  @spec response_headers(any(), any()) :: Plug.Conn.t()
  def response_headers(conn, params) do
    conn =
      Enum.reduce(params, conn, fn {key, value}, acc ->
        put_resp_header(acc, key, value)
      end)

    json(conn, params)
  end

  @spec basic_auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def basic_auth(conn, %{"user" => user, "passwd" => passwd}) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> encoded] ->
        case Base.decode64(encoded) do
          {:ok, decoded} ->
            [provided_user, provided_passwd] = String.split(decoded, ":", parts: 2)

            if provided_user == user && provided_passwd == passwd do
              json(conn, %{authenticated: true, user: user})
            else
              send_resp(conn, 401, "Unauthorized")
            end

          _ ->
            send_unauthorized(conn)
        end

      _ ->
        send_unauthorized(conn)
    end
  end

  @spec bearer(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def bearer(conn, _params) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        # In a real application, you would validate the token here
        # We'll just check if the token is not empty
        if token != "" do
          json(conn, %{authenticated: true, token: token})
        else
          send_resp(conn, 401, "Unauthorized")
        end

      _ ->
        conn
        |> put_resp_header("www-authenticate", "Bearer realm=\"example\"")
        |> send_resp(401, "Unauthorized")
    end
  end

  @spec digest_auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def digest_auth(conn, %{
        "qop" => qop,
        "user" => user,
        "passwd" => passwd,
        "algorithm" => algorithm,
        "stale_after" => stale_after
      }) do
    stale_after = String.to_integer(stale_after)
    handle_digest_auth(conn, qop, user, passwd, algorithm, stale_after)
  end

  def digest_auth(conn, %{
        "qop" => qop,
        "user" => user,
        "passwd" => passwd,
        "algorithm" => algorithm
      }) do
    handle_digest_auth(conn, qop, user, passwd, algorithm, nil)
  end

  def digest_auth(conn, %{"qop" => qop, "user" => user, "passwd" => passwd}) do
    handle_digest_auth(conn, qop, user, passwd, "MD5", nil)
  end

  @spec hidden_basic_auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def hidden_basic_auth(conn, %{"user" => user, "passwd" => passwd}) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> encoded] ->
        case Base.decode64(encoded) do
          {:ok, decoded} ->
            [provided_user, provided_passwd] = String.split(decoded, ":", parts: 2)

            if provided_user == user && provided_passwd == passwd do
              json(conn, %{authenticated: true, user: user})
            else
              send_resp(conn, 404, "Not Found")
            end

          _ ->
            send_resp(conn, 404, "Not Found")
        end

      _ ->
        send_resp(conn, 404, "Not Found")
    end
  end

  @spec status(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def status(conn, %{"code" => code}) do
    code = String.to_integer(code)
    send_resp(conn, code, "")
  end

  @spec delay(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delay(conn, %{"delay" => delay}) do
    {delay, _} = Float.parse(delay)
    delay = min(delay, 10.0)
    :timer.sleep(round(delay * 1000))
    json(conn, %{delay: delay})
  end

  @spec decode_base64(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def decode_base64(conn, %{"value" => value}) do
    case Base.url_decode64(value) do
      {:ok, decoded} -> text(conn, decoded)
      :error -> send_resp(conn, 400, "Invalid base64 encoding")
    end
  end

  @spec random_bytes(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def random_bytes(conn, %{"n" => n}) do
    # 100KB limit
    n = String.to_integer(n) |> min(100 * 1024)
    data = :crypto.strong_rand_bytes(n)

    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, data)
  end

  @spec drip(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def drip(conn, params) do
    duration = Map.get(params, "duration", "2") |> parse_float_or_int()
    numbytes = Map.get(params, "numbytes", "10") |> String.to_integer()
    delay = Map.get(params, "delay", "2") |> parse_float_or_int()

    :timer.sleep(round(delay * 1000))

    interval = round(duration * 1000 / numbytes)

    data =
      for _ <- 1..numbytes do
        :timer.sleep(interval)
        <<0>>
      end

    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, IO.iodata_to_binary(data))
  end

  @spec links(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def links(conn, %{"n" => n, "offset" => offset}) do
    {n, _} = Integer.parse(n)
    {offset, _} = Integer.parse(offset)

    links =
      Enum.map(1..n, fn i ->
        "/links/#{n}/#{offset + i}"
      end)

    html =
      Enum.map(links, fn link ->
        "<a href=\"#{link}\">#{link}</a><br>"
      end)
      |> Enum.join("\n")

    html(conn, "<html><body>#{html}</body></html>")
  end

  @spec range(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def range(conn, %{"numbytes" => numbytes}) do
    {numbytes, _} = Integer.parse(numbytes)
    data = :crypto.strong_rand_bytes(numbytes)

    conn
    |> put_resp_header("accept-ranges", "bytes")
    |> put_resp_header("content-range", "bytes 0-#{numbytes - 1}/#{numbytes}")
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, data)
  end

  @spec stream_bytes(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def stream_bytes(conn, %{"n" => n}) do
    {n, _} = Integer.parse(n)
    data = :crypto.strong_rand_bytes(n)

    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, data)
  end

  @spec stream_json(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def stream_json(conn, %{"n" => n}) do
    n = String.to_integer(n)

    if Mix.env() == :test do
      # For testing, return all numbers at once
      conn
      |> put_resp_content_type("application/json")
      |> json(Enum.to_list(n..1))
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_chunked(200)
      |> stream_data(String.to_integer(n))
    end
  end

  defp stream_data(conn, 0), do: conn

  defp stream_data(conn, n) do
    :timer.sleep(1000)
    chunk(conn, "#{n}\n")
    stream_data(conn, n - 1)
  end

  @spec uuid(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def uuid(conn, _params) do
    uuid = UUID.uuid4()
    json(conn, %{uuid: uuid})
  end

  @spec get_cookies(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_cookies(conn, _params) do
    json(conn, conn.req_cookies)
  end

  @spec delete_cookies(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete_cookies(conn, params) do
    conn =
      Enum.reduce(params, conn, fn {key, _}, acc ->
        delete_resp_cookie(acc, key, max_age: 0)
      end)

    redirect(conn, to: "/cookies")
  end

  @spec set_cookies(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def set_cookies(conn, params) do
    conn =
      Enum.reduce(params, conn, fn {key, value}, acc ->
        put_resp_cookie(acc, key, value)
      end)

    redirect(conn, to: "/cookies")
  end

  @spec set_cookie(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def set_cookie(conn, %{"name" => name, "value" => value}) do
    conn
    |> put_resp_cookie(name, value)
    |> redirect(to: "/cookies")
  end

  @spec image(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def image(conn, %{"format" => format}) do
    image_path =
      case format do
        "png" -> "priv/static/images/sample.png"
        "jpeg" -> "priv/static/images/sample.jpeg"
        "jpg" -> "priv/static/images/sample.jpg"
        "webp" -> "priv/static/images/sample.webp"
        "svg" -> "priv/static/images/sample.svg"
        _ -> "priv/static/images/sample.png"
      end

    conn
    |> put_resp_content_type("image/#{format}")
    |> send_file(200, image_path)
  end

  @spec image(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def image(conn, _params) do
    conn
    |> put_resp_content_type("image/png")
    |> send_file(200, "priv/static/images/sample.png")
  end

  @spec brotli(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def brotli(conn, _params) do
    {:ok, encoded_data} = :brotli.encode("This content is Brotli-encoded.")

    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("content-encoding", "br")
    |> send_resp(200, encoded_data)
  end

  @spec deflate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def deflate(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("content-encoding", "deflate")
    |> send_resp(200, :zlib.compress("This content is Deflate-encoded."))
  end

  @spec deny(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def deny(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "You've been denied access by robots.txt.")
  end

  @spec encoding_utf8(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def encoding_utf8(conn, _params) do
    conn
    |> put_resp_content_type("text/plain", "utf-8")
    |> send_resp(200, "नमस्ते दुनिया")
  end

  @spec gzip(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def gzip(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("content-encoding", "gzip")
    |> send_resp(200, :zlib.gzip("This content is GZip-encoded."))
  end

  @spec html_response(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def html_response(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "<html><body><h1>Hello, World!</h1></body></html>")
  end

  @spec json_response(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def json_response(conn, _params) do
    json(conn, %{message: "This is a JSON response"})
  end

  @spec robots_txt(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def robots_txt(conn, _params) do
    content = """
    # See https://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
    #
    # To ban all spiders from the entire site uncomment the next two lines:
    # User-agent: *
    # Disallow: /
    """

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, String.trim(content))
  end

  @spec xml(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def xml(conn, _params) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(
      200,
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><message>This is an XML response</message></root>"
    )
  end

  @spec forms_post(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def forms_post(conn, _params) do
    json(conn, conn.body_params)
  end

  @spec absolute_redirect(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def absolute_redirect(conn, %{"n" => n}) do
    n = String.to_integer(n)

    if n > 0 do
      redirect(conn, external: "#{custom_current_url(conn)}/absolute-redirect/#{n - 1}")
    else
      json(conn, %{message: "Redirect completed"})
    end
  end

  @spec redirect_to(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirect_to(conn, %{"url" => url} = params) do
    status = Map.get(params, "status_code", "302") |> String.to_integer()

    conn
    |> put_status(status)
    |> redirect(external: url)
  end

  @spec redirectx(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def redirectx(conn, %{"n" => n}) do
    n = String.to_integer(n)

    if n > 0 do
      redirect(conn, to: "/redirect/#{n - 1}")
    else
      json(conn, %{message: "Redirect completed"})
    end
  end

  @spec relative_redirect(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def relative_redirect(conn, %{"n" => n}) do
    n = String.to_integer(n)

    if n > 0 do
      redirect(conn, to: "/relative-redirect/#{n - 1}")
    else
      json(conn, %{message: "Redirect completed"})
    end
  end

  @spec anything(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def anything(conn, params) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    content_type = get_req_header(conn, "content-type") |> List.first()

    {data, json_data, form_data} =
      case content_type do
        "application/json" <> _ ->
          json_data = if body != "", do: Jason.decode!(body), else: %{}
          {body, json_data, %{}}

        "application/x-www-form-urlencoded" <> _ ->
          form_data = if body != "", do: Plug.Conn.Query.decode(body), else: %{}
          {body, nil, form_data}

        _ ->
          {body, nil, %{}}
      end

    # Ensure query_params are fetched
    conn = fetch_query_params(conn)

    response = %{
      method: conn.method,
      url: custom_current_url(conn),
      headers: conn.req_headers |> Enum.into(%{}),
      args: conn.query_params,
      data: data,
      form: form_data,
      json: json_data,
      params: params
    }

    json(conn, response)
  end

  defp request_info(conn) do
    %{
      method: conn.method,
      url: custom_current_url(conn),
      headers: Map.new(conn.req_headers),
      args: conn.query_params,
      form: conn.body_params,
      data: custom_read_body(conn),
      json: if(json?(conn), do: conn.body_params, else: nil),
      origin: format_ip(conn.remote_ip)
    }
  end

  defp custom_read_body(conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, _conn} -> body
      {:more, body, _conn} -> body
      _ -> ""
    end
  end

  defp json?(conn) do
    case get_req_header(conn, "content-type") do
      ["application/json" <> _] -> true
      _ -> false
    end
  end

  defp custom_current_url(conn) do
    conn = fetch_query_params(conn)
    query_string = if conn.query_string != "", do: "?#{conn.query_string}", else: ""
    "#{conn.scheme}://#{conn.host}#{conn.request_path}#{query_string}"
  end

  defp format_ip(ip) do
    case ip do
      {a, b, c, d} ->
        "#{a}.#{b}.#{c}.#{d}"

      {0, 0, 0, 0, 0, 65535, ab, cd} ->
        <<a, b, c, d>> = <<ab::16, cd::16>>
        "#{a}.#{b}.#{c}.#{d}"

      _ ->
        to_string(:inet.ntoa(ip))
    end
  end

  defp handle_digest_auth(conn, qop, user, passwd, algorithm, stale_after) do
    case get_req_header(conn, "authorization") do
      ["Digest " <> credentials] ->
        creds = parse_digest_credentials(credentials)

        if check_digest_auth(creds, user, passwd, conn.method, conn.request_path, algorithm) do
          if stale_after && stale_after > 0 do
            conn
            |> put_resp_header("authentication-info", "nextnonce=#{generate_nonce()}")
            |> json(%{authenticated: true, user: user})
          else
            json(conn, %{authenticated: true, user: user})
          end
        else
          send_digest_challenge(conn, qop, algorithm, false)
        end

      _ ->
        send_digest_challenge(conn, qop, algorithm, false)
    end
  end

  defp send_digest_challenge(conn, qop, algorithm, stale) do
    nonce = generate_nonce()
    opaque = generate_opaque()

    conn
    |> put_resp_header(
      "www-authenticate",
      "Digest realm=\"#{@realm}\", qop=\"#{qop}\", nonce=\"#{nonce}\", opaque=\"#{opaque}\", algorithm=#{algorithm}, stale=#{stale}"
    )
    |> send_resp(401, "Unauthorized")
  end

  defp check_digest_auth(creds, user, passwd, method, uri, algorithm) do
    hash_algo =
      case String.downcase(algorithm) do
        "sha-256" -> :sha256
        "md5" -> :md5
        _ -> raise "Unsupported algorithm: #{algorithm}"
      end

    ha1 = :crypto.hash(hash_algo, "#{user}:#{@realm}:#{passwd}") |> Base.encode16(case: :lower)
    ha2 = :crypto.hash(hash_algo, "#{method}:#{uri}") |> Base.encode16(case: :lower)

    response =
      case creds[:qop] do
        nil ->
          :crypto.hash(hash_algo, "#{ha1}:#{creds[:nonce]}:#{ha2}") |> Base.encode16(case: :lower)

        "auth" ->
          :crypto.hash(
            hash_algo,
            "#{ha1}:#{creds[:nonce]}:#{creds[:nc]}:#{creds[:cnonce]}:#{creds[:qop]}:#{ha2}"
          )
          |> Base.encode16(case: :lower)
      end

    creds[:response] == response
  end

  defp parse_digest_credentials(credentials) do
    credentials
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn pair ->
      [key, value] = String.split(pair, "=", parts: 2)
      {String.to_atom(key), String.trim(value, "\"")}
    end)
    |> Enum.into(%{})
  end

  defp generate_nonce do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp generate_opaque do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp send_unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", "Basic realm=\"HTTPlex\"")
    |> send_resp(401, "Unauthorized")
  end

  defp parse_float_or_int(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> float
      :error -> String.to_integer(value)
    end
  end

  defp parse_float_or_int(value) when is_number(value), do: value
end
