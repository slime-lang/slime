defmodule Slime.Parser.PreprocessorTest do
  use ExUnit.Case
  alias Slime.Parser.Preprocessor
  alias Slime.TemplateSyntaxError

  doctest Preprocessor

  @indent Preprocessor.indent_meta_symbol
  @dedent Preprocessor.dedent_meta_symbol

  test "raise error on inconsistent indentations" do
    slime = """
    div
        div
      div
        | test
    """

    assert_raise(TemplateSyntaxError, fn -> Preprocessor.indent(slime) end)
  end

  test "skip indents in embedded engine lines" do
    slime = """
    engine:
        a
      h
    """
    assert Preprocessor.indent(slime) == """
    engine:
    #{@indent}    a
      h#{@dedent}
    """
  end

  test "skip empty lines at the end of embedded engine body" do
    slime = """
    eex:
      Test: <%= "test" %>

    d
    """
    assert Preprocessor.indent(slime) == """
    eex:
    #{@indent}  Test: <%= "test" %>#{@dedent}

    d
    """
  end
end
