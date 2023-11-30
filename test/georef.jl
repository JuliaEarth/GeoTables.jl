@testset "georef" begin
  table = Table(x=rand(3), y=[1, 2, 3], z=["a", "b", "c"])
  tuple = (x=rand(3), y=[1, 2, 3], z=["a", "b", "c"])

  # explicit domain types
  gtb = georef(table, PointSet(rand(2, 3)))
  @test domain(gtb) isa PointSet
  gtb = georef(tuple, PointSet(rand(2, 3)))
  @test domain(gtb) isa PointSet
  gtb = georef(table, CartesianGrid(3))
  @test domain(gtb) isa CartesianGrid
  gtb = georef(tuple, CartesianGrid(3))
  @test domain(gtb) isa CartesianGrid

  # vectors of geometries
  gtb = georef(table, rand(Point2, 3))
  @test domain(gtb) isa PointSet
  gtb = georef(tuple, rand(Point2, 3))
  @test domain(gtb) isa PointSet
  gtb = georef(table, collect(CartesianGrid(3)))
  @test domain(gtb) isa GeometrySet
  gtb = georef(tuple, collect(CartesianGrid(3)))
  @test domain(gtb) isa GeometrySet

  # coordinates of point set
  gtb = georef(table, rand(2, 3))
  @test domain(gtb) isa PointSet
  gtb = georef(tuple, rand(2, 3))
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
  # throws: different sizes
  tuple2D = (x=rand(3, 3), y=rand(5, 5))
  @test_throws AssertionError georef(tuple2D)
end
