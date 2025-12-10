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
  if paramdim(grid) ≠ Dim
    throw(ArgumentError("invalid cartesian indexing"))
  end
end
