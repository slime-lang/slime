defmodule Slime.PreprocessorTest do
  use ExUnit.Case

  import Slime.Preprocessor, only: [process: 1]

  test "documents are split into lines" do
    result = """
    h1 Hi
      h2 Bye
    """ |> process
    assert result == [
      "h1 Hi",
      "  h2 Bye",
    ]
  end

  test "hard tabs are expanded" do
    result = """
    h1 Hi
    \th2 Bye
    \t\th3 Hi
    """ |> process
    assert result == [
      "h1 Hi",
      "  h2 Bye",
      "    h3 Hi",
    ]
  end


  test "inline tags are expanded onto multiple lines" do
    result = """
    ul
      li.first:a href='/a' A link
      li:a href='/b' B link
    """ |> process
    assert result == [
      "ul",
      "  li.first",
      "    a href='/a' A link",
      "  li",
      "    a href='/b' B link",
    ]
  end

  test "inline tags are expanded when whitespace after the :" do
    result = """
    ul
      li.first: a href='/a' A link
      li:       a href='/b' B link
    """ |> process
    assert result == [
      "ul",
      "  li.first",
      "    a href='/a' A link",
      "  li",
      "    a href='/b' B link",
    ]
  end
end
