defmodule RendererTest do
  use ExUnit.Case, async: true
  doctest Slime.Renderer

  import Slime, only: [render: 1, render: 2]

  @slime """
  doctype html
  html
    head
      meta name="keywords" description="slime"
      title = site_title
    body
      #id.class
        ul
          = Enum.map [1, 2], fn x ->
            li = x
  """

  @html """
  <!DOCTYPE html><html>
  <head>
  <meta description="slime" name="keywords">
  <title>Website Title</title>
  </head>
  <body>
  <div class="class" id="id">
  <ul><li>1</li><li>2</li></ul></div>
  </body>
  </html>
  """ |> String.replace("\n", "")

  @eex """
  <!DOCTYPE html>
  <html>
  <head>
  <meta description="slime" name="keywords">
  <title><%= site_title %></title>
  </head>
  <body>
  <div class="class" id="id">
  <ul><%= Enum.map [1, 2], fn x -> %><li><%= x %></li><% end %></ul>
  </div>
  </body>
  </html>
  """ |> String.replace("\n", "")

  test "precompiles eex template" do
    assert Slime.Renderer.precompile(@slime) == @eex
  end

  test "render html" do
    assert render(@slime, site_title: "Website Title") == @html
  end

  test "doctype" do
    assert render("doctype html") == "<!DOCTYPE html>"
  end

  test "empty input" do
    assert render("") == ""
  end

  test "blank lines" do
    slime = "p\n  \n  | test\n  | test"
    assert render(slime) == "<p>testtest</p>"
  end

  test "skip trailing blank lines" do
    slime = """
    p
      | Hello World

    """
    assert render(slime) == "<p>Hello World</p>"
  end

  test "blank lines after if-else" do
    slime = """
    p
      s
        = if a > 1 do
          = 1
        - else
          = 2
        \np
    """
    assert render(slime, a: 2) == "<p><s>1</s></p><p></p>"
  end

  test "CRLF line endings are converted to LF" do
    assert render("h1\r\n\th2\r\n\t\th3 Hi\r\n") == "<h1><h2><h3>Hi</h3></h2></h1>"
  end

  test "CRLF line endings corner case" do
    example_unix = """
    html
      head
        meta

      body
    """
    example_windows = example_unix |> String.replace("\n", "\r\n")

    assert Slime.Renderer.precompile(example_unix) == Slime.Renderer.precompile(example_windows)
    assert render(example_unix) == render(example_unix)
  end
end
