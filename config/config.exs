use Mix.Config

config :slime, :keep_lines, false

config :dogma,
  rule_set: Dogma.RuleSet.All,

  exclude: [
    # Ignore doctype module as it contains v long string literals
    ~r(\Alib/slime/doctype.ex\z),
  ],

  override: %{
    LineLength    => [ max_length: 120 ], # TODO: Lower me
    FunctionArity => [ max: 5 ],
  }

if Mix.env == :test do
  config :slime, :attr_list_delims, %{"[" => "]", "(" => ")"}
  config :slime, :embedded_engines, %{
    test_engine: RenderEmbeddedEngineTest.TestEngine
  }
end
