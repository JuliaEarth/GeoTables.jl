"""
	overlay(geotable₁, geotable₂;
						method=:intersection)

Computes a spatial overlay between two geotables.

Unlike [`geojoin`](@ref), overlay operations generate new geometries.
Each resulting geometry is associated with the attributes of the input
geometries from which it originated.

## Methods

* `:intersection` - portions shared by both geotables
"""
function overlay(gtb1::AbstractGeoTable, gtb2::AbstractGeoTable; method=:intersection)
  if method ∉ (:intersection,)
    throw(ArgumentError("invalid overlay method, only :intersection is implemented at the moment."))
  end

  # use the CRS and units of the first geotable
  gtb2 = _adjustcrs(gtb1, gtb2)

  # avoid repeated attribute names
  gtb2 = _uniquenames(gtb1, gtb2)

  gtb1 = _adjustunits(gtb1)
  gtb2 = _adjustunits(gtb2)

  _overlay(gtb1, gtb2, method)
end

function _overlay(gtb1, gtb2, method)
  dom1 = domain(gtb1)
  dom2 = domain(gtb2)
  tab1 = values(gtb1)
  tab2 = values(gtb2)
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  if method == :intersection
    rows = _overlayintersection(dom1, dom2)
  end
  isempty(rows) && error("GeoTables currently cannot materialize an empty overlay.")

  inds1 = getindex.(rows, 1)
  inds2 = getindex.(rows, 2)
  geoms = getindex.(rows, 3)

  pairs1 = (var => [Tables.getcolumn(cols1, var)[i] for i in inds1] for var in vars1)
  pairs2 = (var => [Tables.getcolumn(cols2, var)[j] for j in inds2] for var in vars2)
  newtab = (; pairs1..., pairs2...) |> Tables.materializer(tab1)

  georef(newtab, GeometrySet(geoms))
end

function _overlayintersection(dom1, dom2)
  searcher = BBoxSearch(dom2)
  # iterate over geometries in gtb1 and find matches in gtb2
  rowgroups = _tmap(eachindex(dom1)) do i
    geo1 = dom1[i]
    rows = Tuple{Int,Int,Geometry}[]
    candidates = search(geo1, searcher)
    isempty(candidates) && return rows

    # iterate over candidates in gtb2 that have overlapping bounding boxes with the geometry in gtb1
    for j in candidates
      I = intersection(geo1, dom2[j])
      type(I) == NotIntersecting && continue

      push!(rows, (i, j, get(I)))
    end
    rows
  end
  reduce(vcat, rowgroups)
end
