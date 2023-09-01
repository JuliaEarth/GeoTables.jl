"""
    DataView(geotable, inds)

Return a view of `geotable` at indices `inds`.
"""
struct GeoTableView{G<:AbstractGeoTable,I} <: AbstractGeoTable
  geotable::G
  inds::I
end

# getters
getgeotable(v::GeoTableView) = getfield(v, :geotable)
getinds(v::GeoTableView) = getfield(v, :inds)

# specialize constructor to avoid infinite loops
GeoTableView(v::GeoTableView, inds) = GeoTableView(getgeotable(v), getinds(v)[inds])

# ---------------------------
# ABSTRACTGEOTABLE INTERFACE
# ---------------------------

function domain(v::GeoTableView)
  geotable = getgeotable(v)
  inds = getinds(v)
  view(domain(geotable), inds)
end

function Base.values(v::GeoTableView, rank=nothing)
  geotable = getgeotable(v)
  inds = getinds(v)
  R = paramdim(domain(geotable))
  r = isnothing(rank) ? R : rank
  𝒯 = values(geotable, r)
  r == R ? Tables.subset(𝒯, inds) : nothing
end

function constructor(::Type{GeoTableView{D,I}}) where {D<:AbstractGeoTable,I}
  function ctor(domain, values)
    geotable = constructor(D)(domain, values)
    inds = 1:nelements(domain)
    GeoTableView(geotable, inds)
  end
end

# specialize methods for performance
Base.:(==)(v₁::GeoTableView, v₂::GeoTableView) = getgeotable(v₁) == getgeotable(v₂) && getinds(v₁) == getinds(v₂)

# -----------
# IO METHODS
# -----------

function Base.show(io::IO, v::GeoTableView)
  geotable = getgeotable(v)
  nelms = length(getinds(v))
  print(io, "$nelms View{$geotable}")
end
