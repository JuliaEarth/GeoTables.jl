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
julia> georef((a=rand(10), b=rand(10)), rand(Point2, 10))
```
"""
georef(table, geoms::AbstractVector{<:Geometry}) = georef(table, GeometrySet(geoms))

"""
    georef(table, coords)

Georeference `table` on `PointSet(coords)`.

## Examples

```julia
julia> georef((a=rand(10), b=rand(10)), rand(2, 10))
```
"""
georef(table, coords::AbstractVecOrMat) = georef(table, PointSet(coords))

"""
    georef(table, names)

Georeference `table` using coordinate column `names`.

## Examples

```julia
georef((a=rand(10), x=rand(10), y=rand(10)), (:x, :y))
georef((a=rand(10), x=rand(10), y=rand(10)), [:x, :y])
georef((a=rand(10), x=rand(10), y=rand(10)), ("x", "y"))
georef((a=rand(10), x=rand(10), y=rand(10)), ["x", "y"])
```
"""
function georef(table, names::AbstractVector{Symbol})
  cols = Tables.columns(table)
  tnames = Tables.columnnames(cols)
  if names ⊈ tnames
    throw(ArgumentError("coordinate columns not found in the table"))
  end
  vars = setdiff(tnames, names)
  points = map(Point, (Tables.getcolumn(cols, nm) for nm in names)...)
  etable = isempty(vars) ? nothing : (; (nm => Tables.getcolumn(cols, nm) for nm in vars)...)
  domain = PointSet(points)
  GeoTable(domain; etable)
end

georef(table, names::AbstractVector{<:AbstractString}) = georef(table, Symbol.(names))
georef(table, names::NTuple{N,Symbol}) where {N} = georef(table, collect(names))
georef(table, names::NTuple{N,<:AbstractString}) where {N} = georef(table, collect(Symbol.(names)))

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
