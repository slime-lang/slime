defmodule Slime.Parser.PreprocessorTest do
  use ExUnit.Case
  alias Slime.Parser.Preprocessor
  alias Slime.TemplateSyntaxError

  doctest Preprocessor

  @indent Preprocessor.indent_meta_symbol
  @dedent Preprocessor.dedent_meta_symbol

  test "removes trailing spaces" do
    slime = """
    div      \n\t child    \n
    \t             \n
        \n
    \t another_child
    """
    assert Preprocessor.remove_trailing_spaces(slime) == """
    div
    \t child\n
    \n
    \n
    \t another_child
    """
  end

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

  test "skip indents in broken code lines" do
    slime = """
    = "first" <> \\
          ", " <> \\
        "second"
    = Enum.join(["first",
          "second",
        "third",
      "fourth"], ", ")
    """
    assert Preprocessor.indent(slime) == """
    = "first" <> \\
          ", " <> \\
        "second"
    = Enum.join(["first",
          "second",
        "third",
      "fourth"], ", ")
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

  test "skip empty lines at the end of verbatim text" do
    slime = """
    |
      Test: <%= "test" %>

    d
    """
    assert Preprocessor.indent(slime) == """
    |
    #{@indent}  Test: <%= "test" %>#{@dedent}

    d
    """
  end

  test "handle one-line verbatim text without unneccessary indent-dedent" do
    slime = """
    | Test: <%= "test" %>

    d
    """
    assert Preprocessor.indent(slime) == """
    | Test: <%= "test" %>

    d
    """
  end
end
