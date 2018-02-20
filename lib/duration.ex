defmodule UniCLI.DurationFormatter do
  use Timex.Format.Duration.Formatter
  alias Timex.Translator

  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @month @day * 30
  @year @day * 365

  @microsecond 1_000_000

  def format(%Duration{} = duration), do: lformat(duration, Translator.default_locale())
  def format(_), do: {:error, :invalid_duration}

  def lformat(%Duration{} = duration, locale) do
    duration
    |> deconstruct
    |> do_format(locale)
  end

  def lformat(_, _locale), do: {:error, :invalid_duration}

  defp do_format(components, locale), do: do_format(components, <<>>, locale)
  defp do_format([], str, _locale), do: str

  defp do_format([{:s, _} | rest], str, locale), do: do_format(rest, str, locale)

  defp do_format([{unit, value} | rest], str, locale) do
    unit = Atom.to_string(unit)

    unit_with_value =
      Translator.translate_plural(locale, "units", "%{count}#{unit}", "%{count}#{unit}", value)

    case str do
      <<>> -> do_format(rest, "#{unit_with_value}", locale)
      _ -> do_format(rest, str <> " #{unit_with_value}", locale)
    end
  end

  defp deconstruct(duration) do
    micros = Duration.to_microseconds(duration) |> abs
    deconstruct({div(micros, @microsecond), rem(micros, @microsecond)}, [])
  end

  defp deconstruct({0, 0}, []), do: deconstruct({0, 0}, microsecond: 0)
  defp deconstruct({0, 0}, components), do: Enum.reverse(components)

  defp deconstruct({seconds, us}, components) when seconds > 0 do
    cond do
      seconds >= @year ->
        deconstruct({rem(seconds, @year), us}, [{:y, div(seconds, @year)} | components])

      seconds >= @month ->
        deconstruct({rem(seconds, @month), us}, [{:mo, div(seconds, @month)} | components])

      seconds >= @day ->
        deconstruct({rem(seconds, @day), us}, [{:d, div(seconds, @day)} | components])

      seconds >= @hour ->
        deconstruct({rem(seconds, @hour), us}, [{:h, div(seconds, @hour)} | components])

      seconds >= @minute ->
        deconstruct({rem(seconds, @minute), us}, [{:m, div(seconds, @minute)} | components])

      true ->
        deconstruct({0, us}, [{:s, seconds} | components])
    end
  end

  defp deconstruct({0, micro}, components) do
    millis =
      micro
      |> Duration.from_microseconds()
      |> Duration.to_milliseconds()

    cond do
      millis >= 1 -> deconstruct({0, 0}, [{:millisecond, millis} | components])
      true -> deconstruct({0, 0}, [{:microsecond, micro} | components])
    end
  end
end
