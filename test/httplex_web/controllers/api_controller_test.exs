defmodule HTTPlexWeb.APIControllerTest do
  use HTTPlexWeb.ConnCase

  describe "Basic endpoints" do
    test "GET /hello", %{conn: conn} do
      conn = get(conn, ~p"/hello")
      assert json_response(conn, 200) == %{"message" => "Welcome to HTTPlex!"}
    end

    test "GET /ip", %{conn: conn} do
      conn = get(conn, ~p"/ip")
      assert %{"origin" => ip} = json_response(conn, 200)
      assert is_binary(ip)
    end

    test "GET /user-agent", %{conn: conn} do
      user_agent = "TestAgent/1.0"
      conn = conn |> put_req_header("user-agent", user_agent) |> get(~p"/user-agent")
      assert json_response(conn, 200) == %{"user-agent" => user_agent}
    end

    test "GET /headers", %{conn: conn} do
      conn = conn |> put_req_header("x-test-header", "test-value") |> get(~p"/headers")
      assert %{"headers" => headers} = json_response(conn, 200)
      assert headers["x-test-header"] == "test-value"
    end
  end

  describe "HTTP methods" do
    test "GET /get", %{conn: conn} do
      conn = get(conn, ~p"/get?param=value")
      assert %{"args" => %{"param" => "value"}} = json_response(conn, 200)
    end

    test "POST /post", %{conn: conn} do
      conn = post(conn, ~p"/post", %{key: "value"})
      assert %{"form" => %{"key" => "value"}} = json_response(conn, 200)
    end

    test "PUT /put", %{conn: conn} do
      conn = put(conn, ~p"/put", %{key: "value"})
      assert %{"form" => %{"key" => "value"}} = json_response(conn, 200)
    end

    test "PATCH /patch", %{conn: conn} do
      conn = patch(conn, ~p"/patch", %{key: "value"})
      assert %{"form" => %{"key" => "value"}} = json_response(conn, 200)
    end

    test "DELETE /delete", %{conn: conn} do
      conn = delete(conn, ~p"/delete")
      assert %{"method" => "DELETE"} = json_response(conn, 200)
    end
  end

  describe "Digest Authentication" do
    test "GET /digest-auth/{qop}/{user}/{passwd} - initial request", %{conn: conn} do
      conn = get(conn, ~p"/digest-auth/auth/testuser/testpass")
      assert response(conn, 401) =~ "Unauthorized"
      assert get_resp_header(conn, "www-authenticate") |> List.first() =~ ~r/Digest/
    end

    test "GET /digest-auth/{qop}/{user}/{passwd} - successful auth", %{conn: conn} do
      conn =
        perform_digest_auth(
          conn,
          "/digest-auth/auth/testuser/testpass",
          "testuser",
          "testpass",
          "MD5"
        )

      assert json_response(conn, 200) == %{"authenticated" => true, "user" => "testuser"}
    end

    test "GET /digest-auth/{qop}/{user}/{passwd}/{algorithm} - successful auth with SHA-256", %{
      conn: conn
    } do
      conn =
        perform_digest_auth(
          conn,
          "/digest-auth/auth/testuser/testpass/SHA-256",
          "testuser",
          "testpass",
          "SHA-256"
        )

      assert json_response(conn, 200) == %{"authenticated" => true, "user" => "testuser"}
    end

    test "GET /digest-auth/{qop}/{user}/{passwd}/{algorithm}/{stale_after} - stale nonce", %{
      conn: conn
    } do
      # First request should succeed
      conn =
        perform_digest_auth(
          conn,
          "/digest-auth/auth/testuser/testpass/MD5/1",
          "testuser",
          "testpass",
          "MD5"
        )

      assert json_response(conn, 200) == %{"authenticated" => true, "user" => "testuser"}
      assert get_resp_header(conn, "authentication-info") |> List.first() =~ ~r/nextnonce=/

      # Second request should succeed with a new nonce
      conn =
        perform_digest_auth(
          conn,
          "/digest-auth/auth/testuser/testpass/MD5/1",
          "testuser",
          "testpass",
          "MD5"
        )

      assert json_response(conn, 200) == %{"authenticated" => true, "user" => "testuser"}
    end
  end

  # Helper function to perform digest authentication
  defp perform_digest_auth(conn, path, username, password, algorithm) do
    # Get the challenge
    challenge_conn = get(conn, path)

    case get_resp_header(challenge_conn, "www-authenticate") do
      [] ->
        # If we don't get a www-authenticate header, return the conn as is
        challenge_conn

      [auth_header] ->
        %{nonce: nonce, realm: realm} = parse_www_authenticate(auth_header)

        # Generate the response
        hash_algo =
          case String.downcase(algorithm) do
            "sha-256" -> :sha256
            "md5" -> :md5
            _ -> raise "Unsupported algorithm: #{algorithm}"
          end

        ha1 =
          :crypto.hash(hash_algo, "#{username}:#{realm}:#{password}")
          |> Base.encode16(case: :lower)

        ha2 = :crypto.hash(hash_algo, "GET:#{path}") |> Base.encode16(case: :lower)

        response =
          :crypto.hash(hash_algo, "#{ha1}:#{nonce}:00000001:0a4f113b:auth:#{ha2}")
          |> Base.encode16(case: :lower)

        # Make the authenticated request
        auth_header =
          "Digest username=\"#{username}\", realm=\"#{realm}\", nonce=\"#{nonce}\", uri=\"#{path}\", qop=auth, nc=00000001, cnonce=\"0a4f113b\", response=\"#{response}\", opaque=\"\""

        build_conn()
        |> put_req_header("authorization", auth_header)
        |> get(path)
    end
  end

  # Helper function to parse WWW-Authenticate header
  defp parse_www_authenticate(header) do
    header
    |> String.replace("Digest ", "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn pair ->
      [key, value] = String.split(pair, "=", parts: 2)
      {String.to_atom(key), String.trim(value, "\"")}
    end)
    |> Enum.into(%{})
  end

  describe "Status" do
    test "GET /status/:code", %{conn: conn} do
      conn = get(conn, ~p"/status/418")
      assert response(conn, 418) == ""
    end
  end

  describe "Base64 decode" do
    test "GET /base64/{value} decodes base64url-encoded string", %{conn: conn} do
      encoded = "SGVsbG8sIFdvcmxkIQ=="
      conn = get(conn, ~p"/base64/#{encoded}")
      assert response(conn, 200) == "Hello, World!"
    end

    test "GET /base64/{value} returns 400 for invalid base64", %{conn: conn} do
      conn = get(conn, ~p"/base64/invalid_base64")
      assert response(conn, 400) == "Invalid base64 encoding"
    end
  end

  describe "Random bytes" do
    test "GET /bytes/{n} returns n random bytes", %{conn: conn} do
      n = 10
      conn = get(conn, ~p"/bytes/#{n}")
      assert response(conn, 200)
      assert byte_size(response(conn, 200)) == n
    end
  end

  describe "Delayed response" do
    test "GET /delay/{delay} returns after specified delay", %{conn: conn} do
      delay = 2
      start_time = System.system_time(:millisecond)
      conn = get(conn, ~p"/delay/#{delay}")
      end_time = System.system_time(:millisecond)

      assert json_response(conn, 200) == %{"delay" => delay}
      assert end_time - start_time >= delay * 1000
    end

    test "POST /delay/{delay} returns after specified delay", %{conn: conn} do
      delay = 2
      start_time = System.system_time(:millisecond)
      conn = post(conn, ~p"/delay/#{delay}")
      end_time = System.system_time(:millisecond)

      assert json_response(conn, 200) == %{"delay" => delay}
      assert end_time - start_time >= delay * 1000
    end

    # Similar tests for PUT, PATCH, and DELETE...
  end

  describe "Drip data" do
    test "GET /drip returns data over time", %{conn: conn} do
      conn = get(conn, ~p"/drip?duration=1.0&numbytes=5&delay=1.0")
      assert response(conn, 200)
      assert byte_size(response(conn, 200)) == 5
    end
  end

  describe "Generate links" do
    test "GET /links/{n}/{offset} generates n links", %{conn: conn} do
      n = 5
      offset = 0
      conn = get(conn, ~p"/links/#{n}/#{offset}")
      assert response(conn, 200)
      assert response(conn, 200) =~ "<a href=\"/links/5/1\">/links/5/1</a>"
      assert response(conn, 200) =~ "<a href=\"/links/5/5\">/links/5/5</a>"
    end
  end

  describe "Bytes range" do
    test "GET /range/{numbytes} returns specified number of bytes", %{conn: conn} do
      numbytes = 100
      conn = get(conn, ~p"/range/#{numbytes}")
      assert response(conn, 200)
      assert byte_size(response(conn, 200)) == numbytes
      assert get_resp_header(conn, "content-range") == ["bytes 0-99/100"]
    end
  end

  describe "Stream bytes" do
    test "GET /stream-bytes/{n} streams n bytes", %{conn: conn} do
      n = 100
      conn = get(conn, ~p"/stream-bytes/#{n}")
      assert response(conn, 200)
      assert byte_size(response(conn, 200)) == n
    end
  end

  describe "Stream JSON" do
    test "GET /stream/{n} streams n JSON objects", %{conn: conn} do
      conn = get(conn, ~p"/stream/3")
      assert response_content_type(conn, :json)
      # {:ok, _} = Plug.Conn.sent_resp(conn)
      # assert conn.state == :chunked
      assert response_content_type(conn, :json)
      assert json_response(conn, 200) == [3, 2, 1]
    end
  end

  describe "UUID" do
    test "GET /uuid returns a valid UUID", %{conn: conn} do
      conn = get(conn, ~p"/uuid")
      assert %{"uuid" => uuid} = json_response(conn, 200)
      assert {:ok, _} = UUID.info(uuid)
    end
  end

  describe "Cookies" do
    test "GET /cookies", %{conn: conn} do
      conn = conn |> put_req_header("cookie", "test=value") |> get(~p"/cookies")
      assert json_response(conn, 200) == %{"test" => "value"}
    end

    test "POST /cookies/set", %{conn: conn} do
      conn = post(conn, ~p"/cookies/set", %{name: "test", value: "cookie_value"})
      assert json_response(conn, 200) == %{"message" => "Cookie set!"}
      assert conn.resp_cookies["test"] == %{value: "cookie_value"}
    end
  end

  describe "Images" do
    test "GET /image", %{conn: conn} do
      conn = get(conn, ~p"/image")
      assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]
    end

    test "GET /image/:format", %{conn: conn} do
      for format <- ["png", "jpeg", "jpg", "webp", "svg"] do
        conn = get(conn, ~p"/image/#{format}")
        assert get_resp_header(conn, "content-type") == ["image/#{format}; charset=utf-8"]
      end
    end
  end

  describe "Response formats" do
    test "GET /html returns HTML content", %{conn: conn} do
      conn = get(conn, ~p"/html")
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert response(conn, 200) == "<html><body><h1>Hello, World!</h1></body></html>"
    end

    test "GET /json returns JSON content", %{conn: conn} do
      conn = get(conn, ~p"/json")
      assert json_response(conn, 200) == %{"message" => "This is a JSON response"}
    end

    test "GET /xml returns XML content", %{conn: conn} do
      conn = get(conn, ~p"/xml")
      assert get_resp_header(conn, "content-type") == ["application/xml; charset=utf-8"]

      assert response(conn, 200) ==
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><message>This is an XML response</message></root>"
    end
  end

  describe "Forms" do
    test "POST /forms/post", %{conn: conn} do
      conn = post(conn, ~p"/forms/post", %{key: "value"})
      assert json_response(conn, 200) == %{"key" => "value"}
    end
  end

  describe "Redirects" do
    test "GET /redirect/:n redirects for n > 0", %{conn: conn} do
      conn = get(conn, ~p"/redirect/3")
      assert redirected_to(conn, 302) == "https://httplex.com/redirect/2"
    end

    test "GET /redirect/:n stops redirecting when n = 0", %{conn: conn} do
      conn = get(conn, ~p"/redirect/0")
      assert json_response(conn, 200) == %{"message" => "Redirect completed"}
    end
  end

  describe "Catch-all route" do
    test "GET /anything with query params" do
      conn =
        :get
        |> Plug.Test.conn("/anything?key=value")
        |> HTTPlexWeb.Router.call([])

      response = json_response(conn, 200)
      assert response["method"] == "GET"
      assert response["args"] == %{"key" => "value"}
      assert response["data"] == ""
    end

    test "POST /anything with JSON body" do
      body = Jason.encode!(%{key: "value"})
      conn =
        :post
        |> Plug.Test.conn("/anything", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> HTTPlexWeb.Router.call([])

      response = json_response(conn, 200)
      assert response["method"] == "POST"
      assert response["json"] == %{"key" => "value"}
      assert response["data"] == body
    end

    test "PATCH /anything with form data" do
      body = "key=value"
      conn =
        :patch
        |> Plug.Test.conn("/anything", body)
        |> Plug.Conn.put_req_header("content-type", "application/x-www-form-urlencoded")
        |> HTTPlexWeb.Router.call([])

      response = json_response(conn, 200)
      assert response["method"] == "PATCH"
      assert response["form"] == %{"key" => "value"}
      assert response["data"] == body
    end

    test "PUT /anything/{anything}" do
      conn =
        :put
        |> Plug.Test.conn("/anything/test")
        |> HTTPlexWeb.Router.call([])

      response = json_response(conn, 200)
      assert response["method"] == "PUT"
      assert response["url"] =~ "/anything/test"
      assert response["data"] == ""
    end

    test "DELETE /anything/{anything}" do
      conn =
        :delete
        |> Plug.Test.conn("/anything/test")
        |> HTTPlexWeb.Router.call([])

      response = json_response(conn, 200)
      assert response["method"] == "DELETE"
      assert response["url"] =~ "/anything/test"
      assert response["data"] == ""
    end
  end

  describe "Bearer Token Authentication" do
    test "GET /bearer - successful auth", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer valid_token")
        |> get(~p"/bearer")

      assert json_response(conn, 200) == %{"authenticated" => true, "token" => "valid_token"}
    end

    test "GET /bearer - failed auth", %{conn: conn} do
      conn = get(conn, ~p"/bearer")

      assert response(conn, 401) == "Unauthorized"
      assert get_resp_header(conn, "www-authenticate") == ["Bearer realm=\"example\""]
    end
  end

  describe "Hidden Basic Authentication" do
    test "GET /hidden-basic-auth/:user/:passwd - successful auth", %{conn: conn} do
      auth = Base.encode64("testuser:testpass")

      conn =
        conn
        |> put_req_header("authorization", "Basic #{auth}")
        |> get(~p"/hidden-basic-auth/testuser/testpass")

      assert json_response(conn, 200) == %{"authenticated" => true, "user" => "testuser"}
    end

    test "GET /hidden-basic-auth/:user/:passwd - failed auth", %{conn: conn} do
      conn = get(conn, ~p"/hidden-basic-auth/testuser/testpass")

      assert response(conn, 404) == "Not Found"
      assert get_resp_header(conn, "www-authenticate") == []
    end

    test "GET /hidden-basic-auth/:user/:passwd - wrong credentials", %{conn: conn} do
      auth = Base.encode64("wronguser:wrongpass")

      conn =
        conn
        |> put_req_header("authorization", "Basic #{auth}")
        |> get(~p"/hidden-basic-auth/testuser/testpass")

      assert response(conn, 404) == "Not Found"
      assert get_resp_header(conn, "www-authenticate") == []
    end
  end

  describe "Basic Authentication" do
    test "GET /basic-auth/:user/:passwd - successful auth", %{conn: conn} do
      auth = Base.encode64("testuser:testpass")

      conn =
        conn
        |> put_req_header("authorization", "Basic #{auth}")
        |> get(~p"/basic-auth/testuser/testpass")

      assert json_response(conn, 200) == %{"authenticated" => true, "user" => "testuser"}
    end

    test "GET /basic-auth/:user/:passwd - failed auth", %{conn: conn} do
      conn = get(conn, ~p"/basic-auth/testuser/testpass")

      assert response(conn, 401) == "Unauthorized"
      assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"HTTPlex\""]
    end

    test "GET /basic-auth/:user/:passwd - wrong credentials", %{conn: conn} do
      auth = Base.encode64("wronguser:wrongpass")

      conn =
        conn
        |> put_req_header("authorization", "Basic #{auth}")
        |> get(~p"/basic-auth/testuser/testpass")

      assert response(conn, 401) == "Unauthorized"
    end
  end

  describe "Caching" do
    test "GET /cache - returns 304 with If-None-Match header", %{conn: conn} do
      conn = get(conn, ~p"/cache")
      etag = Enum.at(get_resp_header(conn, "etag"), 0)

      conn =
        conn
        |> recycle()
        |> put_req_header("if-none-match", etag)
        |> get(~p"/cache")

      assert response(conn, 304) == ""
    end

    test "GET /cache - returns 304 with If-Modified-Since header", %{conn: conn} do
      conn = get(conn, ~p"/cache")
      last_modified = Enum.at(get_resp_header(conn, "last-modified"), 0)

      conn =
        conn
        |> recycle()
        |> put_req_header("if-modified-since", last_modified)
        |> get(~p"/cache")

      assert response(conn, 304) == ""
    end

    test "GET /cache/:value - sets Cache-Control header", %{conn: conn} do
      conn = get(conn, ~p"/cache/60")

      assert Enum.at(get_resp_header(conn, "cache-control"), 0) == "public, max-age=60"
      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "GET /etag/:etag - returns 304 with matching If-None-Match", %{conn: conn} do
      conn =
        conn
        |> put_req_header("if-none-match", "test-etag")
        |> get(~p"/etag/test-etag")

      assert response(conn, 304) == ""
    end

    test "GET /etag/:etag - returns 412 with non-matching If-Match", %{conn: conn} do
      conn =
        conn
        |> put_req_header("if-match", "wrong-etag")
        |> get(~p"/etag/test-etag")

      assert response(conn, 412) == "Precondition Failed"
    end
  end

  describe "Response Headers" do
    test "GET /response-headers - sets custom headers", %{conn: conn} do
      conn = get(conn, ~p"/response-headers?x-custom-header=test-value")

      assert Enum.at(get_resp_header(conn, "x-custom-header"), 0) == "test-value"
      assert json_response(conn, 200) == %{"x-custom-header" => "test-value"}
    end

    test "POST /response-headers - sets custom headers", %{conn: conn} do
      conn = post(conn, ~p"/response-headers?x-custom-header=test-value")

      assert Enum.at(get_resp_header(conn, "x-custom-header"), 0) == "test-value"
      assert json_response(conn, 200) == %{"x-custom-header" => "test-value"}
    end
  end

  describe "Encoding" do
    test "GET /brotli returns Brotli-encoded data", %{conn: conn} do
      conn = get(conn, ~p"/brotli")
      assert get_resp_header(conn, "content-encoding") == ["br"]
      {:ok, expected_data} = :brotli.encode("This content is Brotli-encoded.")
      assert response(conn, 200) == expected_data
    end

    test "GET /deflate returns Deflate-encoded data", %{conn: conn} do
      conn = get(conn, ~p"/deflate")
      assert get_resp_header(conn, "content-encoding") == ["deflate"]
      assert response(conn, 200) == :zlib.compress("This content is Deflate-encoded.")
    end

    test "GET /encoding/utf8 returns UTF-8 encoded data", %{conn: conn} do
      conn = get(conn, ~p"/encoding/utf8")
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert response(conn, 200) == "नमस्ते दुनिया"
    end

    test "GET /gzip returns GZip-encoded data", %{conn: conn} do
      conn = get(conn, ~p"/gzip")
      assert get_resp_header(conn, "content-encoding") == ["gzip"]
      assert response(conn, 200) == :zlib.gzip("This content is GZip-encoded.")
    end
  end

  describe "Response inspection" do
    test "GET /deny returns denied message", %{conn: conn} do
      conn = get(conn, ~p"/deny")
      assert response(conn, 200) == "You've been denied access by robots.txt."
    end

    test "GET /robots.txt returns robots.txt content", %{conn: conn} do
      conn = get(conn, ~p"/robots.txt")
      expected_content = """
      # See https://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
      #
      # To ban all spiders from the entire site uncomment the next two lines:
      # User-agent: *
      # Disallow: /
      """
      assert String.trim(response(conn, 200)) == String.trim(expected_content)
    end
  end

end
