# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTablesMakieExt

using GeoTables

using Dates
using Tables
using Colorfy
using DataScienceTraits

using CategoricalArrays: categorical # for categorical columns
using Unitful: unit # for units in colorbar ticks

import Makie
import Meshes: viz, viz!
import GeoTables: viewer, cbar

include("utils.jl")
include("viewer.jl")
include("colorbar.jl")

# ----------------
# COMMON MISTAKES
# ----------------

viz(::AbstractGeoTable, args...; kwargs...) = vizmistake()
viz!(::AbstractGeoTable, args...; kwargs...) = vizmistake()
function vizmistake()
  throw(ArgumentError("""
  Expected a `Geometry`, `Domain` or vector of these types. Got a `GeoTable` instead.
  Use the `viewer` to visualize all the columns of the `GeoTable` over its domain.
  """))
end

viewer(args...; kwargs...) = viewermistake()
function viewermistake()
  throw(ArgumentError("""
  Expected a `GeoTable`. Use `viz` to visualize a `Geometry`, `Domain` or vector of these types.
  """))
end

end
