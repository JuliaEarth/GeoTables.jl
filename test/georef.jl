@testset "georef" begin
  table = Table(x=rand(3), y=[1, 2, 3], z=["a", "b", "c"])
  tuple = (x=rand(3), y=[1, 2, 3], z=["a", "b", "c"])

  # explicit domain types
  gtb = georef(table, PointSet(rand(Point, 3)))
  @test domain(gtb) isa PointSet
  gtb = georef(tuple, PointSet(rand(Point, 3)))
  @test domain(gtb) isa PointSet
  gtb = georef(table, CartesianGrid(3))
  @test domain(gtb) isa CartesianGrid
  gtb = georef(tuple, CartesianGrid(3))
  @test domain(gtb) isa CartesianGrid

  # vectors of geometries
  gtb = georef(table, rand(Point, 3))
  @test domain(gtb) isa PointSet
  gtb = georef(tuple, rand(Point, 3))
  @test domain(gtb) isa PointSet
  gtb = georef(table, collect(CartesianGrid(3)))
  @test domain(gtb) isa GeometrySet
  gtb = georef(tuple, collect(CartesianGrid(3)))
  @test domain(gtb) isa GeometrySet

  # coordinates of point set
  gtb = georef(table, [(rand(), rand()) for i in 1:3])
  @test domain(gtb) isa PointSet
  gtb = georef(tuple, [(rand(), rand()) for i in 1:3])
  @test domain(gtb) isa PointSet

  # coordinates names in table
  gtb = georef(table, (:x, :y))
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  gtb = georef(tuple, (:x, :y))
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  gtb = georef(table, [:x, :y])
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  gtb = georef(tuple, [:x, :y])
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  gtb = georef(table, ("x", "y"))
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  gtb = georef(tuple, ("x", "y"))
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  gtb = georef(table, ["x", "y"])
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  gtb = georef(tuple, ["x", "y"])
  @test domain(gtb) isa PointSet
  @test propertynames(gtb) == [:z, :geometry]
  # table without attribute columns
  noattrs = (x=rand(3), y=rand(3))
  gtb = georef(noattrs, [:x, :y])
  @test domain(gtb) isa PointSet
  @test isnothing(values(gtb))
  @test propertynames(gtb) == [:geometry]
  # error: coordinate columns not found in the table
  @test_throws ArgumentError georef(table, [:X, :Y])

  # grid data
  tuple1D = (x=rand(10), y=rand(10))
  gtb = georef(tuple1D)
  @test domain(gtb) == CartesianGrid(10)
  tuple2D = (x=rand(10, 10), y=rand(10, 10))
  gtb = georef(tuple2D)
  @test domain(gtb) == CartesianGrid(10, 10)
  tuple3D = (x=rand(10, 10, 10), y=rand(10, 10, 10))
  gtb = georef(tuple3D)
  @test domain(gtb) == CartesianGrid(10, 10, 10)
  # different types
  tuple1D = (x=[rand(9); missing], y=rand(10))
  gtb = georef(tuple1D)
  @test domain(gtb) == CartesianGrid(10)
  tuple2D = (x=rand(10, 10), y=BitArray(rand(Bool, 10, 10)))
  gtb = georef(tuple2D)
  @test domain(gtb) == CartesianGrid(10, 10)
  # error: all arrays must have the same dimensions
  tuple2D = (x=rand(3, 3), y=rand(5, 5))
  @test_throws ArgumentError georef(tuple2D)

  # custom crs
  table = (a=rand(3), b=rand(3))
  gtb = georef(table, [(0, 0), (1, 1), (2, 2)], crs=Mercator)
  @test crs(gtb.geometry) <: Mercator
  table = (a=rand(10), x=rand(10), y=rand(10))
  gtb = georef(table, ("x", "y"), crs=Cartesian)
  @test crs(gtb.geometry) <: Cartesian
  gtb = georef(table, ("x", "y"), crs=LatLon)
  @test crs(gtb.geometry) <: LatLon

  # crs heuristics
  table = (a=rand(10), x=rand(10), y=rand(10))
  gtb = georef(table, ("x", "y"))
  @test crs(gtb.geometry) <: Cartesian
  table = (a=rand(10), lat=rand(10), lon=rand(10))
  gtb = georef(table, ("lat", "lon"))
  @test crs(gtb.geometry) <: LatLon

  # fix latlon order
  table = (a=[1, 2, 3], lon=[1, 1, 1], lat=[2, 2, 2])
  gtb = georef(table, ("lon", "lat"))
  @test crs(gtb.geometry) <: LatLon
  @test coords(gtb.geometry[1]).lat == 2u"°"
  @test coords(gtb.geometry[1]).lon == 1u"°"

  # epsg/esri code
  table = (a=rand(10), x=rand(10), y=rand(10))
  gtb = georef(table, ("x", "y"), crs=EPSG{3395})
  @test crs(gtb.geometry) <: Mercator
  table = (a=rand(10), x=rand(10), y=rand(10))
  gtb = georef(table, ("x", "y"), crs=ESRI{54034})
  @test crs(gtb.geometry) <: Lambert
end
