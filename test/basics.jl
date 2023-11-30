@testset "Basics" begin
  for (dummy, Dummy) in [(dummygeoref, DummyGeoTable), (georef, GeoTable)]
    # fallback constructor with spatial table
    dom = CartesianGrid(2, 2)
    tab = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), dom)
    dat = Dummy(tab)
    @test domain(dat) == domain(tab)
    @test values(dat) == values(tab)

    # equality of data sets
    data₁ = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), CartesianGrid(2, 2))
    data₂ = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), CartesianGrid(2, 2))
    data₃ = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), PointSet(rand(Point2, 4)))
    @test data₁ == data₂
    @test data₁ != data₃
    @test data₂ != data₃

    # equality with missing data
    data₁ = dummy((a=[1, missing, 3], b=[3, 2, 1]), PointSet([1 2 3; 4 5 6]))
    data₂ = dummy((a=[1, missing, 3], b=[3, 2, 1]), PointSet([1 2 3; 4 5 6]))
    @test data₁ == data₂

    # Tables interface
    dom = CartesianGrid(2, 2)
    dat = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), dom)
    @test Tables.istable(dat)
    sch = Tables.schema(dat)
    @test sch.names == (:a, :b, :geometry)
    @test sch.types == (Int, Int, Quadrangle{2,Float64})
    @test Tables.rowaccess(dat)
    rows = Tables.rows(dat)
    @test Tables.schema(rows) == sch
    @test collect(rows) == [
      (a=1, b=5, geometry=dom[1]),
      (a=2, b=6, geometry=dom[2]),
      (a=3, b=7, geometry=dom[3]),
      (a=4, b=8, geometry=dom[4])
    ]
    @test collect(Tables.columns(dat)) == [[1, 2, 3, 4], [5, 6, 7, 8], [dom[1], dom[2], dom[3], dom[4]]]
    @test Tables.materializer(dat) <: Dummy
    inds = [1, 3]
    @test Tables.subset(dat, inds) == view(dat, inds)
    @test Tables.subset(dat, 1) == (a=1, b=5, geometry=Quadrangle((0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)))
    # viewhint keyword argument is ignored
    @test Tables.subset(dat, inds, viewhint=true) isa GeoTables.SubGeoTable
    @test Tables.subset(dat, inds, viewhint=false) isa GeoTables.SubGeoTable
    @test Tables.subset(dat, 1, viewhint=true) isa NamedTuple
    @test Tables.subset(dat, 1, viewhint=false) isa NamedTuple

    # dataframe interface
    grid = CartesianGrid(2, 2)
    data = dummy((a=[1, 2, 3, 4], b=[5, missing, 7, 8]), grid)
    @test propertynames(data) == [:a, :b, :geometry]
    @test names(data) == ["a", "b", "geometry"]
    @test isequal(data.a, [1, 2, 3, 4])
    @test isequal(data.b, [5, missing, 7, 8])
    @test data.geometry == grid
    @test_throws ErrorException data.c
    for (a, b, geometry) in [(:a, :b, :geometry), ("a", "b", "geometry")]
      @test data[1:2, [a, b]] == dummy((a=[1, 2], b=[5, missing]), view(grid, 1:2))
      @test data[1:2, [a, b, geometry]] == dummy((a=[1, 2], b=[5, missing]), view(grid, 1:2))
      @test isequal(data[1:2, a], [1, 2])
      @test isequal(data[1:2, b], [5, missing])
      @test isequal(data[1:2, geometry], view(grid, 1:2))
      @test data[1:2, :] == dummy((a=[1, 2], b=[5, missing]), view(grid, 1:2))
      @test isequal(data[1, [a, b]], (a=1, b=5, geometry=grid[1]))
      @test isequal(data[1, [a, b, geometry]], (a=1, b=5, geometry=grid[1]))
      @test isequal(data[1, a], 1)
      @test isequal(data[1, b], 5)
      @test isequal(data[1, geometry], grid[1])
      @test isequal(data[1, :], (a=1, b=5, geometry=grid[1]))
      @test data[:, [a, b]] == data
      @test data[:, [a, b, geometry]] == data
      @test isequal(data[:, a], [1, 2, 3, 4])
      @test isequal(data[:, b], [5, missing, 7, 8])
      @test isequal(data[:, geometry], grid)
    end
    # regex
    @test data[3, r"a"] == (a=3, geometry=grid[3])
    @test data[3:4, r"b"] == dummy((b=[7, 8],), view(grid, 3:4))
    @test data[:, r"[ab]"] == data
    # colon with colon
    @test data[:, :] == data
    # geometries
    a = rand(100)
    b = rand(100)
    grid = CartesianGrid(10, 10)
    linds = LinearIndices(size(grid))
    gtb = dummy((; a, b), grid)
    tri = Triangle((1.5, 1.5), (4.5, 4.5), (7.5, 1.5))
    sub = gtb[tri, :]
    @test gtb[linds[4, 3], :a] ∈ sub.a
    @test gtb[linds[5, 3], :a] ∈ sub.a
    @test gtb[linds[6, 3], :a] ∈ sub.a
    @test gtb[linds[4, 3], :b] ∈ sub.b
    @test gtb[linds[5, 3], :b] ∈ sub.b
    @test gtb[linds[6, 3], :b] ∈ sub.b
    @test first(gtb[Point(1, 1), :a]) == gtb[linds[1, 1], :a]
    @test first(gtb[Point(1, 1), "a"]) == gtb[linds[1, 1], :a]
    @test first(gtb[Point(1, 1), [:a]].a) == gtb[linds[1, 1], :a]
    @test first(gtb[Point(1, 1), ["a"]].a) == gtb[linds[1, 1], :a]
    @test first(gtb[Point(1, 1), r"a"].a) == gtb[linds[1, 1], :a]

    # hcat
    dom = PointSet(rand(Point2, 10))
    data₁ = dummy((a=rand(10), b=rand(10)), dom)
    data₂ = dummy((c=rand(10), d=rand(10)), dom)
    data₃ = dummy((e=rand(10), f=rand(10)), dom)
    @test hcat(data₁) == data₁
    hdata = hcat(data₁, data₂)
    @test hdata.a == data₁.a
    @test hdata.b == data₁.b
    @test hdata.c == data₂.c
    @test hdata.d == data₂.d
    @test hdata.geometry == dom
    hdata = hcat(data₁, data₂, data₃)
    @test hdata.a == data₁.a
    @test hdata.b == data₁.b
    @test hdata.c == data₂.c
    @test hdata.d == data₂.d
    @test hdata.e == data₃.e
    @test hdata.f == data₃.f
    @test hdata.geometry == dom
    # maintain column types
    data₁ = dummy((; a=rand(10)), dom)
    data₂ = dummy((; b=rand(1:10, 10)), dom)
    hdata = hcat(data₁, data₂)
    @test eltype(hdata.a) === Float64
    @test eltype(hdata.b) === Int
    # throws
    data₁ = dummy((a=rand(10), b=rand(10)), dom)
    data₂ = dummy((a=rand(10), c=rand(10)), dom)
    @test_throws ArgumentError hcat(data₁, data₂)
    data₁ = dummy((a=rand(10), b=rand(10)), PointSet(rand(Point2, 10)))
    data₂ = dummy((a=rand(10), b=rand(10)), PointSet(rand(Point2, 10)))
    @test_throws ArgumentError hcat(data₁, data₂)

    # vcat
    data₁ = dummy((a=rand(10), b=rand(10)), PointSet(rand(Point2, 10)))
    data₂ = dummy((a=rand(10), b=rand(10)), PointSet(rand(Point2, 10)))
    data₃ = dummy((a=rand(10), b=rand(10)), PointSet(rand(Point2, 10)))
    @test vcat(data₁) == data₁
    vdata = vcat(data₁, data₂)
    @test vdata.a == [data₁.a; data₂.a]
    @test vdata.b == [data₁.b; data₂.b]
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])
    vdata = vcat(data₁, data₂, data₃)
    @test vdata.a == [data₁.a; data₂.a; data₃.a]
    @test vdata.b == [data₁.b; data₂.b; data₃.b]
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry); collect(data₃.geometry)])
    # throws
    data₁ = dummy((a=rand(10), b=rand(10)), PointSet(rand(Point2, 10)))
    data₂ = dummy((a=rand(10), c=rand(10)), PointSet(rand(Point2, 10)))
    @test_throws ArgumentError vcat(data₁, data₂)

    # variables interface
    data = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), PointSet(rand(Point2, 4)))
    @test asarray(data, :a) == asarray(data, "a") == [1, 2, 3, 4]
    @test asarray(data, :b) == asarray(data, "b") == [5, 6, 7, 8]
    data = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), CartesianGrid(2, 2))
    @test asarray(data, :a) == asarray(data, "a") == [1 3; 2 4]
    @test asarray(data, :b) == asarray(data, "b") == [5 7; 6 8]
  end
end