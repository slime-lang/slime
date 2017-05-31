defmodule Slime.Parser.EmbeddedEngine do
  @moduledoc """
  Embedded engine behaviour module.
  Provides basic logic of parsing slime with embedded parts for other engines.
  """
  @type parser_tag :: binary | {:eex | binary, Keyword.t}
  @callback render(binary, Keyword.t) :: parser_tag

  import Slime.Compiler, only: [compile: 1]

  @engines %{
    javascript: Slime.Parser.EmbeddedEngine.Javascript,
    css: Slime.Parser.EmbeddedEngine.Css,
    elixir: Slime.Parser.EmbeddedEngine.Elixir,
    eex: Slime.Parser.EmbeddedEngine.EEx
  }
  |> Map.merge(Application.get_env(:slime, :embedded_engines, %{}))
  |> Enum.into(%{}, fn ({key, value}) -> {to_string(key), value} end)

  def render_with_engine(engine, line_contents) when is_list(line_contents) do
    lines = Enum.map(line_contents, &compile/1)
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

  def render_with_engine(engine, embedded_text) do
    keep_lines = Application.get_env(:slime, :keep_lines)
    embedded_text = if keep_lines do
      "\n" <> embedded_text
    else
      embedded_text
    end
    apply(@engines[engine], :render, [embedded_text, [keep_lines: keep_lines]])
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

  def render(text, _options), do: {"script", children: [text]}
end

defmodule Slime.Parser.EmbeddedEngine.Css do
  @moduledoc """
  CSS engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  def render(text, _options) do
    {"style", attributes: [type: "text/css"], children: [text]}
  end
end

defmodule Slime.Parser.EmbeddedEngine.Elixir do
  @moduledoc """
  Elixir code engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  alias Slime.Parser.Nodes.EExNode

  def render(text, options) do
    newlines = if options[:keep_lines] do
      count = text |> String.split("\n") |> length |> Kernel.-(1)
      [String.duplicate("\n", count)]
    else
      []
    end

    %EExNode{content: text, children: newlines}
  end
end

defmodule Slime.Parser.EmbeddedEngine.EEx do
  @moduledoc """
  EEx engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  def render(text, _options), do: text
end
