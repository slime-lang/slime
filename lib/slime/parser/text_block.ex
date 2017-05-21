defmodule Slime.Parser.TextBlock do
  @moduledoc "
  Utilities for parsing text blocks.
  "

  import Slime.Parser.Transform, only: [wrap_in_quotes: 1]

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
  def render(lines, declaration_indent, trailing_whitespace \\ "") do
    lines = case lines do
      [{_, "", _} | rest] -> rest
      [{relative_indent, first_line, is_eex} | rest] ->
        first_line_indent = relative_indent + declaration_indent
        [{first_line_indent, first_line, is_eex} | rest]
    end

    text_indent = Enum.find_value(lines, 0,
      fn({indent, line, _}) -> line != "" && indent end)

    {text, is_eex} = insert_line_spacing(lines, text_indent)

    text = text <> trailing_whitespace

    if is_eex do
      {:eex, content: wrap_in_quotes(text), inline: true}
    else
      text
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
end
