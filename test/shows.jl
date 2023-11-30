# terminal prints are different on macOS
if !Sys.isapple()
  @testset "show" begin
    a = [0, 6, 6, 3, 9, 5, 2, 2, 8]
    b = [2.34, 7.5, 0.06, 1.29, 3.64, 8.05, 0.11, 0.64, 8.46]
    c = ["txt1", "txt2", "txt3", "txt4", "txt5", "txt6", "txt7", "txt8", "txt9"]
    pset = PointSet(Point.(1:9, 1:9))

    gtb = georef((; a, b, c), pset)
    @test sprint(show, gtb) == "9×4 GeoTable over 9 PointSet{2,Float64}"
    @test sprint(show, MIME("text/plain"), gtb) == """
    9×4 GeoTable over 9 PointSet{2,Float64}
    ┌─────────────┬────────────┬─────────────┬────────────┐
    │      a      │     b      │      c      │  geometry  │
    │ Categorical │ Continuous │ Categorical │   Point2   │
    │  [NoUnits]  │ [NoUnits]  │  [NoUnits]  │            │
    ├─────────────┼────────────┼─────────────┼────────────┤
    │      0      │    2.34    │    txt1     │ (1.0, 1.0) │
    │      6      │    7.5     │    txt2     │ (2.0, 2.0) │
    │      6      │    0.06    │    txt3     │ (3.0, 3.0) │
    │      3      │    1.29    │    txt4     │ (4.0, 4.0) │
    │      9      │    3.64    │    txt5     │ (5.0, 5.0) │
    │      5      │    8.05    │    txt6     │ (6.0, 6.0) │
    │      2      │    0.11    │    txt7     │ (7.0, 7.0) │
    │      2      │    0.64    │    txt8     │ (8.0, 8.0) │
    │      8      │    8.46    │    txt9     │ (9.0, 9.0) │
    └─────────────┴────────────┴─────────────┴────────────┘"""

    vgtb = view(gtb, 1:3)
    @test sprint(show, vgtb) == "3×4 SubGeoTable over 3 view(::PointSet{2,Float64}, 1:3)"
    @test sprint(show, MIME("text/plain"), vgtb) == """
    3×4 SubGeoTable over 3 view(::PointSet{2,Float64}, 1:3)
    ┌─────────────┬────────────┬─────────────┬────────────┐
    │      a      │     b      │      c      │  geometry  │
    │ Categorical │ Continuous │ Categorical │   Point2   │
    │  [NoUnits]  │ [NoUnits]  │  [NoUnits]  │            │
    ├─────────────┼────────────┼─────────────┼────────────┤
    │      0      │    2.34    │    txt1     │ (1.0, 1.0) │
    │      6      │    7.5     │    txt2     │ (2.0, 2.0) │
    │      6      │    0.06    │    txt3     │ (3.0, 3.0) │
    └─────────────┴────────────┴─────────────┴────────────┘"""

    gtb = georef((a=a * u"m/s", b=b * u"km/hr", c=c), pset)
    @test sprint(show, gtb) == "9×4 GeoTable over 9 PointSet{2,Float64}"
    @test sprint(show, MIME("text/plain"), gtb) == """
    9×4 GeoTable over 9 PointSet{2,Float64}
    ┌─────────────┬───────────────┬─────────────┬────────────┐
    │      a      │       b       │      c      │  geometry  │
    │ Categorical │  Continuous   │ Categorical │   Point2   │
    │  [m s^-1]   │  [km hr^-1]   │  [NoUnits]  │            │
    ├─────────────┼───────────────┼─────────────┼────────────┤
    │  0 m s^-1   │ 2.34 km hr^-1 │    txt1     │ (1.0, 1.0) │
    │  6 m s^-1   │ 7.5 km hr^-1  │    txt2     │ (2.0, 2.0) │
    │  6 m s^-1   │ 0.06 km hr^-1 │    txt3     │ (3.0, 3.0) │
    │  3 m s^-1   │ 1.29 km hr^-1 │    txt4     │ (4.0, 4.0) │
    │  9 m s^-1   │ 3.64 km hr^-1 │    txt5     │ (5.0, 5.0) │
    │  5 m s^-1   │ 8.05 km hr^-1 │    txt6     │ (6.0, 6.0) │
    │  2 m s^-1   │ 0.11 km hr^-1 │    txt7     │ (7.0, 7.0) │
    │  2 m s^-1   │ 0.64 km hr^-1 │    txt8     │ (8.0, 8.0) │
    │  8 m s^-1   │ 8.46 km hr^-1 │    txt9     │ (9.0, 9.0) │
    └─────────────┴───────────────┴─────────────┴────────────┘"""

    gtb = georef((a=[missing; a[2:9]], b=[b[1:4]; missing; b[6:9]], c=[c[1:8]; missing]), pset)
    @test sprint(show, gtb) == "9×4 GeoTable over 9 PointSet{2,Float64}"
    @test sprint(show, MIME("text/plain"), gtb) == """
    9×4 GeoTable over 9 PointSet{2,Float64}
    ┌─────────────┬────────────┬─────────────┬────────────┐
    │      a      │     b      │      c      │  geometry  │
    │ Categorical │ Continuous │ Categorical │   Point2   │
    │  [NoUnits]  │ [NoUnits]  │  [NoUnits]  │            │
    ├─────────────┼────────────┼─────────────┼────────────┤
    │   missing   │    2.34    │    txt1     │ (1.0, 1.0) │
    │      6      │    7.5     │    txt2     │ (2.0, 2.0) │
    │      6      │    0.06    │    txt3     │ (3.0, 3.0) │
    │      3      │    1.29    │    txt4     │ (4.0, 4.0) │
    │      9      │  missing   │    txt5     │ (5.0, 5.0) │
    │      5      │    8.05    │    txt6     │ (6.0, 6.0) │
    │      2      │    0.11    │    txt7     │ (7.0, 7.0) │
    │      2      │    0.64    │    txt8     │ (8.0, 8.0) │
    │      8      │    8.46    │   missing   │ (9.0, 9.0) │
    └─────────────┴────────────┴─────────────┴────────────┘"""

    gtb = georef((a=[missing; a[2:9]] * u"m/s", b=[b[1:4]; missing; b[6:9]] * u"km/hr", c=[c[1:8]; missing]), pset)
    @test sprint(show, gtb) == "9×4 GeoTable over 9 PointSet{2,Float64}"
    @test sprint(show, MIME("text/plain"), gtb) == """
    9×4 GeoTable over 9 PointSet{2,Float64}
    ┌─────────────┬───────────────┬─────────────┬────────────┐
    │      a      │       b       │      c      │  geometry  │
    │ Categorical │  Continuous   │ Categorical │   Point2   │
    │  [m s^-1]   │  [km hr^-1]   │  [NoUnits]  │            │
    ├─────────────┼───────────────┼─────────────┼────────────┤
    │   missing   │ 2.34 km hr^-1 │    txt1     │ (1.0, 1.0) │
    │  6 m s^-1   │ 7.5 km hr^-1  │    txt2     │ (2.0, 2.0) │
    │  6 m s^-1   │ 0.06 km hr^-1 │    txt3     │ (3.0, 3.0) │
    │  3 m s^-1   │ 1.29 km hr^-1 │    txt4     │ (4.0, 4.0) │
    │  9 m s^-1   │    missing    │    txt5     │ (5.0, 5.0) │
    │  5 m s^-1   │ 8.05 km hr^-1 │    txt6     │ (6.0, 6.0) │
    │  2 m s^-1   │ 0.11 km hr^-1 │    txt7     │ (7.0, 7.0) │
    │  2 m s^-1   │ 0.64 km hr^-1 │    txt8     │ (8.0, 8.0) │
    │  8 m s^-1   │ 8.46 km hr^-1 │   missing   │ (9.0, 9.0) │
    └─────────────┴───────────────┴─────────────┴────────────┘"""

    gtb = georef((; x=fill(missing, 9)), pset)
    @test sprint(show, gtb) == "9×2 GeoTable over 9 PointSet{2,Float64}"
    @test sprint(show, MIME("text/plain"), gtb) == """
    9×2 GeoTable over 9 PointSet{2,Float64}
    ┌───────────┬────────────┐
    │     x     │  geometry  │
    │  Missing  │   Point2   │
    │ [NoUnits] │            │
    ├───────────┼────────────┤
    │  missing  │ (1.0, 1.0) │
    │  missing  │ (2.0, 2.0) │
    │  missing  │ (3.0, 3.0) │
    │  missing  │ (4.0, 4.0) │
    │  missing  │ (5.0, 5.0) │
    │  missing  │ (6.0, 6.0) │
    │  missing  │ (7.0, 7.0) │
    │  missing  │ (8.0, 8.0) │
    │  missing  │ (9.0, 9.0) │
    └───────────┴────────────┘"""

    gtb = georef(nothing, pset)
    @test sprint(show, gtb) == "9×1 GeoTable over 9 PointSet{2,Float64}"
    @test sprint(show, MIME("text/plain"), gtb) == """
    9×1 GeoTable over 9 PointSet{2,Float64}
    ┌────────────┐
    │  geometry  │
    │   Point2   │
    │            │
    ├────────────┤
    │ (1.0, 1.0) │
    │ (2.0, 2.0) │
    │ (3.0, 3.0) │
    │ (4.0, 4.0) │
    │ (5.0, 5.0) │
    │ (6.0, 6.0) │
    │ (7.0, 7.0) │
    │ (8.0, 8.0) │
    │ (9.0, 9.0) │
    └────────────┘"""

    gtb = georef((; a, b, c), pset)
    @test sprint(show, MIME("text/html"), gtb) == """
    <table>
      <caption style = "text-align: left;">9×4 GeoTable over 9 PointSet{2,Float64}</caption>
      <thead>
        <tr class = "header">
          <th style = "text-align: center;">a</th>
          <th style = "text-align: center;">b</th>
          <th style = "text-align: center;">c</th>
          <th style = "text-align: center;">geometry</th>
        </tr>
        <tr class = "subheader">
          <th style = "text-align: center;">Categorical</th>
          <th style = "text-align: center;">Continuous</th>
          <th style = "text-align: center;">Categorical</th>
          <th style = "text-align: center;">Point2</th>
        </tr>
        <tr class = "subheader headerLastRow">
          <th style = "text-align: center;">[NoUnits]</th>
          <th style = "text-align: center;">[NoUnits]</th>
          <th style = "text-align: center;">[NoUnits]</th>
          <th style = "text-align: center;"></th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td style = "text-align: center;">0</td>
          <td style = "text-align: center;">2.34</td>
          <td style = "text-align: center;">txt1</td>
          <td style = "text-align: center;">(1.0, 1.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">6</td>
          <td style = "text-align: center;">7.5</td>
          <td style = "text-align: center;">txt2</td>
          <td style = "text-align: center;">(2.0, 2.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">6</td>
          <td style = "text-align: center;">0.06</td>
          <td style = "text-align: center;">txt3</td>
          <td style = "text-align: center;">(3.0, 3.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">3</td>
          <td style = "text-align: center;">1.29</td>
          <td style = "text-align: center;">txt4</td>
          <td style = "text-align: center;">(4.0, 4.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">9</td>
          <td style = "text-align: center;">3.64</td>
          <td style = "text-align: center;">txt5</td>
          <td style = "text-align: center;">(5.0, 5.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">5</td>
          <td style = "text-align: center;">8.05</td>
          <td style = "text-align: center;">txt6</td>
          <td style = "text-align: center;">(6.0, 6.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">2</td>
          <td style = "text-align: center;">0.11</td>
          <td style = "text-align: center;">txt7</td>
          <td style = "text-align: center;">(7.0, 7.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">2</td>
          <td style = "text-align: center;">0.64</td>
          <td style = "text-align: center;">txt8</td>
          <td style = "text-align: center;">(8.0, 8.0)</td>
        </tr>
        <tr>
          <td style = "text-align: center;">8</td>
          <td style = "text-align: center;">8.46</td>
          <td style = "text-align: center;">txt9</td>
          <td style = "text-align: center;">(9.0, 9.0)</td>
        </tr>
      </tbody>
    </table>
    """
  end
end
