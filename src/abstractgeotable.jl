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
  if dom isa SubDomain
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
  if dom isa SubDomain
    parentindices(dom)
  else
    1:nrow(geotable)
  end
end

crs(geotable::AbstractGeoTable) = crs(domain(geotable))

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
  pretty_table(io, geotable; backend=:text, _common_kwargs(geotable)...)
end

function Base.show(io::IO, ::MIME"text/html", geotable::AbstractGeoTable)
  pretty_table(io, geotable; backend=:html, _common_kwargs(geotable)...)
end

function _common_kwargs(geotable)
  dom = domain(geotable)
  tab = values(geotable)
  names = propertynames(geotable)

  labels₁ = AnnotatedString[]
  labels₂ = String[]
  labels₃ = String[]
  for name in names
    if name === :geometry
      cname = prettyname(crs(dom))
      dname = rmmodule(datum(crs(dom)))
      label₁ = styled"{(weight=bold),cyan:$name}"
      label₂ = prettyname(eltype(dom))
      label₃ = "🖈 $cname{$dname}" 
    else
      label₁ = styled"{(weight=bold),magenta:$name}"
      T = Tables.getcolumn(Tables.columns(tab), name) |> eltype
      if T <: Missing
        label₂ = "Missing"
        label₃ = "[NoUnits]"
      else
        S = nonmissingtype(T)
        label₂ = string(nameof(scitype(S)))
        label₃ = S <: AbstractQuantity ? "[$(unit(S))]" : "[NoUnits]"
      end
    end
    push!(labels₁, label₁)
    push!(labels₂, label₂)
    push!(labels₃, label₃)
  end

  (
    title=summary(geotable),
    column_labels=[labels₁, labels₂, labels₃],
    alignment=:c,
    maximum_number_of_rows=10,
    new_line_at_end=false
  )
end
