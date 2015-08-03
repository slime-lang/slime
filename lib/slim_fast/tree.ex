defmodule SlimFast.Tree do
  defmodule Branch do
    defstruct attributes: [], children: [], content: "", type: nil
  end

  def build_tree([]), do: []
  def build_tree([{_, line}|t]) when is_binary(line), do: [to_branch(line)|build_tree(t)]
  def build_tree([{_, {:doctype, _} = line}|t]), do: [to_branch(line)|build_tree(t)]
  def build_tree([{indentation, {tag, attrs}}|t]) do
    existing = Keyword.get(attrs, :children, [])
               |> Enum.map(&to_branch/1)

    filter = child_filter(tag, indentation)
    {children, rem} = Enum.split_while(t, filter)

    attrs = Keyword.put(attrs, :children, existing ++ build_tree(children))

    [to_branch({tag, attrs})|build_tree(rem)]
  end

  defp child_filter(:eex, parent) do
    fn
      {indent, _} -> indent > parent
      _ -> true
    end
  end
  defp child_filter(_, parent) do
    fn
      {indent, {:eex, _}} -> indent >= parent
      {indent, _} -> indent > parent
      _ -> true
    end
  end

  defp to_branch(text) when is_binary(text), do: %Branch{type: :text, content: text}
  defp to_branch({:doctype, doc_string}), do: %Branch{type: :doctype, content: doc_string}
  defp to_branch({:eex, attrs}) do
    children = Keyword.get(attrs, :children, [])
    inline = Keyword.get(attrs, :inline, false)
    %Branch{type: :eex, attributes: [inline: inline], children: children, content: attrs[:content]}
  end
  defp to_branch({type, attrs}) do
    [type: type] ++ attrs
    |> Enum.reduce(%Branch{}, fn({k, v}, branch) -> Map.put(branch, k, v) end)
  end
end
