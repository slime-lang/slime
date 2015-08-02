defmodule RendererTest do
  use ExUnit.Case, async: true

  alias SlimFast.Tree.Branch
  alias SlimFast.Renderer

  test "renders simple nesting" do
    tree = [%Branch{type: :div, attributes: [id: "id", class: ["class"]], children: [%Branch{type: :p, children: [%Branch{type: :text, children: [], content: "Hello World"}]}]}]

    expected = "<div id=\"id\" class=\"class\">\n<p>\nHello World</p>\n</div>\n"
    assert Renderer.render(tree) == expected
  end
end
