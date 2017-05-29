defmodule Integration.AppTest do
  use ExUnit.Case

  defmodule App1 do
    @moduledoc false
    def render do
      slime = """
      h1
        ' Hello,
        = name
        | !
      """
      Slime.render(slime, name: "world")
    end
  end

  test "Slime.render/2" do
    assert App1.render == "<h1>Hello, world!</h1>"
  end


  defmodule App2 do
    @moduledoc false
    require Slime

    slime = ~S"""
    h1 Not secret: #{word}
    """
    Slime.function_from_string :def, :public, slime, [:word]

    slime = """
    h1
      | Secret:
      =< word
    """
    Slime.function_from_string :defp, :priv, slime, [:word]

    def private(x), do: priv(x)
  end

  test "Slime.function_from_string/5 def" do
    assert App2.public("Hi!") == "<h1>Not secret: Hi!</h1>"
  end

  test "Slime.function_from_string/5 defp" do
    assert App2.private("Eep!") == "<h1>Secret: Eep!</h1>"
  end


  defmodule App3 do
    @moduledoc false
    require Slime

    file = "test/fixtures/app3_public.slime"
    Slime.function_from_file :def, :public, file, [:name]

    file = "test/fixtures/app3_private.slime"
    Slime.function_from_file :defp, :priv, file, [:n]

    def private(x), do: priv(x)
  end

  test "Slime.function_from_file/5 def" do
    assert App3.public("doc?") == "<div>What's up doc?</div>"
  end

  test "Slime.function_from_file/5 defp" do
    assert App3.private(1..3) == "123"
  end
end
