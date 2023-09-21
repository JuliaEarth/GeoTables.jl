# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

Base.getindex(geotable::AbstractGeoTable, geometry::Geometry, vars::ColSelector) =
  getindex(geotable, indices(domain(geotable), geometry), vars)

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
