# GeoTables.jl

[![][build-img]][build-url] [![][codecov-img]][codecov-url]

Load geospatial tables from known file formats and convert the
geometries to [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl)
geometries that are compatible with the
[GeoStats.jl](https://github.com/JuliaEarth/GeoStats.jl) ecosystem. 

Geometries are loaded in pure Julia using packages such as
[Shapefile.jl](https://github.com/JuliaGeo/Shapefile.jl) and
[GeoJSON.jl](https://github.com/JuliaGeo/GeoJSON.jl).
This means that there are no dependencies on heavy external
libraries such as GDAL.

## Usage

The package provides a single `load` function to load data as a
[Tables.jl](https://github.com/JuliaData/Tables.jl) table
that implements the `Meshes.Data` trait. This means that this
table can be passed directly to GeoStats.jl as geospatial data:

```julia
julia> using GeoTables

julia> table = GeoTables.load("/path/to/file.shp")
4 GeoTable{2,Float64}
  variables
    └─ACRES (Union{Missing, Float64})
    └─Hectares (Union{Missing, Float64})
    └─MACROZONA (Union{Missing, String})
    └─PERIMETER (Union{Missing, Float64})
    └─area_m2 (Union{Missing, Float64})
  domain: 4 GeometrySet{2,Float64}
```

The result can be easily converted into any other table type:

```julia
using DataFrames

df = table |> DataFrame
```

and converted back to geospatial data with:

```julia
using GeoStats

df |> GeoData
```

## Asking for help

If you have any questions, please [contact our community](https://juliaearth.github.io/GeoStats.jl/stable/about/community.html).

[build-img]: https://img.shields.io/github/workflow/status/JuliaEarth/GeoTables.jl/CI?style=flat-square
[build-url]: https://github.com/JuliaEarth/GeoTables.jl/actions

[codecov-img]: https://img.shields.io/codecov/c/github/JuliaEarth/GeoTables.jl?style=flat-square
[codecov-url]: https://codecov.io/gh/JuliaEarth/GeoTables.jl
