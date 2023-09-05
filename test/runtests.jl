using GeoTables
using LinearAlgebra
using TypedTables
using Unitful
using Tables
using Meshes
using Test

include("dummy.jl")

dummydata(domain, table) = DummyGeoTable(domain, Dict(paramdim(domain) => table))
dummymeta(domain, table) = GeoTable(domain, Dict(paramdim(domain) => table))

@testset "GeoTables.jl" begin
  @testset "AbstractGeoTable" begin
    for (dummy, DummyType) in [(dummydata, DummyGeoTable), (dummymeta, GeoTable)]
      # fallback constructor with spatial table
      dom = CartesianGrid(2, 2)
      tab = dummydata(dom, (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
      dat = DummyType(tab)
      @test domain(dat) == domain(tab)
      @test values(dat) == values(tab)

      # equality of data sets
      data₁ = dummy(CartesianGrid(2, 2), (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
      data₂ = dummy(CartesianGrid(2, 2), (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
      data₃ = dummy(PointSet(rand(Point2, 4)), (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
      @test data₁ == data₂
      @test data₁ != data₃
      @test data₂ != data₃

      # equality with missing data
      data₁ = dummy(PointSet([1 2 3; 4 5 6]), (a=[1, missing, 3], b=[3, 2, 1]))
      data₂ = dummy(PointSet([1 2 3; 4 5 6]), (a=[1, missing, 3], b=[3, 2, 1]))
      @test data₁ == data₂

      # Tables interface
      dom = CartesianGrid(2, 2)
      dat = dummy(dom, (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
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
      @test Tables.materializer(dat) <: DummyType

      # dataframe interface
      grid = CartesianGrid(2, 2)
      data = dummy(grid, (a=[1, 2, 3, 4], b=[5, missing, 7, 8]))
      @test propertynames(data) == [:a, :b, :geometry]
      @test names(data) == ["a", "b", "geometry"]
      @test isequal(data.a, [1, 2, 3, 4])
      @test isequal(data.b, [5, missing, 7, 8])
      @test data.geometry == grid
      @test_throws ErrorException data.c
      for (a, b, geometry) in [(:a, :b, :geometry), ("a", "b", "geometry")]
        @test data[1:2, [a, b]] == dummy(view(grid, 1:2), (a=[1, 2], b=[5, missing]))
        @test data[1:2, [a, b, geometry]] == dummy(view(grid, 1:2), (a=[1, 2], b=[5, missing]))
        @test isequal(data[1:2, a], [1, 2])
        @test isequal(data[1:2, b], [5, missing])
        @test isequal(data[1:2, geometry], view(grid, 1:2))
        @test data[1:2, :] == dummy(view(grid, 1:2), (a=[1, 2], b=[5, missing]))
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
      @test data[3:4, r"b"] == dummy(view(grid, 3:4), (b=[7, 8],))
      @test data[:, r"[ab]"] == data

      # hcat
      dom = PointSet(rand(Point2, 10))
      data₁ = dummy(dom, (a=rand(10), b=rand(10)))
      data₂ = dummy(dom, (c=rand(10), d=rand(10)))
      data₃ = dummy(dom, (e=rand(10), f=rand(10)))
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
      # throws
      data₁ = dummy(dom, (a=rand(10), b=rand(10)))
      data₂ = dummy(dom, (a=rand(10), c=rand(10)))
      @test_throws ArgumentError hcat(data₁, data₂)
      data₁ = dummy(PointSet(rand(Point2, 10)), (a=rand(10), b=rand(10)))
      data₂ = dummy(PointSet(rand(Point2, 10)), (a=rand(10), b=rand(10)))
      @test_throws ArgumentError hcat(data₁, data₂)

      # vcat
      data₁ = dummy(PointSet(rand(Point2, 10)), (a=rand(10), b=rand(10)))
      data₂ = dummy(PointSet(rand(Point2, 10)), (a=rand(10), b=rand(10)))
      data₃ = dummy(PointSet(rand(Point2, 10)), (a=rand(10), b=rand(10)))
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
      data₁ = dummy(PointSet(rand(Point2, 10)), (a=rand(10), b=rand(10)))
      data₂ = dummy(PointSet(rand(Point2, 10)), (a=rand(10), c=rand(10)))
      @test_throws ArgumentError vcat(data₁, data₂)

      # variables interface
      data = dummy(PointSet(rand(Point2, 4)), (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
      @test asarray(data, :a) == asarray(data, "a") == [1, 2, 3, 4]
      @test asarray(data, :b) == asarray(data, "b") == [5, 6, 7, 8]
      data = dummy(CartesianGrid(2, 2), (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
      @test asarray(data, :a) == asarray(data, "a") == [1 3; 2 4]
      @test asarray(data, :b) == asarray(data, "b") == [5 7; 6 8]
    end
  end

  @testset "viewing" begin
    for dummy in [dummydata, dummymeta]
      g = CartesianGrid(10, 10)
      t = (a=1:100, b=1:100)
      d = dummy(g, t)
      v = view(d, 1:3)

      g = CartesianGrid(10, 10)
      t = (a=1:100, b=1:100)
      d = dummy(g, t)
      b = Box(Point(1, 1), Point(5, 5))
      v = view(d, b)
      @test domain(v) == CartesianGrid(Point(0, 0), Point(6, 6), dims=(6, 6))
      x = [collect(1:6); collect(11:16); collect(21:26); collect(31:36); collect(41:46); collect(51:56)]
      @test Tables.columntable(values(v)) == (a=x, b=x)

      p = PointSet(collect(vertices(g)))
      d = dummy(p, t)
      v = view(d, b)
      dd = domain(v)
      @test centroid(dd, 1) == Point(1, 1)
      @test centroid(dd, nelements(dd)) == Point(5, 5)
      tt = Tables.columntable(values(v))
      @test tt == (
        a=[13, 14, 15, 16, 17, 24, 25, 26, 27, 28, 35, 36, 37, 38, 39, 46, 47, 48, 49, 50, 57, 58, 59, 60, 61],
        b=[13, 14, 15, 16, 17, 24, 25, 26, 27, 28, 35, 36, 37, 38, 39, 46, 47, 48, 49, 50, 57, 58, 59, 60, 61]
      )

      dom = CartesianGrid(2, 2)
      dat = dummy(dom, (a=[1, 2, 3, 4], b=[5, 6, 7, 8]))
      v = view(dat, 2:4)
      @test domain(v) == view(dom, 2:4)
      @test Tables.columntable(values(v)) == (a=[2, 3, 4], b=[6, 7, 8])
      @test centroid(domain(v), 1) == Point(1.5, 0.5)
      @test centroid(domain(v), 2) == Point(0.5, 1.5)
      @test centroid(domain(v), 3) == Point(1.5, 1.5)
      @test v.a == v."a" == [2, 3, 4]
      @test v.b == v."b" == [6, 7, 8]
    end
  end

  @testset "georef" begin
    table = Table(x=rand(3), y=[1, 2, 3], z=["a", "b", "c"])
    tuple = (x=rand(3), y=[1, 2, 3], z=["a", "b", "c"])

    # explicit domain types
    gtb = georef(table, PointSet(rand(2, 3)))
    @test domain(gtb) isa PointSet
    gtb = georef(tuple, PointSet(rand(2, 3)))
    @test domain(gtb) isa PointSet
    gtb = georef(table, CartesianGrid(3))
    @test domain(gtb) isa CartesianGrid
    gtb = georef(tuple, CartesianGrid(3))
    @test domain(gtb) isa CartesianGrid

    # vectors of geometries
    gtb = georef(table, rand(Point2, 3))
    @test domain(gtb) isa PointSet
    gtb = georef(tuple, rand(Point2, 3))
    @test domain(gtb) isa PointSet
    gtb = georef(table, collect(CartesianGrid(3)))
    @test domain(gtb) isa GeometrySet
    gtb = georef(tuple, collect(CartesianGrid(3)))
    @test domain(gtb) isa GeometrySet

    # coordinates of point set
    gtb = georef(table, rand(2, 3))
    @test domain(gtb) isa PointSet
    gtb = georef(tuple, rand(2, 3))
    @test domain(gtb) isa PointSet

    # coordinates names in table
    gtb = georef(table, (:x, :y))
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]
    gtb = georef(tuple, (:x, :y))
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]
    gtb = georef(table, [:x, :y])
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]
    gtb = georef(tuple, [:x, :y])
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]
    gtb = georef(table, ("x", "y"))
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]
    gtb = georef(tuple, ("x", "y"))
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]
    gtb = georef(table, ["x", "y"])
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]
    gtb = georef(tuple, ["x", "y"])
    @test domain(gtb) isa PointSet
    @test propertynames(gtb) == [:z, :geometry]

    # grid data
    tuple1D = (x=rand(10), y=rand(10))
    gtb = georef(tuple1D)
    @test domain(gtb) == CartesianGrid(10)
    tuple2D = (x=rand(10, 10), y=rand(10, 10))
    gtb = georef(tuple2D)
    @test domain(gtb) == CartesianGrid(10, 10)
    tuple3D = (x=rand(10, 10, 10), y=rand(10, 10, 10))
    gtb = georef(tuple3D)
    @test domain(gtb) == CartesianGrid(10, 10, 10)
    # different types
    tuple1D = (x=[rand(9); missing], y=rand(10))
    gtb = georef(tuple1D)
    @test domain(gtb) == CartesianGrid(10)
    tuple2D = (x=rand(10, 10), y=BitArray(rand(Bool, 10, 10)))
    gtb = georef(tuple2D)
    @test domain(gtb) == CartesianGrid(10, 10)
    # throws: different sizes
    tuple2D = (x=rand(3, 3), y=rand(5, 5))
    @test_throws AssertionError georef(tuple2D)
  end

  # terminal prints are different on macOS
  if !Sys.isapple()
    @testset "show" begin
      a = [0, 6, 6, 3, 9, 5, 2, 2, 8]
      b = [2.34, 7.5, 0.06, 1.29, 3.64, 8.05, 0.11, 0.64, 8.46]
      c = ["txt1", "txt2", "txt3", "txt4", "txt5", "txt6", "txt7", "txt8", "txt9"]
      pset = PointSet(Point.(1:9, 1:9))
      grid = CartesianGrid(3, 3)

      gtb = georef((; a, b, c), pset)
      @test sprint(show, gtb) == "9×4 GeoTable over 9 PointSet{2,Float64}"
      @test sprint(show, MIME("text/plain"), gtb) == """
      9×4 GeoTable over 9 PointSet{2,Float64}
      ┌─────────┬────────────┬─────────┬─────────────────┐
      │       a │          b │       c │        geometry │
      │   Count │ Continuous │ Textual │          Point2 │
      │ NoUnits │    NoUnits │ NoUnits │                 │
      ├─────────┼────────────┼─────────┼─────────────────┤
      │       0 │       2.34 │    txt1 │ Point(1.0, 1.0) │
      │       6 │        7.5 │    txt2 │ Point(2.0, 2.0) │
      │       6 │       0.06 │    txt3 │ Point(3.0, 3.0) │
      │       3 │       1.29 │    txt4 │ Point(4.0, 4.0) │
      │       9 │       3.64 │    txt5 │ Point(5.0, 5.0) │
      │       5 │       8.05 │    txt6 │ Point(6.0, 6.0) │
      │       2 │       0.11 │    txt7 │ Point(7.0, 7.0) │
      │       2 │       0.64 │    txt8 │ Point(8.0, 8.0) │
      │       8 │       8.46 │    txt9 │ Point(9.0, 9.0) │
      └─────────┴────────────┴─────────┴─────────────────┘"""

      vgtb = view(gtb, 1:3)
      @test sprint(show, vgtb) == "3×4 GeoTableView over 3 View{9 PointSet{2,Float64}}"
      @test sprint(show, MIME("text/plain"), vgtb) == """
      3×4 GeoTableView over 3 View{9 PointSet{2,Float64}}
      ┌─────────┬────────────┬─────────┬─────────────────┐
      │       a │          b │       c │        geometry │
      │   Count │ Continuous │ Textual │          Point2 │
      │ NoUnits │    NoUnits │ NoUnits │                 │
      ├─────────┼────────────┼─────────┼─────────────────┤
      │       0 │       2.34 │    txt1 │ Point(1.0, 1.0) │
      │       6 │        7.5 │    txt2 │ Point(2.0, 2.0) │
      │       6 │       0.06 │    txt3 │ Point(3.0, 3.0) │
      └─────────┴────────────┴─────────┴─────────────────┘"""

      gtb = georef((a=a * u"m/s", b=b * u"km/hr", c=c), pset)
      @test sprint(show, gtb) == "9×4 GeoTable over 9 PointSet{2,Float64}"
      @test sprint(show, MIME("text/plain"), gtb) == """
      9×4 GeoTable over 9 PointSet{2,Float64}
      ┌────────────┬───────────────┬─────────┬─────────────────┐
      │          a │             b │       c │        geometry │
      │ Continuous │    Continuous │ Textual │          Point2 │
      │     m s^-1 │      km hr^-1 │ NoUnits │                 │
      ├────────────┼───────────────┼─────────┼─────────────────┤
      │   0 m s^-1 │ 2.34 km hr^-1 │    txt1 │ Point(1.0, 1.0) │
      │   6 m s^-1 │  7.5 km hr^-1 │    txt2 │ Point(2.0, 2.0) │
      │   6 m s^-1 │ 0.06 km hr^-1 │    txt3 │ Point(3.0, 3.0) │
      │   3 m s^-1 │ 1.29 km hr^-1 │    txt4 │ Point(4.0, 4.0) │
      │   9 m s^-1 │ 3.64 km hr^-1 │    txt5 │ Point(5.0, 5.0) │
      │   5 m s^-1 │ 8.05 km hr^-1 │    txt6 │ Point(6.0, 6.0) │
      │   2 m s^-1 │ 0.11 km hr^-1 │    txt7 │ Point(7.0, 7.0) │
      │   2 m s^-1 │ 0.64 km hr^-1 │    txt8 │ Point(8.0, 8.0) │
      │   8 m s^-1 │ 8.46 km hr^-1 │    txt9 │ Point(9.0, 9.0) │
      └────────────┴───────────────┴─────────┴─────────────────┘"""

      nv = length(vertices(grid))
      gtb = GeoTable(grid, etable=(; a, b, c), vtable=(; d=rand(nv)))
      @test sprint(show, gtb) == "9×4 GeoTable over 3×3 CartesianGrid{2,Float64}"
      @test sprint(show, MIME("text/plain"), gtb) == """
      9×4 GeoTable over 3×3 CartesianGrid{2,Float64}
      ┌─────────┬────────────┬─────────┬────────────────────────────────────────────────────────────────────────────────┐
      │       a │          b │       c │                                                                       geometry │
      │   Count │ Continuous │ Textual │                                                         Quadrangle{2, Float64} │
      │ NoUnits │    NoUnits │ NoUnits │                                                                                │
      ├─────────┼────────────┼─────────┼────────────────────────────────────────────────────────────────────────────────┤
      │       0 │       2.34 │    txt1 │ Quadrangle(Point(0.0, 0.0), Point(1.0, 0.0), Point(1.0, 1.0), Point(0.0, 1.0)) │
      │       6 │        7.5 │    txt2 │ Quadrangle(Point(1.0, 0.0), Point(2.0, 0.0), Point(2.0, 1.0), Point(1.0, 1.0)) │
      │       6 │       0.06 │    txt3 │ Quadrangle(Point(2.0, 0.0), Point(3.0, 0.0), Point(3.0, 1.0), Point(2.0, 1.0)) │
      │       3 │       1.29 │    txt4 │ Quadrangle(Point(0.0, 1.0), Point(1.0, 1.0), Point(1.0, 2.0), Point(0.0, 2.0)) │
      │       9 │       3.64 │    txt5 │ Quadrangle(Point(1.0, 1.0), Point(2.0, 1.0), Point(2.0, 2.0), Point(1.0, 2.0)) │
      │       5 │       8.05 │    txt6 │ Quadrangle(Point(2.0, 1.0), Point(3.0, 1.0), Point(3.0, 2.0), Point(2.0, 2.0)) │
      │       2 │       0.11 │    txt7 │ Quadrangle(Point(0.0, 2.0), Point(1.0, 2.0), Point(1.0, 3.0), Point(0.0, 3.0)) │
      │       2 │       0.64 │    txt8 │ Quadrangle(Point(1.0, 2.0), Point(2.0, 2.0), Point(2.0, 3.0), Point(1.0, 3.0)) │
      │       8 │       8.46 │    txt9 │ Quadrangle(Point(2.0, 2.0), Point(3.0, 2.0), Point(3.0, 3.0), Point(2.0, 3.0)) │
      └─────────┴────────────┴─────────┴────────────────────────────────────────────────────────────────────────────────┘
      Additional tables encountered for the following ranks: 0"""
    
      gtb = georef((a=[missing; a[2:9]], b=[b[1:4]; missing; b[6:9]], c=[c[1:8]; missing]), pset)
      @test sprint(show, gtb) == "9×4 GeoTable over 9 PointSet{2,Float64}"
      @test sprint(show, MIME("text/plain"), gtb) == """
      9×4 GeoTable over 9 PointSet{2,Float64}
      ┌─────────┬────────────┬─────────┬─────────────────┐
      │       a │          b │       c │        geometry │
      │   Count │ Continuous │ Textual │          Point2 │
      │ NoUnits │    NoUnits │ NoUnits │                 │
      ├─────────┼────────────┼─────────┼─────────────────┤
      │ missing │       2.34 │    txt1 │ Point(1.0, 1.0) │
      │       6 │        7.5 │    txt2 │ Point(2.0, 2.0) │
      │       6 │       0.06 │    txt3 │ Point(3.0, 3.0) │
      │       3 │       1.29 │    txt4 │ Point(4.0, 4.0) │
      │       9 │    missing │    txt5 │ Point(5.0, 5.0) │
      │       5 │       8.05 │    txt6 │ Point(6.0, 6.0) │
      │       2 │       0.11 │    txt7 │ Point(7.0, 7.0) │
      │       2 │       0.64 │    txt8 │ Point(8.0, 8.0) │
      │       8 │       8.46 │ missing │ Point(9.0, 9.0) │
      └─────────┴────────────┴─────────┴─────────────────┘"""
    end
  end
end
