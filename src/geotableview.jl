"""
    GeoTableView(geotable, inds)

Return a view of `geotable` at indices `inds`.
"""
struct GeoTableView{T<:AbstractGeoTable,I} <: AbstractGeoTable
  geotable::T
  inds::I
end

# getters
getgeotable(v::GeoTableView) = getfield(v, :geotable)
getinds(v::GeoTableView) = getfield(v, :inds)

# specialize constructor to avoid infinite loops
GeoTableView(v::GeoTableView, inds) = GeoTableView(getgeotable(v), getinds(v)[inds])

# ----------------------------
# ABSTRACT GEOTABLE INTERFACE
# ----------------------------

function domain(v::GeoTableView)
  geotable = getgeotable(v)
  inds = getinds(v)
  view(domain(geotable), inds)
end

function Base.values(v::GeoTableView, rank=nothing)
  geotable = getgeotable(v)
  inds = getinds(v)
  dim = paramdim(domain(geotable))
  r = isnothing(rank) ? dim : rank
  table = values(geotable, r)
  if r == dim && !isnothing(table) 
    Tables.subset(table, inds)
  else
    nothing
  end
end

function constructor(::Type{GeoTableView{T,I}}) where {T<:AbstractGeoTable,I}
  function ctor(domain, values)
    geotable = constructor(T)(domain, values)
    inds = 1:nelements(domain)
    GeoTableView(geotable, inds)
  end
end

# specialize methods for performance
Base.:(==)(v₁::GeoTableView, v₂::GeoTableView) = getgeotable(v₁) == getgeotable(v₂) && getinds(v₁) == getinds(v₂)
