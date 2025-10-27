# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    viewer(geotable; kwargs...)

Basic scientific viewer for geospatial table `geotable`.

Aesthetic options are forwarded via `kwargs` to the
`Meshes.viz` recipe.

### Notes

This function will only work in the presence of
a Makie.jl backend via package extensions in
Julia v1.9 or later versions of the language.
"""
function viewer end

"""
    cbar(fig[row, col], values; kwargs...)

Add a colorbar to `fig[row, col]` with the `values`.

Color options are forwarded via `kwargs` to the
`Colorfy.Colorfier` struct.

### Notes

This function will only work in the presence of
a Makie.jl backend via package extensions in
Julia v1.9 or later versions of the language.
"""
function cbar end
