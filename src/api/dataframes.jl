# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

nrow(geotable::AbstractGeoTable) = nelements(domain(geotable))

function ncol(geotable::AbstractGeoTable)
  table = values(geotable)
  isnothing(table) && return 1
  cols = Tables.columns(table)
  vars = Tables.columnnames(cols)
  length(vars) + 1
end

Base.names(geotable::AbstractGeoTable) = string.(propertynames(geotable))

function Base.propertynames(geotable::AbstractGeoTable)
  table = values(geotable)
  if isnothing(table)
    [:geometry]
  else
    cols = Tables.columns(table)
    vars = Tables.columnnames(cols)
    [collect(vars); :geometry]
  end
end

function Base.getproperty(geotable::AbstractGeoTable, var::Symbol)
  if var === :geometry
    domain(geotable)
  else
    table = values(geotable)
    isnothing(table) && _noattrs_error()
    cols = Tables.columns(table)
    Tables.getcolumn(cols, var)
  end
end

Base.getproperty(geotable::AbstractGeoTable, var::AbstractString) = getproperty(geotable, Symbol(var))

const RowSelector = Union{Int,AbstractVector{Int},Colon}

Base.getindex(geotable::AbstractGeoTable, ::Colon, ::Colon) = geotable

Base.getindex(geotable::AbstractGeoTable, rows::RowSelector, vars) = _getindex(geotable, rows, selector(vars))

function _getindex(geotable::AbstractGeoTable, rows::RowSelector, selector::ColumnSelector)
  svars = selector(propertynames(geotable))
  _getindex(geotable, rows, svars)
end

function _getindex(geotable::AbstractGeoTable, rows::RowSelector, selector::SingleColumnSelector)
  svar = selectsingle(selector, propertynames(geotable))
  _getindex(geotable, rows, svar)
end

function _getindex(geotable::AbstractGeoTable, inds::AbstractVector{Int}, vars::AbstractVector{Symbol})
  _checkvars(vars)
  dom = domain(geotable)
  tab = values(geotable)
  vars = setdiff(vars, [:geometry])
  newdom = view(dom, inds)
  newtab = if isnothing(tab)
    !isempty(vars) && _noattrs_error()
    nothing
  else
    sub = Tables.subset(tab, inds)
    cols = Tables.columns(sub)
    pairs = (var => Tables.getcolumn(cols, var) for var in vars)
    (; pairs...) |> Tables.materializer(tab)
  end
  newval = Dict(paramdim(newdom) => newtab)
  constructor(geotable)(newdom, newval)
end

function _getindex(geotable::AbstractGeoTable, ind::Int, vars::AbstractVector{Symbol})
  _checkvars(vars)
  dom = domain(geotable)
  tab = values(geotable)
  vars = setdiff(vars, [:geometry])
  if isnothing(tab)
    !isempty(vars) && _noattrs_error()
    (; geometry=dom[ind])
  else
    row = Tables.subset(tab, ind)
    pairs = (var => Tables.getcolumn(row, var) for var in vars)
    (; pairs..., geometry=dom[ind])
  end
end

function _getindex(geotable::AbstractGeoTable, ::Colon, vars::AbstractVector{Symbol})
  _checkvars(vars)
  dom = domain(geotable)
  tab = values(geotable)
  vars = setdiff(vars, [:geometry])
  newtab = if isnothing(tab)
    !isempty(vars) && _noattrs_error()
    nothing
  else
    cols = Tables.columns(tab)
    pairs = (var => Tables.getcolumn(cols, var) for var in vars)
    (; pairs...) |> Tables.materializer(tab)
  end
  newval = Dict(paramdim(dom) => newtab)
  constructor(geotable)(dom, newval)
end

_getindex(geotable::AbstractGeoTable, inds::AbstractVector{Int}, var::Symbol) = getproperty(view(geotable, inds), var)

_getindex(geotable::AbstractGeoTable, ind::Int, var::Symbol) = getproperty(geotable, var)[ind]

_getindex(geotable::AbstractGeoTable, ::Colon, var::Symbol) = getproperty(geotable, var)

Base.hcat(geotable::AbstractGeoTable...) = reduce(_hcat, geotable)

Base.vcat(geotable::AbstractGeoTable...) = reduce(_vcat, geotable)

function _hcat(geotable1, geotable2)
  dom = domain(geotable1)
  if dom ≠ domain(geotable2)
    throw(ArgumentError("all geotables must have the same domain"))
  end

  tab1 = values(geotable1)
  tab2 = values(geotable2)
  newtab = if !isnothing(tab1) && !isnothing(tab2)
    cols1 = Tables.columns(tab1)
    cols2 = Tables.columns(tab2)
    names1 = Tables.columnnames(cols1)
    names2 = Tables.columnnames(cols2)
    names = [collect(names1); collect(names2)]

    if !allunique(names)
      throw(ArgumentError("all geotables must have different variables"))
    end

    columns = Any[Tables.getcolumn(cols1, name) for name in names1]
    for name in names2
      push!(columns, Tables.getcolumn(cols2, name))
    end

    (; zip(names, columns)...)
  elseif !isnothing(tab1)
    tab1
  elseif !isnothing(tab2)
    tab2
  else
    nothing
  end

  newval = Dict(paramdim(dom) => newtab)
  constructor(geotable1)(dom, newval)
end

function _vcat(geotable1, geotable2)
  dom1 = domain(geotable1)
  dom2 = domain(geotable2)
  tab1 = values(geotable1)
  tab2 = values(geotable2)

  newtab = if !isnothing(tab1) && !isnothing(tab2)
    cols1 = Tables.columns(tab1)
    cols2 = Tables.columns(tab2)
    names = Tables.columnnames(cols1)

    if Set(names) ≠ Set(Tables.columnnames(cols2))
      _vcat_error()
    end

    columns = map(names) do name
      column1 = Tables.getcolumn(cols1, name)
      column2 = Tables.getcolumn(cols2, name)
      [column1; column2]
    end

    (; zip(names, columns)...)
  elseif isnothing(tab1) && isnothing(tab2)
    nothing
  else
    _vcat_error()
  end

  newdom = GeometrySet([collect(dom1); collect(dom2)])
  newval = Dict(paramdim(newdom) => newtab)
  constructor(geotable1)(newdom, newval)
end

_vcat_error() = throw(ArgumentError("all geotables must have the same variables"))

_noattrs_error() = error("there are no attributes in the geotable")

function _checkvars(vars)
  if !allunique(vars)
    throw(ArgumentError("variable names must be unique"))
  end
end
