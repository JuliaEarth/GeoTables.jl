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
  haskey(values, r) ? values[r] : nothing
end

GeoTables.setdomain!(data::DummyGeoTable, newdomain::Domain) = setfield!(data, :domain, newdomain)

dummygeoref(table, domain) = DummyGeoTable(domain, Dict(paramdim(domain) => table))
