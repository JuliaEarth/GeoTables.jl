# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function _rename(geotable::AbstractGeoTable, oldnms, newnms)
  dom = domain(geotable)
  tab = values(geotable)
  newtab = _rename(tab, oldnms, newnms)
  georef(newtab, dom)
end

function _rename(tab, oldnms, newnms)
  cols = Tables.columns(tab)
  names = Tables.columnnames(cols)
  nmdict = Dict(zip(oldnms, newnms))
  pairs = (get(nmdict, nm, nm) => Tables.getcolumn(cols, nm) for nm in names)
  (; pairs...) |> Tables.materializer(tab)
end

#-------------
# AGGREGATION
#-------------

_defaultagg(x) = _defaultagg(elscitype(x))
_defaultagg(::Type) = _skipmissing(first)
_defaultagg(::Type{Continuous}) = _skipmissing(mean)

function _skipmissing(fun)
  x -> begin
    vs = skipmissing(x)
    isempty(vs) ? missing : fun(vs)
  end
end

#-------
# UNITS
#-------

function _adjustunits(geotable::AbstractGeoTable)
  dom = domain(geotable)
  tab = values(geotable)
  newtab = _adjustunits(tab)
  georef(newtab, dom)
end

function _adjustunits(tab)
  cols = Tables.columns(tab)
  vars = Tables.columnnames(cols)
  pairs = (var => _absunit(Tables.getcolumn(cols, var)) for var in vars)
  (; pairs...) |> Tables.materializer(tab)
end

_absunit(x) = _absunit(nonmissingtype(eltype(x)), x)
_absunit(::Type, x) = x
_absunit(::Type{Union{}}, x) = x
function _absunit(::Type{Q}, x) where {Q<:AffineQuantity}
  u = absoluteunit(unit(Q))
  map(v -> uconvert(u, v), x)
end

function _uniquenames(gtb1::AbstractGeoTable, gtb2::AbstractGeoTable, onvars=nothing)
  tab2 = values(gtb2)
  _, newtab2 = _uniquenames(values(gtb1), tab2, onvars)
  newgtb2 = newtab2 === tab2 ? gtb2 : georef(newtab2, domain(gtb2))
  gtb1, newgtb2
end

function _uniquenames(tab1, tab2, onvars=nothing)
  vars1 = Tables.columnnames(Tables.columns(tab1))
  vars2 = Tables.columnnames(Tables.columns(tab2))
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
    tab2 = _rename(tab2, vars, newvars)
  end
  tab1, tab2
end
