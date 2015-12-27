defmodule CompilerTest do
  use ExUnit.Case, async: true

  alias Slime.Tree.Branch
  alias Slime.Compiler

  test "renders simple nesting" do
    tree = [%Branch{type: :div,
        attributes: [id: {:eex, content: "variable"}, class: ["class"]],
        children: [%Branch{type: :p,
            children: [%Branch{type: :text,
                children: [],
                content: "Hello World"}]}]}]

    expected = """
    <div
    <% slim__k = "id"; slim__v = variable %>
    <%= if slim__v do %>
     <%= slim__k %>
    <%= unless slim__v == true do %>
    ="<%= slim__v %>"<% end %><% end %> class="class">
    <p>Hello World</p>
    </div>
    """ |> String.replace("\n", "")
    assert Compiler.compile(tree) == expected
  end

  test "renders eex code with strings containing 'do'" do
    tree = [%Branch{
      type: :eex,
      attributes: [inline: true],
      content: ~s(number_input f, :amount, class: "js-donation-amount")
    }]

    expected = ~s(<%= number_input f, :amount, class: "js-donation-amount" %>)
    assert Compiler.compile(tree) == expected
  end

  test "renders eex code with inline do: block" do
    tree = [%Branch{
      type: :eex,
      attributes: [inline: true],
      content: ~s(if true, do: "ok")
    }]

    expected = ~s(<%= if true, do: "ok" %>)
    assert Compiler.compile(tree) == expected
  end

  test "renders eex code with one-line functions" do
    tree = [%Branch{
      type: :eex,
      attributes: [inline: true],
      content: ~s{Enum.map([], fn (_) -> "ok" end)}
    }]

    expected = ~s{<%= Enum.map([], fn (_) -> "ok" end) %>}
    assert Compiler.compile(tree) == expected
  end

  test "renders eex code with multi-line functions" do
    tree = [%Branch{
      type: :eex,
      attributes: [inline: true],
      content: ~s{Enum.map [], fn (_) ->},
      children: [%Branch{type: :text, content: "test"}]
    }]

    expected = ~s{<%= Enum.map [], fn (_) -> %>test<% end %>}
    assert Compiler.compile(tree) == expected
  end

  test "renders doctype" do
    tree = [%Branch{type: :doctype, content: "<!DOCTYPE html>"}]
    assert Compiler.compile(tree) == "<!DOCTYPE html>"
  end

  test "renders boolean attributes" do
    tree = [
      %Branch{
        type: :input,
        attributes: [class: ["class"],
        required: {:eex, content: "true"}]}
    ]
    assert Compiler.compile(tree) == ~s(<input class="class" required>)
    tree = [
      %Branch{
        type: :input,
        attributes: [class: ["class"],
        required: {:eex, content: "false"}]}
    ]
    assert Compiler.compile(tree) == ~s(<input class="class">)
  end

  test "renders eex" do
    tree = [
      %Branch{type: :title,
        children: [%Branch{type: :eex,
            content: "site_title",
            attributes: [inline: true]}]}
    ]
    expected = "<title><%= site_title %></title>"
    assert Compiler.compile(tree) == expected
  end
end
