defmodule SlimFastTest do
  use ExUnit.Case, async: true

  test "parse simple nesting" do
    parsed = "#id.class\n\tp\n\t| Hello World" |> SlimFast.evaluate
    assert parsed == "<div class=\"class\" id=\"id\">\n<p>Hello World</p>\n</div>\n"
  end

  test "parse attributes" do
    parsed = "meta name=\"name\" description=variable\n#id.class\n\tp\n\t| Hello World" |> SlimFast.evaluate
    assert parsed == "<meta description=<%=variable%> name=\"name\"></meta>\n<div class=\"class\" id=\"id\">\n<p>Hello World</p>\n</div>\n"
  end
end
