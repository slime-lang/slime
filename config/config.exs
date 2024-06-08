import Config

config :slime, :attr_list_delims, %{"[" => "]", "(" => ")"}

config :slime, :embedded_engines, %{
  test_engine: RenderEmbeddedEngineTest.TestEngine
}
