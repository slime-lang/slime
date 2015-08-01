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

  defp render_branch(%Branch{type: type} = branch, ident) do
    opening = branch
              |> Map.take([:css, :id])
              |> Enum.map(fn {k, v} -> render_attribute(k, v) end)
              |> Enum.join(" ")
              |> render_open(type)

    closing = render_close(type)

    opening <> render(branch.children, next_indent(ident)) <> closing
  end

  defp render_open(_attrs, :p), do: "<p>"
  defp render_open(attrs, tag) do
    tag = String.rstrip("#{tag} #{attrs}")
    "<#{tag}>\n"
  end

  defp render_close(tag), do: "</#{tag}>\n"

  defp next_indent(indent), do: indent <> "  "
end
