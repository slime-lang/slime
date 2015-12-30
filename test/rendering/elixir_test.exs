defmodule RenderElixirTest do
  use ExUnit.Case, async: true
  use Slime.Renderer
  import ExUnit.CaptureIO, only: [capture_io: 1]

  test "- evalutes Elixir but does not insert the result" do
    slime = """
    - IO.puts "Hello"
    - _ = "Hi"
    """
    captured = capture_io fn ->
      assert render(slime) == ""
    end
    assert captured == "Hello\n"
  end

  test "= evalutes Elixir and inserts the result" do
    slime = """
    = 1 + 1
    """
    assert render(slime) == "2"
  end

  test "= can be used inside an element (space before)" do
    slime = """
    div = 1 + 1
    """
    assert render(slime) == "<div>2</div>"
  end

  test "= can be used inside an element (no space before)" do
    slime = """
    div= 1 + 1
    """
    assert render(slime) == "<div>2</div>"
  end

  test "if/else can be used in templates" do
    slime = """
    = if meta do
      h1 Hello!
    - else
      h2 Goodbye!
    """
    assert precompile(slime) == ~s(<%= if meta do %><h1>Hello!</h1><% else %><h2>Goodbye!</h2><% end %>)
    assert render(slime, meta: true)  == ~s(<h1>Hello!</h1>)
    assert render(slime, meta: false) == ~s(<h2>Goodbye!</h2>)
  end

  test "unless/else can be used in templates" do
    slime = """
    = unless meta do
      h1 Hello!
    - else
      h2 Goodbye!
    """
    assert precompile(slime) == ~s(<%= unless meta do %><h1>Hello!</h1><% else %><h2>Goodbye!</h2><% end %>)
    assert render(slime, meta: true) == ~s(<h2>Goodbye!</h2>)
    assert render(slime, meta: false)  == ~s(<h1>Hello!</h1>)
  end

  test "render lines with 'do'" do
    defmodule RenderHelperMethodWithDoInArguments do
      require Slime

      def number_input(_, _, _) do
        "ok"
      end

      @slim ~s(= number_input f, :amount, class: "js-donation-amount")
      Slime.function_from_string(:def, :render, @slim, [:f])
    end

    assert RenderHelperMethodWithDoInArguments.render(nil) == "ok"
  end
end
