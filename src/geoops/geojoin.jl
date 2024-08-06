# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

const GEOJOINKINDS = [:left, :inner]

"""
    geojoin(geotable₁, geotable₂, var₁ => agg₁, ..., varₙ => aggₙ; kind=:left, pred=intersects, on=nothing)

Joins `geotable₁` with `geotable₂` using a certain `kind` of join and predicate function `pred`
that takes two geometries and returns a boolean (`(g1, g2) -> g1 ⊆ g2`).

Optionally, add a variable value match to join, in addition to geometric match, by passing
a single name or list of variable names (strings or symbols) to the `on` keyword argument.
The variable value match use the `isequal` function.

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
geojoin(gtb1, gtb2, on=:a)
geojoin(gtb1, gtb2, kind=:inner, on=["a", "b"])
```

See also [`tablejoin`](@ref).
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
  pred=intersects,
  on=nothing
)
  if kind ∉ GEOJOINKINDS
    throw(ArgumentError("invalid kind of join, use one these $GEOJOINKINDS"))
  end

  # fix CRS of the second geotable
  CRS = CoordRefSystems.constructor(crs(domain(gtb1)))
  gtb2 = gtb2 |> Proj(CRS)

  vars1 = Tables.schema(values(gtb1)).names
  vars2 = Tables.schema(values(gtb2)).names

  # check "on" variables
  onvars = _onvars(on)
  onpred = _onpred(onvars)
  if !isnothing(onvars)
    if onvars ⊈ vars1 || onvars ⊈ vars2
      throw(ArgumentError("all variables in `on` kwarg must exist in both geotables"))
    end
  end

  # make variable names unique
  if !isdisjoint(vars1, vars2)
    # repeated variable names
    vars = vars1 ∩ vars2
    if !isnothing(onvars)
      vars = setdiff(vars, onvars)
    end
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
    _geoinnerjoin(gtb1, gtb2, selector, aggfuns, pred, onvars, onpred)
  else
    _geoleftjoin(gtb1, gtb2, selector, aggfuns, pred, onvars, onpred)
  end
end

function _geoleftjoin(gtb1, gtb2, selector, aggfuns, pred, onvars, onpred)
  dom1 = domain(gtb1)
  dom2 = domain(gtb2)
  tab1 = values(gtb1)
  tab2 = values(gtb2)
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  # remove "on" variables from gtb2
  if !isnothing(onvars)
    vars2 = setdiff(vars2, onvars)
  end

  # aggregation functions
  agg = _aggdict(selector, aggfuns, cols2, vars2)

  # rows to join
  nrows = nrow(gtb1)
  rows2 = Tables.rows(tab2)
  jrows = _tmap(1:nrows) do i
    geom1 = element(dom1, i)
    row1 = Tables.subset(tab1, i)
    [row2 for (geom2, row2) in zip(dom2, rows2) if pred(geom1, geom2) && onpred(row1, row2)]
  end

  _leftjoinpos(nrows, jrows, agg, dom1, tab1, cols1, vars1, vars2)
end

function _leftjoinpos(nrows, jrows, agg, dom1, tab1, cols1, vars1, vars2)
  # generate joined column
  function gencol(var)
    map(1:nrows) do i
      rows = jrows[i]
      if isempty(rows)
        missing
      else
        vs = _colvalues(rows, var)
        agg[var](vs)
      end
    end
  end

  pairs1 = (var => Tables.getcolumn(cols1, var) for var in vars1)
  pairs2 = (var => gencol(var) for var in vars2)
  newtab = (; pairs1..., pairs2...) |> Tables.materializer(tab1)

  georef(newtab, dom1)
end

function _geoinnerjoin(gtb1, gtb2, selector, aggfuns, pred, onvars, onpred)
  dom1 = domain(gtb1)
  dom2 = domain(gtb2)
  tab1 = values(gtb1)
  tab2 = values(gtb2)
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  # remove "on" variables from gtb2
  if !isnothing(onvars)
    vars2 = setdiff(vars2, onvars)
  end

  # aggregation functions
  agg = _aggdict(selector, aggfuns, cols2, vars2)

  # rows to join
  nrows = nrow(gtb1)
  rows2 = Tables.rows(tab2)
  jrows = _tmap(1:nrows) do i
    geom1 = element(dom1, i)
    row1 = Tables.subset(tab1, i)
    [row2 for (geom2, row2) in zip(dom2, rows2) if pred(geom1, geom2) && onpred(row1, row2)]
  end

  _innerjoinpos(jrows, agg, dom1, tab1, vars1, vars2)
end

function _innerjoinpos(jrows, agg, dom1, tab1, vars1, vars2)
  # row indices of gtb1 to preserve
  inds = findall(!isempty, jrows)

  # generate joined column
  function gencol(var)
    map(inds) do i
      rows = jrows[i]
      vs = _colvalues(rows, var)
      agg[var](vs)
    end
  end

  sub = Tables.subset(tab1, inds)
  cols = Tables.columns(sub)
  pairs1 = (var => Tables.getcolumn(cols, var) for var in vars1)
  pairs2 = (var => gencol(var) for var in vars2)
  newtab = (; pairs1..., pairs2...) |> Tables.materializer(tab1)

  newdom = view(dom1, inds)
  georef(newtab, newdom)
end

_onvars(::Nothing) = nothing
_onvars(var::Symbol) = [var]
_onvars(var::AbstractString) = [Symbol(var)]
_onvars(vars) = Symbol.(vars)

function _onpred(onvars)
  if isnothing(onvars)
    (_, _) -> true
  else
    (row1, row2) -> all(_isvarequal(row1, row2, var) for var in onvars)
  end
end

_isvarequal(row1, row2, var) = isequal(Tables.getcolumn(row1, var), Tables.getcolumn(row2, var))

_colvalues(rows, var) = [Tables.getcolumn(row, var) for row in rows]

function _aggdict(selector, aggfuns, cols, vars)
  svars = selector(vars)
  agg = Dict(zip(svars, aggfuns))
  for var in vars
    if !haskey(agg, var)
      v = Tables.getcolumn(cols, var)
      agg[var] = _defaultagg(v)
    end
  end
  agg
end

function _tmap(f, itr)
  chunks = Iterators.partition(itr, cld(length(itr), Threads.nthreads()))
  tasks = map(chunks) do chunk
    Threads.@spawn map(f, chunk)
  end
  mapreduce(fetch, vcat, tasks)
end
