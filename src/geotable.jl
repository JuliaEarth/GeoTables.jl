# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GeoTable{𝒯}

A geospatial table where the underlying table of type `𝒯`
is converted lazily row-by-row to contain geometries from
Meshes.jl for computational geometry in pure Julia.

This table type implements the `Meshes.Data` trait and is
therefore compatible with the GeoStats.jl ecosystem.
"""
struct GeoTable{𝒯} <: Meshes.Data
  table::𝒯
end

function Meshes.domain(t::GeoTable)
  table = getfield(t, :table)
  gcol  = geomcolumn(table)
  geoms = Tables.getcolumn(table, gcol)
  items = geom2meshes.(geoms)
  Meshes.Collection(items)
end

function Meshes.values(t::GeoTable, rank=nothing)
  table = getfield(t, :table)
  gcol  = geomcolumn(table)
  rows  = Tables.rows(table)
  sche  = Tables.schema(rows)
  vars  = setdiff(sche.names, [gcol])
  cols  = [var => Tables.getcolumn(table, var) for var in vars]
  geoms = Tables.getcolumn(table, gcol)
  R     = paramdim(geom2meshes(first(geoms)))
  r     = isnothing(rank) ? R : rank
  r == R ? (; cols...) : nothing
end

# helper function to find the geometry column of a table
function geomcolumn(table)
  rows = Tables.rows(table)
  sche = Tables.schema(rows)
  if :geometry ∈ sche.names
    :geometry
  elseif :geom ∈ sche.names
    :geom
  else
    throw(ErrorException("geometry column not found"))
  end
end
