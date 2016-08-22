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

  test " CRLF line endings are converted to LF" do
    result = "h1 Hi\r\n\th2 Bye\r\n\t\th3 Hi\r\n"
    |> process
    assert result == [
      "h1 Hi",
      "  h2 Bye",
      "    h3 Hi",
    ]
  end
end
