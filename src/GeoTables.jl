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
using StyledStrings
using CoordRefSystems
using DataScienceTraits

using Unitful: AbstractQuantity, AffineQuantity
using ColumnSelectors: ColumnSelector, SingleColumnSelector
using ColumnSelectors: Column, NoneSelector
using ColumnSelectors: selector, selectsingle
using TransformsBase: preprocess

import DataAPI: nrow, ncol
import Meshes: partitioninds
import Meshes: sampleinds
import Meshes: sortinds
import Meshes: crs
import TransformsBase: apply, revert, reapply

# required for VSCode table viewer
import TableTraits
import IteratorInterfaceExtensions

# IO utils
include("ioutils.jl")

# abstract type
include("abstractgeotable.jl")
include("api/tables.jl")
include("api/dataframes.jl")
include("api/geotables.jl")

# geometric operations
include("geoops/utils.jl")
include("geoops/macros.jl")
include("geoops/geojoin.jl")
include("geoops/tablejoin.jl")
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

# geometric transforms
include("geotransforms.jl")

# visualization
include("viewer.jl")

function __init__()
  # register error hint for visualization functions
  # since this is a recurring issue for new users
  Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
    if exc.f == viewer || exc.f == cbar
      if isnothing(Base.get_extension(GeoTables, :GeoTablesMakieExt))
        print(
          io,
          """

          Did you import a Makie.jl backend (e.g., GLMakie.jl, CairoMakie.jl) for visualization?

          """
        )
        printstyled(
          io,
          """
          julia> using GeoTables
          julia> import GLMakie # or CairoMakie, WGLMakie, etc.
          """,
          color=:cyan,
          bold=true
        )
      end
    end
  end
end

export
  # interface
  AbstractGeoTable,
  GeoTable,
  domain,
  asarray,
  nrow,
  ncol,

  # geometric operations
  geojoin,
  tablejoin,
  @groupby,
  @transform,
  @combine,

  # georeferencing
  georef,

  # visualization
  viewer,
  cbar

end
