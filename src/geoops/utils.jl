# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function _rename(geotable::AbstractGeoTable, oldnms, newnms)
  dom = domain(geotable)
  tab = values(geotable)
  cols = Tables.columns(tab)
  names = Tables.columnnames(cols)

  nmdict = Dict(zip(oldnms, newnms))
  pairs = (get(nmdict, nm, nm) => Tables.getcolumn(cols, nm) for nm in names)
  newtab = (; pairs...) |> Tables.materializer(tab)

  vals = Dict(paramdim(dom) => newtab)
  constructor(geotable)(dom, vals)
end

#-------------
# AGGREGATION
#-------------

_defaultagg(x) = _defaultagg(elscitype(x))
_defaultagg(::Type) = _skipmissing(first)
_defaultagg(::Type{SciTypes.Continuous}) = _skipmissing(mean)

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
  cols = Tables.columns(tab)
  vars = Tables.columnnames(cols)

  pairs = (var => _absunit(Tables.getcolumn(cols, var)) for var in vars)
  newtab = (; pairs...) |> Tables.materializer(tab)

  vals = Dict(paramdim(dom) => newtab)
  constructor(geotable)(dom, vals)
end

_absunit(x) = _absunit(nonmissingtype(eltype(x)), x)
_absunit(::Type, x) = x
function _absunit(::Type{Q}, x) where {Q<:AffineQuantity}
  u = absoluteunit(unit(Q))
  map(v -> uconvert(u, v), x)
end
