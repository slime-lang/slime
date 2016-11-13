defmodule Mix.Tasks.Compile.Peg do
  use Mix.Task

  @recursive true

  def run(_) do
    peg = Path.expand("src/slime_parser.peg")
    case :neotoma.file('#{peg}', transform_module: :slime_parser_transform) do
      :ok -> :ok
      {:error, reason} ->
        Mix.shell.error "Failed to compile: #{inspect reason}"
        exit(:normal)
    end
  end
end
