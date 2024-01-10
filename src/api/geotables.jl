# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

Base.getindex(geotable::AbstractGeoTable, geometry::Geometry, vars) =
  _getindex(geotable, indices(domain(geotable), geometry), selector(vars))

# --------------
# GRID INDEXING
# --------------

const GridSelector{Dim} = NTuple{Dim,Union{UnitRange{Int},Colon,Int}}

function Base.getindex(geotable::AbstractGeoTable, ijk::Dims{Dim}, vars) where {Dim}
  _checkargs(geotable, Dim)
  _getgridindex(geotable, CartesianIndex(ijk), selector(vars))
end

function Base.getindex(geotable::AbstractGeoTable, ijk::GridSelector{Dim}, vars) where {Dim}
  _checkargs(geotable, Dim)
  dims = size(domain(geotable))
  ranges = ntuple(i -> _asrange(dims[i], ijk[i]), Dim)
  _getgridindex(geotable, CartesianIndices(ranges), selector(vars))
end

function Base.getindex(geotable::AbstractGeoTable, ijk::CartesianIndex{Dim}, vars) where {Dim}
  _checkargs(geotable, Dim)
  _getgridindex(geotable, ijk, selector(vars))
end

function Base.getindex(geotable::AbstractGeoTable, ijk::CartesianIndices{Dim}, vars) where {Dim}
  _checkargs(geotable, Dim)
  _getgridindex(geotable, ijk, selector(vars))
end

function _getgridindex(geotable, ijk, selector::ColumnSelector)
  svars = selector(propertynames(geotable))
  _getgridindex(geotable, ijk, svars)
end

function _getgridindex(geotable, ijk, selector::SingleColumnSelector)
  svar = selectsingle(selector, propertynames(geotable))
  _getgridindex(geotable, ijk, svar)
end

function _getgridindex(geotable, ijk::CartesianIndices, vars::Vector{Symbol})
  grid = domain(geotable)
  tab = values(geotable)
  vars = setdiff(vars, [:geometry])
  newgrid = grid[ijk]
  newtab = if isnothing(tab)
    !isempty(vars) && _noattrs_error()
    nothing
  else
    inds = _asliner(grid, ijk)
    sub = Tables.subset(tab, inds)
    cols = Tables.columns(sub)
    pairs = (var => Tables.getcolumn(cols, var) for var in vars)
    (; pairs...) |> Tables.materializer(tab)
  end
  georef(newtab, newgrid)
end

function _getgridindex(geotable, ijk::CartesianIndices, var::Symbol)
  inds = _asliner(domain(geotable), ijk)
  _getindex(geotable, inds, var)
end

function _getgridindex(geotable, ijk::CartesianIndex, vars::Vector{Symbol})
  ind = _asliner(domain(geotable), ijk)
  _getindex(geotable, ind, vars)
end

function _getgridindex(geotable, ijk::CartesianIndex, var::Symbol)
  ind = _asliner(domain(geotable), ijk)
  _getindex(geotable, ind, var)
end

_asrange(::Int, r::UnitRange{Int}) = r
_asrange(d::Int, ::Colon) = 1:d
_asrange(::Int, i::Int) = i:i

_asliner(grid, ijk::CartesianIndex) = LinearIndices(size(grid))[ijk]
_asliner(grid, ijk::CartesianIndices) = LinearIndices(size(grid))[ijk] |> vec

function _checkargs(geotable, Dim)
  grid = domain(geotable)
  if !(grid isa Grid)
    throw(ArgumentError("cartesian indexing only works with grids"))
  end
  if embeddim(grid) ≠ Dim
    throw(ArgumentError("invalid cartesian indexing"))
  end
end

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
