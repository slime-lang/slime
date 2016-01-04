defmodule Slime.LexerTest do
  use ExUnit.Case

  alias Slime.Lexer

  test "it can detect indents" do
    tokens = Lexer.tokenize """
    br
      br
        br
    """
    assert tokens == [
      indent: 0, tag: 'br',
      indent: 2, tag: 'br',
      indent: 4, tag: 'br',
    ]
  end
end
