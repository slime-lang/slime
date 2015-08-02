defmodule SlimFast.Tree do
  defmodule Branch do
    defstruct attributes: [], children: [], content: "", type: nil
  end

  def build_tree([]), do: []
  def build_tree([{_, line}|t]) when is_binary(line) do
    [to_branch(line)|build_tree(t)]
  end

  def build_tree([h|t]) do
    {indentation, {type, attrs}} = h

    existing = Keyword.get(attrs, :children, [])
               |> Enum.map(&to_branch/1)

    cb = fn {indent, line} ->
            case line do
              {tag, _} -> indent > indentation
              _ -> true
            end
         end
    {children, rem} = Enum.split_while(t, cb)
    attrs = Keyword.put(attrs, :children, existing ++ build_tree(children))

    [to_branch({type, attrs})|build_tree(rem)]
  end

  defp to_branch(text) when is_binary(text), do: %Branch{type: :text, content: text}
  defp to_branch({type, attrs}) do
    [type: type] ++ attrs
    |> Enum.reduce(%Branch{}, fn({k, v}, branch) -> Map.put(branch, k, v) end)
  end

end
