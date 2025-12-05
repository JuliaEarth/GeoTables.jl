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
  # If state is nothing, this is the first call (initialization).
  # We initialize both iterators (domain and table rows) using the
  # standard Julia iterator protocol: iterate(it) -> (item, state),
  # then iterate(it, state) to advance. States are opaque values,
  # not guaranteed to be integers.
  if state === nothing
    # 1. initialize domain iterator (geometry iterator)
    domiter = iterate(rows.domain)
    domiter === nothing && return nothing
    domelm, domstate = domiter

    # 2. if there is no attribute table, return geometry-only row
    if isnothing(rows.trows)
      return (; geometry=domelm), (domstate, nothing)
    end

    # 3. initialize attribute table iterator
    titer = iterate(rows.trows)
    titer === nothing && return nothing
    trow, tstate = titer

    # 4. build combined row and return initial iterator states
    names = Tables.columnnames(trow)
    pairs = (nm => Tables.getcolumn(trow, nm) for nm in names)
    return (; pairs..., geometry=domelm), (domstate, tstate)
  else
    # continuation: unpack opaque iterator states
    domstate, tstate = state

    # 1. advance domain using its stored state
    domiter = iterate(rows.domain, domstate)
    domiter === nothing && return nothing
    domelm, ndomstate = domiter

    # 2. if there is no attribute table, return geometry-only row
    if isnothing(rows.trows)
      return (; geometry=domelm), (ndomstate, nothing)
    end

    # 3. advance attribute table using its stored state
    titer = iterate(rows.trows, tstate)
    titer === nothing && return nothing
    trow, ntstate = titer

    # 4. build combined row and return new iterator states
    names = Tables.columnnames(trow)
    pairs = (nm => Tables.getcolumn(trow, nm) for nm in names)
    return (; pairs..., geometry=domelm), (ndomstate, ntstate)
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
