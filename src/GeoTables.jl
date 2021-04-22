# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes

import Tables
import Meshes

import GADM
import Shapefile as SHP
import GeoInterface as GI

include("conversion.jl")
include("geotable.jl")

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

"""
    gadm(country, subregions...; children=true)

(Down)load GADM table using `GADM.get` and convert
the `geometry` column to Meshes.jl geometries.

If `children` is `true`, return the table with the
geometries of the subregions, otherwise return a single
geometry for the final subregion in the specification.
"""
function gadm(country, subregions...; children=false)
  data  = GADM.get(country, subregions...; children=children)
  table = children ? data[2] : data
  GeoTable(table)
end

end
