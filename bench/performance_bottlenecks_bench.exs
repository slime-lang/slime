defmodule PerformanceBottlenecksBench do
  use Benchfella

  @slime ~S(h2 Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do #{"eiusmod"})
  bench "interpolation performance on long lines" do
    Slime.Parser.parse_line(@slime)
  end

  @slime """
  a.social__link.facebook itemprop="sameAs" href="http://www.facebook.com/test" title="Facebook" target="_blank"
  """
  bench "inline tag split performance on attributes with :" do
    Slime.Preprocessor.process(@slime)
  end
end
