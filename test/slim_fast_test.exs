defmodule SlimFastTest do
  use ExUnit.Case

  alias SlimFast.Tree.Branch

  test "parse simple nesting" do
    parsed = "#id.class\n\tp\n\t| Hello World" |> SlimFast.evaluate
    assert parsed == "<div class=\"class\" id=\"id\">\n<p>\nHello World\n</p>\n</div>"
  end
end
