# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes
using Tables
using Random

import Base: values
import Meshes: unview
import DataAPI: nrow, ncol
import StatsBase: sample

export AbstractGeoTable, domain, values, constructor
export nrow, ncol, asarray, unview
export GeoTable, geotable

include("abstractgeotable.jl")
include("geotableview.jl")
include("geotable.jl")
include("deprecations.jl")

end
