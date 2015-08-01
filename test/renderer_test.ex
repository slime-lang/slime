defmodule RendererTest do
  use ExUnit.Case

  alias SlimFast.Tree.Branch
  alias SlimFast.Renderer

  test "" do
    tree = [%Branch{type: :div, children: [%Branch{type: :p, children: [%Branch{type: :text, children: [], content: "Hello World"}]}], id: "id", css: ["class"]}]

    expected = "<div class=\"class\" id=\"id\">\n<p>\nHello World\n</p>\n</div>"
    assert Renderer.render(tree) == expected
  end
end
