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
  gtype  = GI.geotype(geom)
  coords = GI.coordinates(geom)
  if gtype == :Point
    coords2point(coords)
  elseif gtype == :LineString
    coords2chain(coords)
  elseif gtype == :MultiLineString
    coords2multichain(coords)
  elseif gtype == :Polygon
    coords2poly(coords)
  elseif gtype == :MultiPolygon
    coords2multipoly(coords)
  end
end
