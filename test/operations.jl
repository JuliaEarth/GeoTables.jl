@testset "Operations" begin
  @testset "geojoin" begin
    poly1 = PolyArea((1, 1), (5, 1), (3, 3))
    poly2 = PolyArea((6, 0), (10, 0), (10, 8))
    poly3 = PolyArea((1, 4), (4, 4), (6, 6), (3, 6))
    poly4 = PolyArea((1, 8), (4, 7), (7, 8), (5, 10), (3, 10))
    pset = PointSet((3, 2), (3, 3), (9, 2), (8, 2), (6, 4), (4, 5), (3, 5), (5, 9), (3, 9))
    gset = GeometrySet([poly1, poly2, poly3, poly4])
    grid = CartesianGrid(10, 10)
    linds = LinearIndices(size(grid))
    pointquads = [
      [linds[3, 2], linds[4, 2], linds[3, 3], linds[4, 3]],
      [linds[3, 3], linds[4, 3], linds[3, 4], linds[4, 4]],
      [linds[9, 2], linds[10, 2], linds[9, 3], linds[10, 3]],
      [linds[8, 2], linds[9, 2], linds[8, 3], linds[9, 3]],
      [linds[6, 4], linds[7, 4], linds[6, 5], linds[7, 5]],
      [linds[4, 5], linds[5, 5], linds[4, 6], linds[5, 6]],
      [linds[3, 5], linds[4, 5], linds[3, 6], linds[4, 6]],
      [linds[5, 9], linds[6, 9], linds[5, 10], linds[6, 10]],
      [linds[3, 9], linds[4, 9], linds[3, 10], linds[4, 10]]
    ]
    gtb1 = georef((; a=1:4), gset)
    gtb2 = georef((; b=rand(9)), pset)
    gtb3 = georef((; c=1:100), grid)

    # left join
    jgtb = geojoin(gtb1, gtb2)
    @test propertynames(jgtb) == [:a, :b, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test jgtb.b[1] == mean(gtb2.b[[1, 2]])
    @test jgtb.b[2] == mean(gtb2.b[[3, 4]])
    @test jgtb.b[3] == mean(gtb2.b[[6, 7]])
    @test jgtb.b[4] == mean(gtb2.b[[8, 9]])

    jgtb = geojoin(gtb1, gtb2, :b => std)
    @test propertynames(jgtb) == [:a, :b, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test jgtb.b[1] == std(gtb2.b[[1, 2]])
    @test jgtb.b[2] == std(gtb2.b[[3, 4]])
    @test jgtb.b[3] == std(gtb2.b[[6, 7]])
    @test jgtb.b[4] == std(gtb2.b[[8, 9]])

    jgtb = geojoin(gtb2, gtb1)
    @test propertynames(jgtb) == [:b, :a, :geometry]
    @test jgtb.geometry == gtb2.geometry
    @test jgtb.b == gtb2.b
    @test isequal(jgtb.a, [1, 1, 2, 2, missing, 3, 3, 4, 4])

    jgtb = geojoin(gtb3, gtb1, pred=issubset)
    @test propertynames(jgtb) == [:c, :a, :geometry]
    @test jgtb.geometry == gtb3.geometry
    @test jgtb.c == gtb3.c
    @test jgtb.a[linds[9, 2]] == 2
    @test jgtb.a[linds[9, 3]] == 2
    @test jgtb.a[linds[5, 9]] == 4
    @test jgtb.a[linds[4, 9]] == 4

    jgtb = geojoin(gtb2, gtb3, :c => last, pred=issubset)
    @test propertynames(jgtb) == [:b, :c, :geometry]
    @test jgtb.geometry == gtb2.geometry
    @test jgtb.b == gtb2.b
    @test jgtb.c[1] == last(gtb3.c[pointquads[1]])
    @test jgtb.c[2] == last(gtb3.c[pointquads[2]])
    @test jgtb.c[3] == last(gtb3.c[pointquads[3]])
    @test jgtb.c[4] == last(gtb3.c[pointquads[4]])
    @test jgtb.c[5] == last(gtb3.c[pointquads[5]])
    @test jgtb.c[6] == last(gtb3.c[pointquads[6]])
    @test jgtb.c[7] == last(gtb3.c[pointquads[7]])
    @test jgtb.c[8] == last(gtb3.c[pointquads[8]])
    @test jgtb.c[9] == last(gtb3.c[pointquads[9]])

    # inner join
    jgtb = geojoin(gtb1, gtb2, :b => std, kind=:inner)
    @test propertynames(jgtb) == [:a, :b, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test jgtb.b[1] == std(gtb2.b[[1, 2]])
    @test jgtb.b[2] == std(gtb2.b[[3, 4]])
    @test jgtb.b[3] == std(gtb2.b[[6, 7]])
    @test jgtb.b[4] == std(gtb2.b[[8, 9]])

    jgtb = geojoin(gtb2, gtb1, kind=:inner)
    inds = [1, 2, 3, 4, 6, 7, 8, 9]
    @test propertynames(jgtb) == [:b, :a, :geometry]
    @test jgtb.geometry == view(gtb2.geometry, inds)
    @test jgtb.b == gtb2.b[inds]
    @test jgtb.a == [1, 1, 2, 2, 3, 3, 4, 4]

    jgtb = geojoin(gtb3, gtb2, :b => last, kind=:inner)
    inds = sort(unique(reduce(vcat, pointquads)))
    @test propertynames(jgtb) == [:c, :b, :geometry]
    @test jgtb.geometry == view(gtb3.geometry, inds)
    @test jgtb.c == gtb3.c[inds]
    @test jgtb.b[findfirst(==(pointquads[1][2]), inds)] == gtb2.b[1]
    @test jgtb.b[findfirst(==(pointquads[2][2]), inds)] == gtb2.b[2]
    @test jgtb.b[findfirst(==(pointquads[3][2]), inds)] == gtb2.b[3]
    @test jgtb.b[findfirst(==(pointquads[4][2]), inds)] == gtb2.b[4]
    @test jgtb.b[findfirst(==(pointquads[5][2]), inds)] == gtb2.b[5]
    @test jgtb.b[findfirst(==(pointquads[6][2]), inds)] == gtb2.b[6]
    @test jgtb.b[findfirst(==(pointquads[7][2]), inds)] == gtb2.b[7]
    @test jgtb.b[findfirst(==(pointquads[8][2]), inds)] == gtb2.b[8]
    @test jgtb.b[findfirst(==(pointquads[9][2]), inds)] == gtb2.b[9]

    # units
    gtb4 = georef((; d=rand(9) * u"K"), pset)
    jgtb = geojoin(gtb1, gtb4)
    @test propertynames(jgtb) == [:a, :d, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test unit(eltype(jgtb.d)) == u"K"
    @test jgtb.d[1] == mean(gtb4.d[[1, 2]])
    @test jgtb.d[2] == mean(gtb4.d[[3, 4]])
    @test jgtb.d[3] == mean(gtb4.d[[6, 7]])
    @test jgtb.d[4] == mean(gtb4.d[[8, 9]])

    # affine units
    gtb5 = georef((; e=rand(9) * u"°C"), pset)
    jgtb = geojoin(gtb1, gtb5)
    ngtb = GeoTables._adjustunits(gtb5)
    @test propertynames(jgtb) == [:a, :e, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test unit(eltype(jgtb.e)) == u"K"
    @test jgtb.e[1] == mean(ngtb.e[[1, 2]])
    @test jgtb.e[2] == mean(ngtb.e[[3, 4]])
    @test jgtb.e[3] == mean(ngtb.e[[6, 7]])
    @test jgtb.e[4] == mean(ngtb.e[[8, 9]])

    # units and missings
    gtb6 = georef((; f=[rand(4); missing; rand(4)] * u"°C"), pset)
    jgtb = geojoin(gtb1, gtb6)
    ngtb = GeoTables._adjustunits(gtb6)
    @test propertynames(jgtb) == [:a, :f, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test unit(eltype(jgtb.f)) == u"K"
    @test jgtb.f[1] == mean(ngtb.f[[1, 2]])
    @test jgtb.f[2] == mean(ngtb.f[[3, 4]])
    @test jgtb.f[3] == mean(ngtb.f[[6, 7]])
    @test jgtb.f[4] == mean(ngtb.f[[8, 9]])

    # quantity aggregation
    box1 = Box((0, 0), (1, 1))
    box2 = Box((1, 1), (2, 2))
    pts = Point2[(0.5, 0.5), (1.2, 1.2), (1.8, 1.8)]
    gtb1 = georef((; a=rand(2)), [box1, box2])
    gtb2 = georef((; b=[1, 2, 3] * u"K"), pts)
    gtb3 = georef((; c=[1.0, 2.0, 3.0] * u"K"), pts)
    jgtb = geojoin(gtb1, gtb2)
    @test propertynames(jgtb) == [:a, :b, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test unit(eltype(jgtb.b)) == u"K"
    @test Unitful.numtype(eltype(jgtb.b)) <: Int
    @test jgtb.b[1] == first(gtb2.b[[1]])
    @test jgtb.b[2] == first(gtb2.b[[2, 3]])
    jgtb = geojoin(gtb1, gtb3)
    @test propertynames(jgtb) == [:a, :c, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test unit(eltype(jgtb.c)) == u"K"
    @test Unitful.numtype(eltype(jgtb.c)) <: Float64
    @test jgtb.c[1] == mean(gtb3.c[[1]])
    @test jgtb.c[2] == mean(gtb3.c[[2, 3]])

    # "on" kwarg
    tab1 = (a=1:4, b=["a", "b", "c", "d"])
    tab2 = (a=[1, 1, 0, 0, 0, 3, 3, 0, 0], b=["a", "z", "z", "z", "z", "z", "c", "z", "z"], c=rand(9))
    gtb1 = georef(tab1, gset)
    gtb2 = georef(tab2, pset)

    # left join
    jgtb = geojoin(gtb1, gtb2, on=:a)
    @test propertynames(jgtb) == [:a, :b, :b_, :c, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test jgtb.b == gtb1.b
    @test jgtb.b_[1] == first(gtb2.b[[1, 2]])
    @test ismissing(jgtb.b_[2])
    @test jgtb.b_[3] == first(gtb2.b[[6, 7]])
    @test ismissing(jgtb.b_[4])
    @test jgtb.c[1] == mean(gtb2.c[[1, 2]])
    @test ismissing(jgtb.c[2])
    @test jgtb.c[3] == mean(gtb2.c[[6, 7]])
    @test ismissing(jgtb.c[4])

    jgtb = geojoin(gtb1, gtb2, on=["a", "b"])
    @test propertynames(jgtb) == [:a, :b, :c, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test jgtb.b == gtb1.b
    @test jgtb.c[1] == gtb2.c[1]
    @test ismissing(jgtb.c[2])
    @test jgtb.c[3] == gtb2.c[7]
    @test ismissing(jgtb.c[4])

    # inner join
    jgtb = geojoin(gtb1, gtb2, kind=:inner, on="a")
    @test nrow(jgtb) == 2
    @test propertynames(jgtb) == [:a, :b, :b_, :c, :geometry]
    @test jgtb.geometry == view(gtb1.geometry, [1, 3])
    @test jgtb.a == gtb1.a[[1, 3]]
    @test jgtb.b == gtb1.b[[1, 3]]
    @test jgtb.b_[1] == first(gtb2.b[[1, 2]])
    @test jgtb.b_[2] == first(gtb2.b[[6, 7]])
    @test jgtb.c[1] == mean(gtb2.c[[1, 2]])
    @test jgtb.c[2] == mean(gtb2.c[[6, 7]])

    jgtb = geojoin(gtb1, gtb2, kind=:inner, on=[:a, :b])
    @test nrow(jgtb) == 2
    @test propertynames(jgtb) == [:a, :b, :c, :geometry]
    @test jgtb.geometry == view(gtb1.geometry, [1, 3])
    @test jgtb.a == gtb1.a[[1, 3]]
    @test jgtb.b == gtb1.b[[1, 3]]
    @test jgtb.c[1] == gtb2.c[1]
    @test jgtb.c[2] == gtb2.c[7]

    # error: invalid kind of join
    @test_throws ArgumentError geojoin(gtb1, gtb2, kind=:test, on=:a)
    # error: all variables in "on" kwarg must exist in both geotables
    @test_throws ArgumentError geojoin(gtb1, gtb2, on=[:a, :c])
  end

  @testset "tablejoin" begin
    tab1 = (a=1:4, b=["a", "b", "c", "d"])
    tab2 = (a=[1, 1, 0, 0, 0, 3, 3, 0, 0], b=["a", "z", "z", "z", "z", "z", "c", "z", "z"], c=rand(9))
    gtb1 = georef(tab1, rand(Point2, 4))

    # left join
    jgtb = tablejoin(gtb1, tab2, on=:a)
    @test propertynames(jgtb) == [:a, :b, :b_, :c, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test jgtb.b == gtb1.b
    @test jgtb.b_[1] == first(tab2.b[[1, 2]])
    @test ismissing(jgtb.b_[2])
    @test jgtb.b_[3] == first(tab2.b[[6, 7]])
    @test ismissing(jgtb.b_[4])
    @test jgtb.c[1] == mean(tab2.c[[1, 2]])
    @test ismissing(jgtb.c[2])
    @test jgtb.c[3] == mean(tab2.c[[6, 7]])
    @test ismissing(jgtb.c[4])

    jgtb = tablejoin(gtb1, tab2, on=["a", "b"])
    @test propertynames(jgtb) == [:a, :b, :c, :geometry]
    @test jgtb.geometry == gtb1.geometry
    @test jgtb.a == gtb1.a
    @test jgtb.b == gtb1.b
    @test jgtb.c[1] == tab2.c[1]
    @test ismissing(jgtb.c[2])
    @test jgtb.c[3] == tab2.c[7]
    @test ismissing(jgtb.c[4])

    # inner join
    jgtb = tablejoin(gtb1, tab2, kind=:inner, on="a")
    @test nrow(jgtb) == 2
    @test propertynames(jgtb) == [:a, :b, :b_, :c, :geometry]
    @test jgtb.geometry == view(gtb1.geometry, [1, 3])
    @test jgtb.a == gtb1.a[[1, 3]]
    @test jgtb.b == gtb1.b[[1, 3]]
    @test jgtb.b_[1] == first(tab2.b[[1, 2]])
    @test jgtb.b_[2] == first(tab2.b[[6, 7]])
    @test jgtb.c[1] == mean(tab2.c[[1, 2]])
    @test jgtb.c[2] == mean(tab2.c[[6, 7]])

    jgtb = tablejoin(gtb1, tab2, kind=:inner, on=[:a, :b])
    @test nrow(jgtb) == 2
    @test propertynames(jgtb) == [:a, :b, :c, :geometry]
    @test jgtb.geometry == view(gtb1.geometry, [1, 3])
    @test jgtb.a == gtb1.a[[1, 3]]
    @test jgtb.b == gtb1.b[[1, 3]]
    @test jgtb.c[1] == tab2.c[1]
    @test jgtb.c[2] == tab2.c[7]

    # error: invalid kind of join
    @test_throws ArgumentError tablejoin(gtb1, tab2, kind=:test, on=:a)
    # error: all variables in "on" kwarg must exist in geotable and table
    @test_throws ArgumentError tablejoin(gtb1, tab2, on=[:a, :c])
  end

  @testset "@groupby" begin
    d = georef((z=[1, 2, 3], x=[4, 5, 6]), rand(2, 3))
    g = @groupby(d, :z)
    @test all(nrow.(g) .== 1)
    rows = [[1 4], [2 5], [3 6]]
    for i in 1:3
      @test Tables.matrix(values(g[i])) ∈ rows
    end

    z = vec([1 1 1; 2 2 2; 3 3 3])
    sdata = georef((z=z,), CartesianGrid(3, 3))
    p = @groupby(sdata, :z)
    @test indices(p) == [[1, 4, 7], [2, 5, 8], [3, 6, 9]]

    # groupby with missing values
    z = vec([missing 1 1; 2 missing 2; 3 3 missing])
    sdata = georef((z=z,), CartesianGrid(3, 3))
    p = @groupby(sdata, :z)
    @test indices(p) == [[1, 5, 9], [2, 8], [3, 6], [4, 7]]

    # macro
    x = [1, 1, 1, 1, 2, 2, 2, 2]
    y = [1, 1, 2, 2, 3, 3, 4, 4]
    z = [1, 2, 3, 4, 5, 6, 7, 8]
    table = (; x, y, z)
    sdata = georef(table, rand(2, 8))

    # args...
    # integers
    p = @groupby(sdata, 1)
    @test indices(p) == [[1, 2, 3, 4], [5, 6, 7, 8]]
    # symbols
    p = @groupby(sdata, :y)
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]
    # strings
    p = @groupby(sdata, "x", "y")
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]

    # vector...
    # integers
    p = @groupby(sdata, [1])
    @test indices(p) == [[1, 2, 3, 4], [5, 6, 7, 8]]
    # symbols
    p = @groupby(sdata, [:y])
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]
    # strings
    p = @groupby(sdata, ["x", "y"])
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]

    # tuple...
    # integers
    p = @groupby(sdata, (1,))
    @test indices(p) == [[1, 2, 3, 4], [5, 6, 7, 8]]
    # symbols
    p = @groupby(sdata, (:y,))
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]
    # strings
    p = @groupby(sdata, ("x", "y"))
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]

    # regex
    p = @groupby(sdata, r"[xy]")
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]

    # variable interpolation
    cols = (:x, :y)
    p = @groupby(sdata, cols)
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]
    p = @groupby(sdata, cols...)
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]

    c1, c2 = :x, :y
    p = @groupby(sdata, c1, c2)
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]
    p = @groupby(sdata, [c1, c2])
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]
    p = @groupby(sdata, (c1, c2))
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]

    # missing values
    x = [1, 1, missing, missing, 2, 2, 2, 2]
    y = [1, 1, 2, 2, 3, 3, missing, missing]
    z = [1, 2, 3, 4, 5, 6, 7, 8]
    table = (; x, y, z)
    sdata = georef(table, rand(2, 8))

    p = @groupby(sdata, :x)
    @test indices(p) == [[1, 2], [3, 4], [5, 6, 7, 8]]
    p = @groupby(sdata, :x, :y)
    @test indices(p) == [[1, 2], [3, 4], [5, 6], [7, 8]]

    # isequal
    x = [0.0, 0, 0, -0.0, 2, 2, 2, 2]
    y = [1, 1, 2, 2, 3, 3, 4, 4]
    z = [1, 2, 3, 4, 5, 6, 7, 8]
    table = (; x, y, z)
    sdata = georef(table, rand(2, 8))

    p = @groupby(sdata, :x)
    @test indices(p) == [[1, 2, 3], [4], [5, 6, 7, 8]]
    p = @groupby(sdata, :x, :y)
    @test indices(p) == [[1, 2], [3], [4], [5, 6], [7, 8]]

    # expression as first argument
    x = [1, 1, 1, 1, 2, 2, 2, 2]
    y = [1, 1, 2, 2, 3, 3, 4, 4]
    table = (; x, y)
    sdata = georef(table, CartesianGrid(2, 4))
    opr(sdata) = georef(values(sdata), GeometrySet(centroid.(domain(sdata))))

    p = @groupby(sdata |> opr, :x)
    pinds = [[1, 2, 3, 4], [5, 6, 7, 8]]
    @test indices(p) == pinds
    for (pdata, inds) in zip(p, pinds)
      @test pdata.geometry == GeometrySet(centroid.(domain(sdata)[inds]))
    end

    p = @groupby(sdata |> opr, :y)
    pinds = [[1, 2], [3, 4], [5, 6], [7, 8]]
    @test indices(p) == pinds
    for (pdata, inds) in zip(p, pinds)
      @test pdata.geometry == GeometrySet(centroid.(domain(sdata)[inds]))
    end
  end

  @testset "@transform" begin
    table = (x=rand(10), y=rand(10))
    sdata = georef(table, rand(2, 10))

    ndata = @transform(sdata, :z = :x - 2 * :y)
    @test ndata.z == sdata.x .- 2 .* sdata.y

    ndata = @transform(sdata, :z = :x - :y, :w = :x + :y)
    @test ndata.z == sdata.x .- sdata.y
    @test ndata.w == sdata.x .+ sdata.y

    ndata = @transform(sdata, :sinx = sin(:x), :cosy = cos(:y))
    @test ndata.sinx == sin.(sdata.x)
    @test ndata.cosy == cos.(sdata.y)

    # user defined functions & :geometry
    dist(point) = norm(coordinates(point))
    ndata = @transform(sdata, :dist_to_origin = dist(:geometry))
    @test ndata.dist_to_origin == dist.(domain(sdata))

    # replace :geometry column
    testfunc(point) = Point(coordinates(point) .+ 1)
    ndata = @transform(sdata, :geometry = testfunc(:geometry))
    @test domain(ndata) == GeometrySet(testfunc.(domain(sdata)))

    # unexported functions
    ndata = @transform(sdata, :logx = Base.log(:x), :expy = Base.exp(:y))
    @test ndata.logx == log.(sdata.x)
    @test ndata.expy == exp.(sdata.y)

    # column name interpolation
    ndata = @transform(sdata, {"z"} = {"x"} - 2 * {"y"})
    @test ndata.z == sdata.x .- 2 .* sdata.y

    xnm, ynm, znm = :x, :y, :z
    ndata = @transform(sdata, {znm} = {xnm} - 2 * {ynm})
    @test ndata.z == sdata.x .- 2 .* sdata.y

    # variable interpolation
    k = 10
    ndata = @transform(sdata, :z = k + :y, :w = :x - k)
    @test ndata.z == k .+ sdata.y
    @test ndata.w == sdata.x .- k

    # contant columns
    k = 1
    ndata = @transform(sdata, :z = k, :w = 5, :a = 1.5, :b = "test")
    @test ndata.z == fill(k, nrow(sdata))
    @test ndata.w == fill(5, nrow(sdata))
    @test ndata.a == fill(1.5, nrow(sdata))
    @test ndata.b == fill("test", nrow(sdata))

    # string literals
    ndata = @transform(sdata, :x_str = join([:x, "test"]))
    @test ndata.x_str == [join([x, "test"]) for x in sdata.x]

    # column replacement
    table = (x=rand(10), y=rand(10), z=rand(10))
    sdata = georef(table, rand(2, 10))

    ndata = @transform(sdata, :z = :x + :y, :w = :x - :y)
    @test ndata.z == sdata.x .+ sdata.y
    @test ndata.w == sdata.x .- sdata.y
    @test Tables.schema(values(ndata)).names == (:x, :y, :z, :w)

    ndata = @transform(sdata, :x = :y, :y = :z, :z = :x)
    @test ndata.x == sdata.y
    @test ndata.y == sdata.z
    @test ndata.z == sdata.x
    @test Tables.schema(values(ndata)).names == (:x, :y, :z)

    # missing values
    x = [1, 1, missing, missing, 2, 2, 2, 2]
    y = [1, 1, 2, 2, 3, 3, missing, missing]
    table = (; x, y)
    sdata = georef(table, rand(8, 2))

    ndata = @transform(sdata, :z = :x * :y, :w = :x / :y)
    @test isequal(ndata.z, sdata.x .* sdata.y)
    @test isequal(ndata.w, sdata.x ./ sdata.y)

    # Partition
    x = [1, 1, 1, 1, 2, 2, 2, 2]
    y = [1, 1, 2, 2, 3, 3, 4, 4]
    z = [1, 2, 3, 4, 5, 6, 7, 8]
    table = (; x, y, z)
    sdata = georef(table, rand(2, 8))

    p = @groupby(sdata, :x, :y)
    np = @transform(p, :z = 2 * :x + :y)
    @test np.object.z == 2 .* sdata.x .+ sdata.y
    @test indices(np) == indices(p)
    @test metadata(np) == metadata(p)

    # expression as first argument
    table = (x=rand(25), y=rand(25))
    sdata = georef(table, CartesianGrid(5, 5))
    opr(sdata) = georef(values(sdata), GeometrySet(centroid.(domain(sdata))))

    ndata = @transform(sdata |> opr, :z = :x - 2 * :y)
    @test ndata.z == sdata.x .- 2 .* sdata.y
    @test ndata.geometry == GeometrySet(centroid.(domain(sdata)))

    @test_throws ArgumentError @transform(p, :x = 3 * :x)
    @test_throws ArgumentError @transform(p, :y = 3 * :y)
  end

  @testset "@combine" begin
    x = [1, 1, 1, 1, 2, 2, 2, 2]
    y = [1, 1, 2, 2, 3, 3, 4, 4]
    z = [1, 2, 3, 4, 5, 6, 7, 8]
    table = (; x, y, z)
    grid = CartesianGrid(2, 4)
    sdata = georef(table, grid)

    c = @combine(sdata, :x_sum = sum(:x))
    @test c.x_sum == [sum(sdata.x)]
    @test domain(c) == GeometrySet([Multi(domain(sdata))])
    @test Tables.schema(values(c)).names == (:x_sum,)

    c = @combine(sdata, :y_mean = mean(:y), :z_median = median(:z))
    @test c.y_mean == [mean(sdata.y)]
    @test c.z_median == [median(sdata.z)]
    @test domain(c) == GeometrySet([Multi(domain(sdata))])
    @test Tables.schema(values(c)).names == (:y_mean, :z_median)

    # combine geometry column
    c = @combine(sdata, :geometry = centroid(:geometry))
    @test isnothing(values(c))
    @test domain(c) == GeometrySet([centroid(domain(sdata))])
    c = @combine(sdata, :y_mean = mean(:y), :geometry = centroid(:geometry))
    @test c.y_mean == [mean(sdata.y)]
    @test domain(c) == GeometrySet([centroid(domain(sdata))])

    # column name interpolation
    c = @combine(sdata, {"z"} = sum({"x"}) + prod({"y"}))
    @test c.z == [sum(sdata.x) + prod(sdata.y)]

    xnm, ynm, znm = :x, :y, :z
    c = @combine(sdata, {znm} = sum({xnm}) + prod({ynm}))
    @test c.z == [sum(sdata.x) + prod(sdata.y)]

    # Partition
    p = @groupby(sdata, :x)
    c = @combine(p, :y_sum = sum(:y), :z_prod = prod(:z))
    @test c.x == [first(data.x) for data in p]
    @test c.y_sum == [sum(data.y) for data in p]
    @test c.z_prod == [prod(data.z) for data in p]
    @test domain(c) == GeometrySet([Multi(domain(data)) for data in p])
    @test Tables.schema(values(c)).names == (:x, :y_sum, :z_prod)

    p = @groupby(sdata, :x, :y)
    c = @combine(p, :z_mean = mean(:z))
    @test c.x == [first(data.x) for data in p]
    @test c.y == [first(data.y) for data in p]
    @test c.z_mean == [mean(data.z) for data in p]
    @test domain(c) == GeometrySet([Multi(domain(data)) for data in p])
    @test Tables.schema(values(c)).names == (:x, :y, :z_mean)

    # combine geometry column
    p = @groupby(sdata, :x, :y)
    c = @combine(p, :geometry = centroid(:geometry))
    @test c.x == [first(data.x) for data in p]
    @test c.y == [first(data.y) for data in p]
    @test domain(c) == GeometrySet([centroid(domain(data)) for data in p])
    c = @combine(p, :z_mean = mean(:z), :geometry = centroid(:geometry))
    @test c.x == [first(data.x) for data in p]
    @test c.y == [first(data.y) for data in p]
    @test c.z_mean == [mean(data.z) for data in p]
    @test domain(c) == GeometrySet([centroid(domain(data)) for data in p])

    # expression as first argument
    opr(sdata) = georef(values(sdata), GeometrySet(centroid.(domain(sdata))))

    c = @combine(sdata |> opr, :x_sum = sum(:x))
    @test c.x_sum == [sum(sdata.x)]
    @test domain(c) == GeometrySet([Multi(centroid.(domain(sdata)))])
    @test Tables.schema(values(c)).names == (:x_sum,)
  end
end
