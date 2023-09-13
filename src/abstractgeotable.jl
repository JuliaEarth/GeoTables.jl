"""
    AbstractGeoTable

A domain implementing the [`Domain`](@ref) trait together with tables
of values for geometries of the domain.
"""
abstract type AbstractGeoTable end

"""
    domain(geotable)

Return underlying domain of the `geotable`.
"""
function domain end

"""
    values(geotable, [rank])

Return the values of `geotable` for a given `rank` as a table.

The rank is a non-negative integer that specifies the
parametric dimension of the geometries of interest:

* 0 - points
* 1 - segments
* 2 - triangles, quadrangles, ...
* 3 - tetrahedrons, hexahedrons, ...

If the rank is not specified, it is assumed to be the rank
of the elements of the domain.
"""
values

"""
    constructor(T::Type)

Return the constructor of the geotable type `T` as a function.
The function takes a domain and a dictionary of tables as
inputs and combines them into an instance of the geotable type.
"""
function constructor end

# ----------
# FALLBACKS
# ----------

constructor(::T) where {T<:AbstractGeoTable} = constructor(T)

function (::Type{T})(table) where {T<:AbstractGeoTable}
  # build domain from geometry column
  cols = Tables.columns(table)
  geoms = Tables.getcolumn(cols, :geometry)
  domain = GeometrySet(geoms)

  # build table of features from remaining columns
  vars = setdiff(Tables.columnnames(cols), [:geometry])
  pairs = (var => Tables.getcolumn(cols, var) for var in vars)
  newtable = (; pairs...)

  # data table for elements
  values = Dict(paramdim(domain) => newtable)

  # combine the two with constructor
  constructor(T)(domain, values)
end

function Base.:(==)(geotable₁::AbstractGeoTable, geotable₂::AbstractGeoTable)
  # must have the same domain
  if domain(geotable₁) != domain(geotable₂)
    return false
  end

  # must have the same geotable tables
  for rank in 0:paramdim(domain(geotable₁))
    vals₁ = values(geotable₁, rank)
    vals₂ = values(geotable₂, rank)
    if !isequal(vals₁, vals₂)
      return false
    end
  end

  return true
end

nrow(geotable::AbstractGeoTable) = nelements(domain(geotable))

function ncol(geotable::AbstractGeoTable)
  table = values(geotable)
  isnothing(table) && return 1
  cols = Tables.columns(table)
  vars = Tables.columnnames(cols)
  length(vars) + 1
end

Base.view(geotable::AbstractGeoTable, inds) = SubGeoTable(geotable, inds)

Base.view(geotable::AbstractGeoTable, geometry::Geometry) = SubGeoTable(geotable, indices(domain(geotable), geometry))

# -----------------
# TABLES INTERFACE
# -----------------

Tables.istable(::Type{<:AbstractGeoTable}) = true

Tables.rowaccess(::Type{<:AbstractGeoTable}) = true

function Tables.rows(geotable::AbstractGeoTable)
  table = values(geotable)
  trows = isnothing(table) ? nothing : Tables.rows(table)
  GeoTableRows(domain(geotable), trows)
end

Tables.schema(geotable::AbstractGeoTable) = Tables.schema(Tables.rows(geotable))

Tables.subset(geotable::AbstractGeoTable, inds; viewhint=nothing) = SubGeoTable(geotable, inds)

# wrapper type for rows of the geotable table
# so that we can easily inform the schema
struct GeoTableRows{D<:Domain,R}
  domain::D
  trows::R
end

Base.length(rows::GeoTableRows) = nelements(rows.domain)

function Base.iterate(rows::GeoTableRows, state=1)
  if state > length(rows)
    nothing
  else
    elm, _ = iterate(rows.domain, state)
    row = if isnothing(rows.trows)
      (; geometry=elm)
    else
      trow, _ = iterate(rows.trows, state)
      names = Tables.columnnames(trow)
      pairs = (nm => Tables.getcolumn(trow, nm) for nm in names)
      (; pairs..., geometry=elm)
    end
    row, state + 1
  end
end

function Tables.schema(rows::GeoTableRows)
  geomtype = eltype(rows.domain)
  if isnothing(rows.trows)
    Tables.Schema((:geometry,), (geomtype,))
  else
    schema = Tables.schema(rows.trows)
    names, types = schema.names, schema.types
    Tables.Schema((names..., :geometry), (types..., geomtype))
  end
end

Tables.materializer(::Type{T}) where {T<:AbstractGeoTable} = T

# --------------------
# DATAFRAME INTERFACE
# --------------------

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

function Base.getindex(geotable::AbstractGeoTable, inds::AbstractVector{Int}, vars::AbstractVector{Symbol})
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

Base.getindex(geotable::AbstractGeoTable, inds::AbstractVector{Int}, var::Symbol) =
  getproperty(view(geotable, inds), var)

