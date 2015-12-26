defmodule EExComparisonBench do
  use Benchfella
  require SlimFast

  SlimFast.function_from_string :def, :slim_fast, """
  - site_title = "Hello, world!"
  doctype html
  html
    head
      meta name="keywords" description="slim fast"
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
    <meta name="keywords">
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

  bench "SlimFast" do
    slim_fast()
  end

  bench "EEx" do
    eex()
  end
end
