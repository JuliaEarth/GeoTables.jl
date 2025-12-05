@testset "No attributes" begin
  pset = PointSet((0, 0), (1, 1), (2, 2))
  gtb = GeoTable(pset)
  @test ncol(gtb) == 1
  @test size(gtb) == (3, 1)
  @test size(gtb, 1) == 3
  @test size(gtb, 2) == 1
  @test axes(gtb) == (Base.OneTo(3), Base.OneTo(1))
  @test axes(gtb, 1) == Base.OneTo(3)
  @test axes(gtb, 2) == Base.OneTo(1)
  @test gtb[begin:end, :] == gtb
  @test gtb[:, begin:end] == gtb
  @test gtb[:, begin:begin] == gtb
  @test gtb[:, end:end] == gtb
  @test gtb[:, 1:1] == gtb
  @test gtb[begin, :] == gtb[1, :]
  @test gtb[end, :] == gtb[3, :]
  @test gtb[:, begin] == gtb[:, 1]
  @test gtb[:, end] == gtb[:, 1]

  # GeoTableRows
  rows = Tables.rows(gtb)
  sch = Tables.schema(rows)
  @test sch.names == (:geometry,)
  @test sch.types == (eltype(pset),)
  row, state = iterate(rows)
  @test Tables.columnnames(row) == (:geometry,)
  @test Tables.getcolumn(row, :geometry) == pset[1]
  row, state = iterate(rows, state)
  @test Tables.columnnames(row) == (:geometry,)
  @test Tables.getcolumn(row, :geometry) == pset[2]
  row, state = iterate(rows, state)
  @test Tables.columnnames(row) == (:geometry,)
  @test Tables.getcolumn(row, :geometry) == pset[3]
  @test isnothing(iterate(rows, state))

  # dataframe interface
  @test propertynames(gtb) == [:geometry]
  @test gtb.geometry == pset
  @test gtb[1:2, [:geometry]].geometry == view(pset, 1:2)
  @test gtb[1, [:geometry]].geometry == pset[1]
  @test gtb[1, :].geometry == pset[1]
  @test gtb[:, [:geometry]] == gtb
  ngtb = georef((; x=rand(3)), pset)
  hgtb = hcat(gtb, ngtb)
  @test propertynames(hgtb) == [:x, :geometry]
  @test hgtb.x == ngtb.x
  @test hgtb.geometry == pset
  npset = PointSet((4, 4), (5, 5), (6, 6))
  ngtb = GeoTable(npset)
  vgtb = vcat(gtb, ngtb)
  @test propertynames(vgtb) == [:geometry]
  @test vgtb.geometry == PointSet([collect(pset); collect(npset)])

  # viewing
  v = view(gtb, [1, 3])
  @test isnothing(values(v))
  @test v.geometry == view(pset, [1, 3])

  # grid indexing
  grid = CartesianGrid(10, 10)
  linds = LinearIndices(size(grid))
  gtb = GeoTable(grid)
  @test isnothing(values(gtb[(1:3, :), :]))
  @test gtb[(1:3, :), :].geometry == grid[1:3, :]
  @test gtb[(1:3, :), :].geometry isa CartesianGrid

  # throws
  @test_throws ErrorException gtb.test
  @test_throws AssertionError gtb[[1, 3], [:test]]
  @test_throws AssertionError gtb[2, [:test]]
  @test_throws AssertionError gtb[:, [:test]]
  @test_throws AssertionError gtb[:, r"test"]
end
