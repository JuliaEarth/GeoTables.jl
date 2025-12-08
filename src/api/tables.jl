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

function Base.iterate(rows::GeoTableRows, state=1)
  if state > length(rows)
    nothing
  else
    elm, _ = iterate(rows.domain, state)
    row = if isnothing(rows.trows)
      (; geometry=elm)
    else
      # Capture the result safely
      itr = iterate(rows.trows, state)
      # Check if the attribute iterator returned nothing
      if isnothing(itr)
        # Fallback: If attributes are exhausted or empty, return just geometry
        (; geometry=elm)
      else
        trow, _ = itr
        names = Tables.columnnames(trow)
        pairs = (nm => Tables.getcolumn(trow, nm) for nm in names)
        (; pairs..., geometry=elm)
      end
    end
    row, state + 1
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
