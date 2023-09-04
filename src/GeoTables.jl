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
include("georef.jl")
include("deprecations.jl")

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
