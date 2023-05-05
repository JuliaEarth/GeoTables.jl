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
datadir = joinpath(@__DIR__,"data")
writedir = mktempdir()

@testset "GeoTables.jl" begin
  @testset "convert" begin
    points = Point2[(0,0),(0.5,2),(2.2,2.2)]
    outer = Point2[(0,0),(0.5,2),(2.2,2.2),(0,0)]

    # GI functions
    @test GI.ngeom(Segment(points[1:2])) == 2
    @test GI.ngeom(Chain(points)) == 3
    @test GI.ngeom(Chain(outer)) == 4
    @test GI.ngeom(PolyArea(outer)) == 1
    @test GI.ngeom(Multi(points)) == 3
    @test GI.ngeom(Multi([Chain(outer), Chain(outer)])) == 2
    @test GI.ngeom(Multi([PolyArea(outer), PolyArea(outer)])) == 2

    # Shapefile.jl
    ps = [SHP.Point(0,0), SHP.Point(0.5,2), SHP.Point(2.2,2.2)]
    exterior = [SHP.Point(0,0), SHP.Point(0.5,2), SHP.Point(2.2,2.2), SHP.Point(0,0)]
    box = SHP.Rect(0.0, 0.0, 2.2, 2.2)
    point = SHP.Point(1.0,1.0)
    chain = SHP.LineString{SHP.Point}(view(ps, 1:3))
    poly = SHP.SubPolygon([SHP.LinearRing{SHP.Point}(view(exterior, 1:4))])
    multipoint = SHP.MultiPoint(box, ps)
    multichain = SHP.Polyline(box, [0,3], repeat(ps, 2))
    multipoly = SHP.Polygon(box, [0,4], repeat(exterior, 2))
    @test GeoTables.geom2meshes(point) == Point(1.0, 1.0)
    @test GeoTables.geom2meshes(chain) == Chain(points)
    @test GeoTables.geom2meshes(poly) == PolyArea(outer)
    @test GeoTables.geom2meshes(multipoint) == Multi(points)
    @test GeoTables.geom2meshes(multichain) == Multi([Chain(points), Chain(points)])
    @test GeoTables.geom2meshes(multipoly) == Multi([PolyArea(outer), PolyArea(outer)])

    # ArchGDAL.jl
    ps = [(0,0), (0.5,2), (2.2,2.2)]
    exterior = [(0,0), (0.5,2), (2.2,2.2), (0,0)]
    point = AG.createpoint(1.0,1.0)
    chain = AG.createlinestring(ps)
    poly = AG.createpolygon(exterior)
    multipoint = AG.createmultipoint(ps)
    multichain = AG.createmultilinestring([ps, ps])
    multipoly = AG.createmultipolygon([[exterior], [exterior]])
    @test GeoTables.geom2meshes(point) == Point(1.0, 1.0)
    @test GeoTables.geom2meshes(chain) == Chain(points)
    @test GeoTables.geom2meshes(poly) == PolyArea(outer)
    @test GeoTables.geom2meshes(multipoint) == Multi(points)
    @test GeoTables.geom2meshes(multichain) == Multi([Chain(points), Chain(points)])
    @test GeoTables.geom2meshes(multipoly) == Multi([PolyArea(outer), PolyArea(outer)])

    # GeoJSON.jl
    points = Point2f[(0,0),(0.5,2),(2.2,2.2)]
    outer = Point2f[(0,0),(0.5,2),(2.2,2.2),(0,0)]
    point = GJS.read("""{"type":"Point","coordinates":[1,1]}""")
    chain = GJS.read("""{"type":"LineString","coordinates":[[0,0],[0.5,2],[2.2,2.2]]}""")
    poly = GJS.read("""{"type":"Polygon","coordinates":[[[0,0],[0.5,2],[2.2,2.2],[0,0]]]}""")
    multipoint = GJS.read("""{"type":"MultiPoint","coordinates":[[0,0],[0.5,2],[2.2,2.2]]}""")
    multichain = GJS.read("""{"type":"MultiLineString","coordinates":[[[0,0],[0.5,2],[2.2,2.2]],[[0,0],[0.5,2],[2.2,2.2]]]}""")
    multipoly = GJS.read("""{"type":"MultiPolygon","coordinates":[[[[0,0],[0.5,2],[2.2,2.2],[0,0]]],[[[0,0],[0.5,2],[2.2,2.2],[0,0]]]]}""")
    @test GeoTables.geom2meshes(point) == Point2f(1.0, 1.0)
    @test GeoTables.geom2meshes(chain) == Chain(points)
    @test GeoTables.geom2meshes(poly) == PolyArea(outer)
    @test GeoTables.geom2meshes(multipoint) == Multi(points)
    @test GeoTables.geom2meshes(multichain) == Multi([Chain(points), Chain(points)])
    @test GeoTables.geom2meshes(multipoly) == Multi([PolyArea(outer), PolyArea(outer)])
  end

  @testset "load" begin
    @testset "Shapefile" begin
      varnames = (:code, :name, :date, :variable, :geometry)

      table = GeoTables.load(joinpath(datadir, "points.shp"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa Date
      @test table.variable[1] isa Real
      @test table.geometry isa PointSet
      @test table.geometry[1] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.shp"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa Date
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi
      @test collect(table.geometry[1])[1] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.shp"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa Date
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi
      @test collect(table.geometry[1])[1] isa PolyArea

      table = GeoTables.load(joinpath(datadir,"path.shp"))
      @test Tables.schema(table).names == (:ZONA, :geometry)
      @test nitems(table) == 6
      @test table.ZONA == ["PA 150","BR 364","BR 163","BR 230","BR 010","Estuarina PA"]
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi

      table = GeoTables.load(joinpath(datadir,"zone.shp"))
      @test Tables.schema(table).names == (:PERIMETER, :ACRES, :MACROZONA, :Hectares, :area_m2, :geometry)
      @test nitems(table) == 4
      @test table.PERIMETER == [5.850803650776888e6, 9.539471535859613e6, 1.01743436941e7, 7.096124186552936e6]
      @test table.ACRES == [3.23144676827e7, 2.50593712407e8, 2.75528426573e8, 1.61293042687e8]
      @test table.MACROZONA == ["Estuario","Fronteiras Antigas","Fronteiras Intermediarias","Fronteiras Novas"]
      @test table.Hectares == [1.30772011078e7, 1.01411677447e8, 1.11502398263e8, 6.52729785685e7]
      @test table.area_m2 == [1.30772011078e11, 1.01411677447e12, 1.11502398263e12, 6.52729785685e11]
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi

      table = GeoTables.load(joinpath(datadir,"ne_110m_land.shp"))
      @test Tables.schema(table).names == (:featurecla, :scalerank, :min_zoom, :geometry)
      @test nitems(table) == 127
      @test all(==("Land"), table.featurecla)
      @test all(∈([0,1]), table.scalerank)
      @test all(∈([0.0,0.5,1.0,1.5]), table.min_zoom)
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Multi
    end

    @testset "GeoJSON" begin
      varnames = (:code, :name, :date, :variable, :geometry)

      table = GeoTables.load(joinpath(datadir, "points.geojson"))
      @test isempty(setdiff(Tables.schema(table).names, varnames))
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa PointSet
      @test table.geometry[1] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.geojson"))
      @test isempty(setdiff(Tables.schema(table).names, varnames))
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.geojson"))
      @test isempty(setdiff(Tables.schema(table).names, varnames))
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa PolyArea
    end

    @testset "ArchGDAL" begin
      varnames = (:code, :name, :date, :variable, :geometry)

      table = GeoTables.load(joinpath(datadir, "points.gpkg"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa DateTime
      @test table.variable[1] isa Real
      @test table.geometry isa PointSet
      @test table.geometry[1] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.gpkg"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa DateTime
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.gpkg"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa DateTime
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table.geometry[1] isa PolyArea
    end
  end

  @testset "save" begin
    filetypes = ["geojson", "gpkg", "shp"]

    @testset "points" begin
      for ft in filetypes
        table = GeoTables.load(joinpath(datadir, "points.$ft"))
        GeoTables.save(joinpath(writedir, "tpoints.geojson"), table)
        newtable = GeoTables.load(joinpath(writedir, "tpoints.geojson"))
        GeoTables.save(joinpath(writedir, "tpoints.shp"), table, force = true)
        newtable = GeoTables.load(joinpath(writedir, "tpoints.shp"))
      end
    end

    @testset "lines" begin
      table = GeoTables.load(joinpath(datadir, "lines.geojson"), numbertype = Float64)
      GeoTables.save(joinpath(writedir, "tlines.geojson"), table)
      newtable = GeoTables.load(joinpath(writedir, "tlines.geojson"))
      GeoTables.save(joinpath(writedir, "tlines.shp"), table, force = true)
      newtable = GeoTables.load(joinpath(writedir, "tlines.shp"))

      for ft in ["gpkg", "shp"]
        table = GeoTables.load(joinpath(datadir, "lines.$ft"))
        GeoTables.save(joinpath(writedir, "tlines.geojson"), table)
        newtable = GeoTables.load(joinpath(writedir, "tlines.geojson"))
        GeoTables.save(joinpath(writedir, "tlines.shp"), table, force = true)
        newtable = GeoTables.load(joinpath(writedir, "tlines.shp"))
      end
    end

    @testset "polygons" begin
      table = GeoTables.load(joinpath(datadir, "polygons.geojson"), numbertype = Float64)
      GeoTables.save(joinpath(writedir, "tpolygons.geojson"), table)
      newtable = GeoTables.load(joinpath(writedir, "tpolygons.geojson"))
      GeoTables.save(joinpath(writedir, "tpolygons.shp"), table, force = true)
      newtable = GeoTables.load(joinpath(writedir, "tpolygons.shp"))

      for ft in ["gpkg", "shp"]
        table = GeoTables.load(joinpath(datadir, "polygons.$ft"))
        GeoTables.save(joinpath(writedir, "tpolygons.geojson"), table)
        newtable = GeoTables.load(joinpath(writedir, "tpolygons.geojson"))
        GeoTables.save(joinpath(writedir, "tpolygons.shp"), table, force = true)
        newtable = GeoTables.load(joinpath(writedir, "tpolygons.shp"))
      end
    end

    @testset "multipolygons" begin
      for file in ["path", "zone", "ne_110m_land"]
        table = GeoTables.load(joinpath(datadir,"$file.shp"))
        GeoTables.save(joinpath(writedir, "t$file.geojson"), table)
        newtable = GeoTables.load(joinpath(writedir, "t$file.geojson"))
        GeoTables.save(joinpath(writedir, "t$file.shp"), table, force = true)
        newtable = GeoTables.load(joinpath(writedir, "t$file.shp"))
      end
    end
  end

  @testset "gadm" begin
    table = GeoTables.gadm("BRA", depth = 1, ϵ=0.04)
    @test nitems(table) == 27

    table = GeoTables.gadm("USA", depth = 1, ϵ=0.04)
    @test nitems(table) == 51

    table = GeoTables.gadm("IND", depth = 1)
    @test nitems(table) == 36
  end
end

rm(writedir, recursive = true)
