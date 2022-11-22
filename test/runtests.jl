using GeoTables
using Tables
using Meshes
using Test, Random

# environment settings
isCI = "CI" ∈ keys(ENV)
islinux = Sys.islinux()
datadir = joinpath(@__DIR__,"data")

@testset "GeoTables.jl" begin
  @testset "load" begin
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
