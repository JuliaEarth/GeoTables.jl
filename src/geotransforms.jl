# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function apply(transform::GeometricTransform, geotable::AbstractGeoTable)
  newdom, cache = apply(transform, domain(geotable))
  newgeotable = georef(values(geotable), newdom)
  newgeotable, cache
end

function revert(transform::GeometricTransform, newgeotable::AbstractGeoTable, cache)
  dom = revert(transform, domain(newgeotable), cache)
  georef(values(newgeotable), dom)
end

function reapply(transform::GeometricTransform, geotable::AbstractGeoTable, cache)
  newdom = reapply(transform, domain(geotable), cache)
  georef(values(geotable), newdom)
end
