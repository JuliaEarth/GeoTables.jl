# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    @groupby(geotable, col₁, col₂, ..., colₙ)
    @groupby(geotable, [col₁, col₂, ..., colₙ])
    @groupby(geotable, (col₁, col₂, ..., colₙ))

Group geospatial `geotable` by columns `col₁`, `col₂`, ..., `colₙ`.

    @groupby(geotable, regex)

Group geospatial `geotable` by columns that match with `regex`.

# Examples

```julia
@groupby(geotable, 1, 3, 5)
@groupby(geotable, [:a, :c, :e])
@groupby(geotable, ("a", "c", "e"))
@groupby(geotable, r"[ace]")
```
"""
macro groupby(geotable::Symbol, cols...)
  tuple = Expr(:tuple, esc.(cols)...)
  :(_groupby($(esc(geotable)), $tuple))
end

macro groupby(geotable::Symbol, cols)
  :(_groupby($(esc(geotable)), $(esc(cols))))
end

_groupby(geotable::AbstractGeoTable, cols) = _groupby(geotable, selector(cols))
_groupby(geotable::AbstractGeoTable, cols::C...) where {C<:Column} = _groupby(geotable, selector(cols))

function _groupby(geotable::AbstractGeoTable, selector::ColumnSelector)
  table = values(geotable)

  cols = Tables.columns(table)
  names = Tables.columnnames(cols)
  snames = selector(names)

  scolumns = (Tables.getcolumn(cols, nm) for nm in snames)
  srows = collect(zip(scolumns...))

  urows = unique(srows)
  inds = map(row -> findall(isequal(row), srows), urows)

  metadata = Dict(:names => snames, :rows => urows)
  Partition(geotable, inds, metadata)
end
