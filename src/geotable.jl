# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GeoTable(domain, values)

A geospatial `domain` together with a dictionary of tabular `values`.
For each rank `r` (or parametric dimension) there can exist a table
`values[r]` implementing the Tables.jl interface.

    GeoTable(domain; vtable, etable)

A geospatial `domain` together with a `vtable` of values for the
`vertices` of the `domain`, and a `etable` of values for the
`elements` of the `domain`.

## Examples

```julia
# attach temperature and pressure to grid elements
GeoTable(CartesianGrid(10,10),
  Dict(2 => (temperature=rand(100), pressure=rand(100)))
)

# same as above but uses etable keyword argument
GeoTable(CartesianGrid(10,10),
  etable = (temperature=rand(100), pressure=rand(100))
)
```

See also [`georef`](@ref).
"""
struct GeoTable{D<:Domain,T} <: AbstractGeoTable
  domain::D
  values::Dict{Int,T}
end

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

# getters
getdomain(gtb::GeoTable) = getfield(gtb, :domain)
getvalues(gtb::GeoTable) = getfield(gtb, :values)

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
