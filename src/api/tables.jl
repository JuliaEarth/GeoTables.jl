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

function Base.iterate(rows::GeoTableRows)
  domnext = iterate(rows.domain)
  trowsnext = isnothing(rows.trows) ? nothing : iterate(rows.trows)
  _iterate(domnext, trowsnext)
end

function Base.iterate(rows::GeoTableRows, (dstate, tstate))
  domnext = iterate(rows.domain, dstate)
  trowsnext = isnothing(rows.trows) || isnothing(tstate) ? nothing : iterate(rows.trows, tstate)
  _iterate(domnext, trowsnext)
end

function _iterate(domnext, trowsnext)
  if isnothing(domnext)
    nothing
  else
    elm, dstate = domnext
    if isnothing(trowsnext)
      (; geometry=elm), (dstate, nothing)
    else
      trow, tstate = trowsnext
      names = Tables.columnnames(trow)
      pairs = (nm => Tables.getcolumn(trow, nm) for nm in names)
      (; pairs..., geometry=elm), (dstate, tstate)
    end
  end
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
