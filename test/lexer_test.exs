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
      indent: 0, tag: "br",
      indent: 2, tag: "br",
      indent: 4, tag: "br",
    ]
  end

  test "it can detect classes" do
    tokens = Lexer.tokenize """
    .foo
    """
    assert tokens == [ indent: 0, class: "foo" ]
  end

  test "it can detect IDs" do
    tokens = Lexer.tokenize """
    #bar
    """
    assert tokens == [ indent: 0, id: "bar" ]
  end
end
