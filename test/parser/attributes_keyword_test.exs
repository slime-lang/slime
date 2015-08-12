defmodule ParserAttributesKeywordTest do
  use ExUnit.Case
  doctest SlimFast.Parser.AttributesKeyword

  test "handles multiple eex nodes" do
    result = SlimFast.Parser.AttributesKeyword.merge(
      [class: "a", class: {:eex, content: "b"}, class: {:eex, content: "c"}],
      %{class: " "}
    )
    assert result == [class: {:eex, content: ~S("a #{b} #{c}"), inline: true}]
  end

  test "supports custom delimiter" do
    result = SlimFast.Parser.AttributesKeyword.merge(
      [class: "a", class: "b"],
      %{class: "--"}
    )
    assert result == [class: "a--b"]
  end

  test "leaves unspecified attributes as is" do
    result = SlimFast.Parser.AttributesKeyword.merge(
      [class: "a", id: "id", class: "b", id: "id1"],
      %{class: " "}
    )
    assert result == [class: "a b", id: "id", id: "id1"]
  end

  test "handles all attributes specified in merge rules" do
    result = SlimFast.Parser.AttributesKeyword.merge(
      [class: "a", id: "id", class: "b", id: "id1"],
      %{class: " ", id: "+"}
    )
    assert result == [id: "id+id1", class: "a b"]
  end
end
