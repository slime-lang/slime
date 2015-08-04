defmodule SlimFast do
  use SlimFast.Renderer

  defmacro __using__([]) do
    quote do
      import unquote __MODULE__

      use SlimFast.Renderer
    end
  end
end
