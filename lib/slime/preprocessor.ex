defmodule Slime.Preprocessor do
  @moduledoc """
  In order to make parsing Slime documents easier we run some simple
  transformations on the document to standardise the format.
  """

  @tabsize 2
  @soft_tab String.duplicate(" ", @tabsize)

  def process(document) do
    document
    |> expand_tabs
    |> remove_trailing_newlines
    |> convert_crlf_to_lf
    |> split_into_lines
  end

  defp expand_tabs(document) do
    String.replace(document, ~r/\t/m, @soft_tab)
  end

  defp remove_trailing_newlines(document) do
    String.replace(document, ~r/\n+\z/m, "")
  end

  defp split_into_lines(document) do
    String.split(document, "\n")
  end
  
  defp convert_crlf_to_lf(document) do
    String.replace(document, ~r/\r/, "")
  end
end
