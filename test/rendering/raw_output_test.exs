defmodule RawOutputTest do
  use ExUnit.Case

  alias Slime.Renderer
  alias Phoenix.HTML
  alias Phoenix.HTML.Engine

  defp render(template, bindings \\ []) do
    template
    |> Renderer.render(bindings, engine: Engine)
    |> HTML.safe_to_string
  end

  test "render raw dynamic content" do
    slime = """
    == "<>"
    """
    assert render(slime) == "<>"
  end

  test "render raw attribute value" do
    slime = """
    a href==href
    """
    assert render(slime, href: "&") == ~s[<a href="&"></a>]
  end

  test "render raw tag content" do
    slime = """
    p == "<>"
    """
    assert render(slime) == ~s[<p><></p>]
  end

  test "render raw text interpolation" do
    slime = ~S"""
    | test #{{"<>"}}
    """
    assert render(slime) == "test <>"
  end
end
