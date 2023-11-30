using GeoTables
using TypedTables
using TableTransforms
using Unitful
using Tables
using Meshes
using LinearAlgebra
using Statistics
using Test

include("dummy.jl")

# list of tests
testfiles = ["basics.jl"]

@testset "GeoTables.jl" begin
  for testfile in testfiles
    println("Testing $testfile...")
    include(testfile)
  end
end
