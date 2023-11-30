@testset "Geometric transforms" begin
  d = georef((z=rand(100), w=rand(100)))
  p = StdCoords()
  n, c = apply(p, d)
  dom = domain(n)
  cen = centroid.(dom)
  xs = first.(coordinates.(cen))
  @test dom isa CartesianGrid
  @test all(x -> -0.5 ≤ x ≤ 0.5, xs)
end
