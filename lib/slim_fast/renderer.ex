defmodule SlimFast.Renderer do
  alias SlimFast.Tree.Branch

  @self_closing [:area, :br, :col, :doctype, :embed, :hr, :img, :input, :link, :meta]

  def render(tree) do
    tree
    |> Enum.map(fn branch -> render_branch(branch) end)
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

  defp render_branch(%Branch{type: :doctype, content: text}), do: text
  defp render_branch(%Branch{type: :text, content: text}), do: text
  defp render_branch(%Branch{type: type} = branch) do
    opening = branch.attributes
              |> Enum.map(fn {k, v} -> render_attribute(k, v) end)
              |> Enum.join(" ")
              |> render_open(branch)

    closing = render_close(branch)
    opening <> render(branch.children) <> closing
  end

  defp render_open(_, %Branch{type: :eex, content: code, attributes: attrs}) do
    inline = if attrs[:inline], do: "=", else: ""
    "<%#{inline} #{code} %>"
  end

  defp render_open(attrs, %Branch{type: type, children: children}) do
    type = String.rstrip("#{type} #{attrs}")
    "<#{type}>"
  end

  defp render_close(%Branch{type: type}) when type in @self_closing, do: ""
  defp render_close(%Branch{type: :eex, content: code}) do
    cond do
      Regex.match? ~r/(fn.*->|do:?)/, code -> "<% end %>"
      true -> ""
    end
  end
  defp render_close(%Branch{type: type}), do: "</#{type}>"
end
