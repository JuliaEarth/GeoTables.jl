# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function cbar(fig, values; colormap=:viridis, colorrange=:extrema)
  v = asobservable(values)
  s = asobservable(colormap)
  r = asobservable(colorrange)

  args = Makie.@lift begin
    v′, _, s′, r′ = Colorfy.handleargs($v, 1.0, $s, $r)
    cmap = cbarcolormap(v′, s′, r′)
    limits = cbarlimits(v′, r′)
    ticks = cbarticks(v′, limits)
    tickformat = cbartickformat(v′)
    (cmap, limits, ticks, tickformat)
  end

  cmap = Makie.@lift $args[1]
  limits = Makie.@lift $args[2]
  ticks = Makie.@lift $args[3]
  tickformat = Makie.@lift $args[4]

  Makie.Colorbar(fig; colormap=cmap, limits, ticks, tickformat)
end

cbarcolormap(values, colorscheme, colorrange) = colorscheme
function cbarcolormap(values::CategArray, colorscheme, colorrange)
  n = length(levels(values))
  cs = get(colorscheme, 1:n, colorrange)
  Makie.cgrad(cs, n, categorical=true)
end

function cbarlimits(values, colorrange)
  # see ColorSchemes.get for the logic behind these limits
  if colorrange == :clamp
    (0.0, 1.0)
  elseif colorrange == :extrema
    extrema(float, skipmissing(Colorfy.nominal(values)))
  elseif colorrange == :centered
    maximum(float ∘ abs, skipmissing(Colorfy.nominal(values))) .* (-1, 1)
  else
    Tuple(Colorfy.nominal(collect(colorrange)))
  end
end
cbarlimits(values::CategArray, colorrange) = promote(0.0, length(levels(values)))

cbarticks(values, limits) = range(limits..., 5)
cbarticks(values::CategArray, limits) = 0:length(levels(values))

function cbartickformat(values)
  T = nonmissingtype(eltype(values))
  if T <: Quantity
    u = unit(T)
    ticks -> map(t -> asstring(t) * " " * asstring(u), ticks)
  else
    ticks -> map(asstring, ticks)
  end
end
cbartickformat(values::CategArray) = ticks -> map(t -> tick2level(t, levels(values)), ticks)

function tick2level(tick, levels)
  i = trunc(Int, tick)
  isassigned(levels, i) ? asstring(levels[i]) : ""
end
