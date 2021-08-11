using GeoTables
using Tables
using Meshes
using Test, Random, Plots
using ReferenceTests, ImageIO

# workaround GR warnings
ENV["GKSwstype"] = "100"

# environment settings
isCI = "CI" ∈ keys(ENV)
islinux = Sys.islinux()
visualtests = !isCI || (isCI && islinux)
datadir = joinpath(@__DIR__,"data")

@testset "GeoTables.jl" begin
  table = GeoTables.load(joinpath(datadir,"test1.gpkg"))
  @test table.id isa Vector{String}
  @test table.x isa Vector{Float64}
  @test table.y isa Vector{Float64}
  @test table.z isa Vector{Float64}
  @test table.geometry isa Vector{<:Point}

  table = GeoTables.load(joinpath(datadir,"test2.gpkg"))
  row = first(Tables.rows(table))
  @test row.municipio  == "Fortaleza"
  @test row.ano_cria   == 1725.0
  @test row.regiao     == "Grande Fortaleza"
  @test row.area_km2   == 312.21031
  @test row.codigo_ibg == "2304400"
  @test row.geometry isa Multi

  if visualtests
    zone = GeoTables.load(joinpath(datadir,"zone.shp"))
    path = GeoTables.load(joinpath(datadir,"path.shp"))

    Random.seed!(123)
    p = plot(size=(600,400))
    plot!(domain(zone), fill=true, color=:gray)
    plot!(domain(path), fill=true, color=:gray90)
    @test_reference "data/zonepath.png" p
  end
end
