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
  if state === nothing
    domstate, tabstate = nothing, nothing
  else
    domstate, tabstate = state
  end
  # Iterate domain
  domiter = domstate === nothing ? iterate(rows.domain) : iterate(rows.domain, domstate)
  domiter === nothing && return nothing
  elm, newdomstate = domiter
  # If no inner table, return geometry only
  if isnothing(rows.trows)
    return (; geometry=elm), (newdomstate, nothing)
  end
  # Iterate table rows
  tabiter = tabstate === nothing ? iterate(rows.trows) : iterate(rows.trows, tabstate)
  if tabiter === nothing
    return (; geometry=elm), (newdomstate, nothing)
  end
  trow, newtabstate = tabiter
  # Construct row with table columns and geometry
  names = Tables.columnnames(trow)
  pairs = (nm => Tables.getcolumn(trow, nm) for nm in names)
  return (; pairs..., geometry=elm), (newdomstate, newtabstate)
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
