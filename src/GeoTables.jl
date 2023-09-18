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
import Meshes: partitioninds
import Meshes: sampleinds
import Meshes: sortinds

include("abstractgeotable.jl")
include("geotable.jl")
include("subgeotable.jl")
include("indices.jl")
include("georef.jl")

export
  # interface
  AbstractGeoTable,
  GeoTable,
  domain,
  constructor,
  nrow,
  ncol,
  asarray,

  # georeferencing
  georef

end
