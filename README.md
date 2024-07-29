# HTTPlex - test and debug HTTP requests

HTTPlex is an Elixir-based web service that provides a simple HTTP request and response service. It is inspired from [httpbin](https://httpbin.org/) and helps developers test and debug HTTP requests.

## Features

The project is built using Elixir and the Phoenix framework. It defines a controller (`HTTPlexWeb.APIController`) that handles various HTTP endpoints. Each function in the controller corresponds to a different feature:

- `index/2`: Welcomes users to HTTPlex.
- `ip/2`: Retrieves and returns the client's IP address.
- `user_agent/2`: Extracts and returns the User-Agent header.
- `headers/2`: Collects and returns all request headers.
- `get/2`, `post/2`, `put/2`, `patch/2`, `delete/2`: Handles different HTTP methods and returns comprehensive request information.
- `status/2`: Responds with a custom status code.
- `delay/2`: Introduces a specified delay before responding.
- `base64/2`: Decodes Base64 URL-encoded strings.
- `bytes/2`: Generates random bytes.
- `cookies/2`: Returns the cookies sent with the request.
- `cookies_set/2`: Sets a cookie with the provided name and value.
- `image/2`: Returns an image in the specified format (`png`, `jpeg`, `webp`, `svg`).
- `json/2`: Returns a sample JSON document.
- `xml/2`: Returns a sample XML document.
- `forms_post/2`: Returns form data sent in a POST request.
- `redirect/2`: Redirects to a different URL `n` times.
- `stream/2`: Streams data incrementally `n` times.

The `request_info/1` helper function collects detailed information about the request, including method, URL, headers, parameters, and body data.

## Usage

To use HTTPlex, send HTTP requests to the appropriate endpoints. The service will respond with JSON data (in most cases) containing the requested information or performing the specified action.

For example:
- `GET /ip` will return your IP address.
- `POST /post` with some data will echo back information about your POST request.
- `GET /status/404` will respond with a 404 status code.

This service is particularly useful for testing HTTP clients, debugging web applications, and understanding how different types of HTTP requests are structured and processed.

## Running it

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## License

The theme is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abhinavs/httplex.

## Other Projects

If you like HTTPlex, do check out my other projects
*   [soopr](https://www.soopr.co) - a tool that supports you in content marketing
*   [ping](https://www.apicblocks.com/ping) - monitor your websites's uptime
*   [annexr](https://www.annexr.com) - chat based search for your website.
*   [apicagent](https://www.apicagent.com) - a FREE API that extracts device details from user-agent string


✨⚡You can read more about me on my [blog](https://www.abhinav.co/about/) or follow me on Twitter - [@abhinav](https://twitter.com/abhinav)
