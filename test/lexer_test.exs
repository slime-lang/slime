defmodule Slime.LexerTest do
  use ExUnit.Case

  alias Slime.Lexer

  defmacro slime ~> tokens do
    quote bind_quoted: binding do
      assert Lexer.tokenize(slime) == tokens
    end
  end

  test "it can detect indents" do
    """
    br
      br
        br
    """ ~> [
      indent: 0, tag: "br",
      indent: 2, tag: "br",
      indent: 4, tag: "br",
    ]
  end

  test "it can detect classes" do
    """
    .foo
    """ ~> [
      indent: 0, class: "foo",
    ]
  end

  test "it can detect IDs" do
    """
    #bar
    """ ~> [
      indent: 0, id: "bar"
    ]
  end
end
