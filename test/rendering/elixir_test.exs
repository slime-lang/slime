defmodule RenderElixirTest do
  use ExUnit.Case, async: true
  use SlimFast.Renderer
  import ExUnit.CaptureIO, only: [capture_io: 1]

  test "- evalutes Elixir but does not insert the result" do
    slim = """
    - IO.puts "Hello"
    - _ = "Hi"
    """
    captured = capture_io fn ->
      assert render(slim) == ""
    end
    assert captured == "Hello\n"
  end

  test "= evalutes Elixir and inserts the result" do
    slim = """
    = 1 + 1
    """
    assert render(slim) == "2"
  end

  test "if/else can be used in templates" do
    slim = """
    = if meta do
      h1 Hello!
    - else
      h2 Goodbye!
    """
    assert precompile(slim) == ~s(<%= if meta do %><h1>Hello!</h1><% else %><h2>Goodbye!</h2><% end %>)
    assert render(slim, meta: true)  == ~s(<h1>Hello!</h1>)
    assert render(slim, meta: false) == ~s(<h2>Goodbye!</h2>)
  end

  test "unless/else can be used in templates" do
    slim = """
    = unless meta do
      h1 Hello!
    - else
      h2 Goodbye!
    """
    assert precompile(slim) == ~s(<%= unless meta do %><h1>Hello!</h1><% else %><h2>Goodbye!</h2><% end %>)
    assert render(slim, meta: true) == ~s(<h2>Goodbye!</h2>)
    assert render(slim, meta: false)  == ~s(<h1>Hello!</h1>)
  end
end
