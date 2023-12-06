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
import Meshes: ascolors, defaultscheme
import GeoTables: viewer

const CategArray{T,N} = Union{CategoricalArray{T,N},SubArray{T,N,<:CategoricalArray}}

include("colors.jl")
include("viewer.jl")

end
