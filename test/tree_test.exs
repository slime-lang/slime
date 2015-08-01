defmodule TreeTest do
  use ExUnit.Case, async: true

  alias SlimFast.Tree
  alias SlimFast.Tree.Branch

  test "parses simple nesting" do
    expected = [%Branch{type: :div, children: [%Branch{type: :p, children: [%Branch{type: :text, children: [], content: "Hello World"}]}], id: "id", css: ["class"]}]

    parsed = [{0, {:div, id: "id", css: ["class"], children: []}}, {1, {:p, id: nil, css: [], children: [{:text, content: "Hello World"}]}}] |> Tree.build_tree
    assert parsed == expected

    parsed = [{0, {:div, id: "id", css: ["class"], children: []}}, {1, {:p, id: nil, css: [], children: [{:text, content: "Hello World"}]}}] |> Tree.build_tree
    assert parsed == expected
  end
end
