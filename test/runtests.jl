using GeoTables
using Tables
using Meshes
using Test, Random
using Dates
import Shapefile as SHP
import ArchGDAL as AG
import GeoJSON as GJ

# environment settings
isCI = "CI" ∈ keys(ENV)
islinux = Sys.islinux()
datadir = joinpath(@__DIR__,"data")

@testset "GeoTables.jl" begin
  @testset "convert" begin
    points = Point2[(0,0),(0.5,2),(2.2,2.2)]
    outer = Point2[(0,0),(0.5,2),(2.2,2.2),(0,0)]

    # Shapefile.jl
    ps = [SHP.Point(0,0), SHP.Point(0.5,2), SHP.Point(2.2,2.2)]
    exterior = [SHP.Point(0,0), SHP.Point(0.5,2), SHP.Point(2.2,2.2), SHP.Point(0,0)]
    box = SHP.Rect(0.0, 0.0, 2.2, 2.2)
    point = SHP.Point(1.0,1.0)
    chain = SHP.LineString{SHP.Point}(view(ps, 1:3))
    poly = SHP.SubPolygon([SHP.LinearRing{SHP.Point}(view(ps, 1:3))])
    multipoint = SHP.MultiPoint(box, ps)
    multichain = SHP.Polyline(box, [0,3], repeat(ps, 2))
    multipoly = SHP.Polygon(box, [0,4], repeat(exterior, 2))
    @test GeoTables.geom2meshes(point) == Point(1.0, 1.0)
    # @test GeoTables.geom2meshes(chain) == Chain(points)
    # @test GeoTables.geom2meshes(poly) == PolyArea(outer)
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
    point = GJ.read("""{"type":"Point","coordinates":[1,1]}""")
    chain = GJ.read("""{"type":"LineString","coordinates":[[0,0],[0.5,2],[2.2,2.2]]}""")
    poly = GJ.read("""{"type":"Polygon","coordinates":[[[0,0],[0.5,2],[2.2,2.2],[0,0]]]}""")
    multipoint = GJ.read("""{"type":"MultiPoint","coordinates":[[0,0],[0.5,2],[2.2,2.2]]}""")
    multichain = GJ.read("""{"type":"MultiLineString","coordinates":[[[0,0],[0.5,2],[2.2,2.2]],[[0,0],[0.5,2],[2.2,2.2]]]}""")
    multipoly = GJ.read("""{"type":"MultiPolygon","coordinates":[[[[0,0],[0.5,2],[2.2,2.2],[0,0]]],[[[0,0],[0.5,2],[2.2,2.2],[0,0]]]]}""")
    @test GeoTables.geom2meshes(point) == Point2f(1.0, 1.0)
    @test GeoTables.geom2meshes(chain) == Chain(points)
    @test GeoTables.geom2meshes(poly) == PolyArea(outer)
    @test GeoTables.geom2meshes(multipoint) == Multi(points)
    @test GeoTables.geom2meshes(multichain) == Multi([Chain(points), Chain(points)])
    @test GeoTables.geom2meshes(multipoly) == Multi([PolyArea(outer), PolyArea(outer)])
  end

  @testset "load" begin

    @testset "custom datasets" begin
      table = GeoTables.load(joinpath(datadir,"path.shp"))
      @test Tables.schema(table).names == (:ZONA, :geometry)
      @test nitems(table) == 6
      @test table.ZONA == ["PA 150","BR 364","BR 163","BR 230","BR 010","Estuarina PA"]
      @test table.geometry isa GeometrySet
      @test table[1,:geometry] isa Multi

      table = GeoTables.load(joinpath(datadir,"zone.shp"))
      @test Tables.schema(table).names == (:PERIMETER, :ACRES, :MACROZONA, :Hectares, :area_m2, :geometry)
      @test nitems(table) == 4
      @test table.PERIMETER == [5.850803650776888e6, 9.539471535859613e6, 1.01743436941e7, 7.096124186552936e6]
      @test table.ACRES == [3.23144676827e7, 2.50593712407e8, 2.75528426573e8, 1.61293042687e8]
      @test table.MACROZONA == ["Estuario","Fronteiras Antigas","Fronteiras Intermediarias","Fronteiras Novas"]
      @test table.Hectares == [1.30772011078e7, 1.01411677447e8, 1.11502398263e8, 6.52729785685e7]
      @test table.area_m2 == [1.30772011078e11, 1.01411677447e12, 1.11502398263e12, 6.52729785685e11]
      @test table.geometry isa GeometrySet
      @test table[1,:geometry] isa Multi

      table = GeoTables.load(joinpath(datadir,"ne_110m_land.shp"))
      @test Tables.schema(table).names == (:featurecla, :scalerank, :min_zoom, :geometry)
      @test nitems(table) == 127
      @test all(==("Land"), table.featurecla)
      @test all(∈([0,1]), table.scalerank)
      @test all(∈([0.0,0.5,1.0,1.5]), table.min_zoom)
      @test table.geometry isa GeometrySet
      @test table[1,:geometry] isa Multi
    end

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
      @test table[1,:geometry] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.shp"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa Date
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table[1, :geometry] isa Multi
      @test collect(table[1, :geometry])[1] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.shp"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa Date
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table[1, :geometry] isa Multi
      @test collect(table[1, :geometry])[1] isa PolyArea
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
      @test table[1,:geometry] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.geojson"))
      @test isempty(setdiff(Tables.schema(table).names, varnames))
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table[1, :geometry] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.geojson"))
      @test isempty(setdiff(Tables.schema(table).names, varnames))
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa String
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table[1, :geometry] isa PolyArea
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
      @test table[1,:geometry] isa Point

      table = GeoTables.load(joinpath(datadir, "lines.gpkg"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa DateTime
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table[1, :geometry] isa Chain

      table = GeoTables.load(joinpath(datadir, "polygons.gpkg"))
      @test Tables.schema(table).names == varnames
      @test nitems(table) == 5
      @test table.code[1] isa Integer
      @test table.name[1] isa String
      @test table.date[1] isa DateTime
      @test table.variable[1] isa Real
      @test table.geometry isa GeometrySet
      @test table[1, :geometry] isa PolyArea
    end
  end

  @testset "save" begin
    table = GeoTables.load(joinpath(datadir,"path.shp"))
    GeoTables.save(joinpath(datadir,"path.geojson"), table)
    table = GeoTables.load(joinpath(datadir,"zone.shp"))
    GeoTables.save(joinpath(datadir,"path.geojson"), table)
  end

  @testset "gadm" begin
    table = GeoTables.gadm("BRA", depth = 1, ϵ=0.04)
    gset  = domain(table)
    @test nelements(domain(table)) == 27

    table = GeoTables.gadm("USA", depth = 1, ϵ=0.04)
    @test nelements(domain(table)) == 51

    table = GeoTables.gadm("IND", depth = 1)
    @test nelements(domain(table)) == 36
  end
end
