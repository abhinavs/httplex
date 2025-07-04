# HTTPlex - a simple HTTP request & response service

HTTPlex is an Elixir-based web service that provides a simple HTTP request and response service. It is inspired from [httpbin](https://httpbin.org/) and helps developers test and debug HTTP requests.

## Features

The project is built using Elixir and the Phoenix framework. It defines a controller (`HTTPlexWeb.APIController`) that handles various HTTP endpoints:

HTTP Methods:

- `index/2`: Welcome message
- `get/2`, `post/2`, `put/2`, `patch/2`, `delete/2`: Return request info for respective HTTP methods
- `anything/2`: Accepts and returns data for any HTTP method

Request Inspection:

- `ip/2`: Returns the client's IP address
- `user_agent/2`: Returns the user-agent header
- `headers/2`: Returns all request headers

Response Inspection:

- `response_headers/2`: Sets custom response headers

Auth:

- `basic_auth/2`, `hidden_basic_auth/2`: Test Basic Authentication (hidden version doesn't send WWW-Authenticate header)
- `bearer/2`: Tests Bearer Token Authentication
- `digest_auth/2`: Tests Digest Authentication

Status codes:

- `status/2`: Returns response with specified status code

Request formats:

- `forms_post/2`: Handles form data submission

Response formats:

- `html_response/2`: Returns an HTML response
- `json_response/2`: Returns a JSON response
- `xml/2`: Returns an XML response
- `image/2`: Returns an image in specified format

Redirects:

- `absolute_redirect/2`: Performs absolute redirects
- `redirect_to/2`: Redirects to specified URL
- `redirectx/2`: Performs multiple redirects
- `relative_redirect/2`: Performs relative redirects

Dynamic data:

- `uuid/2`: Generates and returns a UUID
- `random_bytes/2`: Returns random bytes
- `deny/2`: Simulates denied access by robots.txt
- `robots_txt/2`: Returns a sample robots.txt file
- `delay/2`: Delays the response for specified seconds
- `drip/2`: Drips data over a duration
- `links/2`: Returns page containing n links
- `range/2`: Streams n bytes with Accept-Ranges and Content-Range headers
- `stream_bytes/2`: Streams n bytes of data
- `stream_json/2`: Streams JSON data

Cookies:

- `get_cookies/2`: Returns all cookies sent with the request
- `set_cookies/2`, `set_cookie/2`: Set multiple or a single cookie
- `delete_cookies/2`: Deletes specified cookies

Encoding:

- `brotli/2`: Returns Brotli-encoded data
- `deflate/2`: Returns Deflate-encoded data
- `gzip/2`: Returns GZip-encoded data
- `encoding_utf8/2`: Returns UTF-8 encoded text

Caching:

- `cache/2`: Tests caching headers
- `cache_control/2`: Sets Cache-Control header with specified max-age
- `etag/2`: Tests ETag functionality

Each function or group of functions corresponds to different features or test scenarios for HTTP requests and responses.

## Usage

To use HTTPlex, send HTTP requests to the appropriate endpoints. The service will respond with JSON data (in most cases) containing the requested information or performing the specified action.

For example:

- `GET /ip` will return your IP address.
- `POST /post` with some data will echo back information about your POST request.
- `GET /status/404` will respond with a 404 status code.

This service is particularly useful for testing HTTP clients, debugging web applications, and understanding how different types of HTTP requests are structured and processed.

## Running it

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## License

The theme is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/abhinavs/httplex>.

## Other Projects

If you like HTTPlex, do check out my other projects

- [soopr](https://www.soopr.co) - a tool that supports you in content marketing
- [ping](https://www.apicblocks.com/ping) - monitor your websites's uptime
- [annexr](https://www.annexr.com) - chat based search for your website.
- [apicagent](https://www.apicagent.com) - a FREE API that extracts device details from user-agent string
- [cookie](https://github.com/abhinavs/cookie) - an open source landing website with supporting pages and integrated blog

✨⚡You can read more about me on my [blog](https://www.abhinav.co/about/) or follow me on Twitter - [@abhinav](https://x.com/abhinav)

Updated: 8 Feb 2026
