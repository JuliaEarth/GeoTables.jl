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
    load(fname, layer=0, lazy=false, kwargs...)

Load geospatial table from file `fname` and convert the
`geometry` column to Meshes.jl geometries.

Optionally, specify the `layer` of geometries to read
within the file and keyword arguments `kwargs` accepted
by `Shapefile.Table`, `GeoJSON.read` and `ArchGDAL.read`.
For example, use `numbertype = Float64` to read `.geojson`
geometries with `Float64` precision.

The option `lazy` can be used to convert geometries on
the fly instead of converting them immediately.

## Supported formats

- `*.shp` via Shapefile.jl
- `*.geojson` via GeoJSON.jl
- Other formats via ArchGDAL.jl
"""
function load(fname; layer=0, lazy=false, kwargs...)
  if endswith(fname, ".shp")
    table = SHP.Table(fname; kwargs...)
  elseif endswith(fname, ".geojson")
    data = Base.read(fname)
    table = GJS.read(data; kwargs...)
  else # fallback to GDAL
    data = AG.read(fname; kwargs...)
    table = AG.getlayer(data, layer)
  end
  gtable = GeoTable(table)
  lazy ? gtable : Meshes.MeshData(gtable)
end

"""
    save(fname, geotable; kwargs...)

Save geospatial table to file `fname` using the
appropriate format based on the file extension.
Optionally, specify keyword arguments accepted by
`Shapefile.write` and `GeoJSON.write`. For example, use
`force = true` to force writing on existing `.shp` file.

## Supported formats

- `*.shp` via Shapefile.jl
- `*.geojson` via GeoJSON.jl
"""
function save(fname, geotable; kwargs...)
  if endswith(fname, ".shp")
    SHP.write(fname, geotable; kwargs...)
  elseif endswith(fname, ".geojson")
    GJS.write(fname, geotable; kwargs...)
  else
    throw(ErrorException("file format not supported"))
  end
end

"""
    gadm(country, subregions...; depth=0, ϵ=nothing,
         min=3, max=typemax(Int), maxiter=10)

(Down)load GADM table using `GADM.get` and convert
the `geometry` column to Meshes.jl geometries.

The `depth` option can be used to return tables for subregions
at a given depth starting from the given region specification.

The options `ϵ`, `min`, `max` and `maxiter` are forwarded to the
`decimate` function from Meshes.jl to reduce the number of vertices.
"""
function gadm(country, subregions...; depth=0, ϵ=nothing, min=3, max=typemax(Int), maxiter=10, kwargs...)
  table = GADM.get(country, subregions...; depth=depth, kwargs...)
  gtable = GeoTable(table)
  𝒯 = values(gtable)
  𝒟 = domain(gtable)
  𝒩 = decimate(𝒟, ϵ, min=min, max=max, maxiter=maxiter)
  meshdata(𝒩, etable=𝒯)
end

end
