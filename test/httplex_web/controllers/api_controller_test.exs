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

  describe "Status and delay" do
    test "GET /status/:code", %{conn: conn} do
      conn = get(conn, ~p"/status/418")
      assert response(conn, 418) == ""
    end

    test "GET /delay/:n", %{conn: conn} do
      start_time = System.monotonic_time(:millisecond)
      conn = get(conn, ~p"/delay/1")
      end_time = System.monotonic_time(:millisecond)

      assert json_response(conn, 200) == %{"delay" => 1}
      assert end_time - start_time >= 1000
    end
  end

  describe "Encoding and bytes" do
    test "GET /base64/:value", %{conn: conn} do
      encoded = Base.url_encode64("Hello, World!")
      conn = get(conn, ~p"/base64/#{encoded}")
      assert text_response(conn, 200) == "Hello, World!"
    end

    test "GET /bytes/:n", %{conn: conn} do
      conn = get(conn, ~p"/bytes/10")
      assert byte_size(response(conn, 200)) == 10
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
      for format <- ["png", "jpeg", "webp", "svg"] do
        conn = get(conn, ~p"/image/#{format}")
        assert get_resp_header(conn, "content-type") == ["image/#{format}; charset=utf-8"]
      end
    end
  end

  describe "Response formats" do
    test "GET /json", %{conn: conn} do
      conn = get(conn, ~p"/json")
      assert %{"project" => _} = json_response(conn, 200)
    end

    test "GET /xml", %{conn: conn} do
      conn = get(conn, ~p"/xml")
      assert response_content_type(conn, :xml)
      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
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

  describe "Streaming" do
    test "GET /stream/:n", %{conn: conn} do
      conn = get(conn, ~p"/stream/3")
      assert response_content_type(conn, :json)
      # {:ok, _} = Plug.Conn.sent_resp(conn)
      # assert conn.state == :chunked
      assert response_content_type(conn, :json)
      assert json_response(conn, 200) == [3, 2, 1]
    end
  end

  describe "Catch-all route" do
    test "GET /*anything", %{conn: conn} do
      conn = get(conn, ~p"/anything/test")
      response = json_response(conn, 200)
      assert response["method"] == "GET"
      assert is_map(response["headers"])
      assert is_map(response["body"])
      assert is_map(response["query"])
      assert String.contains?(response["url"], "/anything/test")
    end
  end
end
