defmodule DialyzerChecks.Attributes do
  @moduledoc false
  require Slime

  slime = ~S"""
  div data-content=true
  """
  Slime.function_from_string :def, :render_true, slime, []

  slime = ~S"""
  div data-content=("ss" <> "dd")
  """
  Slime.function_from_string :def, :render_concatination, slime, []

  slime = ~S"""
  div data-content="test interpolation #{3}"
  """
  Slime.function_from_string :def, :render_interpolation, slime, []

  slime = ~S"""
  div data-content=Enum.join(["ss", "dd"], " ")
  """
  Slime.function_from_string :def, :render_always_binary, slime, []

  @spec test() :: true
  defp test, do: true

  slime = ~S"""
  div data-content=test()
  """
  Slime.function_from_string :def, :render_always_true, slime, []
end
