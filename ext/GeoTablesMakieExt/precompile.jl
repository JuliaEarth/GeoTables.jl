# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

using PrecompileTools

using Meshes
using Unitful

@setup_workload begin
  # popular scientific types
  vars = (
    rand(4),
    rand(4) * u"K",
    rand(1:3, 4),
    rand(1:3, 4) * u"K",
    rand(Bool, 4),
    rand(["yes", "no"], 4)
  )

  # viz on Cartesian grid
  grid = CartesianGrid(2, 2)

  @compile_workload begin
    for var in vars
      geotable = georef((; var), grid)
      viewer(geotable)
    end
  end
end