function Base.getindex(geotable::AbstractGeoTable, inds::AbstractVector{Int}, ::Colon)
  dview = view(geotable, inds)
  newdom = domain(dview)
  newtab = values(dview)
  newval = Dict(paramdim(newdom) => newtab)
  constructor(geotable)(newdom, newval)
end

function Base.getindex(geotable::AbstractGeoTable, ind::Int, vars::AbstractVector{Symbol})
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

Base.getindex(geotable::AbstractGeoTable, ind::Int, var::Symbol) = getproperty(geotable, var)[ind]

function Base.getindex(geotable::AbstractGeoTable, ind::Int, ::Colon)
  dom = domain(geotable)
  tab = values(geotable)
  if isnothing(tab)
    (; geometry=dom[ind])
  else
    row = Tables.subset(tab, ind)
    vars = Tables.columnnames(row)
    pairs = (var => Tables.getcolumn(row, var) for var in vars)
    (; pairs..., geometry=dom[ind])
  end
end

function Base.getindex(geotable::AbstractGeoTable, ::Colon, vars::AbstractVector{Symbol})
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

Base.getindex(geotable::AbstractGeoTable, ::Colon, var::Symbol) = getproperty(geotable, var)

Base.getindex(geotable::AbstractGeoTable, inds, vars::AbstractVector{<:AbstractString}) =
  getindex(geotable, inds, Symbol.(vars))

Base.getindex(geotable::AbstractGeoTable, inds, var::AbstractString) = getindex(geotable, inds, Symbol(var))

function Base.getindex(geotable::AbstractGeoTable, inds, var::Regex)
  tab = values(geotable)
  if isnothing(tab)
    _noattrs_error()
  else
    cols = Tables.columns(tab)
    names = Tables.columnnames(cols) |> collect
    snames = filter(nm -> occursin(var, String(nm)), names)
    getindex(geotable, inds, snames)
  end
end

Base.getindex(geotable::AbstractGeoTable, geometry::Geometry, vars) =
  getindex(geotable, indices(domain(geotable), geometry), vars)

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

    columns1 = [Tables.getcolumn(cols1, name) for name in names1]
    columns2 = [Tables.getcolumn(cols2, name) for name in names2]
    columns = [columns1; columns2]

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

# ----------
# UTILITIES
# ----------

"""
    asarray(geotable, var)

Returns the geotable for the variable `var` in `geotable` as a Julia array
with size equal to the size of the underlying domain if the size is
defined, otherwise returns a vector.
"""
function asarray(geotable::AbstractGeoTable, var::Symbol)
  dom = domain(geotable)
  hassize = hasmethod(size, (typeof(dom),))
  dataval = getproperty(geotable, var)
  hassize ? reshape(dataval, size(dom)) : dataval
end

asarray(geotable::AbstractGeoTable, var::AbstractString) = asarray(geotable, Symbol(var))

# -----------
# IO METHODS
# -----------

function Base.summary(io::IO, geotable::AbstractGeoTable)
  dom = domain(geotable)
  name = nameof(typeof(geotable))
  print(io, "$(nrow(geotable))×$(ncol(geotable)) $name over $dom")
end

Base.show(io::IO, geotable::AbstractGeoTable) = summary(io, geotable)

function Base.show(io::IO, ::MIME"text/plain", geotable::AbstractGeoTable)
  fcolor = crayon"bold magenta"
  gcolor = crayon"bold (0,128,128)"
  hcolors = [fill(fcolor, ncol(geotable) - 1); gcolor]
  pretty_table(
    io,
    geotable;
    backend=Val(:text),
    _common_kwargs(geotable)...,
    header_crayon=hcolors,
    newline_at_end=false
  )
end

function Base.show(io::IO, ::MIME"text/html", geotable::AbstractGeoTable)
  pretty_table(io, geotable; backend=Val(:html), _common_kwargs(geotable)..., max_num_of_rows=10)
end

function _common_kwargs(geotable)
  dom = domain(geotable)
  tab = values(geotable)
  names = propertynames(geotable)

  # header
  colnames = string.(names)

  # subheaders
  tuples = map(names) do name
    if name === :geometry
      t = Meshes.prettyname(eltype(dom))
      u = ""
    else
      cols = Tables.columns(tab)
      x = Tables.getcolumn(cols, name)
      T = eltype(x)
      if T <: Quantity
        t = "Continuous"
        u = "[$(unit(T))]"
      else
        t = _coltype(x)
        u = "[NoUnits]"
      end
    end
    t, u
  end
  types = first.(tuples)
  units = last.(tuples)

  (title=summary(geotable), header=(colnames, types, units), alignment=:c, vcrop_mode=:bottom)
end

_coltype(x) = _coltype(x, elscitype(x))
_coltype(x, ::Type) = string(nameof(nonmissingtype(elscitype(x))))
_coltype(x, ::Type{Missing}) = "Missing"
