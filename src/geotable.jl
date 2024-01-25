# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GeoTable(domain, values)

A `domain` together with a dictionary of geotable `values`. For each rank `r`
(or parametric dimension) there can exist a corresponding Tables.jl table
`values[r]`.

## Examples

```julia
# attach temperature and pressure to grid elements
GeoTable(CartesianGrid(10,10),
  Dict(2 => (temperature=rand(100), pressure=rand(100)))
)
```
"""
mutable struct GeoTable{T} <: AbstractGeoTable
  domain::Domain
  values::Dict{Int,T}
end

# getters
getdomain(gtb::GeoTable) = getfield(gtb, :domain)
getvalues(gtb::GeoTable) = getfield(gtb, :values)

"""
    GeoTable(domain; vtable, etable)

Create spatial geotable from a `domain`, a table `vtable`
with geotable for the vertices, and a table `etable` with
geotable for the elements.

## Examples

```julia
GeoTable(CartesianGrid(10,10),
  etable = (temperature=rand(100), pressure=rand(100))
)
```
"""
function GeoTable(domain::Domain; vtable=nothing, etable=nothing)
  d = paramdim(domain)
  values = if !isnothing(vtable) && !isnothing(etable)
    Dict(0 => vtable, d => etable)
  elseif !isnothing(etable)
    Dict(d => etable)
  elseif !isnothing(vtable)
    Dict(0 => vtable)
  else
    Dict(d => nothing)
  end
  GeoTable(domain, values)
end

# -----------
# MUTABILITY
# -----------

function Base.setproperty!(geotable::GeoTable, name::Symbol, domain::Domain)
  if name !== :geometry
    error("only the `geometry` column can be set in the current version")
  end
  if length(domain) ≠ nrow(geotable)
    error("the new domain must have the same number of elements as the geotable")
  end
  setfield!(geotable, :domain, domain)
end

Base.setproperty!(geotable::GeoTable, name::Symbol, geoms::AbstractVector{<:Geometry}) =
  setproperty!(geotable, name, GeometrySet(geoms))

# ----------------------------
# ABSTRACT GEOTABLE INTERFACE
# ----------------------------

domain(geotable::GeoTable) = getdomain(geotable)

function Base.values(geotable::GeoTable, rank=nothing)
  domain = getdomain(geotable)
  values = getvalues(geotable)
  r = isnothing(rank) ? paramdim(domain) : rank
  get(values, r, nothing)
end
