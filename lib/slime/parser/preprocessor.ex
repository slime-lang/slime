defmodule Slime.Parser.Preprocessor do
  @moduledoc """
  This module helps to process input and insert indents and dedents to simplify parser design.
  """
  alias Slime.TemplateSyntaxError

  @indent "\x0E"
  @dedent "\x0F"

  @tabsize Application.get_env(:slime, :tabsize, 2)

  def indent_meta_symbol, do: @indent
  def dedent_meta_symbol, do: @dedent

  def process(input) do
    input
    |> convert_crlf_to_lf
    |> remove_trailing_spaces
    |> indent
  end

  @doc """
  Removes trailing whitespace, leaving newlines intact.
  """
  def remove_trailing_spaces(input) do
    Regex.replace(~r/[ \t]+$/m, input, "")
  end

  @doc """
  Takes an input binary and inserts virtual indent and dedent.

  ## Examples:
      iex> Slime.Parser.Preprocessor.indent("t\\n p")
      "t\\n#{@indent} p#{@dedent}"

      iex> Slime.Parser.Preprocessor.indent("t\\n p\\n  a\\nh")
      "t\\n#{@indent} p\\n#{@indent}  a#{@dedent}#{@dedent}\\nh"
  """
  def indent(input) do
    case String.split(input, "\n") do
      [line] -> line
      lines -> indent(lines, [0], [])
    end
  end

  defp indent([], stack, result) do
    dedents = case Enum.count(stack) - 1 do
      0 -> ""
      dedents -> String.duplicate(@dedent, dedents)
    end

    (result |> Enum.reverse |> Enum.join("\n")) <> dedents
  end

  defp indent([line | rest], [current | _] = stack, result) do
    indent = indent_size(line, current, rest)
    {stack, result} = cond do
      current == indent -> {stack, [line | result]}
      current < indent -> {[indent | stack], [@indent <> line | result]}
      current > indent ->
        {dedents, stack} = Enum.split_while(stack, &(&1 > indent))
        if consistent_indentation?(indent, stack) do
          dedents = String.duplicate(@dedent, Enum.count(dedents))
          [prev_line | result] = result
          {stack, [line, prev_line <> dedents | result]}
        else
          raise TemplateSyntaxError,
            message: "Malformed indentation",
            line: line,
            line_number: Enum.count(result) + 1,
            column: indent
        end
    end

    {rest, result} = skip_inconsistent_indentation(line, indent, rest, result)
    indent(rest, stack, result)
  end

  defp skip_inconsistent_indentation(line, indent, rest, result) do
    cond do
      embedded_engine?(line) -> skip_embedded_engine(indent, rest, result)
      broken_code_line?(line) -> skip_broken_code_lines(rest, result)
      true -> {rest, result}
    end
  end

  defp consistent_indentation?(indent, [next | _]) when next != indent, do: false
  defp consistent_indentation?(_, _), do: true

  @doc """
  Counts indent size by indent string using :tab_size config option

  ## Examples:
      iex> Slime.Parser.Preprocessor.indent_size("    ")
      4

      iex> Slime.Parser.Preprocessor.indent_size("  \t")
      4

      iex> Slime.Parser.Preprocessor.indent_size("")
      0
  """
  def indent_size(spaces) when is_binary(spaces), do: indent_size(String.codepoints(spaces), 0)
  def indent_size(spaces) when is_list(spaces), do: indent_size(spaces, 0)

  defp indent_size([], result), do: result
  defp indent_size([symbol | rest], result) do
    size = case symbol do
      " " -> 1
      "\t" -> @tabsize
    end

    indent_size(rest, result + size)
  end

  defp indent_size(line, current, rest) do
    case indent_symbols(line) do
      nil -> if rest == [], do: 0, else: current
      symbols -> indent_size(symbols)
    end
  end

  defp embedded_engine?(line), do: line =~ ~r/^[ \t]*+\w+:$/
  defp broken_code_line?(line), do: line =~ ~r/^[ \t]*+[=-].*(,|\\)$/
  defp broken_code_line_continuation?(line), do: line =~ ~r/[^\\](,|\\)$/

  def skip_embedded_engine(indent, lines, result) do
    {embedded, rest} = Enum.split_while(lines, fn (line) ->
      line_empty?(line) || indent_size(line, indent, lines) > indent
    end)
    [embed_first_line | embed_rest] = embedded
    embedded = [@indent <> embed_first_line | embed_rest]
    {empty_tail, embedded} = embedded |> Enum.reverse |> Enum.split_while(&(line_empty?(&1)))
    [embed_last_line | embed_rest] = embedded
    {rest, empty_tail ++ [embed_last_line <> @dedent | embed_rest] ++ result}
  end

  def skip_broken_code_lines(lines, result) do
    {broken_lines, [last_line | rest]} = Enum.split_while(lines, fn (line) ->
      line_empty?(line) || broken_code_line_continuation?(line)
    end)
    {rest, [last_line | Enum.reverse(broken_lines)] ++ result}
  end

  defp line_empty?(line) do
    line |> indent_symbols |> is_nil
  end

  defp indent_symbols(line) do
    case Regex.run(~r/^[ \t]*+(?!$|\s)/, line) do
      # NOTE: empty line
      nil -> nil
      [symbols] -> symbols
    end
  end

  defp convert_crlf_to_lf(document) do
    String.replace(document, ~r/\r/, "")
  end
end
