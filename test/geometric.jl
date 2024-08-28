@testset "Geometric transforms" begin
  d = georef((z=rand(100), w=rand(100)))
  p = StdCoords()
  n, c = apply(p, d)
  dom = domain(n)
  cen = centroid.(dom)
  xs = first.(to.(cen))
  @test dom isa CartesianGrid
  @test all(x -> -0.5u"m" ≤ x ≤ 0.5u"m", xs)

  pset = PointSet([Point(1, 0), Point(2, 1), Point(3, 1), Point(4, 0)])
  d = georef((; a=[1, 2, 3, 4]), pset)
  p = Crop(x=(1.5, 3.5))
  n, c = apply(p, d)
  @test n.geometry == PointSet([Point(2, 1), Point(3, 1)])
  @test n.a == [2, 3]
end
