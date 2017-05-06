defmodule ParserMultilineElixirTest do
  use ExUnit.Case
  alias Slime.Parser

  test "= allows multi-line elixir expressions ending with backslash" do
    lines = [
      "= very_long_method_name \\",
      "        another_expression \\",
      "     Final_expression"
    ]
    parsed  = Parser.parse(Enum.join(lines, "\n"))
    content = lines |> Enum.join("\n") |> String.lstrip(?=) |> String.lstrip

    assert parsed == [{0, {:eex, [content: content, inline: true, spaces: %{}]}}]
  end

  test "= allows multi-line elixir method arguments" do
    lines = [
      "=method_name param1,",
      "             param2,",
      "             param3"
    ]
    parsed  = Parser.parse(Enum.join(lines, "\n"))
    content = lines |> Enum.join("\n") |> String.lstrip(?=) |> String.lstrip

    assert parsed == [{0, {:eex, [content: content, inline: true, spaces: %{}]}}]
  end

  test "- allows multi-line elixir expressions ending with backslash" do
    lines = [
      "- very_long_method_name \\",
      "        another_expression \\",
      "     Final_expression"
    ]
    parsed  = Parser.parse(Enum.join(lines, "\n"))
    content = lines |> Enum.join("\n") |> String.lstrip(?-) |> String.lstrip

    assert parsed == [{0, {:eex, [content: content, inline: false, spaces: %{}]}}]
  end

  test "- allows multi-line elixir method arguments" do
    lines = [
      "-method_name param1,",
      "             param2,",
      "             param3"
    ]
    parsed  = Parser.parse(Enum.join(lines, "\n"))
    content = lines |> Enum.join("\n") |> String.lstrip(?-) |> String.lstrip

    assert parsed == [{0, {:eex, [content: content, inline: false, spaces: %{}]}}]
  end
end
