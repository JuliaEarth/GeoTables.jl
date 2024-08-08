using GeoTables
using TypedTables
using TableTransforms
using CategoricalArrays
using DataScienceTraits
using CoordRefSystems
using Unitful
using Tables
using Meshes
using CoDa
using LinearAlgebra
using Statistics
using Random
using Test

import TableTraits
import IteratorInterfaceExtensions

include("dummy.jl")

# list of tests
testfiles = [
  "basics.jl",
  "views.jl",
  "georef.jl",
  "noattribs.jl",
  "indices.jl",
  "operations.jl",
  "feature.jl",
  "geometric.jl",
  "misc.jl",
  "shows.jl"
]

@testset "GeoTables.jl" begin
  for testfile in testfiles
    println("Testing $testfile...")
    include(testfile)
  end
end
