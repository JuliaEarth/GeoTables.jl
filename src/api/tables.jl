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

# helper: iterate when there is no inner table (geometry only)
function _iterate(dom, ::Nothing, state)
  domstate, _ = state
  domiter = isnothing(domstate) ? iterate(dom) : iterate(dom, domstate)
  isnothing(domiter) && return nothing
  elm, newdomstate = domiter
  return (; geometry=elm), (newdomstate, nothing)
end

# helper: iterate when inner table is present (geometry + attributes)
function _iterate(dom, tab, state)
  domstate, tabstate = state
  domiter = isnothing(domstate) ? iterate(dom) : iterate(dom, domstate)
  isnothing(domiter) && return nothing
  elm, newdomstate = domiter
  tabiter = isnothing(tabstate) ? iterate(tab) : iterate(tab, tabstate)
  if isnothing(tabiter)
    return (; geometry=elm), (newdomstate, nothing)
  end
  trow, newtabstate = tabiter
  names = Tables.columnnames(trow)
  pairs = (nm => Tables.getcolumn(trow, nm) for nm in names)
  return (; pairs..., geometry=elm), (newdomstate, newtabstate)
end

function Base.iterate(rows::GeoTableRows, state=nothing)
  effstate = isnothing(state) ? (nothing, nothing) : state
  return _iterate(rows.domain, rows.trows, effstate)
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
