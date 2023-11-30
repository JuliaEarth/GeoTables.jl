@testset "viewing" begin
  for dummy in [dummygeoref, georef]
    g = CartesianGrid(10, 10)
    t = (a=1:100, b=1:100)
    d = dummy(t, g)
    v = view(d, 1:3)

    g = CartesianGrid(10, 10)
    t = (a=1:100, b=1:100)
    d = dummy(t, g)
    b = Box(Point(1, 1), Point(5, 5))
    v = view(d, b)
    @test domain(v) == CartesianGrid(Point(0, 0), Point(6, 6), dims=(6, 6))
    x = [collect(1:6); collect(11:16); collect(21:26); collect(31:36); collect(41:46); collect(51:56)]
    @test Tables.columntable(values(v)) == (a=x, b=x)

    p = PointSet(collect(vertices(g)))
    d = dummy(t, p)
    v = view(d, b)
    dd = domain(v)
    @test centroid(dd, 1) == Point(1, 1)
    @test centroid(dd, nelements(dd)) == Point(5, 5)
    tt = Tables.columntable(values(v))
    @test tt == (
      a=[13, 14, 15, 16, 17, 24, 25, 26, 27, 28, 35, 36, 37, 38, 39, 46, 47, 48, 49, 50, 57, 58, 59, 60, 61],
      b=[13, 14, 15, 16, 17, 24, 25, 26, 27, 28, 35, 36, 37, 38, 39, 46, 47, 48, 49, 50, 57, 58, 59, 60, 61]
    )

    dom = CartesianGrid(2, 2)
    dat = dummy((a=[1, 2, 3, 4], b=[5, 6, 7, 8]), dom)
    v = view(dat, 2:4)
    @test domain(v) == view(dom, 2:4)
    @test Tables.columntable(values(v)) == (a=[2, 3, 4], b=[6, 7, 8])
    @test centroid(domain(v), 1) == Point(1.5, 0.5)
    @test centroid(domain(v), 2) == Point(0.5, 1.5)
    @test centroid(domain(v), 3) == Point(1.5, 1.5)
    @test v.a == v."a" == [2, 3, 4]
    @test v.b == v."b" == [6, 7, 8]

    # viewing with geometries
    a = rand(100)
    b = rand(100)
    grid = CartesianGrid(10, 10)
    linds = LinearIndices(size(grid))
    gtb = dummy((; a, b), grid)
    tri = Triangle((1.5, 1.5), (4.5, 4.5), (7.5, 1.5))
    v = view(gtb, tri)
    @test gtb.a[linds[4, 3]] ∈ v.a
    @test gtb.a[linds[5, 3]] ∈ v.a
    @test gtb.a[linds[6, 3]] ∈ v.a
    @test gtb.b[linds[4, 3]] ∈ v.b
    @test gtb.b[linds[5, 3]] ∈ v.b
    @test gtb.b[linds[6, 3]] ∈ v.b
  end
end
