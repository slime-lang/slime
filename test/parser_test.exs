defmodule ParserTest do
  use ExUnit.Case, async: false

  alias Slime.Parser

  test "parses simple nesting" do
    parsed = ["#id.class", "  p", "    | Hello World"] |> Parser.parse_lines
    assert parsed == [
      {0, {"div", attributes: [class: "class", id: "id"], children: [], spaces: %{}, close: false}},
      {2, {"p", attributes: [], children: [], spaces: %{}, close: false}},
      {4, "Hello World"}
    ]

    parsed = ["#id.class","  p Hello World"] |> Parser.parse_lines
    assert parsed == [
      {0, {"div", attributes: [class: "class", id: "id"], children: [], spaces: %{}, close: false}},
      {2, {"p", attributes: [], children: ["Hello World"], spaces: %{}, close: false}}
    ]
  end

  test "parses css classes with dashes" do
    {_, {"div", opts}} = ".my-css-class test"
                         |> Parser.parse_line
    assert opts[:attributes][:class] == "my-css-class"
    assert opts[:children] == ["test"]
  end

  test "parses attributes" do
    {_, {"meta", opts}} = ~S(meta name=variable content="one two")
                         |> Parser.parse_line

    assert opts[:attributes] == [
      name: {:eex, content: "variable", inline: true}, content: "one two"
    ]
  end

  test "parses attributes with wrappers" do
    {_, {"meta", opts}} = ~s[meta(name=other content="one two")]
                         |> Parser.parse_line

    assert opts[:attributes] == [
      name: {:eex, content: "other", inline: true}, content: "one two"
    ]
  end

  test "parse when '{}' wrapper disabled" do
    {_, {"div", opts}} = ~S(div {it-is="content"})
                        |> Parser.parse_line

    assert opts[:children] == [~s[{it-is="content"}]]
  end

  test ~s(show error message for div[id="test"} case) do
    assert_raise(Slime.TemplateSyntaxError, fn () ->
      Parser.parse_line(~S(div [it-is="content"}))
    end)
  end

  test "parses boolean attributes" do
    {_, {"input", opts}} = ~s[input (type="text" required=true)]
                          |> Parser.parse_line

    assert opts[:attributes] == [type: "text", required: {:eex, content: "true", inline: true}]

    {_, {"input", opts}} = ~s[input (type="text" required)]
                          |> Parser.parse_line

    assert opts[:attributes] == [type: "text", required: {:eex, content: "true", inline: true}]
  end

  test "parses attributes with interpolation" do
    {_, {"meta", opts}} = ~S(meta content="one#{two}") |> Parser.parse_line

    assert opts[:attributes] == [content: {:eex, content: ~S("one#{two}"), inline: true}]
  end

  test "parses attributes with qutation inside interoplation correctly" do
    {_, {"meta", opts}} = ~S[meta content="one#{two("three")}"] |> Parser.parse_line

    assert opts[:attributes] == [content: {:eex, content: ~S["one#{two("three")}"], inline: true}]
  end

  test "parses attributes with tuples inside interoplation correctly" do
    {_, {"meta", opts}} = ~S[meta content="one#{two({"three" "four"})}"] |> Parser.parse_line

    assert opts[:attributes] == [content: {:eex, content: ~S["one#{two({"three" "four"})}"], inline: true}]
  end

  test "parses attributes with elixir code" do
    {_, {"meta", opts}} = ~S(meta content=@user.name) |> Parser.parse_line
    assert opts[:attributes] == [content: {:eex, content: ~S(@user.name), inline: true}]

    {_, {"meta", opts}} = ~S(meta content=user.name) |> Parser.parse_line
    assert opts[:attributes] == [content: {:eex, content: ~S(user.name), inline: true}]

    {_, {"meta", opts}} = ~S(meta content=user["name"]) |> Parser.parse_line
    assert opts[:attributes] == [content: {:eex, content: ~S(user["name"]), inline: true}]
  end

  test "parses attributes and inline children" do
    {_, {"div", opts}} = ~S(div id="id" text content)
                        |> Parser.parse_line

    assert opts[:attributes] == [id: "id"]
    assert opts[:children] == ["text content"]

    {_, {"div", opts}} = ~S(div id="id" = elixir_func)
                        |> Parser.parse_line

    assert opts[:children] == [{:eex, content: "elixir_func", inline: true}]
  end

  test "parses inline children with interpolation" do
    {_, {"div", opts}} = "div text \#{content}" |> Parser.parse_line

    assert opts[:children] == [{:eex, content: ~S("text #{content}"), inline: true}]
  end

  test "parses content with interpolation" do
    {_, {:eex, opts}} = "| text \#{content}" |> Parser.parse_line

    assert opts[:inline]
    assert opts[:content] == ~S("text #{content}")

    {_, {:eex, opts}} = "' text \#{content}\n" |> Parser.parse_line

    assert opts[:inline]
    assert opts[:content] == ~s(" text \#{content}\n")
  end

  test "parses doctype" do
    {_, {:doctype, doc_string}} = "doctype html"
                         |> Parser.parse_line

    assert doc_string == "<!DOCTYPE html>"
  end

  test "parse inline html" do
    {_, text} = Parser.parse_line("<h3>Text</h3>")
    assert text == "<h3>Text</h3>"
  end

  test "parse inline html with interpolation" do
    {_, {:eex, opts}} = Parser.parse_line(~S(<h3>Text" #{elixir_func}</h3>))
    assert opts[:inline]
    assert opts[:content] == ~S["<h3>Text\" #{elixir_func}</h3>"]
  end

  test "quote inline html with interpolation" do
    {_, {:eex, opts}} = Parser.parse_line(~S(<h3>Text""" #{"elixir_string"} "</h3>))
    assert opts[:inline]
    assert opts[:content] == ~S["<h3>Text\"\"\" #{"elixir_string"} \"</h3>"]
  end

  test "parses final newline properly" do
    parsed = ["#id.class", "  p", "    | Hello World", ""] |> Parser.parse_lines
    assert parsed == [
      {0, {"div", attributes: [class: "class", id: "id"], children: [], spaces: %{}, close: false}},
      {2, {"p", attributes: [], children: [], spaces: %{}, close: false}},
      {4, "Hello World"}
    ]
  end

  test "parses html comments" do
    {_, {:html_comment, opts}} = Parser.parse_line("/! html comment")
    assert opts[:children] == ["html comment"]
  end

  test "parses IE comments" do
    {_, {:ie_comment, opts}} = Parser.parse_line("/[if IE]")
    assert opts[:content] == "if IE"
  end

  test "parses code comments" do
    {_, ""} = Parser.parse_line("/ code comment")
  end

  test "parses outputs" do
    {_, {:eex, opts}} = Parser.parse_line("= elixir_func")
    assert opts[:inline]
    assert opts[:content] == "elixir_func"

    {_, {:eex, opts}} = Parser.parse_line("== elixir_func")
    assert opts[:inline]
    assert opts[:content] == "elixir_func"
  end

  test "parses closed tags" do
    {_, {"img", opts}} = ~S(img id="id"/) |> Parser.parse_line

    assert opts[:close]
  end

  test "ignores empty lines" do
    parsed = ["#id.class", "     "] |> Parser.parse_lines

    assert parsed == [
      {0, {"div", attributes: [class: "class", id: "id"], children: [], spaces: %{}, close: false}}
    ]
  end
end
