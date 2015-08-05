defmodule ParserTest do
  use ExUnit.Case

  alias SlimFast.Parser

  test "parses simple nesting" do
    parsed = ["#id.class", "\tp", "\t| Hello World"] |> Parser.parse_lines
    assert parsed == [{0, {:div, attributes: [class: ["class"], id: "id"], children: []}}, {2, {:p, attributes: [], children: []}}, {2, "Hello World"}]

    parsed = ["#id.class","\tp Hello World"] |> Parser.parse_lines
    assert parsed == [{0, {:div, attributes: [class: ["class"], id: "id"], children: []}}, {2, {:p, attributes: [], children: ["Hello World"]}}]
  end

  test "parses attributes" do
    {_, {:meta, opts}} = "meta name=variable content=\"one two\""
                         |> Parser.parse_line

    assert opts[:attributes] == [content: "one two", name: {:eex, content: "variable", inline: true}]
  end

  test "parses attributes with interpolation" do
    {_, {:meta, opts}} = ~S(meta content="one#{two}") |> Parser.parse_line

    assert opts[:attributes] == [content: {:eex, content: ~S("one#{two}"), inline: true}]
  end

  test "parses attributes and inline children" do
    {_, {:div, opts}} = "div id=\"id\" text content"
                        |> Parser.parse_line

    assert opts[:attributes] == [id: "id"]
    assert opts[:children] == ["text content"]

    {_, {:div, opts}} = "div id=\"id\" = elixir_func"
                        |> Parser.parse_line

    assert opts[:children] == [{:eex, content: "elixir_func", inline: true}]
  end

  test "parses inline children with interpolation" do
    {_, {:div, opts}} = "div text \#{content}" |> Parser.parse_line

    assert opts[:children] == [{:eex, content: ~S("text #{content}"), inline: true}]
  end

  test "parses content with interpolation" do
    {_, {:eex, opts}} = "| text \#{content}" |> Parser.parse_line

    assert opts[:inline] == true
    assert opts[:content] == ~S("text #{content}")

    {_, {:eex, opts}} = "' text \#{content}\n" |> Parser.parse_line

    assert opts[:inline] == true
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
    assert opts[:inline] == true
    assert opts[:content] == "\"<h3>Text\\\" \#{elixir_func}</h3>\""
  end

  test "parses final newline properly" do
    parsed = ["#id.class", "\tp", "\t| Hello World", ""] |> Parser.parse_lines
    assert parsed == [{0, {:div, attributes: [class: ["class"], id: "id"], children: []}}, {2, {:p, attributes: [], children: []}}, {2, "Hello World"}]
  end
end
