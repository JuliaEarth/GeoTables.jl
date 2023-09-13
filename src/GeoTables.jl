# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes
using Tables
using Random
using PrettyTables
using ScientificTypes
using Unitful

import DataAPI: nrow, ncol

include("abstractgeotable.jl")
include("geotable.jl")
include("subgeotable.jl")
include("georef.jl")

export
  # AbstractGeoTable interface
  AbstractGeoTable,
  domain,
  # Base.values,
  constructor,
  nrow,
  ncol,
  asarray,

  # implementation
  GeoTable,

  # georeferencing
  georef

end
