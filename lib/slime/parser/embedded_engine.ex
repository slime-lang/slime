defmodule Slime.Parser.EmbeddedEngine do
  @moduledoc """
  Embedded engine behaviour module.
  Provides basic logic of parsing slime with embedded parts for other engines.
  """
  @type parser_tag :: binary | {:eex | binary, Keyword.t}
  @callback render(binary, Keyword.t) :: parser_tag

  @embedded_engine_regex ~r/^(?<indent>\s*)(?<engine>\w+):$/
  @empty_line_regex ~r/^\s*$/

  @engines %{
    javascript: Slime.Parser.EmbeddedEngine.Javascript,
    css: Slime.Parser.EmbeddedEngine.Css,
    elixir: Slime.Parser.EmbeddedEngine.Elixir,
    eex: Slime.Parser.EmbeddedEngine.EEx
  }
  |> Map.merge(Application.get_env(:slime, :embedded_engines, %{}))
  |> Enum.into(%{}, fn ({key, value}) -> {to_string(key), value} end)
  @registered_engines Map.keys(@engines)

  def parse(header, lines) do
    case Regex.named_captures(@embedded_engine_regex, header) do
      %{"engine" => engine, "indent" => indent} when engine in @registered_engines ->
        indent = String.length(indent)
        {embedded_lines, rest} = split_lines(lines, indent)
        {{indent, render_with_engine(engine, embedded_lines)}, rest}
      _ -> nil
    end
  end

  defp render_with_engine(engine, lines) when is_list(lines) do
    embedded_text = case lines do
      [] -> ""
      [line | _] ->
        strip_indent = indent(line)
        lines
        |> Enum.map(&strip_line(&1, strip_indent))
        |> Enum.join("\n")
    end

    render_with_engine(engine, embedded_text)
  end

  defp render_with_engine(engine, embedded_text) do
    keep_lines = Application.get_env(:slime, :keep_lines)
    embedded_text = if keep_lines do
      "\n" <> embedded_text
    else
      embedded_text
    end
    apply(@engines[engine], :render, [embedded_text, [keep_lines: keep_lines]])
  end

  defp split_lines(lines, indent_size) do
    Enum.split_while(lines, fn (line) ->
      line =~ @empty_line_regex || indent_size < indent(line)
    end)
  end

  defp indent(line) do
    String.length(line) - String.length(String.lstrip(line))
  end

  defp strip_line(line, strip_indent) do
    String.slice(line, min(strip_indent, indent(line))..-1)
  end
end

defmodule Slime.Parser.EmbeddedEngine.Javascript do
  @moduledoc """
  Javascript engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine
  import Slime.Parser, only: [parse_eex_string: 1]

  def render(text, _options) do
    {"script", children: [parse_eex_string(text)]}
  end
end

defmodule Slime.Parser.EmbeddedEngine.Css do
  @moduledoc """
  CSS engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine
  import Slime.Parser, only: [parse_eex_string: 1]

  def render(text, _options) do
    {"style", attributes: [type: "text/css"], children: [parse_eex_string(text)]}
  end
end

defmodule Slime.Parser.EmbeddedEngine.Elixir do
  @moduledoc """
  Elixir code engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  def render(text, options) do
    children = if options[:keep_lines] do
      text |> String.split("\n") |> Enum.map(fn(_) -> "" end)
    else
      []
    end
    {:eex, content: text, inline: false, children: children}
  end
end

defmodule Slime.Parser.EmbeddedEngine.EEx do
  @moduledoc """
  EEx engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  def render(text, _options) do
    text
  end
end
