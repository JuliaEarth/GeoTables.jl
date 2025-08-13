# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    @combine(geotable, :col₁ = expr₁, :col₂ = expr₂, ..., :colₙ = exprₙ)

Returns geospatial `geotable` with columns `:col₁`, `:col₂`, ..., `:colₙ`
computed with reduction expressions `expr₁`, `expr₂`, ..., `exprₙ`.

If a reduction expression is not defined for the `:geometry` column,
the geometries will be reduced using `Multi`.

See also: [`@groupby`](@ref).

## Examples

```julia
@combine(geotable, :x_sum = sum(:x))
@combine(geotable, :x_mean = mean(:x))
@combine(geotable, :x_mean = mean(:x), :geometry = centroid(:geometry))

groups = @groupby(geotable, :y)
@combine(groups, :x_prod = prod(:x))
@combine(groups, :x_median = median(:x))
@combine(groups, :x_median = median(:x), :geometry = centroid(:geometry))

@combine(geotable, {"z"} = sum({"x"}) + prod({"y"}))
xnm, ynm, znm = :x, :y, :z
@combine(geotable, {znm} = sum({xnm}) + prod({ynm}))
```
"""
macro combine(object, exprs...)
  splits = map(expr -> _split(expr, false), exprs)
  colnames = first.(splits)
  colexprs = last.(splits)
  quote
    local obj = $(esc(object))
    if obj isa Partition
      local partition = obj
      _combine(partition, [$(colnames...)], [$(map(_partexpr, colexprs)...)])
    else
      local geotable = obj
      _combine(geotable, [$(colnames...)], [$(map(_dataexpr, colexprs)...)])
    end
  end
end

function _combine(geotable::AbstractGeoTable, names, columns)
  table = values(geotable)

  geoms = if :geometry ∈ names
    ind = findfirst(==(:geometry), names)
    popat!(names, ind)
    popat!(columns, ind)
  else
    [Multi(domain(geotable))]
  end

  newtab = if isempty(names)
    nothing
  else
    (; zip(names, columns)...) |> Tables.materializer(table)
  end

  newdom = GeometrySet(geoms)

  georef(newtab, newdom)
end

function _combine(partition::Partition{T}, names, columns) where {T<:AbstractGeoTable}
  table = values(parent(partition))
  meta = metadata(partition)

  geoms = if :geometry ∈ names
    ind = findfirst(==(:geometry), names)
    popat!(names, ind)
    popat!(columns, ind)
  else
    [Multi(domain(geotable)) for geotable in partition]
  end

  grows = meta[:rows]
  gnames = meta[:names]
  gcolumns = [[row[i] for row in grows] for i in 1:length(gnames)]
  newnames = [gnames; names]
  newcolumns = [gcolumns; columns]

  newtab = (; zip(newnames, newcolumns)...) |> Tables.materializer(table)

  newdom = GeometrySet(geoms)

  georef(newtab, newdom)
end

_partexpr(colexpr) = :([$colexpr for geotable in partition])
_dataexpr(colexpr) = :([$colexpr])
