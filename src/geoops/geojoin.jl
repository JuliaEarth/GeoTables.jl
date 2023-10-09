# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

const KINDS = [:left, :inner]

"""
    geojoin(geotable₁, geotable₂, var₁ => agg₁, ..., varₙ => aggₙ; kind=:left, pred=intersects)

Joins `geotable₁` with `geotable₂` using a certain `kind` of join and predicate function `pred`
that takes two geometries and returns a boolean (`(g1, g2) -> g1 ⊆ g2`).

Whenever two or more matches are encountered, aggregate `varᵢ` with aggregation function `aggᵢ`.
If no aggregation function is provided for a variable, then the aggregation function will be
selected according to the scientific types: `mean` for continuous and `first` otherwise.

## Kinds

* `:left` - Returns all rows of `geotable₁` filling entries with `missing` when there is no match in `geotable₂`.
* `:inner` - Returns the subset of rows of `geotable₁` that has a match in `geotable₂`.

# Examples

```julia
geojoin(gtb1, gtb2)
geojoin(gtb1, gtb2, 1 => mean)
geojoin(gtb1, gtb2, :a => mean, :b => std)
geojoin(gtb1, gtb2, "a" => mean, pred=issubset)
```
"""
geojoin(gtb1::AbstractGeoTable, gtb2::AbstractGeoTable; kwargs...) =
  _geojoin(gtb1, gtb2, NoneSelector(), Function[]; kwargs...)

geojoin(gtb1::AbstractGeoTable, gtb2::AbstractGeoTable, pairs::Pair{C,<:Function}...; kwargs...) where {C<:Column} =
  _geojoin(gtb1, gtb2, selector(first.(pairs)), collect(Function, last.(pairs)); kwargs...)

function _geojoin(
  gtb1::AbstractGeoTable,
  gtb2::AbstractGeoTable,
  selector::ColumnSelector,
  aggfuns::Vector{Function};
  kind=:left,
  pred=intersects
)
  if kind ∉ KINDS
    throw(ArgumentError("invalid kind of join, use one these $KINDS"))
  end

  # make variable names unique
  vars1 = Tables.schema(values(gtb1)).names
  vars2 = Tables.schema(values(gtb2)).names
  if !isdisjoint(vars1, vars2)
    # repeated variable names
    vars = vars1 ∩ vars2
    newvars = map(vars) do var
      while var ∈ vars1
        var = Symbol(var, :_)
      end
      var
    end
    gtb2 = _rename(gtb2, vars, newvars)
  end

  gtb1 = _adjustunits(gtb1)
  gtb2 = _adjustunits(gtb2)

  if kind === :inner
    _innerjoin(gtb1, gtb2, selector, aggfuns, pred)
  else
    _leftjoin(gtb1, gtb2, selector, aggfuns, pred)
  end
end

function _leftjoin(gtb1, gtb2, selector, aggfuns, pred)
  dom1 = domain(gtb1)
  dom2 = domain(gtb2)
  tab1 = values(gtb1)
  tab2 = values(gtb2)
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  # aggregation functions
  svars = selector(vars2)
  agg = Dict(zip(svars, aggfuns))
  for var in vars2
    if !haskey(agg, var)
      v = Tables.getcolumn(cols2, var)
      agg[var] = _defaultagg(v)
    end
  end

  # rows to join
  nrows = nrow(gtb1)
  ncols = ncol(gtb2) - 1
  types = Tables.schema(tab2).types
  rows = [[T[] for T in types] for _ in 1:nrows]
  for (i1, geom1) in enumerate(dom1)
    for (i2, geom2) in enumerate(dom2)
      if pred(geom1, geom2)
        row = Tables.subset(tab2, i2)
        for j in 1:ncols
          v = Tables.getcolumn(row, j)
          push!(rows[i1][j], v)
        end
      end
    end
  end

  # generate joined column
  function gencol(j, var)
    map(1:nrows) do i
      vs = rows[i][j]
      if isempty(vs)
        missing
      else
        agg[var](vs)
      end
    end
  end

  pairs1 = (var => Tables.getcolumn(cols1, var) for var in vars1)
  pairs2 = (var => gencol(j, var) for (j, var) in enumerate(vars2))
  newtab = (; pairs1..., pairs2...) |> Tables.materializer(tab1)

  vals = Dict(paramdim(dom1) => newtab)
  constructor(gtb1)(dom1, vals)
end

function _innerjoin(gtb1, gtb2, selector, aggfuns, pred)
  dom1 = domain(gtb1)
  dom2 = domain(gtb2)
  tab1 = values(gtb1)
  tab2 = values(gtb2)
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  # aggregation functions
  svars = selector(vars2)
  agg = Dict(zip(svars, aggfuns))
  for var in vars2
    if !haskey(agg, var)
      v = Tables.getcolumn(cols2, var)
      agg[var] = _defaultagg(v)
    end
  end

  nrows = nrow(gtb1)
  ncols = ncol(gtb2) - 1
  types = Tables.schema(tab2).types
  # rows of gtb2 to join
  rows = [[T[] for T in types] for _ in 1:nrows]
  # row indices of gtb1 to preserve
  inds = Int[]
  for (i1, geom1) in enumerate(dom1)
    for (i2, geom2) in enumerate(dom2)
      if pred(geom1, geom2)
        i1 ∉ inds && push!(inds, i1)
        row = Tables.subset(tab2, i2)
        for j in 1:ncols
          v = Tables.getcolumn(row, j)
          push!(rows[i1][j], v)
        end
      end
    end
  end

  # generate joined column
  function gencol(j, var)
    map(inds) do i
      vs = rows[i][j]
      agg[var](vs)
    end
  end

  sub = Tables.subset(tab1, inds)
  cols = Tables.columns(sub)
  pairs1 = (var => Tables.getcolumn(cols, var) for var in vars1)
  pairs2 = (var => gencol(j, var) for (j, var) in enumerate(vars2))
  newtab = (; pairs1..., pairs2...) |> Tables.materializer(tab1)

  newdom = view(dom1, inds)
  vals = Dict(paramdim(newdom) => newtab)
  constructor(gtb1)(newdom, vals)
end
