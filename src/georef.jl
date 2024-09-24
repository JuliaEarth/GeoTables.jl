# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    georef(table, domain)

Georeference `table` on `domain` from
[Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl)

## Examples

```julia
julia> georef((a=rand(100), b=rand(100)), CartesianGrid(10, 10))
```
"""
georef(table, domain::Domain) = GeoTable(domain, etable=table)

"""
    georef(table, geoms)

Georeference `table` on vector of geometries `geoms` from
[Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl)

## Examples

```julia
julia> georef((a=rand(10), b=rand(10)), rand(Point, 10))
```
"""
georef(table, geoms::AbstractVector{<:Geometry}) = georef(table, GeometrySet(geoms))

"""
    georef(table, coords; [crs])

Georeference `table` using coordinates `coords` of points.

Optionally, specify the coordinate reference system `crs`, which is
set by default based on heuristics. Any `CRS` or `EPSG`/`ESRI` code
from [CoordRefSystems.jl](https://github.com/JuliaEarth/CoordRefSystems.jl)
is supported.

## Examples

```julia
julia> georef((a=[1, 2, 3], b=[4, 5, 6], [(0, 0), (1, 1), (2, 2)])
julia> georef((a=[1, 2, 3], b=[4, 5, 6], [(0, 0), (1, 1), (2, 2)], crs=LatLon)
julia> georef((a=[1, 2, 3], b=[4, 5, 6], [(0, 0), (1, 1), (2, 2)], crs=EPSG{4326})
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
    georef(table, names; [crs], [lenunit])

Georeference `table` using coordinates of points stored in column `names`.

Optionally, specify the coordinate reference system `crs`, which is
set by default based on heuristics, and the `lenunit` (default to meter)
that will be used in CRS types that allow this flexibility. Any `CRS` or `EPSG`/`ESRI` 
code from [CoordRefSystems.jl](https://github.com/JuliaEarth/CoordRefSystems.jl)
is supported.

## Examples

```julia
georef((a=rand(10), x=rand(10), y=rand(10)), ("x", "y"))
georef((a=rand(10), x=rand(10), y=rand(10)), ("x", "y"), crs=LatLon)
georef((a=rand(10), x=rand(10), y=rand(10)), ("x", "y"), crs=EPSG{4326})
georef((a=rand(10), x=rand(10), y=rand(10)), ("x", "y"), lenunit=u"cm")
```
"""
function georef(table, names::AbstractVector{Symbol}; crs=nothing, lenunit=u"m")
  cols = Tables.columns(table)
  tnames = Tables.columnnames(cols)
  if names ⊈ tnames
    throw(ArgumentError("coordinate columns not found in the table"))
  end

  # guess crs if necessary
  ccrs, cnames = isnothing(crs) ? guesscrs(cols, names) : (validcrs(crs), names)

  # build points with coordinates
  point = pointbuilder(ccrs, lenunit)
  points = map(point, (Tables.getcolumn(cols, nm) for nm in cnames)...)

  # build table with values
  vnames = setdiff(tnames, names)
  etable = isempty(vnames) ? nothing : (; (nm => Tables.getcolumn(cols, nm) for nm in vnames)...)

  georef(etable, points)
end

georef(table, names::AbstractVector{<:AbstractString}; kwargs...) = georef(table, Symbol.(names); kwargs...)
georef(table, names::NTuple{N,Symbol}; kwargs...) where {N} = georef(table, collect(names); kwargs...)
georef(table, names::NTuple{N,<:AbstractString}; kwargs...) where {N} =
  georef(table, collect(Symbol.(names)); kwargs...)

"""
    georef(tuple)

Georeference a named `tuple` on `CartesianGrid(dims)`,
with `dims` obtained from the arrays stored in the tuple.

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
  lonnames = variants(["lon", "long", "longitude"])
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

# point builder that adds the length unit to the right coordinates
function pointbuilder(crs, u)
  if crs <: Cartesian
    (xyz...) -> Point(crs((xyz .* u)...))
  elseif crs <: Polar
    (ρ, ϕ) -> Point(crs(ρ * u, ϕ * u"rad"))
  elseif crs <: Cylindrical
    (ρ, ϕ, z) -> Point(crs(ρ * u, ϕ * u"rad", z * u))
  elseif crs <: Spherical
    (r, θ, ϕ) -> Point(crs(r * u, θ * u"rad", ϕ * u"rad"))
  else
    (coords...) -> Point(crs(coords...))
  end
end

# variants of given names with uppercase, etc.
variants(names) = [names; uppercase.(names); uppercasefirst.(names)]

# validate crs/code provided by user
validcrs(crs::Type{<:CRS}) = crs
validcrs(code::Type{<:EPSG}) = CoordRefSystems.get(code)
validcrs(code::Type{<:ESRI}) = CoordRefSystems.get(code)
