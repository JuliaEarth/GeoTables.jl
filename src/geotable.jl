# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GeoTable(domain, values)

A `domain` together with a dictionary of geotable `values`. For each rank `r`
(or parametric dimension) there can exist a corresponding Tables.jl table
`values[r]`. The helper function [`geotable`](@ref) is recommended instead
of the raw constructor of the type.
"""
struct GeoTable{D<:Domain,V<:Dict} <: AbstractGeoTable
  domain::D
  values::V
end

domain(geotable::GeoTable) = getfield(geotable, :domain)

function Base.values(geotable::GeoTable, rank=nothing)
  domain = getfield(geotable, :domain)
  values = getfield(geotable, :values)
  r = isnothing(rank) ? paramdim(domain) : rank
  haskey(values, r) ? values[r] : nothing
end

constructor(::Type{<:GeoTable}) = GeoTable

# ----------------
# HELPER FUNCTION
# ----------------

"""
    geotable(domain, values)

Create spatial geotable from a `domain` implementing the
the [`Domain`](@ref) trait and a dictionary of geotable
`values` where `values[r]` holds a Tables.jl table
for the rank `r`.

## Examples

```julia
# attach temperature and pressure to grid elements
geotable(CartesianGrid(10,10),
  Dict(2 => (temperature=rand(100), pressure=rand(100)))
)
```
"""
geotable(domain::Domain, values::Dict) = GeoTable(domain, values)

"""
    geotable(vertices, elements, values)

Create spatial geotable from a [`SimpleMesh`](@ref) with
`vertices` and `elements`, and a dictionary of geotable
`values`.

## Examples

```julia
# vertices and elements
vertices = Point2[(0,0),(1,0),(1,1),(0,1)]
elements = connect.([(1,2,3),(3,4,1)])

# attach geotable to ranks 0 and 2
geotable(vertices, elements,
  Dict(
    0 => (temperature=[1.0,2.0,3.0,4.0], pressure=[4.0,3.0,2.0,1.0]),
    2 => (quality=["A","B"], state=[true,false])
  )
)
```
"""
geotable(vertices, elements, values) = geotable(SimpleMesh(vertices, elements), values)

"""
    geotable(domain; vtable, etable)

Create spatial geotable from a `domain`, a table `vtable`
with geotable for the vertices, and a table `etable` with
geotable for the elements.

## Examples

```julia
geotable(CartesianGrid(10,10),
  etable = (temperature=rand(100), pressure=rand(100))
)
```
"""
function geotable(domain; vtable=nothing, etable=nothing)
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
  geotable(domain, values)
end

"""
    geotable(vertices, elements; vtable, etable)

Create spatial geotable from a [`SimpleMesh`](@ref) with
`vertices` and `elements`, a table `vtable` with geotable
for the vertices, and a table `etable` with geotable for
the elements.

## Examples

```julia
# vertices and elements
vertices = Point2[(0,0),(1,0),(1,1),(0,1)]
elements = connect.([(1,2,3),(3,4,1)])

# attach geotable to mesh
geotable(vertices, elements,
  vtable = (temperature=[1.0,2.0,3.0,4.0], pressure=[4.0,3.0,2.0,1.0]),
  etable = (quality=["A","B"], state=[true,false])
)
```
"""
geotable(vertices, elements; vtable=nothing, etable=nothing) =
  geotable(SimpleMesh(vertices, elements); vtable=vtable, etable=etable)
