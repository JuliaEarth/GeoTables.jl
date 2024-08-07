# dummy type implementing the AbstractGeoTable trait
mutable struct DummyGeoTable{V} <: AbstractGeoTable
  domain::Domain
  values::V
end

GeoTables.domain(data::DummyGeoTable) = getfield(data, :domain)

function GeoTables.values(data::DummyGeoTable, rank=nothing)
  domain = getfield(data, :domain)
  values = getfield(data, :values)
  r = isnothing(rank) ? paramdim(domain) : rank
  get(values, r, nothing)
end

dummygeoref(table, domain) = DummyGeoTable(domain, Dict(paramdim(domain) => table))
