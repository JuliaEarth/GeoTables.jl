"""
	overlay(geotable₁, geotable₂;
						method=:intersection,
						searchmethod=BBoxSearch)

Computes a spatial overlay between two geotables.

Unlike [`geojoin`](@ref), overlay operations generate new geometries.
Each resulting geometry is associated with the attributes of the input
geometries from which it originated.

## Methods

* `:intersection` - portions shared by both geotables
"""
function overlay(gtb1::AbstractGeoTable, gtb2::AbstractGeoTable; method=:intersection, searchmethod=BBoxSearch)
  if method ∉ (:intersection,)
    throw(ArgumentError("invalid overlay method, only :intersection is implemented at the moment."))
  end

  # use the CRS and units of the first geotable
  gtb2 = _adjustcrs(gtb1, gtb2)

  # avoid repeated attribute names
  gtb2 = _uniquenames(gtb1, gtb2)

  gtb1 = _adjustunits(gtb1)
  gtb2 = _adjustunits(gtb2)

  _overlay(gtb1, gtb2, method, searchmethod)
end

function _overlay(gtb1, gtb2, method, searchmethod)
  dom1 = domain(gtb1)
  dom2 = domain(gtb2)
  tab1 = values(gtb1)
  tab2 = values(gtb2)
  cols1 = Tables.columns(tab1)
  cols2 = Tables.columns(tab2)
  vars1 = Tables.columnnames(cols1)
  vars2 = Tables.columnnames(cols2)

  if method == :intersection
    rows = _overlayintersection(dom1, dom2, searchmethod)
  end

  inds1 = getindex.(rows, 1)
  inds2 = getindex.(rows, 2)
  geoms = getindex.(rows, 3)

  pairs1 = (var => [Tables.getcolumn(cols1, var)[i] for i in inds1] for var in vars1)
  pairs2 = (var => [Tables.getcolumn(cols2, var)[j] for j in inds2] for var in vars2)
  newtab = (; pairs1..., pairs2...) |> Tables.materializer(tab1)

  if isempty(rows)
    error("GeoTables currently cannot materialize an empty overlay.")
  else
    georef(newtab, GeometrySet(geoms))
  end
end

function _overlayintersection(dom1, dom2, searchmethod)
  searcher = searchmethod(dom2)
  # iterate over geometries in gtb1 and find matches in gtb2
  rowgroups = _tmap(eachindex(dom1)) do i
    geo1 = dom1[i]
    rows = Tuple{Int,Int,Geometry}[]
    # iterate over candidates in gtb2 that have overlapping bounding boxes with the geometry in gtb1
    for j in search(geo1, searcher)
      geo2 = dom2[j]
      # flatten Multi geometries on both sides
      for g1 in Meshes.flatten(geo1)
        for g2 in Meshes.flatten(geo2)
          I = intersection(g1, g2)
          type(I) == NotIntersecting && continue
          geom = get(I)
          if geom isa Geometry
            push!(rows, (i, j, geom))
          elseif geom isa GeometrySet
            for k in eachindex(geom)
              push!(rows, (i, j, geom[k]))
            end
          end
        end
      end
    end
    rows
  end
  reduce(vcat, rowgroups; init=Tuple{Int,Int,Geometry}[])
end
