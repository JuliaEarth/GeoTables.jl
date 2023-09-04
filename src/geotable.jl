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
struct GeoTable{D<:Domain,T} <: AbstractGeoTable
  domain::D
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
  elseif isnothing(vtable)
    Dict(d => etable)
  elseif isnothing(etable)
    Dict(0 => vtable)
  else
    throw(ArgumentError("missing geotable tables"))
  end
  GeoTable(domain, values)
end

# ----------------------------
# ABSTRACT GEOTABLE INTERFACE
# ----------------------------

domain(geotable::GeoTable) = getdomain(geotable)

function Base.values(geotable::GeoTable, rank=nothing)
  domain = getdomain(geotable)
  values = getvalues(geotable)
  r = isnothing(rank) ? paramdim(domain) : rank
  haskey(values, r) ? values[r] : nothing
end

constructor(::Type{<:GeoTable}) = GeoTable
