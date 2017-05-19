defmodule Slime.Parser.TextBlock do
  @moduledoc "
  Utilities for parsing text blocks.
  "

  @doc """
  Given a text block and its declaration indentation level (see below),
  produces a {content, is_eex} tuple.

  nested
    | Text block
       that spans over multiple lines
  ---
   ^
  declaration indent
  """
  def render(lines, decl_indent) do
    [{first_line_indent, first_line, is_eex_line} | rest] = lines

    text_indent = if first_line == "" do
      [{indent, _, _} | _] = rest
      indent
    else
      decl_indent + first_line_indent
    end

    content = [{text_indent, first_line, is_eex_line} | rest]

    Enum.reduce(content, {"", false},
      fn ({line_indent, line, is_eex_line}, {text, is_eex}) ->
        text = if text == "", do: text, else: text <> "\n"
        leading_space = String.duplicate(" ", line_indent - text_indent)
        {text <> leading_space <> line, is_eex || is_eex_line}
      end)
  end
end
