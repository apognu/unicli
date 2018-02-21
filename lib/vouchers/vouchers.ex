defmodule UniCLI.Vouchers do
  @list_headers [
    "ID",
    "Code",
    "Validity",
    "Usable",
    "Down",
    "Up",
    "Quota",
    "Note"
  ]

  def run(settings, subcommands, options) do
    case subcommands do
      [:list] -> list(settings, options)
      [:create] -> create(settings, options)
      [:revoke] -> revoke(settings, options)
    end
  end

  def list(settings, _) do
    case UniCLI.HTTP.request(settings, :get, "/stat/voucher") do
      {:ok, %{"data" => vouchers}} ->
        vouchers
        |> Enum.map(fn voucher ->
          duration =
            Timex.Duration.from_minutes(voucher["duration"])
            |> Timex.format_duration(UniCLI.DurationFormatter)

          [
            voucher["_id"],
            voucher["code"],
            duration,
            quota(voucher["used"], voucher["quota"]),
            if(
              voucher["qos_rate_max_down"],
              do:
                "#{Size.humanize!(round(voucher["qos_rate_max_down"] / 8) * 1000, bits: true)}ps",
              else: "-"
            ),
            if(
              voucher["qos_rate_max_up"],
              do: "#{Size.humanize!(round(voucher["qos_rate_max_up"] / 8) * 1000, bits: true)}ps",
              else: "-"
            ),
            if(
              voucher["qos_usage_quota"],
              do: Size.humanize!(voucher["qos_usage_quota"] * 1024 * 1024),
              else: "-"
            ),
            voucher["note"]
          ]
        end)
        |> UniCLI.Util.tableize(@list_headers)

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end

  def create(settings, %Optimus.ParseResult{options: options}) do
    %{
      number: number,
      comment: comment,
      usage: usage,
      validity: validity,
      quota: quota,
      quota_download: quota_download,
      quota_upload: quota_upload
    } = options

    payload = %{
      "cmd" => "create-voucher",
      "n" => number,
      "note" => comment,
      "quota" => usage,
      "expire" => validity
    }

    payload = if quota_download > 0, do: Map.put(payload, "down", quota_download), else: payload
    payload = if quota_upload > 0, do: Map.put(payload, "up", quota_upload), else: payload
    payload = if quota > 0, do: Map.put(payload, "bytes", quota), else: payload

    case UniCLI.HTTP.request(settings, :post, "/cmd/hotspot", payload) do
      {:ok, _} ->
        IO.puts("Voucher was created.")

      {:error, error} ->
        IO.puts("ERROR: could not create voucher: #{error}")
    end
  end

  def revoke(settings, %Optimus.ParseResult{args: %{id: id}}) do
    case UniCLI.HTTP.request(settings, :post, "/cmd/hotspot", %{
           "cmd" => "delete-voucher",
           "_id" => id
         }) do
      {:ok, _} ->
        IO.puts("Voucher '#{id}' was revoked.")

      {:error, error} ->
        IO.puts("ERROR: could not revoke voucher: #{error}")
    end
  end

  defp quota(current, max) do
    case max do
      0 -> "∞"
      _ -> "#{current}/#{max}"
    end
  end
end
