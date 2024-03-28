# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTablesMakieExt

using GeoTables

using Dates
using Tables
using Unitful
using Distributions
using CategoricalArrays
using DataScienceTraits
using Makie: cgrad, coloralpha
using Makie.Colors: Colorant, Gray
using DataScienceTraits: Continuous
using DataScienceTraits: Categorical
using DataScienceTraits: Distributional
using DataScienceTraits: Unknown

import Makie
import Meshes: viz, viz!
import Meshes: ascolors
import Meshes: defaultscheme
import GeoTables: viewer

const CategArray{T,N} = Union{CategoricalArray{T,N},SubArray{T,N,<:CategoricalArray}}

include("colors.jl")
include("viewer.jl")

# ----------------
# COMMON MISTAKES
# ----------------

viz(::AbstractGeoTable, args...; kwargs...) = vizmistake()
viz!(::AbstractGeoTable, args...; kwargs...) = vizmistake()
vizmistake() = throw(ArgumentError(
  """
  Expected a `Geometry`, `Domain` or vector of these types. Got a `GeoTable` instead.
  Use the `viewer` to visualize all the columns of the `GeoTable` over its domain.
  """
))

viewer(args...; kwargs...) = viewermistake()
viewermistake() = throw(ArgumentError(
  """
  Expected a `GeoTable`. Use `viz` to visualize a `Geometry`, `Domain` or vector of these types.
  """
))

end
