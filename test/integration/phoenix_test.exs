defmodule Integration.PhoenixTest do
  use ExUnit.Case

  test "inline tags" do
    rendered =
      ~S(p: a data-click="#{action}" Click me)
      |> phoenix_html_render(action: "clicked")

    assert rendered == ~S(<p><a data-click="clicked">Click me</a></p>)
  end

  test "inline html with interpolation" do
    rendered = ~S"""
    p
      <a data-click=#{action}>Click me</a>
    """ |> phoenix_html_render(action: "clicked")

    assert rendered == ~S(<p><a data-click="clicked">Click me</a></p>)
  end

  test "verbatim text with inline html and interpolation" do
    rendered = ~S"""
    | Hey,
       <a data-click="#{action}">Click me</a>!
    """ |> phoenix_html_render(action: "clicked")

    assert rendered == ~s(Hey,\n <a data-click="clicked">Click me</a>!)
  end

  defp phoenix_html_render(slime, bindings) do
    slime
    |> Slime.Renderer.precompile
    |> EEx.eval_string(bindings, engine: Phoenix.HTML.Engine)
    |> Phoenix.HTML.safe_to_string
  end
end
