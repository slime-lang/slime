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
      [{_, []} | rest] ->
        normalize_indent(rest)

      [first_line | rest] ->
        [first_line | normalize_indent(rest, declaration_indent)]
    end

    insert_line_spacing(lines)
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

  defp normalize_indent([]), do: []
  defp normalize_indent(lines) do
    indents =
      lines
      |> Enum.map(fn {indent, _} -> indent end)
      |> Enum.filter(& &1 != 0)
    min_indent = case indents do
      [] -> 0
      _ -> Enum.min(indents)
    end
    {leading, rest} = Enum.split_while(lines, fn {indent, _} -> indent != min_indent end)
    result =
      leading
      |> Enum.map(fn {_, content} -> {min_indent, content} end)
      |> Enum.concat(rest)
    normalize_indent(result, min_indent - 1)
  end

  defp normalize_indent(lines, declaration_indent) do
    Enum.map(lines, fn {indent, content} ->
      {indent - declaration_indent, content}
    end)
  end

  defp insert_line_spacing(lines) do
    concat_lines(lines,
      fn({line_indent, line_contents}, content) ->
        if 1 < line_indent do
          ["\n" | [String.duplicate(" ", line_indent - 1) | line_contents ++ content]]
        else
          ["\n" | line_contents ++ content]
        end
      end)
  end

  defp concat_lines([], _), do: []
  defp concat_lines(lines, concat_function) do
    [_leading_newline | content] = List.foldr(lines, [], concat_function)
    content
  end
end
