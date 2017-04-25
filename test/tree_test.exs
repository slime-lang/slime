defmodule TreeTest do
  use ExUnit.Case, async: true

  alias Slime.Tree
  alias Slime.Tree.EExNode
  alias Slime.Tree.HTMLNode
  alias Slime.Tree.TextNode

  test "creates simple tree" do
    expected = [
      %HTMLNode{
        tag: :div,
        attributes: [id: "id", class: ["class"]],
        children: [
          %EExNode{
            attributes: [inline: false],
            content: "true",
            children: []},
          %HTMLNode{
            tag: :p,
            attributes: [],
            children: [
              %TextNode{
                content: "Hello World"}]}]}]

    parsed = [
      {0, {:div, attributes: [id: "id", class: ["class"]], children: []}},
      {2, {:eex, attributes: [inline: false], content: "true"}},
      {2, {:p, attributes: [], children: ["Hello World"]}}
    ] |> Tree.build_tree

    assert parsed == expected
  end

  test "creates tree with mixed nesting" do
    expected = [
      %HTMLNode{
        tag: :div,
        attributes: [class: ~w(wrap)],
        children: [
          %HTMLNode{
            tag: :div,
            attributes: [class: ~w(row)],
            children: [
              %HTMLNode{
                tag: :div,
                attributes: [class: ~w(col-lg-12)],
                children: [
                  %HTMLNode{
                    tag: :div,
                    attributes: [class: ~w(box)],
                    children: [
                      %HTMLNode{
                        tag: :p,
                        attributes: [],
                        children: [%TextNode{content: "One"}]}]},
                  %HTMLNode{
                    tag: :p,
                    attributes: [],
                    children: [%TextNode{content: "Two"}]}]}]}]},
      %HTMLNode{
        tag: :p,
        attributes: [],
        children: [%TextNode{content: "Three"}]}]

    parsed = [
      {0, {:div,
           attributes: [class: ~w(wrap)],
           children: [
             {:div,
              attributes: [class: ~w(row)],
              children: [
                {:div,
                 attributes: [class: ~w(col-lg-12)],
                 children: []}]}]}},
      {2, {:div,
           attributes: [class: ~w(box)],
           children: [
             {:p, attributes: [], children: ~w(One)}]}},
      {2, {:p, attributes: [], children: ~w(Two)}},
      {0, {:p, attributes: [], children: ~w(Three)}}
    ] |> Tree.build_tree

    assert parsed == expected
  end
end
