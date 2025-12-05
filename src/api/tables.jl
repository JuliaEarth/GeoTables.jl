# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

Tables.istable(::Type{<:AbstractGeoTable}) = true

Tables.rowaccess(::Type{<:AbstractGeoTable}) = true

function Tables.rows(geotable::AbstractGeoTable)
  table = values(geotable)
  trows = isnothing(table) ? nothing : Tables.rows(table)
  GeoTableRows(domain(geotable), trows)
end

Tables.schema(geotable::AbstractGeoTable) = Tables.schema(Tables.rows(geotable))

Tables.subset(geotable::AbstractGeoTable, inds; viewhint=nothing) = SubGeoTable(geotable, inds)
Tables.subset(geotable::AbstractGeoTable, ind::Int; viewhint=nothing) = geotable[ind, :]

# wrapper type for rows of the geotable table
# so that we can easily inform the schema
struct GeoTableRows{D<:Domain,R}
  domain::D
  trows::R
end

Base.length(rows::GeoTableRows) = nelements(rows.domain)

function Base.iterate(rows::GeoTableRows, state=nothing)
  # initialize state tuple if starting
  effstate = isnothing(state) ? (nothing, nothing) : state
  # dispatch to the correct helper based on rows.trows type
  return _iterate(rows.domain, rows.trows, effstate)
end

# helper: iterate when there is no inner table (geometry only)
function _iterate(dom, ::Nothing, state)
  dstate, _ = state
  diter = isnothing(dstate) ? iterate(dom) : iterate(dom, dstate)
  isnothing(diter) && return nothing
  elm, newdstate = diter
  return (; geometry=elm), (newdstate, nothing)
end

# helper: iterate when inner table is present (geometry + attributes)
function _iterate(dom, tab, state)
  dstate, tstate = state
  # advance both iterators (lockstep)
  diter = isnothing(dstate) ? iterate(dom) : iterate(dom, dstate)
  titer = isnothing(tstate) ? iterate(tab) : iterate(tab, tstate)
  # control flow based on domain only (design guarantee)
  isnothing(diter) && return nothing
  elm, newdstate = diter
  trow, newtstate = titer
  names = Tables.columnnames(trow)
  # construct row using splatting
  val = (; (nm => Tables.getcolumn(trow, nm) for nm in names)..., geometry=elm)
  return val, (newdstate, newtstate)
end

function Tables.schema(rows::GeoTableRows)
  geomtype = eltype(rows.domain)
  if isnothing(rows.trows)
    Tables.Schema((:geometry,), (geomtype,))
  else
    schema = Tables.schema(rows.trows)
    names, types = schema.names, schema.types
    Tables.Schema((names..., :geometry), (types..., geomtype))
  end
end

Tables.materializer(::Type{T}) where {T<:AbstractGeoTable} = T

# required for VSCode table viewer
TableTraits.isiterabletable(::AbstractGeoTable) = true
IteratorInterfaceExtensions.isiterable(::AbstractGeoTable) = true
IteratorInterfaceExtensions.getiterator(gtb::AbstractGeoTable) = Tables.datavaluerows(gtb)
