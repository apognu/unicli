defmodule UniCLI.HTTP do
  use Tesla

  plug(Tesla.Middleware.JSON)

  # Fetch a cookie to authenticate against the controller
  # :refresh uses cached cookies in ~/.unifi/cookies.json
  # :renew logs in again with credentials in environment variables
  defp login(settings, action \\ :refresh) do
    cookies_file = "#{settings.directory}/cookies.json"

    # If the cache file exists
    if settings.directory && action == :refresh && File.exists?(cookies_file) do
      with {:ok, file} <- File.read(cookies_file),
           {:ok, data} <- Poison.decode(file),
           cookies <- Enum.map(data, fn cookie -> {"cookie", cookie} end) do
        check_login(settings, cookies)
      else
        # If we cannot read the cache file, log in again
        _ ->
          login(settings, :renew)
      end
    else
      response =
        post(settings.host <> "/api/login", %{
          "username" => settings.username,
          "password" => settings.password
        })

      case response do
        {:ok, %Tesla.Env{status: 200, headers: _} = env} ->
          cookies =
            Tesla.get_headers(env, "set-cookie")
            |> Enum.map(fn cookie -> {"cookie", cookie} end)

          # Write cache file for future :refresh
          if settings.directory do
            data = Enum.map(cookies, fn {_, cookie} -> cookie end)

            File.write(cookies_file, Poison.encode!(data))
          end

          {:ok, cookies}

        {:ok, _} ->
          {:error, "invalid credentials"}

        {:error, e} ->
          {:error, "could not connect: #{to_string(e)}"}
      end
    end
  end

  defp check_login(settings, cookies) do
    # On refresh, check if refresh was successful
    with {:ok, %Tesla.Env{status: 200}} <- get(settings.host <> "/api/self", headers: cookies) do
      {:ok, cookies}
    else
      # If the cookie is invalid, log in again
      _ ->
        login(settings, :renew)
    end
  end

  def request(settings, method, url, body \\ %{})

  def request(settings, :get, url, _body) do
    with {:ok, cookies} <- login(settings),
         {:ok, %Tesla.Env{status: 200, body: body}} <-
           get(settings.host <> "/api/s/default" <> url, headers: cookies) do
      {:ok, body}
    else
      {:error, error} -> {:error, error}
    end
  end

  def request(settings, :post, url, body) do
    with {:ok, cookies} <- login(settings),
         {:ok, %Tesla.Env{status: 200, body: body}} <-
           post(settings.host <> "/api/s/default" <> url, body, headers: cookies) do
      {:ok, body}
    else
      [:error, error] ->
        {:error, error}
    end
  end

  def request(settings, :put, url, body) do
    with {:ok, cookies} <- login(settings),
         {:ok, %Tesla.Env{status: 200, body: body}} <-
           put(settings.host <> "/api/s/default" <> url, body, headers: cookies) do
      {:ok, body}
    else
      [:error, error] ->
        {:error, error}
    end
  end
end
