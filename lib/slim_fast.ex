defmodule SlimFast do
  use SlimFast.Renderer

  defmacro __using__([]) do
    quote do
      import unquote __MODULE__

      use SlimFast.Renderer
    end
  end

  @doc """
  Generates a function definition from the file contents.
  The kind (`:def` or `:defp`) must be given, the
  function name, its arguments and the compilation options.
  This function is useful in case you have templates but
  you want to precompile inside a module for speed.
  ## Examples
      # sample.slim
      = a + b
      # sample.ex
      defmodule Sample do
        require SlimFast
        SlimFast.function_from_file :def, :sample, "sample.slim", [:a, :b]
      end
      # iex
      Sample.sample(1, 2) #=> "3\n"
  """
  defmacro function_from_file(kind, name, file, args \\ [], options \\ []) do
    quote bind_quoted: binding do
      require EEx
      eex = file |> File.read! |> SlimFast.Renderer.precompile
      EEx.function_from_string(kind, name, eex, args, options)
    end
  end

  @doc """
  Generates a function definition from the string.
  The kind (`:def` or `:defp`) must be given, the
  function name, its arguments and the compilation options.
  ## Examples
      iex> defmodule Sample do
      ...>   require SlimFast
      ...>   SlimFast.function_from_string :def, :sample, "= a + b", [:a, :b]
      ...> end
      iex> Sample.sample(1, 2)
      "3\\n"
  """
  defmacro function_from_string(kind, name, source, args \\ [], options \\ []) do
    quote bind_quoted: binding do
      require EEx
      eex = source |> SlimFast.Renderer.precompile
      EEx.function_from_string(kind, name, eex, args, options)
    end
  end
end
