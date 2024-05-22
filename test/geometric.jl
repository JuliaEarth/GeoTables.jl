@testset "Geometric transforms" begin
  d = georef((z=rand(100), w=rand(100)))
  p = StdCoords()
  n, c = apply(p, d)
  dom = domain(n)
  cen = centroid.(dom)
  xs = first.(to.(cen))
  @test dom isa CartesianGrid
  @test all(x -> -0.5u"m" ≤ x ≤ 0.5u"m", xs)
end
