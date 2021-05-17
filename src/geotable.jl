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

function Meshes.values(t::GeoTable)
  table = getfield(t, :table)
  gcol  = geomcolumn(table)
  sche  = Tables.schema(table)
  vars  = setdiff(sche.names, [gcol])
  cols  = map(vars) do var
    var => Tables.getcolumn(table, var)
  end
  (; cols...)
end

# helper function to find the geometry column of a table
function geomcolumn(table)
  s = Tables.schema(table)
  if :geometry ∈ s.names
    :geometry
  elseif :geom ∈ s.names
    :geom
  else
    throw(ErrorException("geometry column not found"))
  end
end
