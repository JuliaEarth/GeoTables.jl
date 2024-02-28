@testset "Basics" begin
  for (dummy, Dummy) in [(dummygeoref, DummyGeoTable), (georef, GeoTable)]
    # fallback constructor with spatial table
    dom = CartesianGrid(2, 2)
    tab = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), dom)
    dat = Dummy(tab)
    @test domain(dat) == domain(tab)
    @test values(dat) == values(tab)

    # mutability
    dom = CartesianGrid(10, 10)
    tab = (; a=rand(100))
    dat = dummy(tab, dom)
    # another domain
    newdom = convert(SimpleMesh, dom)
    dat.geometry = newdom
    @test dat.geometry isa SimpleMesh
    @test dat.geometry == newdom
    @test values(dat) == tab
    # vector of geometries
    pts = rand(Point2, 100)
    dat.geometry = pts
    @test dat.geometry isa PointSet
    @test dat.geometry == PointSet(pts)
    @test values(dat) == tab
    # error: only the "geometry" column can be set with this syntax currently
    @test_throws ErrorException dat.a = 1:100
    # error: only domains and vectors of geometries are supported as "geometry" column values
    @test_throws ErrorException dat.geometry = 1:100
    # error: the new domain must have the same number of elements as the geotable
    @test_throws ErrorException dat.geometry = rand(Point2, 10)

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

    # parent and parentindices
    dom = CartesianGrid(2, 2)
    dat = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), dom)
    @test parent(dat) === dat
    @test parentindices(dat) == 1:4
    # geotable with subdomain
    dom = CartesianGrid(3, 3)
    inds = [1, 3, 5, 7, 9]
    dat = dummy((a=[1, 2, 3, 4, 5], b=[6, 7, 8, 9, 10]), view(dom, inds))
    pdat = parent(dat)
    @test domain(pdat) == dom
    @test parentindices(dat) == inds
    @test isequal(pdat.a, [1, missing, 2, missing, 3, missing, 4, missing, 5])
    @test isequal(pdat.b, [6, missing, 7, missing, 8, missing, 9, missing, 10])
    dat = dummy(nothing, view(dom, inds))
    pdat = parent(dat)
    @test domain(pdat) == dom
    @test parentindices(dat) == inds
    @test isnothing(values(pdat))

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
      @test data[[true, true, false, false], [a, b]] == dummy((a=[1, 2], b=[5, missing]), view(grid, 1:2))
      @test data[[true, true, false, false], [a, b, geometry]] == dummy((a=[1, 2], b=[5, missing]), view(grid, 1:2))
      @test isequal(data[[true, true, false, false], a], [1, 2])
      @test isequal(data[[true, true, false, false], b], [5, missing])
      @test isequal(data[[true, true, false, false], geometry], view(grid, 1:2))
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

    # optimizations
    # colon with colon
    @test data[:, :] == data
    # inds with colon
    @test data[1:2, :] isa GeoTables.SubGeoTable

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

    # grid indexing
    a = rand(100)
    b = rand(100)
    grid = CartesianGrid(10, 10)
    linds = LinearIndices(size(grid))
    gtb = dummy((; a, b), grid)
    @test gtb[(1, 1), :a] == gtb[linds[1, 1], :a]
    @test gtb[(1:3, :), "a"] == gtb[vec(linds[1:3, :]), :a]
    @test gtb[(10, 10), [:b]] == gtb[linds[10, 10], [:b]]
    @test gtb[(1:3, :), ["b"]] == gtb[vec(linds[1:3, :]), [:b]]
    @test domain(gtb[(1:3, :), :]) isa CartesianGrid

    # error: cartesian indexing only works with grids
    gtb = dummy((; a=rand(4)), PointSet(rand(Point2, 4)))
    @test_throws ArgumentError gtb[(1, 1), :a]
    # error: invalid cartesian indexing
    gtb = dummy((; a=rand(8)), CartesianGrid(2, 2))
    @test_throws ArgumentError gtb[(1, 1, 1), :a]

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

    # same column names
    data₁ = dummy((a=rand(10), b=rand(10)), dom)
    data₂ = dummy((a=rand(10), c=rand(10)), dom)
    hdata = hcat(data₁, data₂)
    @test propertynames(hdata) == [:a, :b, :a_, :c, :geometry]
    @test hdata.a == data₁.a
    @test hdata.b == data₁.b
    @test hdata.a_ == data₂.a
    @test hdata.c == data₂.c
    @test hdata.geometry == dom
    data₁ = dummy((a=rand(10), b=rand(10)), dom)
    data₂ = dummy((a=rand(10), b=rand(10)), dom)
    hdata = hcat(data₁, data₂)
    @test propertynames(hdata) == [:a, :b, :a_, :b_, :geometry]
    @test hdata.a == data₁.a
    @test hdata.b == data₁.b
    @test hdata.a_ == data₂.a
    @test hdata.b_ == data₂.b
    @test hdata.geometry == dom
    data₁ = dummy((a=rand(10), b=rand(10)), dom)
    data₂ = dummy((a=rand(10), b=rand(10)), dom)
    data₃ = dummy((a=rand(10), b=rand(10)), dom)
    hdata = hcat(data₁, data₂, data₃)
    @test propertynames(hdata) == [:a, :b, :a_, :b_, :a__, :b__, :geometry]
    @test hdata.a == data₁.a
    @test hdata.b == data₁.b
    @test hdata.a_ == data₂.a
    @test hdata.b_ == data₂.b
    @test hdata.a__ == data₃.a
    @test hdata.b__ == data₃.b
    @test hdata.geometry == dom

    # error: different domains
    data₁ = dummy((a=rand(10), b=rand(10)), PointSet(rand(Point2, 10)))
    data₂ = dummy((c=rand(10), d=rand(10)), PointSet(rand(Point2, 10)))
    @test_throws ArgumentError hcat(data₁, data₂)

    # vcat
    pset₁ = PointSet(rand(Point2, 10))
    pset₂ = PointSet(rand(Point2, 10))
    pset₃ = PointSet(rand(Point2, 10))
    data₁ = dummy((a=rand(10), b=rand(10)), pset₁)
    data₂ = dummy((a=rand(10), b=rand(10)), pset₂)
    data₃ = dummy((a=rand(10), b=rand(10)), pset₃)

    @test vcat(data₁) == data₁
    vdata = vcat(data₁, data₂)
    @test vdata.a == [data₁.a; data₂.a]
    @test vdata.b == [data₁.b; data₂.b]
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])
    vdata = vcat(data₁, data₂, data₃)
    @test vdata.a == [data₁.a; data₂.a; data₃.a]
    @test vdata.b == [data₁.b; data₂.b; data₃.b]
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry); collect(data₃.geometry)])
    vdata = vcat(data₁[6:10, :], data₁[1:5, :])
    @test vdata.geometry isa SubDomain
    @test parentindices(vdata.geometry) == [6:10; 1:5]

    # union (default)
    data₁ = dummy((a=rand(10), b=rand(10)), pset₁)
    data₂ = dummy((a=rand(10), c=rand(10)), pset₂)
    vdata = vcat(data₁, data₂)
    @test propertynames(vdata) == [:a, :b, :c, :geometry]
    @test vdata.a == [data₁.a; data₂.a]
    @test isequal(vdata.b, [data₁.b; fill(missing, 10)])
    @test isequal(vdata.c, [fill(missing, 10); data₂.c])
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])

    data₁ = dummy((a=rand(10), b=rand(10)), pset₁)
    data₂ = dummy(nothing, pset₂)
    vdata = vcat(data₁, data₂)
    @test isequal(vdata.a, [data₁.a; fill(missing, 10)])
    @test isequal(vdata.b, [data₁.b; fill(missing, 10)])
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])

    data₁ = dummy(nothing, pset₁)
    data₂ = dummy((a=rand(10), b=rand(10)), pset₂)
    vdata = vcat(data₁, data₂)
    @test isequal(vdata.a, [fill(missing, 10); data₂.a])
    @test isequal(vdata.b, [fill(missing, 10); data₂.b])
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])

    data₁ = dummy(nothing, pset₁)
    data₂ = dummy(nothing, pset₂)
    vdata = vcat(data₁, data₂)
    @test isnothing(values(vdata))
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])

    # intersect
    data₁ = dummy((a=rand(10), b=rand(10)), pset₁)
    data₂ = dummy((a=rand(10), c=rand(10)), pset₂)
    vdata = vcat(data₁, data₂, kind=:intersect)
    @test propertynames(vdata) == [:a, :geometry]
    @test vdata.a == [data₁.a; data₂.a]
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])

    data₁ = dummy(nothing, pset₁)
    data₂ = dummy(nothing, pset₂)
    vdata = vcat(data₁, data₂, kind=:intersect)
    @test isnothing(values(vdata))
    @test vdata.geometry == PointSet([collect(data₁.geometry); collect(data₂.geometry)])

    # error: invalid kind
    @test_throws ArgumentError vcat(data₁, data₂, kind=:test)
    # error: no intersection found
    data₁ = dummy((a=rand(10), b=rand(10)), pset₁)
    data₂ = dummy((c=rand(10), d=rand(10)), pset₂)
    @test_throws ArgumentError vcat(data₁, data₂, kind=:intersect)
    data₁ = dummy((a=rand(10), b=rand(10)), pset₁)
    data₂ = dummy(nothing, pset₂)
    @test_throws ArgumentError vcat(data₁, data₂, kind=:intersect)
    data₁ = dummy(nothing, pset₁)
    data₂ = dummy((a=rand(10), b=rand(10)), pset₂)
    @test_throws ArgumentError vcat(data₁, data₂, kind=:intersect)

    # variables interface
    data = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), PointSet(rand(Point2, 4)))
    @test asarray(data, :a) == asarray(data, "a") == [1, 2, 3, 4]
    @test asarray(data, :b) == asarray(data, "b") == [5, 6, 7, 8]
    data = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), CartesianGrid(2, 2))
    @test asarray(data, :a) == asarray(data, "a") == [1 3; 2 4]
    @test asarray(data, :b) == asarray(data, "b") == [5 7; 6 8]
  end
end
