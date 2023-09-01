# dummy type implementing the AbstractGeoTable trait
struct DummyGeoTable{D,V} <: AbstractGeoTable
  domain::D
  values::V
end

GeoTables.domain(data::DummyGeoTable) = getfield(data, :domain)

function GeoTables.values(data::DummyGeoTable, rank=nothing)
  domain = getfield(data, :domain)
  values = getfield(data, :values)
  r = isnothing(rank) ? paramdim(domain) : rank
  haskey(values, r) ? values[r] : nothing
end

GeoTables.constructor(::Type{<:DummyGeoTable}) = DummyGeoTable
