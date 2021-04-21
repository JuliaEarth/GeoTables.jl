module GeoTables

using Meshes

import Meshes
import Shapefile as SHP
import GeoInterface as GI

# ---------------------
# CONVERSION FUNCTIONS
# ---------------------

coords2point(coords) = Point(coords)

coords2multipoint(coords) = Multi(coords2point.(coords))

coords2chain(coords) = Chain(Point.(coords))

coords2multichain(coords) = Multi(coords2chain.(coords))

function coords2poly(coords)
  chains = [Point.(coord) for coord in coords]
  PolyArea(chains[begin], chains[begin+1:end])
end

coords2multipoly(coords) = Multi(coords2poly.(coords))

function geom2meshes(geom)
  gtype  = GI.geotype(geom)
  coords = GI.coordinates(geom)
  if gtype == :Point
    coords2point(coords)
  elseif gtype == :LineString
    coords2chain(coords)
  elseif gtype == :MultiLineString
    coords2multichain(coords)
  elseif gtype == :Polygon
    coords2poly(coords)
  elseif gtype == :MultiPolygon
    coords2multipoly(coords)
  end
end

# --------------
# GEOTABLE TYPE
# --------------

"""
    GeoTable{𝒯}

A geospatial table where the underlying table of type `𝒯`
is converted lazily row-by-row to contain geometries from
Meshes.jl for computational geometry in pure Julia.

This table type implements the `Meshes.Data` trait and is
therefore ready to use with the GeoStats.jl ecosystem.
"""
struct GeoTable{𝒯} <: Meshes.Data
  table::𝒯
end

function Meshes.domain(t::GeoTable{𝒯}) where {𝒯<:SHP.Table}
  geoms = SHP.shapes(t.table)
  items = geom2meshes.(geoms)
  Meshes.Collection(items)
end

function Meshes.values(t::GeoTable{𝒯}) where {𝒯<:SHP.Table}
  SHP.getdbf(t.table)
end

"""
    load(fname)

Load geospatial table from file `fname` and convert the
`geometry` column to Meshes.jl geometries.

Currently supported file types are:

- `*.shp` via Shapefile.jl
"""
function load(fname)
  if endswith(fname, ".shp")
    table = SHP.Table(fname)
  else
    throw(ErrorException("Unknown file format"))
  end
  GeoTable(table)
end

end
