defmodule RenderInlineHTMLTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1, render: 2]

  @inline_slime ~S"""
  <html>
    head
      title Example
    <body>
      table
        = for a <- articles do
          <tr><td>#{a.name}</td><td>#{a.desc}</td></tr>
    </body>
  </html>
  """

  @inline_html """
  <html>
  <head>
  <title>Example</title>
  </head>
  <body>
  <table>
  <tr><td>Art 1</td><td>Desc 1</td></tr><tr><td>Art 2</td><td>Desc 2</td></tr>
  </table>
  </body>
  </html>
  """ |> String.replace("\n", "")

  test "render inline html with for loop" do
    articles = [%{name: "Art 1", desc: "Desc 1"}, %{name: "Art 2", desc: "Desc 2"}]
    assert render(@inline_slime, articles: articles) == @inline_html
  end

  test "render inline html" do
    assert render(~S(<h3>Text</h3>)) == "<h3>Text</h3>"
  end

  test "render inline html with interpolation" do
    assert render(~S(<h3>Text" #{val}</h3>), val: "test") == ~S[<h3>Text" test</h3>]
  end

  test "render quote inline html with interpolation" do
    assert render(~S(<h3>Text""" #{"elixir_string"} "</h3>)) == ~s[<h3>Text""" elixir_string "</h3>]
  end
end
