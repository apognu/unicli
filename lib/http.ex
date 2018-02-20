defmodule UniCLI.HTTP do
  use Tesla

  plug(Tesla.Middleware.JSON)

  defp login(settings) do
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

        {:ok, cookies}

      {:ok, _} ->
        {:error, "invalid credentials"}

      {:error, e} ->
        {:error, "could not connect: #{to_string(e)}"}
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
