defmodule SlimFast.Tree do
  defmodule Branch do
    defstruct children: [], content: "", css: [], id: nil, type: nil
  end

  def build_tree([]), do: []
  def build_tree([h|t]) do
    {indentation, {type, attrs}} = h

    existing = Keyword.get(attrs, :children, [])
               |> Enum.map(&to_branch/1)

    {children, rem} = Enum.split_while t, fn {ident, {tag, _}} -> ident > indentation or tag == :text end
    attrs = Keyword.put(attrs, :children, existing ++ build_tree(children))

    [to_branch({type, attrs})|build_tree(rem)]
  end

  defp to_branch({type, attrs}) do
    [type: type] ++ attrs
    |> Enum.reduce(%Branch{}, fn({k, v}, branch) -> Map.put(branch, k, v) end)
  end
end
