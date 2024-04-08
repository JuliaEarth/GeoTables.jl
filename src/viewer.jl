# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    viewer(geotable; kwargs...)

Basic scientific viewer for geospatial table `geotable`.

Aesthetic options are forwarded via `kwargs` to the `Meshes.viz` recipe.
"""
function viewer end

"""
    cbar(fig[row, col], values; kwargs...)

Add a colorbar to `fig[row, col]` with the `values`.

Color options are forwarded via `kwargs` to the `Colorfy.Colorfier` struct.
"""
function cbar end
