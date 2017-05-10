defmodule ParserTest do
  use ExUnit.Case, async: false

  alias Slime.Parser
  import Parser, only: [parse: 1]

  test "parses simple nesting" do
    slime = """
    #id.class
      p
        | Hello World
    """
    assert parse(slime) == [
      {0, {"div", attributes: [{"class", "class"}, {"id", "id"}], spaces: %{}, close: false}},
      {2, {"p", attributes: [], spaces: %{}, close: false}},
      {4, "Hello World"}
    ]
  end

  test "parses inline nesting" do
    assert parse(".row: .col-lg-12: p Hello World") == [
      {0, {"div",
        attributes: [{"class", "row"}],
        spaces: %{},
        children: [
          {"div",
            attributes: [{"class", "col-lg-12"}],
            spaces: %{},
            children: [
              {"p",
                attributes: [],
                spaces: %{},
                children: ["Hello World"],
                close: false
              }
            ],
            close: false
          }
        ],
        close: false
      }}
    ]
  end

  test "parses attributes" do
    [{_, {"meta", opts}}] = parse(~S(meta name=variable content="one two"))
    assert opts[:attributes] == [
      {"content", "one two"},
      {"name", {:eex, content: "variable", inline: true}}
    ]
  end

  test ~s(raises error on unmatching attributes wrapper) do
    assert_raise(Slime.TemplateSyntaxError, fn -> parse(~S(div[id="test"})) end)
  end

  test "ignores trailing empty lines" do
    slime = """
    #id.class

    """
    assert parse(slime) == [
      {0, {"div", attributes: [{"class", "class"}, {"id", "id"}], spaces: %{}, close: false}}
    ]
  end
end
