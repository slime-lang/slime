defmodule SlimFast.Renderer do
  alias SlimFast.Tree.Branch

  def render(tree, indent \\ "") do
    tree
    |> Enum.map(fn branch -> render_branch(branch, indent) end)
    |> Enum.join("")
  end

  defp render_attribute(_, []), do: ""
  defp render_attribute(_, ""), do: ""
  defp render_attribute(name, value) do
    value = cond do
              is_binary(value) ->
                "\"" <> value <> "\""
              is_list(value) ->
                "\"" <> Enum.join(value, " ") <> "\""
              is_tuple(value) ->
                {_, attrs} = value
                "<%=" <> attrs[:content] <> "%>"
              true -> to_string(value)
            end

    to_string(name) <> "=" <> value
  end

  defp render_branch(%Branch{type: :text, content: text}, _ident), do: text
  defp render_branch(%Branch{type: type, children: children} = branch, ident) do
    opening = branch.attributes
              |> Enum.map(fn {k, v} -> render_attribute(k, v) end)
              |> Enum.join(" ")
              |> render_open(type, children)

    closing = render_close(type)

    opening <> render(branch.children, next_indent(ident)) <> closing
  end

  defp render_open(_, :br, _), do: "<br>"
  defp render_open(_, :p, _), do: "<p>"
  defp render_open(attrs, tag, children) do
    tag = String.rstrip("#{tag} #{attrs}")
    newline = if length(children) > 0, do: "\n", else: ""
    "<#{tag}>#{newline}"
  end

  defp render_open(:br), do: ""
  defp render_close(tag), do: "</#{tag}>\n"

  defp next_indent(indent), do: indent <> "  "
end
