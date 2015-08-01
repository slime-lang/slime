defmodule SlimFastTest do
  use ExUnit.Case

  alias SlimFast.Tree.Branch

  test "parse simple nesting" do
    parsed = "#id.class\n\tp\n\t| Hello World" |> SlimFast.evaluate
    assert parsed == [%Branch{type: :div, children: [%Branch{type: :p, children: [%Branch{type: :text, children: [], content: "Hello World"}]}], id: "id", css: ["class"]}]
  end
end
