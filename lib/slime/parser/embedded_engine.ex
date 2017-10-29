defmodule Slime.Parser.EmbeddedEngine do
  @moduledoc """
  Embedded engine behaviour module.
  Provides basic logic of parsing slime with embedded parts for other engines.
  """
  alias Slime.Parser.Nodes.EExNode

  @type parser_tag :: binary | {binary, Keyword.t} | %EExNode{}
  @type engine_input :: [binary | {:eex, binary}]
  @callback render(engine_input, Keyword.t) :: parser_tag

  import Slime.Parser.TextBlock, only: [render_content: 2]

  @engines %{
    javascript: Slime.Parser.EmbeddedEngine.Javascript,
    css: Slime.Parser.EmbeddedEngine.Css,
    elixir: Slime.Parser.EmbeddedEngine.Elixir,
    eex: Slime.Parser.EmbeddedEngine.EEx
  }
  |> Map.merge(Application.get_env(:slime, :embedded_engines, %{}))
  |> Enum.into(%{}, fn ({key, value}) -> {to_string(key), value} end)
  @registered_engines Map.keys(@engines)

  def parse(engine, lines) when engine in @registered_engines do
    # NOTE: Add an empty line to keep spaces consistent with verbatim text case
    embedded_text = render_content([{0, []} | lines], 0)

    {:ok, render_with_engine(engine, embedded_text)}
  end
  def parse(engine, _) do
    {:error, ~s(Unknown embedded engine "#{engine}")}
  end

  defp render_with_engine(engine, text) do
    keep_lines = Application.get_env(:slime, :keep_lines)
    text = if keep_lines, do: ["\n" | text], else: text

    apply(@engines[engine], :render, [text, [keep_lines: keep_lines]])
  end
end

defmodule Slime.Parser.EmbeddedEngine.Javascript do
  @moduledoc """
  Javascript engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  def render(text, _options), do: {"script", children: text}
end

defmodule Slime.Parser.EmbeddedEngine.Css do
  @moduledoc """
  CSS engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  def render(text, _options) do
    {"style", attributes: [type: "text/css"], children: text}
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
      count = Enum.count(text, &Kernel.==(&1, "\n"))
      [String.duplicate("\n", count)]
    else
      []
    end

    eex = Enum.map_join(text, fn
      ({:eex, interpolation}) -> ~S"#{" <> interpolation <> "}"
      (text) -> text
    end)

    %EExNode{content: eex, children: newlines}
  end
end

defmodule Slime.Parser.EmbeddedEngine.EEx do
  @moduledoc """
  EEx engine callback module
  """

  @behaviour Slime.Parser.EmbeddedEngine

  def render(text, _options), do: text
end
