# dummy type implementing the AbstractGeoTable trait
struct DummyGeoTable{T,V} <: AbstractGeoTable
  domain::T
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

dummygeoref(table, domain) = DummyGeoTable(domain, Dict(paramdim(domain) => table))
