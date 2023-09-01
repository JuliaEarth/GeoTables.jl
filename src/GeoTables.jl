# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes
using Tables
using Random

import Meshes: unview
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

  # viewing
  # Base.view,
  unview,

  # DataAPI interface
  nrow,
  ncol,

  # utilities
  asarray

end
