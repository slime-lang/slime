defmodule TreeTest do
  use ExUnit.Case, async: true

  alias SlimFast.Tree
  alias SlimFast.Tree.Branch

  test "creates simple tree" do
    expected = [%Branch{
                  type: :div,
                  attributes: [id: "id", class: ["class"]],
                  children: [%Branch{
                                type: :p,
                                attributes: [],
                                children: [%Branch{
                                              attributes: [],
                                              type: :text,
                                              content: "Hello World"}]}]}]

    parsed = [{0, {:div, attributes: [id: "id", class: ["class"]], children: []}}, {1, {:p, attributes: [], children: ["Hello World"]}}] |> Tree.build_tree

    assert parsed == expected
  end
end
