@testset "Geometric transforms" begin
  d = georef((z=rand(100), w=rand(100)))
  p = StdCoords()
  n, c = apply(p, d)
  dom = domain(n)
  cen = centroid.(dom)
  xs = first.(to.(cen))
  @test dom isa CartesianGrid
  @test all(x -> -0.5u"m" ≤ x ≤ 0.5u"m", xs)

  g = CartesianGrid(4, 4)
  d = georef((; a=1:16), g)
  p = Slice(x=(1.5, 3.5))
  n, c = apply(p, d)
  @test n.geometry == CartesianGrid((1.0, 0.0), (4.0, 4.0), dims=(3, 4))
  @test n.a == [2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15, 16]
end
