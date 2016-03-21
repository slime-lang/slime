defmodule Slime.Lexer do
  @moduledoc """
  Leex based lexing of Slime documents. See src/slime_lexer.xrl for details.
  """

  def tokenize(document) when is_binary document do
    document
    |> strip_trailing_newlines
    |> prefix_newline
    |> to_char_list
    |> tokenize
  end

  def tokenize(document) when is_list document do
    {:ok, tokens, _} = document |> :slime_lexer.string
    tokens
  end


  defp prefix_newline(<< ?\n::utf8 , _rest::utf8 >> = string) do
    string
  end
  defp prefix_newline(string) when is_binary string do
    "\n" <> string
  end

  defp strip_trailing_newlines(document) when is_binary document do
    String.replace( document, ~r/\n+\z/, "" )
  end
end
