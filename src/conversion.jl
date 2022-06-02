# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

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
