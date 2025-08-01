# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

const TABLEJOINKINDS = [:left, :inner]

"""
    tablejoin(geotable, table, var₁ => agg₁, ..., varₙ => aggₙ; kind=:left, on)

Joins `geotable` with `table` using the values of the `on` variables to match rows with a certain `kind` of join.

`on` variables can be a single name or list of variable names (strings or symbols).
The variable value match use the `isequal` function.

Whenever two or more matches are encountered, aggregate `varᵢ` with aggregation function `aggᵢ`.
If no aggregation function is provided for a variable, then the aggregation function will be
selected according to the scientific types: `mean` for continuous and `first` otherwise.

## Kinds

* `:left` - Returns all rows of `geotable` filling entries with `missing` when there is no match in `table`.
* `:inner` - Returns the subset of rows of `geotable` that has a match in `table`.

## Examples

```julia
tablejoin(gtb, tab, on=:a)
tablejoin(gtb, tab, 1 => mean, on=:a)
tablejoin(gtb, tab, :a => mean, :b => std, on=:a)
tablejoin(gtb, tab, "a" => mean, on=[:a, :b])
tablejoin(gtb, tab, kind=:inner, on=["a", "b"])
```

See also [`geojoin`](@ref).
"""
tablejoin(gtb::AbstractGeoTable, tab; kwargs...) = _tablejoin(gtb, tab, NoneSelector(), Function[]; kwargs...)

tablejoin(gtb::AbstractGeoTable, tab, pairs::Pair{C,<:Function}...; kwargs...) where {C<:Column} =
  _tablejoin(gtb, tab, selector(first.(pairs)), collect(Function, last.(pairs)); kwargs...)

function _tablejoin(gtb::AbstractGeoTable, tab, selector::ColumnSelector, aggfuns::Vector{Function}; kind=:left, on)
  if kind ∉ TABLEJOINKINDS
    throw(ArgumentError("invalid kind of join, use one these $TABLEJOINKINDS"))
  end

  vars1 = Tables.schema(values(gtb)).names
  vars2 = Tables.schema(tab).names

  # check "on" variables
  onvars = _onvars(on)
  onpred = _onpred(onvars)
  if onvars ⊈ vars1 || onvars ⊈ vars2
    throw(ArgumentError("all variables in `on` kwarg must exist in geotable and table"))
  end

  # make variable names unique
  if !isdisjoint(vars1, vars2)
    # repeated variable names
    vars = setdiff(vars1 ∩ vars2, onvars)
    newvars = map(vars) do var
      while var ∈ vars1
        var = Symbol(var, :_)
      end
      var
    end
    tab = _rename(tab, vars, newvars)
  end

  gtb = _adjustunits(gtb)
  tab = _adjustunits(tab)

  if kind === :inner
    _tableinnerjoin(gtb, tab, selector, aggfuns, onvars, onpred)
  else
    _tableleftjoin(gtb, tab, selector, aggfuns, onvars, onpred)
  end
end

function _tableleftjoin(gtb, tab, selector, aggfuns, onvars, onpred)
  dom1 = domain(gtb)
  tab1 = values(gtb)
  tab2 = tab
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  # remove "on" variables from gtb2
  vars2 = setdiff(vars2, onvars)

  # aggregation functions
  agg = _aggdict(selector, aggfuns, cols2, vars2)

  # rows to join
  nrows = nrow(gtb)
  rows2 = Tables.rows(tab2)
  jrows = _tmap(1:nrows) do i
    row1 = Tables.subset(tab1, i)
    [row2 for row2 in rows2 if onpred(row1, row2)]
  end

  _leftjoinpos(nrows, jrows, agg, dom1, tab1, cols1, vars1, vars2)
end

function _tableinnerjoin(gtb, tab, selector, aggfuns, onvars, onpred)
  dom1 = domain(gtb)
  tab1 = values(gtb)
  tab2 = tab
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  # remove "on" variables from gtb2
  vars2 = setdiff(vars2, onvars)

  # aggregation functions
  agg = _aggdict(selector, aggfuns, cols2, vars2)

  # rows to join
  nrows = nrow(gtb)
  rows2 = Tables.rows(tab2)
  jrows = _tmap(1:nrows) do i
    row1 = Tables.subset(tab1, i)
    [row2 for row2 in rows2 if onpred(row1, row2)]
  end

  _innerjoinpos(jrows, agg, dom1, tab1, vars1, vars2)
end
