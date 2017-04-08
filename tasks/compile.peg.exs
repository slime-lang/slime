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
    File.write!("src/slime_parser.peg", grammar)
    peg = "src/slime_parser.peg" |> Path.expand |> String.to_charlist
    case :neotoma.file(peg, transform_module: :slime_parser_transform) do
      :ok -> :ok
      {:error, reason} ->
        Mix.shell.error "Failed to compile: #{inspect reason}"
        exit(:normal)
    end
  end
end
