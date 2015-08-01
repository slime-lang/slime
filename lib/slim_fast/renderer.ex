defmodule SlimFast.Renderer do
  alias SlimFast.Tree.Branch

  def render(tree, indent \\ "") do
    tree
    |> Enum.map(fn branch -> render_branch(branch, indent) end)
    |> Enum.join("\n")
  end

  defp render_attribute(:css, []), do: ""
  defp render_attribute(:css, classes) do
    classes = Enum.join(classes, " ")
    "class=\"#{classes}\""
  end

  defp render_attribute(:id, nil), do: ""
  defp render_attribute(:id, id), do: "id=\"#{id}\""

  defp render_branch(%Branch{type: :text, content: text}, _ident) do
    text
  end

  defp render_branch(branch, ident) do
    attrs = branch
            |> Map.take([:css, :id])
            |> Enum.map(fn {k, v} -> render_attribute(k, v) end)
            |> Enum.join(" ")

    opening = String.rstrip("#{branch.type} #{attrs}")
    "<#{opening}>\n"
      <> render(branch.children, next_indent(ident))
      <> "\n</#{branch.type}>"
  end

  defp next_indent(indent), do: indent <> "  "
end
