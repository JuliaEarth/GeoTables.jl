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
  tuplestate = isnothing(state) ? (nothing, nothing) : state
  _iterate(rows.domain, rows.trows, tuplestate)
end

# iterate geometry only
function _iterate(dom, ::Nothing, tuplestate)
  dstate, _ = tuplestate
  dnext = isnothing(dstate) ? iterate(dom) : iterate(dom, dstate)
  isnothing(dnext) && return nothing
  geom, ndstate = dnext
  (; geometry=geom), (ndstate, nothing)
end

# iterate geometry + attributes
function _iterate(dom, trows, tuplestate)
  dstate, tstate = tuplestate
  dnext = isnothing(dstate) ? iterate(dom) : iterate(dom, dstate)
  isnothing(dnext) && return nothing
  geom, ndstate = dnext
  tnext = isnothing(tstate) ? iterate(trows) : iterate(trows, tstate)
  trow, ntstate = tnext
  names = Tables.columnnames(trow)
  attri = (nm => Tables.getcolumn(trow, nm) for nm in names)
  (; attri..., geometry=geom), (ndstate, ntstate)
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
