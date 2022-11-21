# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

# --------------------------------------
# Minimum GeoInterface.jl to perform IO
# --------------------------------------

GI.isgeometry(::Point) = true
GI.isgeometry(::Geometry) = true
GI.geomtrait(::Point) = GI.PointTrait()
GI.geomtrait(::Segment) = GI.LineTrait()
GI.geomtrait(::Chain) = GI.LineStringTrait()
GI.geomtrait(::Polygon) = GI.PolygonTrait()
GI.geomtrait(::Multi{<:Any,<:Any,<:Chain}) = GI.MultiLineStringTrait()
GI.geomtrait(::Multi{<:Any,<:Any,<:Polygon}) = GI.MultiPolygonTrait()

GI.ncoord(::GI.PointTrait, p::Point) = embeddim(p)
GI.getcoord(::GI.PointTrait, p::Point) = coordinates(p)
GI.getcoord(::GI.PointTrait, p::Point, i) = coordinates(p)[i]

GI.ngeom(::Any, s::Segment) = nvertices(s)
GI.getgeom(::Any, s::Segment, i) = vertices(s)[i]

GI.ngeom(::Any, c::Chain) = nvertices(c)
GI.getgeom(::Any, c::Chain, i) = vertices(c)[i]

GI.ngeom(::Any, p::Polygon) = length(chains(p))
GI.getgeom(::Any, p::Polygon, i) = chains(p)[i]

GI.ngeom(::Any, m::Multi) = length(collect(m))
GI.getgeom(::Any, m::Multi, i) = collect(m)[i]

GI.isfeaturecollection(::Data) = true
GI.trait(::Data) = GI.FeatureCollectionTrait()
GI.nfeature(::Any, d::Data) = nelements(domain(d))
GI.getfeature(::Any, d::Data, i) = Tables.rows(d)[i]

# --------------------------------------
# Convert geometries to Meshes.jl types
# --------------------------------------

coords2point(coords) = Point(coords)

coords2multipoint(coords) = Multi(coords2point.(coords))

coords2chain(coords) = Chain(Point.(coords))

coords2multichain(coords) = Multi(coords2chain.(coords))

function coords2poly(coords)
  chains = [Point.(coord) for coord in coords]
  PolyArea(chains[begin], chains[begin+1:end])
end

coords2multipoly(coords) = Multi(coords2poly.(coords))

function geom2meshes(geom)
  gtrait = GI.geomtrait(geom)
  coords = GI.coordinates(geom)
  if gtrait isa GI.PointTrait
    coords2point(coords)
  elseif gtrait isa GI.LineStringTrait
    coords2chain(coords)
  elseif gtrait isa GI.MultiLineStringTrait
    coords2multichain(coords)
  elseif gtrait isa GI.PolygonTrait
    coords2poly(coords)
  elseif gtrait isa GI.MultiPolygonTrait
    coords2multipoly(coords)
  end
end
