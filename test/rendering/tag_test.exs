defmodule TagTest do
  use ExUnit.Case, async: true

  import Slime, only: [render: 1]

  test "dashed-strings can be used as tags" do
    assert render(~s(my-component text)) == ~s(<my-component>text</my-component>)
  end
end
