# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

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
    setdomain!(geotable, newdomain)

Sets the `geotable` domain to `newdomain`.
"""
function setdomain! end

# ----------
# FALLBACKS
# ----------

function (::Type{T})(table) where {T<:AbstractGeoTable}
  # build domain from geometry column
  cols = Tables.columns(table)
  geoms = Tables.getcolumn(cols, :geometry)
  domain = GeometrySet(geoms)

  # build table of features from remaining columns
  vars = setdiff(Tables.columnnames(cols), [:geometry])
  pairs = (var => Tables.getcolumn(cols, var) for var in vars)
  newtable = (; pairs...)

  georef(newtable, domain)
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

Base.view(geotable::AbstractGeoTable, inds::AbstractVector{Int}) = SubGeoTable(geotable, inds)

Base.view(geotable::AbstractGeoTable, geometry::Geometry) = SubGeoTable(geotable, indices(domain(geotable), geometry))

function Base.parent(geotable::AbstractGeoTable)
  dom = domain(geotable)
  if dom isa Meshes.SubDomain
    pdom = parent(dom)

    tab = values(geotable)
    newtab = if !isnothing(tab)
      n = nelements(pdom)
      inds = parentindices(dom)
      cols = Tables.columns(tab)
      vars = Tables.columnnames(cols)
      pairs = map(vars) do var
        x = Tables.getcolumn(cols, var)
        y = Vector{Union{Missing,eltype(x)}}(missing, n)
        y[inds] .= x
        var => y
      end
      (; pairs...) |> Tables.materializer(tab)
    else
      nothing
    end

    georef(newtab, pdom)
  else
    geotable
  end
end

function Base.parentindices(geotable::AbstractGeoTable)
  dom = domain(geotable)
  if dom isa Meshes.SubDomain
    parentindices(dom)
  else
    1:nrow(geotable)
  end
end

setdomain!(geotable::AbstractGeoTable, geoms::AbstractVector{<:Geometry}) = setdomain!(geotable, GeometrySet(geoms))

function Base.setproperty!(geotable::AbstractGeoTable, name::Symbol, value)
  if name === :geometry
    if !(value isa Domain || value isa AbstractVector{<:Geometry})
      error("only domains and vectors of geometries are supported")
    end
    if length(value) ≠ nrow(geotable)
      error("the new domain must have the same number of elements as the geotable")
    end
    setdomain!(geotable, value)
  else
    error("only the `geometry` column can be set in the current version")
  end
  value
end

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
      if T <: Missing
        t = "Missing"
        u = "[NoUnits]"
      else
        S = nonmissingtype(T)
        t = string(nameof(scitype(S)))
        u = S <: AbstractQuantity ? "[$(unit(S))]" : "[NoUnits]"
      end
    end
    t, u
  end
  types = first.(tuples)
  units = last.(tuples)

  (title=summary(geotable), header=(colnames, types, units), alignment=:c, vcrop_mode=:bottom)
end
