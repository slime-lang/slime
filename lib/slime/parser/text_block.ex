defmodule Slime.Parser.TextBlock do
  @moduledoc "
  Utilities for parsing text blocks.
  "

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
      [{_, []} | rest] -> rest
      [{relative_indent, first_line_contents} | rest] ->
        first_line_indent = relative_indent + declaration_indent
        [{first_line_indent, first_line_contents} | rest]
    end

    text_indent = Enum.find_value(lines, 0,
      fn({indent, line_contents}) -> !Enum.empty?(line_contents) && indent end)

    insert_line_spacing(lines, text_indent)
  end

  @doc """
  Given a text block, returns the text without indentation.
  """
  def render_without_indentation(lines) do
    concat_lines(lines,
      fn({_line_indent, line_contents}, content) ->
        ["\n" | line_contents ++ content]
      end)
  end

  defp insert_line_spacing(lines, text_indent) do
    concat_lines(lines,
      fn({line_indent, line_contents}, content) ->
        leading_space = String.duplicate(" ", line_indent - text_indent)
        case leading_space do
          "" -> ["\n" | line_contents ++ content]
          _  -> ["\n" | [leading_space | line_contents ++ content]]
        end
      end)
  end

  defp concat_lines([], _), do: []
  defp concat_lines(lines, concat_function) do
    [_leading_newline | content] = List.foldr(lines, [], concat_function)
    content
  end
end
