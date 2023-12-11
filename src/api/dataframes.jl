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

"""
    hcat(geotables...)
  
Horizontally concatenate the `geotables` that have the same domain.

If a geotable has the same column names as others,
an underscore will be added to these names to make them unique.
"""
Base.hcat(geotables::AbstractGeoTable...) = reduce(hcat, geotables)

function Base.hcat(geotable1::AbstractGeoTable, geotable2::AbstractGeoTable)
  dom = domain(geotable1)
  if dom ≠ domain(geotable2)
    throw(ArgumentError("all geotables must have the same domain"))
  end

  tab1 = values(geotable1)
  tab2 = values(geotable2)
  newtab = if !isnothing(tab1) && !isnothing(tab2)
    cols1 = Tables.columns(tab1)
    cols2 = Tables.columns(tab2)
    names1 = Tables.columnnames(cols1) |> collect
    names2 = Tables.columnnames(cols2) |> collect

    names = if isdisjoint(names1, names2)
      vcat(names1, names2)
    else
      # make unique
      newnames2 = map(names2) do name
        while name ∈ names1
          name = Symbol(name, :_)
        end
        name
      end
      vcat(names1, newnames2)
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

const VCATKINDS = [:union, :intersect]

"""
    vcat(geotables...; kind=:union)
  
Vertically concatenate the `geotables` using a certain `kind` of vcat.

## Kinds

* `:union` - The columns of all geotables are preserved, filling the entries with `missing` 
  when one of the geotables does not have the column present in the other.
* `:intersect` - Only columns that are present in all geotables are returned and, 
  if there is no intersection, an error will be thrown.
"""
Base.vcat(geotables::AbstractGeoTable...; kwars...) = reduce((gtb1, gtb2) -> vcat(gtb1, gtb2; kwars...), geotables)

function Base.vcat(geotable1::AbstractGeoTable, geotable2::AbstractGeoTable; kind=:union)
  if kind ∉ VCATKINDS
    throw(ArgumentError("invalid kind of vcat, use one these $VCATKINDS"))
  end

  dom1 = domain(geotable1)
  dom2 = domain(geotable2)
  tab1 = values(geotable1)
  tab2 = values(geotable2)

  newtab = if kind == :union
    nrows1 = nrow(geotable1)
    nrows2 = nrow(geotable2)
    _unionvcat(tab1, tab2, nrows1, nrows2)
  else
    _intersectvcat(tab1, tab2)
  end

  newdom = vcat(dom1, dom2)
  newval = Dict(paramdim(newdom) => newtab)
  constructor(geotable1)(newdom, newval)
end

function _unionvcat(tab1, tab2, nrows1, nrows2)
  if !isnothing(tab1) && !isnothing(tab2)
    cols1 = Tables.columns(tab1)
    cols2 = Tables.columns(tab2)
    names1 = Tables.columnnames(cols1) |> collect
    names2 = Tables.columnnames(cols2) |> collect
    names = unique(vcat(names1, names2))

    missings1 = fill(missing, nrows1)
    missings2 = fill(missing, nrows2)
    columns = map(names) do name
      column1 = name ∈ names1 ? Tables.getcolumn(cols1, name) : missings1
      column2 = name ∈ names2 ? Tables.getcolumn(cols2, name) : missings2
      vcat(column1, column2)
    end

    (; zip(names, columns)...)
  elseif !isnothing(tab1)
    cols = Tables.columns(tab1)
    names = Tables.columnnames(cols)

    missings = fill(missing, nrows2)
    columns = map(names) do name
      column = Tables.getcolumn(cols, name)
      vcat(column, missings)
    end

    (; zip(names, columns)...)
  elseif !isnothing(tab2)
    cols = Tables.columns(tab2)
    names = Tables.columnnames(cols)

    missings = fill(missing, nrows1)
    columns = map(names) do name
      column = Tables.getcolumn(cols, name)
      vcat(missings, column)
    end

    (; zip(names, columns)...)
  else
    nothing
  end
end

function _intersectvcat(tab1, tab2)
  if !isnothing(tab1) && !isnothing(tab2)
    cols1 = Tables.columns(tab1)
    cols2 = Tables.columns(tab2)
    names1 = Tables.columnnames(cols1) |> collect
    names2 = Tables.columnnames(cols2) |> collect
    names = names1 ∩ names2
    isempty(names) && _nointersection_error()

    columns = map(names) do name
      column1 = Tables.getcolumn(cols1, name)
      column2 = Tables.getcolumn(cols2, name)
      vcat(column1, column2)
    end

    (; zip(names, columns)...)
  elseif isnothing(tab1) && isnothing(tab2)
    nothing
  else
    _nointersection_error()
  end
end

_nointersection_error() = throw(ArgumentError("no intersection found"))

_noattrs_error() = error("there are no attributes in the geotable")
