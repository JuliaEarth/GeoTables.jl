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
GI.nfeature(::Any, d::Data) = nitems(d)
GI.getfeature(::Any, d::Data, i) = d[i,:]

# --------------------------------------
# Convert geometries to Meshes.jl types
# --------------------------------------

function GI.convert(::Type{Point}, ::GI.PointTrait, geom)
    if GI.is3d(geom)
        return Point(GI.x(geom), GI.y(geom), GI.z(geom))
    else
        return Point(GI.x(geom), GI.y(geom))
    end
end

function GI.convert(::Type{Segment}, ::GI.LineTrait, geom)
    p1 = GI.getgeom(geom, 1)
    p2 = GI.getgeom(geom, 2)
    if GI.is3d(geom)
        Segment(Point(GI.x(p1), GI.y(p1), GI.z(p1)), Point(GI.x(p2), GI.y(p2), GI.z(p1)))
    else
        Segment(Point(GI.x(p1), GI.y(p1)), Point(GI.x(p2), GI.y(p2)))
    end
end

function GI.convert(::Type{Chain}, ::GI.LineStringTrait, geom)
    if GI.is3d(geom)
        Chain([Point(GI.x(p), GI.y(p), GI.z(p)) for p in GI.getgeom(geom)])
    else
        Chain([Point(GI.x(p), GI.y(p)) for p in GI.getgeom(geom)])
    end
end

function GI.convert(::Type{Polygon}, ::GI.PolygonTrait, geom)
    if GI.is3d(geom)
        exterior = [Point(GI.x(p), GI.y(p), GI.z(p)) for p in GI.getgeom(GI.getexterior(geom))]
    else
        exterior = [Point(GI.x(p), GI.y(p)) for p in GI.getgeom(GI.getexterior(geom))]
    end
    if GI.nhole(geom) == 0
        return PolyArea(exterior)
    else
        interiors = map(x -> [Point(GI.x(p), GI.y(p)) for p in GI.getgeom(x)], GI.gethole(geom))
        return PolyArea(exterior, interiors)
    end
end

function GI.convert(::Type{Multi}, ::GI.MultiPointTrait, geom)
    Multi([GI.convert(Point, GI.PointTrait(), x) for x in geom])
end

function GI.convert(::Type{Multi}, ::GI.MultiLineStringTrait, geom)
    Multi([GI.convert(Chain, GI.LineStringTrait(), x) for x in geom])
end

function GI.convert(::Type{Multi}, ::GI.MultiPolygonTrait, geom)
    Multi([GI.convert(Polygon, GI.PolygonTrait(), x) for x in geom])
end

# --------------------------------------
# GeoInterface approach to call convert
# --------------------------------------

geointerface_geomtype(::GI.PointTrait) = Point
geointerface_geomtype(::GI.LineTrait) = Segment
geointerface_geomtype(::GI.LineStringTrait) = Chain
geointerface_geomtype(::GI.PolygonTrait) = Polygon
geointerface_geomtype(::GI.MultiPointTrait) = Multi
geointerface_geomtype(::GI.MultiLineStringTrait) = Multi
geointerface_geomtype(::GI.MultiPolygonTrait) = Multi

geom2meshes(geom) = GI.convert(GeoTables, geom)
