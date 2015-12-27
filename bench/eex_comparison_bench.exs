defmodule EExComparisonBench do
  use Benchfella
  require Slime

  Slime.function_from_string :def, :slime, """
  - site_title = "Hello, world!"
  doctype html
  html
    head
      meta name="keywords" description="Slime"
      title = site_title
    body
      #id.class
        ul
          = for x <- [1, 2] do
            li = x
  """

  EEx.function_from_string :def, :eex, """
  <% site_title = "Hello, world!" %>
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="keywords" description="Slime">
    <title><%= site_title %></title>
  </head>

  <body>
    <div class="class" id="id">
      <ul>
      <%= for x <- [1, 2] do %>
        <li><%= x %></li>
      <% end %>
      </ul>
    </div>
  </body>
  </html>
  """

  bench "Slime" do
    slime()
  end

  bench "EEx" do
    eex()
  end
end
