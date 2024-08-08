# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    georef(table, domain)

Georeference `table` on `domain`.

`table` must implement the [Tables.jl](https://github.com/JuliaData/Tables.jl)
interface (e.g., `DataFrame`, `CSV.File`, `XLSX.Worksheet`).

`domain` must implement the [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl)
interface (e.g., `CartesianGrid`, `SimpleMesh`, `GeometrySet`).

## Examples

```julia
julia> georef((a=rand(100), b=rand(100)), CartesianGrid(10, 10))
```
"""
georef(table, domain::Domain) = GeoTable(domain, etable=table)

"""
    georef(table, geoms)

Georeference `table` on vector of geometries `geoms`.

`geoms` must implement the [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl)
interface (e.g., `Point`, `Quadrangle`, `Hexahedron`).

## Examples

```julia
julia> georef((a=rand(10), b=rand(10)), rand(Point, 10))
```
"""
georef(table, geoms::AbstractVector{<:Geometry}) = georef(table, GeometrySet(geoms))

"""
    georef(table, coords; [crs])

Georeference `table` on `PointSet(coords)` using Cartesian `coords`.

Optionally, specify the coordinate reference system `crs`, which is
set by default based on heuristics.

## Examples

```julia
julia> georef((a=rand(10), b=rand(10)), [(rand(), rand()) for i in 1:10])
```
"""
function georef(table, coords::AbstractVector; crs=nothing)
  clen = length(first(coords))
  ccrs = isnothing(crs) ? Cartesian{NoDatum,clen} : validcrs(crs)
  point(xyz...) = Point(ccrs(xyz...))
  points = [point(xyz...) for xyz in coords]
  georef(table, points)
end

"""
    georef(table, names; [crs])

Georeference `table` using coordinates stored in given column `names`.

Optionally, specify the coordinate reference system `crs`, which is
set by default based on heuristics.

## Examples

```julia
georef((a=rand(10), x=rand(10), y=rand(10)), ("x", "y"))
georef((a=rand(10), x=rand(10), y=rand(10)), ["x", "y"])
georef((a=rand(10), x=rand(10), y=rand(10)), ["x", "y"], crs=Cartesian)
georef((a=rand(10), x=rand(10), y=rand(10)), ["x", "y"], crs=LatLon)
```
"""
function georef(table, names::AbstractVector{Symbol}; crs=nothing)
  cols = Tables.columns(table)
  tnames = Tables.columnnames(cols)
  if names ⊈ tnames
    throw(ArgumentError("coordinate columns not found in the table"))
  end

  # guess crs if necessary
  ccrs, cnames = isnothing(crs) ? guesscrs(cols, names) : (validcrs(crs), names)

  # build points with coordinates
  point(xyz...) = Point(ccrs(xyz...))
  points = map(point, (Tables.getcolumn(cols, nm) for nm in cnames)...)

  # build table with values
  vnames = setdiff(tnames, names)
  etable = isempty(vnames) ? nothing : (; (nm => Tables.getcolumn(cols, nm) for nm in vnames)...)

  georef(etable, points)
end

georef(table, names::AbstractVector{<:AbstractString}; crs=nothing) = georef(table, Symbol.(names); crs)
georef(table, names::NTuple{N,Symbol}; crs=nothing) where {N} = georef(table, collect(names); crs)
georef(table, names::NTuple{N,<:AbstractString}; crs=nothing) where {N} = georef(table, collect(Symbol.(names)); crs)

"""
    georef(tuple)

Georeference a named `tuple` on `CartesianGrid(dims)`,
with `dims` being the dimensions of the `tuple` arrays.

## Examples

```julia
julia> georef((a=rand(10, 10), b=rand(10, 10))) # 2D grid
julia> georef((a=rand(10, 10, 10), b=rand(10, 10, 10))) # 3D grid
```
"""
function georef(tuple::NamedTuple{NM,<:NTuple{N,AbstractArray}}) where {NM,N}
  dims = size(first(tuple))
  for i in 2:length(tuple)
    if size(tuple[i]) ≠ dims
      throw(ArgumentError("all arrays must have the same dimensions"))
    end
  end
  table = (; (nm => reshape(x, prod(dims)) for (nm, x) in pairs(tuple))...)
  georef(table, CartesianGrid(dims))
end

# --------
# HELPERS
# --------

# guess crs based on column values and coordinate names
# return guessed crs and columns names in correct order
function guesscrs(cols, names)
  snames = string.(names)
  ncoord = length(snames)

  # variants of latlon names
  latnames = variants(["lat", "latitude"])
  lonnames = variants(["lon", "longitude"])
  latselect = findfirst(∈(latnames), snames)
  lonselect = findfirst(∈(lonnames), snames)

  if ncoord == 2 && !isnothing(latselect) && !isnothing(lonselect)
    # geodetic latitude and longitude
    crs = LatLon
    cnames = Symbol.(snames[[latselect, lonselect]])
  else
    crs = Cartesian
    cnames = names
  end

  crs, cnames
end

# variants of given names with uppercase, etc.
variants(names) = [names; uppercase.(names); uppercasefirst.(names)]

# validate crs/code provided by user
validcrs(crs::Type{<:CRS}) = crs
validcrs(code::Type{<:EPSG}) = CoordRefSystems.get(code)
validcrs(code::Type{<:ESRI}) = CoordRefSystems.get(code)
