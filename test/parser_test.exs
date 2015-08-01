defmodule ParserTest do
  use ExUnit.Case, async: true

  alias SlimFast.Parser

  test "parses simple nesting" do
    parsed = ["#id.class", "\tp", "\t| Hello World"] |> Parser.parse_lines
    assert parsed == [{0, {:div, id: "id", css: ["class"], children: []}}, {1, {:p, id: nil, css: [], children: []}}, {1, {:text, content: "Hello World"}}]

    parsed = ["#id.class","\tp Hello World"] |> Parser.parse_lines
    assert parsed == [{0, {:div, id: "id", css: ["class"], children: []}}, {1, {:p, id: nil, css: [], children: [{:text, content: "Hello World"}]}}]
  end
end
