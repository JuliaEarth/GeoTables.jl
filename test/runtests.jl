using GeoTables
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
  zone = GeoTables.load(joinpath(datadir,"zone.shp"))
  path = GeoTables.load(joinpath(datadir,"path.shp"))

  if visualtests
    Random.seed!(123)
    p = plot(size=(600,400))
    plot!(domain(zone), fill=true, color=:gray)
    plot!(domain(path), fill=true, color=:gray90)
    @test_reference "data/zonepath.png" p
  end
end
