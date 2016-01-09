defmodule Slime.Tree.HTMLNode do
  @moduledoc """
  An HTML node in the tree.
  """

  defstruct attributes: [],
            children: [],
            content: "",
            tag: nil,
            spaces: %{},
            close: false
end
