@testset "indices" begin
  # -------------
  # PARTITIONING
  # -------------
  t = georef((a=rand(100), b=rand(100)), CartesianGrid(10, 10))
  for method in [
    UniformPartition(2),
    FractionPartition(0.5),
    BlockPartition(2),
    BallPartition(2),
    BisectPointPartition(Vec(1, 1), Point(5, 5)),
    BisectFractionPartition(Vec(1, 1)),
    PlanePartition(Vec(1, 1)),
    DirectionPartition(Vec(1, 1)),
    IndexPredicatePartition((i, j) -> iseven(i + j)),
    PointPredicatePartition((pᵢ, pⱼ) -> norm(to(x) + to(y)) < 5u"m"),
    ProductPartition(UniformPartition(2), UniformPartition(2)),
    HierarchicalPartition(UniformPartition(2), UniformPartition(2))
  ]
    Π = partition(t, method)
    inds = reduce(vcat, indices(Π))
    @test sort(inds) == 1:100
  end

  # ---------
  # SAMPLING
  # ---------
  t = georef((z=rand(50, 50),))
  s = sample(t, UniformSampling(100))
  @test nrow(s) == 100

  # --------
  # SORTING
  # --------
  t = georef((z=rand(50, 50),))
  s = sort(t, DirectionSort((1.0, 0.0)))
  @test nrow(s) == nrow(t)
end
