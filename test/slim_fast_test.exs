defmodule SlimFastTest do
  use ExUnit.Case, async: true

  @slim """
  doctype html
  html
    head
      meta name="keywords" description="slim fast"
      title = site_title
    body
      #id.class
        p
        - if true do
          | Hello World
        - else
          | Goodbye
        - end
  """

  @htmleex """
  <!DOCTYPE html>
  <html>
    <head>
      <meta description="slim fast" name="keywords">
      <title>
        <%= site_title %>
      </title>
    </head>
    <body>
      <div class="class" id="id">
        <p>
          <% if true do %>
            Hello World
          <% else %>
            Goodbye
          <% end %>
        </p>
      </div>
    </body>
  </html>
  """

  test "render html" do
    assert SlimFast.evaluate(@slim) == @htmleex
  end
end
