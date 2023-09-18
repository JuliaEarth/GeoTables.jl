# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

partitioninds(rng::AbstractRNG, geotable::AbstractGeoTable, method::PartitionMethod) =
  partitioninds(rng, domain(geotable), method)

sampleinds(rng::AbstractRNG, geotable::AbstractGeoTable, method::DiscreteSamplingMethod) =
  sampleinds(rng, domain(geotable), method)

sortinds(geotable::AbstractGeoTable, method::SortingMethod) = sortinds(domain(geotable), method)
