defmodule SlimFastTest do
  use ExUnit.Case

  test "parse simple nesting" do
    parsed = "#id.class\n\tp\n\t| Hello World" |> SlimFast.evaluate
    assert parsed == "<div class=\"class\" id=\"id\">\n<p>Hello World</p>\n</div>\n"
  end
end
