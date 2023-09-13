"""
    SubGeoTable(geotable, inds)

Return a view of `geotable` at indices `inds`.
"""
struct SubGeoTable{T<:AbstractGeoTable,I} <: AbstractGeoTable
  geotable::T
  inds::I
end

# getters
getgeotable(v::SubGeoTable) = getfield(v, :geotable)
getinds(v::SubGeoTable) = getfield(v, :inds)

# specialize constructor to avoid infinite loops
SubGeoTable(v::SubGeoTable, inds) = SubGeoTable(getgeotable(v), getinds(v)[inds])

# ----------------------------
# ABSTRACT GEOTABLE INTERFACE
# ----------------------------

function domain(v::SubGeoTable)
  geotable = getgeotable(v)
  inds = getinds(v)
  view(domain(geotable), inds)
end

function Base.values(v::SubGeoTable, rank=nothing)
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

function constructor(::Type{SubGeoTable{T,I}}) where {T<:AbstractGeoTable,I}
  function ctor(domain, values)
    geotable = constructor(T)(domain, values)
    inds = 1:nelements(domain)
    SubGeoTable(geotable, inds)
  end
end

# specialize methods for performance
Base.:(==)(v₁::SubGeoTable, v₂::SubGeoTable) = getgeotable(v₁) == getgeotable(v₂) && getinds(v₁) == getinds(v₂)
