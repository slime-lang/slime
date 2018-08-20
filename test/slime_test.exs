defmodule SlimeTest do
  use ExUnit.Case
  doctest Slime

  test "TemplateSyntaxError banner with error in first column" do
    error = %Slime.TemplateSyntaxError{column: 0, line: "test line", line_number: 1}
    assert Slime.TemplateSyntaxError.message(error) == ~S"""
    Syntax error
    INPUT, Line 1, Column 0
    test line
    ^
    """
  end
end
