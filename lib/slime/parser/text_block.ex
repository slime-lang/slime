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
  def render(lines, decl_indent, trailing_whitespace \\ "") do
    [{first_line_indent, first_line, is_eex_line} | rest] = lines

    text_indent = if first_line == "" do
      [{indent, _, _} | _] = rest
      indent
    else
      decl_indent + first_line_indent
    end

    content = [{text_indent, first_line, is_eex_line} | rest]

    {text, is_eex} = Enum.reduce(content, {"", false},
      fn ({line_indent, line, is_eex_line}, {text, is_eex}) ->
        text = if text == "", do: text, else: text <> "\n"
        leading_space = String.duplicate(" ", line_indent - text_indent)
        {text <> leading_space <> line, is_eex || is_eex_line}
      end)

    text = text <> trailing_whitespace

    if is_eex do
      {:eex, content: wrap_in_quotes(text), inline: true}
    else
      text
    end
  end
end
