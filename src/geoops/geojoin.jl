# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

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

## Examples

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
  if kind ∉ (:left, :inner)
    throw(ArgumentError("invalid kind of join, use one of :left or :inner"))
  end

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

  # adjust CRS of the second geotable if necessary
  gtb2 = _adjustcrs(gtb1, gtb2)

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

  _geojoinof(kind, gtb1, gtb2, selector, aggfuns, pred, onvars, onpred)
end

function _geojoinof(kind, gtb1, gtb2, selector, aggfuns, pred, onvars, onpred)
  dom1 = domain(gtb1)
  dom2 = domain(gtb2)
  tab1 = values(gtb1)
  tab2 = values(gtb2)
  cols2 = Tables.columns(tab2)
  vars2 = Tables.columnnames(cols2)

  # remove "on" variables from gtb2
  if !isnothing(onvars)
    vars2 = setdiff(vars2, onvars)
  end

  # aggregation functions
  agg = _aggdict(selector, aggfuns, cols2, vars2)

  # flag predicates for which overlapping bounding boxes are necessary
  usebbox = pred ∈ (intersects, issubset, isequal)
  usebbox && (searcher = BBoxSearch(dom2))

  # rows indices to join
  jinds = _tmap(1:nrow(gtb1)) do i
    geo1 = dom1[i]
    row1 = Tables.subset(tab1, i, viewhint=true)
    if usebbox
      inds = search(geo1, searcher)
      filter!(inds) do j
        # check "on" predicate first
        if !isnothing(onvars)
          row2 = Tables.subset(tab2, j, viewhint=true)
          onpred(row1, row2) || return false
        end
        # check spatial predicate next
        pred(geo1, dom2[j])
      end
      sort!(inds)
    else
      filter(1:nelements(dom2)) do j
        (isnothing(onvars) || onpred(row1, Tables.subset(tab2, j, viewhint=true))) && pred(geo1, dom2[j])
      end
    end
  end

  if kind == :left
    _leftjoinpos(jinds, agg, gtb1, vars2, cols2)
  elseif kind == :inner
    _innerjoinpos(jinds, agg, gtb1, vars2, cols2)
  end
end

function _leftjoinpos(jinds, agg, gtb1, vars2, cols2)
  dom1 = domain(gtb1)
  tab1 = values(gtb1)
  cols1 = Tables.columns(tab1)
  vars1 = Tables.columnnames(cols1)

  # generate joined column
  function gencol(var)
    vals = Tables.getcolumn(cols2, var)
    map(jinds) do matches
      if isempty(matches)
        missing
      else
        vs = [vals[j] for j in matches]
        agg[var] == collect ? vs : agg[var](vs)
      end
    end
  end

  pairs1 = (var => Tables.getcolumn(cols1, var) for var in vars1)
  pairs2 = (var => gencol(var) for var in vars2)
  newtab = (; pairs1..., pairs2...) |> Tables.materializer(tab1)

  georef(newtab, dom1)
end

function _innerjoinpos(jinds, agg, gtb1, vars2, cols2)
  dom1 = domain(gtb1)
  tab1 = values(gtb1)

  # row indices of gtb1 to preserve
  inds = findall(!isempty, jinds)

  # extract subtable of attributes
  sub1 = Tables.subset(tab1, inds, viewhint=true)
  cols1 = Tables.columns(sub1)
  vars1 = Tables.columnnames(cols1)

  # generate joined column
  function gencol(var)
    vals = Tables.getcolumn(cols2, var)
    map(inds) do i
      matches = jinds[i]
      vs = [vals[j] for j in matches]
      agg[var] == collect ? vs : agg[var](vs)
    end
  end

  pairs1 = (var => Tables.getcolumn(cols1, var) for var in vars1)
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

function _adjustcrs(gtb1, gtb2)
  CRS1 = crs(domain(gtb1))
  CRS2 = crs(domain(gtb2))
  if CRS1 !== CRS2
    gtb2 |> Proj(CRS1)
  else
    gtb2
  end
end

_isvarequal(row1, row2, var) = isequal(Tables.getcolumn(row1, var), Tables.getcolumn(row2, var))

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
