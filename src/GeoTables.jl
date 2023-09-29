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

using Unitful: AbstractQuantity
using ColumnSelectors: ColumnSelector, SingleColumnSelector
using ColumnSelectors: selector, selectsingle

import DataAPI: nrow, ncol
import Meshes: partitioninds
import Meshes: sampleinds
import Meshes: sortinds

# abstract type
include("abstractgeotable.jl")
include("api/tables.jl")
include("api/dataframes.jl")
include("api/geotables.jl")

# concrete types
include("geotable.jl")
include("subgeotable.jl")

# indices specializations
include("indices.jl")

# georeferencing
include("georef.jl")

export
  # interface
  AbstractGeoTable,
  GeoTable,
  domain,
  constructor,
  asarray,
  nrow,
  ncol,

  # georeferencing
  georef

end
