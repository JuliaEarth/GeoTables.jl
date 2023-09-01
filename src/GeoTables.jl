# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes
using Tables
using Random

import DataAPI: nrow, ncol

include("abstractgeotable.jl")
include("geotableview.jl")
include("geotable.jl")
include("deprecations.jl")

export
  # AbstractGeoTable interface
  AbstractGeoTable,
  domain,
  # Base.values,
  constructor,

  # implementation
  GeoTable,
  geotable,

  # DataAPI interface
  nrow,
  ncol,

  # utilities
  asarray

end
