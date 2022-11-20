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
specify the layer of geometries to read within the file.

## Supported formats

- `*.shp` via Shapefile.jl
- `*.geojson` via GeoJSON.jl
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
    save(fname, geotable)

Save geospatial table to file `fname` using the
appropriate format based on the file extension.

## Supported formats

- `*.geojson` via GeoJSON.jl
"""
function save(fname, geotable)
  if endswith(fname, ".geojson")
    GJS.write(fname, geotable)
  else
    throw(ErrorException("file format not supported"))
  end
end

"""
    gadm(country, subregions...; depth=0, tol=0.04)

(Down)load GADM table using `GADM.get` and convert
the `geometry` column to Meshes.jl geometries.

The `depth` option can be used to return tables for subregions
at a given depth starting from the given region specification.

If `tol` is greater than zero, decimate the geometries to reduce
the number of vertices. The greater is the `tol` value, the more
aggressive is the reduction.
"""
function gadm(country, subregions...; depth=0, tol=0.04)
  table  = GADM.get(country, subregions...; depth=depth)
  gtable = GeoTable(table)
  if tol > 0
    𝒯 = values(gtable)
    𝒟 = domain(gtable)
    meshdata(decimate(𝒟, tol), etable=𝒯)
  else
    gtable
  end
end

end
