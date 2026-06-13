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
    cbar(fig[row, col], values; colormap=:viridis, colorrange=:extrema)

Add a colorbar to `fig[row, col]` for the given
`values` and options for the `colorfy` function
from the Colorfy.jl package.

### Notes

This function will only work in the presence of
a Makie.jl backend via package extensions in
Julia v1.9 or later versions of the language.
"""
function cbar end
