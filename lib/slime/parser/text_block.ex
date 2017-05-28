defmodule Slime.Parser.TextBlock do
  @moduledoc "
  Utilities for parsing text blocks.
  "

  import Slime.Parser.Transform, only: [wrap_in_quotes: 1]
  alias Slime.Parser.Nodes.EExNode

  @doc """
  Given a text block and its declaration indentation level (see below),
  produces a string (or a dynamic EEx tuple) that can be inserted into the tree.

  nested
    | Text block
       that spans over multiple lines
  ---
   ^
  declaration indent
  """
  def render_content(lines, declaration_indent) do
    lines = case lines do
      [{_, "", _} | rest] -> rest
      [{relative_indent, first_line, is_eex} | rest] ->
        first_line_indent = relative_indent + declaration_indent
        [{first_line_indent, first_line, is_eex} | rest]
    end

    text_indent = Enum.find_value(lines, 0,
      fn({indent, line, _}) -> line != "" && indent end)

    lines
    |> insert_line_spacing(text_indent)
    |> wrap_text
  end

  @doc """
  Given a text block, returns the text without indentation.
  """
  def render_without_indentation(lines) do
    lines
    |> skip_line_spacing
    |> wrap_text
  end

  defp wrap_text({text, is_eex}) do
    if is_eex do
      [%EExNode{content: wrap_in_quotes(text), output: true}]
    else
      [text]
    end
  end

  defp insert_line_spacing(lines, text_indent) do
    lines |> Enum.reduce({"", false},
      fn ({line_indent, line, is_eex_line}, {text, is_eex}) ->
        text = if text == "", do: text, else: text <> "\n"
        leading_space = String.duplicate(" ", line_indent - text_indent)
        {text <> leading_space <> line, is_eex || is_eex_line}
      end)
  end

  defp skip_line_spacing(lines) do
    lines |> Enum.reduce({"", false},
      fn ({_, line, is_eex_line}, {text, is_eex}) ->
        text = if text == "", do: text, else: text <> "\n"
        {text <> line, is_eex || is_eex_line}
      end)
  end
end
