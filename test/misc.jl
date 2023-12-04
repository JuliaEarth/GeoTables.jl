@testset "Miscellaneous transforms" begin
  # compositional data
  d = georef((z=rand(1000), w=rand(1000)))
  n = d |> Closure()
  t = Tables.columns(n)
  @test n isa AbstractGeoTable
  @test Tables.columnnames(t) == (:z, :w, :geometry)

  n = d |> Remainder()
  t = Tables.columns(n)
  @test n isa AbstractGeoTable
  @test Tables.columnnames(t) == (:z, :w, :remainder, :geometry)

  n = d |> ALR()
  t = Tables.columns(n)
  @test n isa AbstractGeoTable
  @test Tables.columnnames(t) == (:ARL1, :geometry)

  n = d |> CLR()
  t = Tables.columns(n)
  @test n isa AbstractGeoTable
  @test Tables.columnnames(t) == (:CLR1, :CLR2, :geometry)

  n = d |> ILR()
  t = Tables.columns(n)
  @test n isa AbstractGeoTable
  @test Tables.columnnames(t) == (:ILR1, :geometry)

  # feature + geometric transform
  d = georef((z=rand(1000), w=rand(1000)))
  p = Quantile() → StdCoords()
  n, c = apply(p, d)
  r = revert(p, n, c)
  Xr = Tables.matrix(values(r))
  Xd = Tables.matrix(values(d))
  @test isapprox(Xr, Xd, atol=0.1)
end
