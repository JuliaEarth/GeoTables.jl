# adapted from https://github.com/evetion/GeoDataFrames.jl/blob/master/src/io.jl
# and from https://github.com/yeesian/ArchGDAL.jl/blob/master/test/test_tables.jl#L264

const DRIVER = AG.extensions()

const SUPPORTED = [
  ".arrow",
  ".arrows",
  ".db",
  ".dbf",
  ".feather",
  ".fgb",
  ".geojson",
  ".geojsonl",
  ".geojsons",
  ".gml",
  ".gpkg",
  ".ipc",
  ".jml",
  ".kml",
  ".mbtiles",
  ".mvt",
  ".nc",
  ".parquet",
  ".pbf",
  ".pdf",
  ".shp",
  ".shz",
  ".sql",
  ".sqlite",
  ".xml"
]

const AGGEOM = Dict(
  GI.PointTrait() => AG.wkbPoint,
  GI.LineStringTrait() => AG.wkbLineString,
  GI.LinearRingTrait() => AG.wkbMultiLineString,
  GI.PolygonTrait() => AG.wkbPolygon,
  GI.MultiPointTrait() => AG.wkbMultiPoint,
  GI.MultiLineStringTrait() => AG.wkbMultiLineString,
  GI.MultiPolygonTrait() => AG.wkbMultiPolygon
)

asstrings(options::Dict{<:AbstractString,<:AbstractString}) =
  [uppercase(String(k)) * "=" * String(v) for (k, v) in options]

function agwrite(fname, geotable; layername="data", options=Dict("geometry_name" => "geometry"))
  ext = last(splitext(fname))
  if ext ∉ SUPPORTED
    error("file format not supported")
  end

  geoms = domain(geotable)
  table = values(geotable)
  rows = Tables.rows(table)
  schema = Tables.schema(table)

  # Set geometry name in options
  if !haskey(options, "geometry_name")
    options["geometry_name"] = "geometry"
  end

  driver = AG.getdriver(DRIVER[ext])
  trait = GI.geomtrait(first(geoms))
  aggeom = get(AGGEOM, trait, AG.wkbUnknown)
  optionlist = asstrings(options)
  agtypes = map(schema.types) do type
    try
      T = nonmissingtype(type)
      convert(AG.OGRFieldType, T)
    catch
      error("type $type not supported")
    end
  end

  AG.create(fname; driver) do dataset
    AG.createlayer(; dataset, name=layername, geom=aggeom, options=optionlist) do layer
      for (name, type) in zip(schema.names, agtypes)
        AG.addfielddefn!(layer, String(name), type)
      end

      for (row, geom) in zip(rows, geoms)
        AG.addfeature(layer) do feature
          for name in schema.names
            x = Tables.getcolumn(row, name)
            i = AG.findfieldindex(feature, name)
            if ismissing(x)
              AG.setfieldnull!(feature, i)
            else
              AG.setfield!(feature, i, x)
            end
          end

          AG.setgeom!(feature, GI.convert(AG.IGeometry, geom))
        end
      end
    end
  end

  fname
end
