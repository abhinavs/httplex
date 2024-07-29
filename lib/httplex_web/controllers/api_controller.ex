defmodule HTTPlexWeb.APIController do
  use HTTPlexWeb, :controller

  def index(conn, _params) do
    json(conn, %{message: "Welcome to HTTP Plex!"})
  end

  def ip(conn, _params) do
    json(conn, %{origin: to_string(:inet.ntoa(conn.remote_ip))})
  end

  def user_agent(conn, _params) do
    user_agent = get_req_header(conn, "user-agent") |> List.first()
    json(conn, %{"user-agent": user_agent})
  end

  def headers(conn, _params) do
    json(conn, %{headers: Map.new(conn.req_headers)})
  end

  def get(conn, _params) do
    json(conn, request_info(conn))
  end

  def post(conn, _params) do
    json(conn, request_info(conn))
  end

  def put(conn, _params) do
    json(conn, request_info(conn))
  end

  def patch(conn, _params) do
    json(conn, request_info(conn))
  end

  def delete(conn, _params) do
    json(conn, request_info(conn))
  end

  def status(conn, %{"code" => code}) do
    code = String.to_integer(code)
    send_resp(conn, code, "")
  end

  def delay(conn, %{"n" => n}) do
    seconds = String.to_integer(n)
    :timer.sleep(seconds * 1000)
    json(conn, %{delay: seconds})
  end

  def decode_base64(conn, %{"value" => value}) do
    case Base.url_decode64(value) do
      {:ok, decoded} -> text(conn, decoded)
      :error -> text(conn, "Invalid Base64 data")
    end
  end

  def random_bytes(conn, %{"n" => n}) do
    # 100KB limit
    n = String.to_integer(n) |> min(100 * 1024)
    data = :crypto.strong_rand_bytes(n)

    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, data)
  end

  def cookies(conn, _params) do
    cookies = conn.req_cookies
    json(conn, cookies)
  end

  def set_cookies(conn, %{"name" => name, "value" => value}) do
    conn
    |> put_resp_cookie(name, value)
    |> json(%{message: "Cookie set!"})
  end

  def image(conn, %{"format" => format}) do
    image_path =
      case format do
        "png" -> "priv/static/images/sample.png"
        "jpeg" -> "priv/static/images/sample.jpeg"
        "webp" -> "priv/static/images/sample.webp"
        "svg" -> "priv/static/images/sample.svg"
        _ -> "priv/static/images/sample.png"
      end

    conn
    |> put_resp_content_type("image/#{format}")
    |> send_file(200, image_path)
  end

  def image(conn, _params) do
    conn
    |> put_resp_content_type("image/png")
    |> send_file(200, "priv/static/images/sample.png")
  end

  def json_response(conn, _params) do
    json(conn, %{
      project: %{
        name: "Example Project",
        description: "This is an example project JSON structure",
        created_at: "2024-07-28",
        team: [
          %{
            name: "Alice",
            role: "Project Manager",
            contact: "alice@example.com"
          },
          %{
            name: "Bob",
            role: "Lead Developer",
            contact: "bob@example.com"
          },
          %{
            name: "Charlie",
            role: "Designer",
            contact: "charlie@example.com"
          }
        ],
        tasks: [
          %{
            title: "Initial Planning",
            status: "Completed",
            due_date: "2024-06-15"
          },
          %{
            title: "Development",
            status: "In Progress",
            due_date: "2024-08-01",
            subtasks: [
              %{title: "Set up project repository", status: "Completed"},
              %{title: "Implement authentication", status: "In Progress"},
              %{title: "Create API endpoints", status: "Pending"}
            ]
          },
          %{
            title: "Design",
            status: "Pending",
            due_date: "2024-08-10",
            notes: "Coordinate with Charlie for the design assets"
          }
        ]
      }
    })
  end

  def xml_response(conn, _params) do
    xml_data = """
    <?xml version="1.0" encoding="UTF-8" ?>
    <project>
      <name>Example Project</name>
      <description>This is an example project XML structure</description>
      <created_at>2024-07-28</created_at>
      <team>
        <member>
          <name>Alice</name>
          <role>Project Manager</role>
          <contact>alice@example.com</contact>
        </member>
        <member>
          <name>Bob</name>
          <role>Lead Developer</role>
          <contact>bob@example.com</contact>
        </member>
        <member>
          <name>Charlie</name>
          <role>Designer</role>
          <contact>charlie@example.com</contact>
        </member>
      </team>
      <tasks>
        <task>
          <title>Initial Planning</title>
          <status>Completed</status>
          <due_date>2024-06-15</due_date>
        </task>
        <task>
          <title>Development</title>
          <status>In Progress</status>
          <due_date>2024-08-01</due_date>
          <subtasks>
            <subtask>
              <title>Set up project repository</title>
              <status>Completed</status>
            </subtask>
            <subtask>
              <title>Implement authentication</title>
              <status>In Progress</status>
            </subtask>
            <subtask>
              <title>Create API endpoints</title>
              <status>Pending</status>
            </subtask>
          </subtasks>
        </task>
        <task>
          <title>Design</title>
          <status>Pending</status>
          <due_date>2024-08-10</due_date>
          <notes>Coordinate with Charlie for the design assets</notes>
        </task>
      </tasks>
    </project>
    """

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml_data)
  end

  def forms_post(conn, _params) do
    json(conn, conn.body_params)
  end

  def redirectx(conn, %{"n" => n}) do
    n = String.to_integer(n)

    if n > 0 do
      redirect(conn, external: "https://httplex.com/redirect/#{n - 1}")
    else
      json(conn, %{message: "Reached final redirect", n: n})
    end
  end

  def stream(conn, %{"n" => n}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_chunked(200)
    |> stream_data(String.to_integer(n))
  end

  defp stream_data(conn, 0), do: conn

  defp stream_data(conn, n) do
    :timer.sleep(1000)
    chunk(conn, "#{n}\n")
    stream_data(conn, n - 1)
  end

  def anything(conn, _params) do
    json(conn, %{
      method: conn.method,
      headers: Enum.into(conn.req_headers, %{}),
      query: conn.query_params,
      body: conn.body_params
    })
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
      origin: to_string(:inet.ntoa(conn.remote_ip))
    }
  end

  defp custom_read_body(conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, _conn} -> body
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
    scheme = conn.scheme
    host = conn.host
    port = conn.port
    request_path = conn.request_path
    query_string = conn.query_string

    url = "#{scheme}://#{host}"

    url =
      if (scheme == :https and port != 443) or (scheme == :http and port != 80) do
        "#{url}:#{port}"
      else
        url
      end

    url = "#{url}#{request_path}"
    if query_string != "", do: "#{url}?#{query_string}", else: url
  end
end
