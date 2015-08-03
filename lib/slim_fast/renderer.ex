defmodule SlimFast.Renderer do
  alias SlimFast.Tree.Branch

  @self_closing [:area, :br, :col, :doctype, :embed, :hr, :img, :input, :link, :meta]

  def render(tree, indent \\ "") do
    tree
    |> Enum.map(fn branch -> render_branch(branch, indent) end)
    |> Enum.join
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

  defp render_branch(%Branch{type: :doctype, content: text}, _ident), do: text <> "\n"
  defp render_branch(%Branch{type: :text, content: text}, ident), do: ident <> text <> "\n"
  defp render_branch(%Branch{type: type} = branch, indent) do
    opening = branch.attributes
              |> Enum.map(fn {k, v} -> render_attribute(k, v) end)
              |> Enum.join(" ")
              |> render_open(type, branch, indent)

    closing = render_close(type, indent)
    indent = next_indent(indent)
    opening <> render(branch.children, indent) <> closing
  end

  defp render_open(_, :eex, %Branch{content: code, attributes: attrs}, indent) do
    inline = if attrs[:inline], do: "=", else: ""
    "#{indent}<%#{inline} #{code} %>\n"
  end

  defp render_open(attrs, tag, %Branch{children: children}, indent) do
    tag = String.rstrip("#{tag} #{attrs}")
    newline = if length(children) > 0, do: "\n", else: ""
    "#{indent}<#{tag}>#{newline}"
  end

  defp render_close(:eex, _), do: ""
  defp render_close(tag, _) when tag in @self_closing, do: "\n"
  defp render_close(tag, indent), do: "#{indent}</#{tag}>\n"

  defp next_indent(indent), do: indent <> "  "
end
