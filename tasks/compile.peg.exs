defmodule Mix.Tasks.Compile.Peg do
  @moduledoc """
  Compile peg template file into parser module
  """

  use Mix.Task
  require EEx

  @recursive true

  def run(_) do
    attr_list_delims = Application.get_env(
      :slime, :attr_list_delims, %{"[" => "]", "(" => ")", "{" => "}"}
    )
    grammar = EEx.eval_file("src/slime_parser.peg.eex", attr_list_delims: attr_list_delims)

    if contents_changed?("src/slime_parser.peg", grammar) do
      compile_grammar("src/slime_parser.peg", grammar)
    else
      :ok
    end
  end

  defp contents_changed?(file, expected) do
    case File.read(file) do
      {:ok, contents} ->
        contents != expected

      _ ->
        true
    end
  end

  defp compile_grammar(file, grammar) do
    File.write!(file, grammar)
    peg = file |> Path.expand |> String.to_charlist
    case :neotoma.file(peg, transform_module: :slime_parser_transform) do
      :ok -> :ok
      {:error, reason} ->
        Mix.shell.error "Failed to compile: #{inspect reason}"
        exit(:normal)
    end
  end
end
