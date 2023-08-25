using GeoTables
using Tables
using Meshes
using Test, Random
using Dates
import GeoInterface as GI
import Shapefile as SHP
import ArchGDAL as AG
import GeoJSON as GJS

# environment settings
isCI = "CI" ∈ keys(ENV)
islinux = Sys.islinux()
datadir = joinpath(@__DIR__, "data")
savedir = mktempdir()

# Note: Shapefile.jl saves Chains and Polygons as Multi
# This function is used to work around this problem
_isequal(d1::Domain, d2::Domain) = all(_isequal(g1, g2) for (g1, g2) in zip(d1, d2))

_isequal(g1, g2) = g1 == g2
_isequal(m1::Multi, m2::Multi) = m1 == m2
_isequal(g, m::Multi) = _isequal(m, g)
function _isequal(m::Multi, g)
  gs = collect(m)
  length(gs) == 1 && first(gs) == g
end

@testset "GeoTables.jl" begin
  @testset "convert" begin
    points = Point2[(0, 0), (2.2, 2.2), (0.5, 2)]
    outer = Point2[(0, 0), (2.2, 2.2), (0.5, 2), (0, 0)]

    # GI functions
    @test GI.ngeom(Segment(points[1], points[2])) == 2
    @test GI.ngeom(Rope(points)) == 3
    @test GI.ngeom(Ring(points)) == 4
    @test GI.ngeom(PolyArea(points)) == 1
    @test GI.ngeom(Multi(points)) == 3
    @test GI.ngeom(Multi([Rope(points), Rope(points)])) == 2
    @test GI.ngeom(Multi([PolyArea(points), PolyArea(points)])) == 2

    # Shapefile.jl
    ps = [SHP.Point(0, 0), SHP.Point(2.2, 2.2), SHP.Point(0.5, 2)]
    exterior = [SHP.Point(0, 0), SHP.Point(2.2, 2.2), SHP.Point(0.5, 2), SHP.Point(0, 0)]
    box = SHP.Rect(0.0, 0.0, 2.2, 2.2)
    point = SHP.Point(1.0, 1.0)
    chain = SHP.LineString{SHP.Point}(view(ps, 1:3))
    poly = SHP.SubPolygon([SHP.LinearRing{SHP.Point}(view(exterior, 1:4))])
    multipoint = SHP.MultiPoint(box, ps)
    multichain = SHP.Polyline(box, [0, 3], repeat(ps, 2))
    multipoly = SHP.Polygon(box, [0, 4], repeat(exterior, 2))
    @test GeoTables.geom2meshes(point) == Point(1.0, 1.0)
    @test GeoTables.geom2meshes(chain) == Rope(points)
    @test GeoTables.geom2meshes(poly) == PolyArea(points)
    @test GeoTables.geom2meshes(multipoint) == Multi(points)
    @test GeoTables.geom2meshes(multichain) == Multi([Rope(points), Rope(points)])
    @test GeoTables.geom2meshes(multipoly) == Multi([PolyArea(points), PolyArea(points)])
    # degenerate chain with 2 equal points
    ps = [SHP.Point(2.2, 2.2), SHP.Point(2.2, 2.2)]
    chain = SHP.LineString{SHP.Point}(view(ps, 1:2))
    @test GeoTables.geom2meshes(chain) == Ring((2.2, 2.2))

    # ArchGDAL.jl
    ps = [(0, 0), (2.2, 2.2), (0.5, 2)]
    outer = [(0, 0), (2.2, 2.2), (0.5, 2), (0, 0)]
    point = AG.createpoint(1.0, 1.0)
    chain = AG.createlinestring(ps)
    poly = AG.createpolygon(outer)
    multipoint = AG.createmultipoint(ps)
    multichain = AG.createmultilinestring([ps, ps])
    multipoly = AG.createmultipolygon([[outer], [outer]])
    polyarea = PolyArea(outer[begin:(end - 1)])
    @test GeoTables.geom2meshes(point) == Point(1.0, 1.0)
    @test GeoTables.geom2meshes(chain) == Rope(points)
    @test GeoTables.geom2meshes(poly) == polyarea
    @test GeoTables.geom2meshes(multipoint) == Multi(points)
    @test GeoTables.geom2meshes(multichain) == Multi([Rope(points), Rope(points)])
    @test GeoTables.geom2meshes(multipoly) == Multi([polyarea, polyarea])
    # degenerate chain with 2 equal points
    chain = AG.createlinestring([(2.2, 2.2), (2.2, 2.2)])
    @test GeoTables.geom2meshes(chain) == Ring((2.2, 2.2))

    # GeoJSON.jl
    points = Point2f[(0, 0), (2.2, 2.2), (0.5, 2)]
    outer = Point2f[(0, 0), (2.2, 2.2), (0.5, 2)]
    point = GJS.read("""{"type":"Point","coordinates":[1,1]}""")
    chain = GJS.read("""{"type":"LineString","coordinates":[[0,0],[2.2,2.2],[0.5,2]]}""")
    poly = GJS.read("""{"type":"Polygon","coordinates":[[[0,0],[2.2,2.2],[0.5,2],[0,0]]]}""")
    multipoint = GJS.read("""{"type":"MultiPoint","coordinates":[[0,0],[2.2,2.2],[0.5,2]]}""")
    multichain =
      GJS.read("""{"type":"MultiLineString","coordinates":[[[0,0],[2.2,2.2],[0.5,2]],[[0,0],[2.2,2.2],[0.5,2]]]}""")
    multipoly = GJS.read(
      """{"type":"MultiPolygon","coordinates":[[[[0,0],[2.2,2.2],[0.5,2],[0,0]]],[[[0,0],[2.2,2.2],[0.5,2],[0,0]]]]}"""
    )
    @test GeoTables.geom2meshes(point) == Point2f(1.0, 1.0)
    @test GeoTables.geom2meshes(chain) == Rope(points)
    @test GeoTables.geom2meshes(poly) == PolyArea(outer)
    @test GeoTables.geom2meshes(multipoint) == Multi(points)
    @test GeoTables.geom2meshes(multichain) == Multi([Rope(points), Rope(points)])
    @test GeoTables.geom2meshes(multipoly) == Multi([PolyArea(outer), PolyArea(outer)])
    # degenerate chain with 2 equal points
    chain = GJS.read("""{"type":"LineString","coordinates":[[2.2,2.2],[2.2,2.2]]}""")
    @test GeoTables.geom2meshes(chain) == Ring(Point2f(2.2, 2.2))
  end

  @testset "load" begin
    @testset "Shapefile" begin
      table = GeoTables.load(joinpath(datadir, "points.shp"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa PointSet
      @test table.geometry[1] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.shp"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi
      @test collect(table.geometry[1])[1] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.shp"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi
      @test collect(table.geometry[1])[1] isa PolyArea

      table = GeoTables.load(joinpath(datadir, "path.shp"))
      @test Tables.schema(table).names == (:ZONA, :geometry)
      @test length(table.geometry) == 6
      @test table.ZONA == ["PA 150", "BR 364", "BR 163", "BR 230", "BR 010", "Estuarina PA"]
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi

      table = GeoTables.load(joinpath(datadir, "zone.shp"))
      @test Tables.schema(table).names == (:PERIMETER, :ACRES, :MACROZONA, :Hectares, :area_m2, :geometry)
      @test length(table.geometry) == 4
      @test table.PERIMETER == [5.850803650776888e6, 9.539471535859613e6, 1.01743436941e7, 7.096124186552936e6]
      @test table.ACRES == [3.23144676827e7, 2.50593712407e8, 2.75528426573e8, 1.61293042687e8]
      @test table.MACROZONA == ["Estuario", "Fronteiras Antigas", "Fronteiras Intermediarias", "Fronteiras Novas"]
      @test table.Hectares == [1.30772011078e7, 1.01411677447e8, 1.11502398263e8, 6.52729785685e7]
      @test table.area_m2 == [1.30772011078e11, 1.01411677447e12, 1.11502398263e12, 6.52729785685e11]
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi

      table = GeoTables.load(joinpath(datadir, "land.shp"))
      @test Tables.schema(table).names == (:featurecla, :scalerank, :min_zoom, :geometry)
      @test length(table.geometry) == 127
      @test all(==("Land"), table.featurecla)
      @test all(∈([0, 1]), table.scalerank)
      @test all(∈([0.0, 0.5, 1.0, 1.5]), table.min_zoom)
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi

      # https://github.com/JuliaEarth/GeoTables.jl/issues/32
      @test GeoTables.load(joinpath(datadir, "issue32.shp")) isa Meshes.MeshData

      # lazy loading
      @test GeoTables.load(joinpath(datadir, "lines.shp")) isa Meshes.MeshData
      @test GeoTables.load(joinpath(datadir, "lines.shp"), lazy=true) isa GeoTables.GeoTable
    end

    @testset "GeoJSON" begin
      table = GeoTables.load(joinpath(datadir, "points.geojson"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa PointSet
      @test table.geometry[1] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.geojson"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.geojson"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa PolyArea

      # lazy loading
      @test GeoTables.load(joinpath(datadir, "lines.geojson")) isa Meshes.MeshData
      @test GeoTables.load(joinpath(datadir, "lines.geojson"), lazy=true) isa GeoTables.GeoTable
    end

    @testset "KML" begin
      table = GeoTables.load(joinpath(datadir, "field.kml"))
      @test length(table.geometry) == 4
      @test table.Name[1] isa String
      @test table.Description[1] isa String
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa PolyArea
    end

    @testset "GeoPackage" begin
      table = GeoTables.load(joinpath(datadir, "points.gpkg"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa PointSet
      @test table.geometry[1] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.gpkg"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.gpkg"))
      @test length(table.geometry) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa PolyArea

      # lazy loading
      @test GeoTables.load(joinpath(datadir, "lines.gpkg")) isa Meshes.MeshData
      @test GeoTables.load(joinpath(datadir, "lines.gpkg"), lazy=true) isa GeoTables.GeoTable
    end
  end

  @testset "save" begin
    fnames = [
      "points.geojson",
      "points.gpkg",
      "points.shp",
      "lines.geojson",
      "lines.gpkg",
      "lines.shp",
      "polygons.geojson",
      "polygons.gpkg",
      "polygons.shp",
      "land.shp",
      "path.shp",
      "zone.shp",
      "issue32.shp"
    ]

    # saved and loaded tables are the same
    for fname in fnames, fmt in [".shp", ".geojson", ".gpkg"]
      # input and output file names
      f1 = joinpath(datadir, fname)
      f2 = joinpath(savedir, replace(fname, "." => "-") * fmt)

      # load and save table
      kwargs = endswith(f1, ".geojson") ? (; numbertype=Float64) : ()
      gt1 = GeoTables.load(f1; kwargs...)
      GeoTables.save(f2, gt1)
      kwargs = endswith(f2, ".geojson") ? (; numbertype=Float64) : ()
      gt2 = GeoTables.load(f2; kwargs...)

      # compare domain and values
      d1 = domain(gt1)
      d2 = domain(gt2)
      @test _isequal(d1, d2)
      t1 = values(gt1)
      t2 = values(gt2)
      c1 = Tables.columns(t1)
      c2 = Tables.columns(t2)
      n1 = Tables.columnnames(c1)
      n2 = Tables.columnnames(c2)
      @test Set(n1) == Set(n2)
      for n in n1
        x1 = Tables.getcolumn(c1, n)
        x2 = Tables.getcolumn(c2, n)
        @test x1 == x2
      end
    end
  end

  @testset "gadm" begin
    table = GeoTables.gadm("SVN", depth=1, ϵ=0.04)
    @test length(table.geometry) == 12

    table = GeoTables.gadm("QAT", depth=1, ϵ=0.04)
    @test length(table.geometry) == 7

    table = GeoTables.gadm("ISR", depth=1)
    @test length(table.geometry) == 7
  end
end
