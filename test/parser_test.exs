defmodule ParserTest do
  use ExUnit.Case, async: false

  alias Slime.Parser

  test "parses simple nesting" do
    parsed = ["#id.class", "  p", "    | Hello World"] |> parse_lines
    assert parsed == [
      {0, {"div", attributes: [{"class", "class"}, {"id", "id"}], spaces: %{}, close: false}},
      {2, {"p", attributes: [], spaces: %{}, close: false}},
      {4, "Hello World"}
    ]

    parsed = ["#id.class","  p Hello World"] |> parse_lines
    assert parsed == [
      {0, {"div", attributes: [{"class", "class"}, {"id", "id"}], spaces: %{}, close: false}},
      {2, {"p", attributes: [], spaces: %{}, children: ["Hello World"], close: false}}
    ]
  end

  test "parses inline nesting" do
    parsed = Parser.parse(".row: .col-lg-12: p Hello World")
    assert parsed == [
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

  test "parses css classes with dashes" do
    {_, {"div", opts}} = parse_line(".my-css-class test")
    assert opts[:attributes] == [{"class", "my-css-class"}]
    assert opts[:children] == ["test"]
  end

  test "parses attributes" do
    {_, {"meta", opts}} = parse_line(~S(meta name=variable content="one two"))
    assert opts[:attributes] == [
      {"content", "one two"},
      {"name", {:eex, content: "variable", inline: true}}
    ]
  end

  test "parses attributes with wrappers" do
    {_, {"meta", opts}} = ~s[meta(name=other content="one two")]
                         |> parse_line

    assert opts[:attributes] == [
      {"content", "one two"},
      {"name", {:eex, content: "other", inline: true}}
    ]
  end

  test ~s(show error message for div[id="test"} case) do
    assert_raise(Slime.TemplateSyntaxError, fn () ->
      parse_line(~S(div[id="test"}))
    end)
  end

  test ~s(show error message for div [id="test"} case with leading space) do
    assert_raise(Slime.TemplateSyntaxError, fn () ->
      parse_line(~S(div [id="test"}))
    end)
  end

  test "parses boolean attributes" do
    {_, {"input", opts}} = parse_line(~s[input (type="text" required=true)])
    assert opts[:attributes] == [{"required", {:eex, content: "true", inline: true}}, {"type", "text"}]

    {_, {"input", opts}} = parse_line(~s[input (type="text" required)])
    assert opts[:attributes] == [{"required", true}, {"type", "text"}]
  end

  test "parses attributes with interpolation" do
    {_, {"meta", opts}} = ~S(meta content="one#{two}") |> parse_line

    assert opts[:attributes] == [{"content", {:eex, content: ~S("one#{two}"), inline: true}}]
  end

  test "parses attributes with qutation inside interoplation correctly" do
    {_, {"meta", opts}} = ~S[meta content="one#{two("three")}"] |> parse_line

    assert opts[:attributes] == [{"content", {:eex, content: ~S["one#{two("three")}"], inline: true}}]
  end

  test "parses attributes with tuples inside interoplation correctly" do
    {_, {"meta", opts}} = ~S[meta content="one#{two({"three" "four"})}"] |> parse_line

    assert opts[:attributes] == [{"content", {:eex, content: ~S["one#{two({"three" "four"})}"], inline: true}}]
  end

  test "parses attributes with elixir code" do
    {_, {"meta", opts}} = ~S(meta content=@user.name) |> parse_line
    assert opts[:attributes] == [{"content", {:eex, content: ~S(@user.name), inline: true}}]

    {_, {"meta", opts}} = ~S(meta content=user.name) |> parse_line
    assert opts[:attributes] == [{"content", {:eex, content: ~S(user.name), inline: true}}]

    {_, {"meta", opts}} = ~S(meta content=user["name"]) |> parse_line
    assert opts[:attributes] == [{"content", {:eex, content: ~S(user["name"]), inline: true}}]

    {_, {"meta", opts}} = ~S[meta content=Module.function(param1, param2)] |> parse_line
    assert opts[:attributes] == [{"content", {:eex, content: ~S[Module.function(param1, param2)], inline: true}}]
  end

  test "parses attributes and inline children" do
    {_, {"div", opts}} = ~S(div id="id" text content)
                        |> parse_line

    assert opts[:attributes] == [{"id", "id"}]
    assert opts[:children] == ["text content"]

    {_, {"div", opts}} = ~S(div id="id" = elixir_func)
                        |> parse_line

    assert opts[:children] == [{:eex, content: "elixir_func", inline: true}]
  end

  test "parses inline children with interpolation" do
    {_, {"div", opts}} = "div text \#{content}" |> parse_line

    assert opts[:children] == [{:eex, content: ~S("text #{content}"), inline: true}]
  end

  test "parses content with interpolation" do
    {_, {:eex, opts}} = "| text \#{content}" |> parse_line

    assert opts[:inline]
    assert opts[:content] == ~S("text #{content}")

    {_, {:eex, opts}} = "' text \#{content}\n" |> parse_line

    assert opts[:inline]
    assert opts[:content] == ~s("text \#{content} ")
  end

  test "parses doctype" do
    {_, {:doctype, doc_string}} = "doctype html"
                         |> parse_line

    assert doc_string == "<!DOCTYPE html>"
  end

  test "parse inline html" do
    {_, text} = parse_line("<h3>Text</h3>")
    assert text == "<h3>Text</h3>"
  end

  test "parse inline html with interpolation" do
    {_, {:eex, opts}} = parse_line(~S(<h3>Text" #{elixir_func}</h3>))
    assert opts[:inline]
    assert opts[:content] == ~S["<h3>Text\" #{elixir_func}</h3>"]
  end

  test "quote inline html with interpolation" do
    {_, {:eex, opts}} = parse_line(~S(<h3>Text""" #{"elixir_string"} "</h3>))
    assert opts[:inline]
    assert opts[:content] == ~S["<h3>Text\"\"\" #{"elixir_string"} \"</h3>"]
  end

  test "parses final newline properly" do
    parsed = ["#id.class", "  p", "    | Hello World", ""] |> parse_lines
    assert parsed == [
      {0, {"div", attributes: [{"class", "class"}, {"id", "id"}], spaces: %{}, close: false}},
      {2, {"p", attributes: [], spaces: %{}, close: false}},
      {4, "Hello World"}
    ]
  end

  test "parses html comments" do
    {_, {:html_comment, opts}} = parse_line("/! html comment")
    assert opts[:children] == ["html comment"]
  end

  test "parses IE comments" do
    {_, {:ie_comment, opts}} = parse_line("/[if IE]")
    assert opts[:content] == "if IE"
  end

  test "parses code comments" do
    assert parse_lines(["/ code comment"]) == []
  end

  test "parses outputs" do
    {_, {:eex, opts}} = parse_line("= elixir_func")
    assert opts[:inline]
    assert opts[:content] == "elixir_func"

    {_, {:eex, opts}} = parse_line("== elixir_func")
    assert opts[:inline]
    assert opts[:content] == "elixir_func"
  end

  test "parses closed tags" do
    {_, {"img", opts}} = ~S(img id="id"/) |> parse_line

    assert opts[:close]
  end

  test "ignores empty lines" do
    parsed = ["#id.class", "     "] |> parse_lines

    assert parsed == [
      {0, {"div", attributes: [{"class", "class"}, {"id", "id"}], spaces: %{}, close: false}}
    ]
  end

  def parse_lines(lines), do: Parser.parse(Enum.join(lines, "\n"))
  def parse_line(line), do: line |> Parser.parse |> List.first
end
