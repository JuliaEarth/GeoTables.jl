# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTables

using Meshes

import Tables
import Meshes

import GADM
import GeoJSON as GJS
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
  elseif endswith(fname, ".geojson")
    data  = Base.read(fname)
    table = GJS.read(data)
  else # fallback to GDAL
    data  = AG.read(fname)
    table = AG.getlayer(data, layer)
  end
  GeoTable(table)
end

"""
    gadm(country, subregions...; depth=0, decimation=0.04)

(Down)load GADM table using `GADM.get` and convert
the `geometry` column to Meshes.jl geometries.

The `depth` option can be used to return tables for subregions
at a given depth starting from the given region specification.

If `decimation` is greater than zero, decimate the geometries
to reduce the number of vertices. The greater is the `decimation`
value, the more aggressive is the reduction.
"""
function gadm(country, subregions...; depth=0, decimation=0.04)
  table  = GADM.get(country, subregions...; depth=depth)
  gtable = GeoTable(table)
  if decimation > 0
    𝒯 = values(gtable)
    𝒟 = domain(gtable)
    𝒩 = decimate(𝒟, decimation)
    meshdata(𝒩, etable=𝒯)
  else
    gtable
  end
end

end
