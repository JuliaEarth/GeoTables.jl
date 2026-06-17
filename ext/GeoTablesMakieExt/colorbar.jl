# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function cbar(fig, values; colormap=:viridis, colorrange=:extrema)
  v = asobservable(values)
  s = asobservable(colormap)
  r = asobservable(colorrange)

  args = Makie.@lift begin
    v′, _, s′, r′ = Colorfy.handleargs($v, 1.0, $s, $r)
    cmap = cbarcolormap(v′, s′)
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

cbarcolormap(values, colorscheme) = colorscheme
function cbarcolormap(values::CategArray, colorscheme)
  n = length(levels(values))
  cs = colorscheme[range(n > 1 ? 0 : 1, 1, length=n)]
  Makie.cgrad(cs, n, categorical=true)
end

function cbarlimits(values, colorrange)
  if colorrange == :extrema
    extrema(float, skipmissing(Colorfy.nominal(values)))
  else
    Tuple(Colorfy.nominal(collect(colorrange)))
  end
end
cbarlimits(values::CategArray, colorrange) = promote(0.0, length(levels(values)))

cbarticks(values, limits) = range(limits..., 5)
cbarticks(values::CategArray, limits) = 0:length(levels(values))

cbartickformat(values::CategArray) = ticks -> map(t -> tick2level(t, levels(values)), ticks)
function cbartickformat(values)
  T = nonmissingtype(eltype(values))
  if T <: Quantity
    u = unit(T)
    ticks -> map(t -> asstring(t) * " " * asstring(u), ticks)
  else
    ticks -> map(asstring, ticks)
  end
end

function tick2level(tick, levels)
  i = trunc(Int, tick)
  isassigned(levels, i) ? asstring(levels[i]) : ""
end
