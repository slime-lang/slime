defmodule Slime.Parser.Preprocessor do
  @moduledoc """
  This module helps to process input and insert indents and dedents to simplify parser design.
  """

  @indent "\x0E"
  @dedent "\x0F"

  @tabsize Application.get_env(:slime, :tabsize, 2)

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
    indent = case Regex.run(~r/^[ \t]*+(?!$|\s)/, line) do
      # NOTE: empty line
      nil ->
        case rest do
          [] -> 0
          _ -> current
        end
      # other lines
      [indent_symbols] -> indent_size(indent_symbols)
    end
    {stack, result} = cond do
      current == indent -> {stack, [line | result]}
      current < indent -> {[indent | stack], [@indent <> line | result]}
      current > indent ->
        {dedents, stack} = Enum.split_while(stack, &(&1 > indent))
        dedents = String.duplicate(@dedent, Enum.count(dedents))
        [prev_line | result] = result
        {stack, [line, prev_line <> dedents | result]}
    end
    indent(rest, stack, result)
  end

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
end
