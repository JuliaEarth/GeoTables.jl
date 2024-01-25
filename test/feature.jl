@testset "Feature transforms" begin
  # transforms that are revertible
  d = georef((z=rand(100), w=rand(100)))
  for p in [
    Select(:z),
    Reject(:z),
    Satisfies(x -> true),
    Rename(:z => :a),
    StdNames(),
    StdFeats(),
    Sort(:z),
    Sample(10),
    Filter(x -> true),
    DropMissing(),
    DropExtrema(:z),
    Map(:z => identity),
    Replace(1.0 => 2.0),
    Coalesce(value=0.0),
    Coerce(:z => Continuous),
    Indicator(:z),
    Identity(),
    Center(),
    LowHigh(),
    MinMax(),
    Interquartile(),
    ZScore(),
    Quantile(),
    Functional(exp),
    EigenAnalysis(:V),
    PCA(),
    DRS(),
    SDS(),
    RowTable(),
    ColTable()
  ]
    n, c = apply(p, d)
    @test n isa AbstractGeoTable
    if isrevertible(p)
      r = revert(p, n, c)
      @test r isa AbstractGeoTable
    end
  end

  # transforms with categorical variables
  d = georef((c=categorical([1, 2, 3]),))
  for p in [Levels(:c => [1, 2, 3]), OneHot(:c)]
    n, c = apply(p, d)
    r = revert(p, n, c)
    @test n isa AbstractGeoTable
    @test r isa AbstractGeoTable
  end

  d = georef((z=rand(100), w=rand(100)))
  p = Select(:w)
  n, c = apply(p, d)
  @test propertynames(n) == [:w, :geometry]

  d = georef((z=rand(100), w=rand(100)))
  p = Sample(100)
  n, c = apply(p, d)
  @test propertynames(n) == [:z, :w, :geometry]

  d = georef((a=[1, missing, 3], b=[3, 2, 1]))
  p = DropMissing()
  n, c = apply(p, d)
  @test n.a == [1, 3]
  @test n.b == [3, 1]
  @test nelements(domain(n)) == 2

  # performance tests
  sz = (100, 100)
  n = prod(sz)
  rng = MersenneTwister(2)

  a = rand(rng, n)
  b = shuffle(rng, [fill(missing, 100); rand(rng, n - 100)])
  coda = CoDaArray((c=rand(rng, n), d=rand(rng, n), e=rand(rng, n)))
  gtb = georef((; a, b, coda), CartesianGrid(sz))

  T1 = Sort(:a)
  T2 = Filter(row -> row.a > 0.5)
  T3 = DropMissing(:b)
  T4 = DropExtrema(:a)
  T5 = Sample(1000; rng)
  apply(T1, gtb)
  @test @elapsed(apply(T1, gtb)) < 0.2
  apply(T2, gtb)
  @test @elapsed(apply(T2, gtb)) < 0.2
  apply(T3, gtb)
  @test @elapsed(apply(T3, gtb)) < 0.2
  apply(T4, gtb)
  @test @elapsed(apply(T4, gtb)) < 0.2
  apply(T5, gtb)
  @test @elapsed(apply(T5, gtb)) < 0.2
end
