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
end
