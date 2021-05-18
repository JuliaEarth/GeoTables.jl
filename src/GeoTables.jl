# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes

import Tables
import Meshes

import GADM
import Shapefile as SHP
import ArchGDAL as AG
import GeoInterface as GI

include("conversion.jl")
include("geotable.jl")

"""
    load(fname, layer=0)

Load geospatial table from file `fname` and convert the
`geometry` column to Meshes.jl geometries. Optionally,
specify the layer of geometries to read in the file.

Currently supported file types are:

- `*.shp` via Shapefile.jl
- Other formats via ArchGDAL.jl
"""
function load(fname, layer=0)
  if endswith(fname, ".shp")
    table = SHP.Table(fname)
  else # fallback to GDAL
    file  = AG.read(fname)
    data  = AG.getlayer(file, layer)
    table = AG.Table(data)
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
