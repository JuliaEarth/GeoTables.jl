# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes
using Tables
using Random
using Unitful
using Statistics
using PrettyTables
using ScientificTypes

using Unitful: AbstractQuantity, AffineQuantity
using ColumnSelectors: ColumnSelector, SingleColumnSelector
using ColumnSelectors: Column, NoneSelector
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

# geometric operations
include("geoops/utils.jl")
include("geoops/macros.jl")
include("geoops/geojoin.jl")
include("geoops/groupby.jl")
include("geoops/transform.jl")
include("geoops/combine.jl")

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

  # geometric operations
  geojoin,
  @groupby,
  @transform,
  @combine,

  # georeferencing
  georef

end
