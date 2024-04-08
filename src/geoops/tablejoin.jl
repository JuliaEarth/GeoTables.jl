# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

leftjoin(gtb::AbstractGeoTable, tb; kwargs...) = _tableleftjoin(gtb, tb, NoneSelector(), Function[]; kwargs...)

leftjoin(gtb::AbstractGeoTable, tb, pairs::Pair{C,<:Function}...; kwargs...) where {C<:Column} =
  _tableleftjoin(gtb, tb, selector(first.(pairs)), collect(Function, last.(pairs)); kwargs...)

function _tableleftjoin(gtb::AbstractGeoTable, tb, selector::ColumnSelector, aggfuns::Vector{Function}; on)
  vars1 = Tables.schema(values(gtb)).names
  vars2 = Tables.schema(tb).names

  # check "on" variables
  onvars = _onvars(on)
  onpred = _onpred(onvars)
  if onvars ⊈ vars1 || onvars ⊈ vars2
    throw(ArgumentError("all variables in `on` kwarg must exist in geotables and table"))
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
    tb = _rename(tb, vars, newvars)
  end

  gtb = _adjustunits(gtb)
  tb = _adjustunits(tb)

  _tableleftjoin(gtb, tb, selector, aggfuns, onvars, onpred)
end

function _tableleftjoin(gtb, tb, selector, aggfuns, onvars, onpred)
  dom1 = domain(gtb)
  tab1 = values(gtb)
  tab2 = tb
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  # remove "on" variables from gtb2
  vars2 = setdiff(vars2, onvars)

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
  nrows = nrow(gtb)
  rows2 = Tables.rows(tab2)
  jrows = _tmap(1:nrows) do i
    row1 = Tables.subset(tab1, i)
    [row2 for row2 in rows2 if onpred(row1, row2)]
  end

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
