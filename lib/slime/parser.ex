defmodule Slime.Parser do
  @moduledoc """
  Build a Slime tree from a Slime document.
  """

  alias Slime.Parser.Preprocessor
  alias Slime.TemplateSyntaxError

  def parse(""), do: []
  def parse(input) do
    indented_input = Preprocessor.process(input)
    case :slime_parser.parse(indented_input) do
      {:fail, error} ->
        raise TemplateSyntaxError, syntax_error(input, indented_input, error)
      tokens -> tokens
    end
  end

  defp syntax_error(input, indented_input, error) do
    {_reason, error, {{:line, line}, {:column, column}}} = error
    indented_line = indented_input |> String.split("\n") |> Enum.at(line - 1)
    input_line = input |> String.split("\n") |> Enum.at(line - 1)
    indent = Preprocessor.indent_meta_symbol
    column = case indented_line do
      <<^indent::binary-size(1), _::binary>> -> column - 1
      _ -> column
    end
    dedent = Preprocessor.dedent_meta_symbol
    message = case error do
      {:no_match, ^indent} -> "Unexpected indent"
      {:no_match, ^dedent} -> "Unexpected dedent"
      {:no_match, symbol} -> "Unexpected symbol '#{symbol}'"
      _ -> inspect(error)
    end
    [
      line: input_line,
      message: message,
      line_number: line,
      column: column
    ]
  end
end
