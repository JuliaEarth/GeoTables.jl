# GeoTables.jl

[![][build-img]][build-url] [![][codecov-img]][codecov-url]

Load geospatial tables from known file formats and convert the
geometries to [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl)
geometries that are compatible with the
[GeoStats.jl](https://github.com/JuliaEarth/GeoStats.jl) ecosystem. 

Geometries are loaded from disk in pure Julia whenever possible
using packages such as [Shapefile.jl](https://github.com/JuliaGeo/Shapefile.jl)
and [GeoJSON.jl](https://github.com/JuliaGeo/GeoJSON.jl), or
(down)loaded from the internet using the
[GADM.jl](https://github.com/JuliaGeo/GADM.jl) package.

## Usage

### Loading data from disk

The `load` function loads data from disk:

```julia
julia> using GeoTables

julia> table = GeoTables.load("/path/to/file.shp")
4 GeoTable{2,Float64}
  variables
    └─ACRES (Float64)
    └─Hectares (Float64)
    └─MACROZONA (String)
    └─PERIMETER (Float64)
    └─area_m2 (Float64)
  domain: 4 GeometrySet{2,Float64}
```

### Loading data from GADM

The `gadm` function (down)loads data from the GADM project:

```julia
julia> t = GeoTables.gadm("BRA", children=true)
27 GeoTable{2,Float64}
  variables
    └─CC_1 (String)
    └─ENGTYPE_1 (String)
    └─GID_0 (String)
    └─GID_1 (String)
    └─HASC_1 (String)
    └─NAME_0 (String)
    └─NAME_1 (String)
    └─NL_NAME_1 (String)
    └─TYPE_1 (String)
    └─VARNAME_1 (String)
  domain: 27 GeometrySet{2,Float64}
```

### Performance tips

The result can be easily converted into any other table type
to avoid converting the geometries every time the underlying
domain is queried.

```julia
using GeoStats

table |> GeoData
```

## Asking for help

If you have any questions, please [contact our community](https://juliaearth.github.io/GeoStats.jl/stable/about/community.html).

[build-img]: https://img.shields.io/github/workflow/status/JuliaEarth/GeoTables.jl/CI?style=flat-square
[build-url]: https://github.com/JuliaEarth/GeoTables.jl/actions

[codecov-img]: https://img.shields.io/codecov/c/github/JuliaEarth/GeoTables.jl?style=flat-square
[codecov-url]: https://codecov.io/gh/JuliaEarth/GeoTables.jl
