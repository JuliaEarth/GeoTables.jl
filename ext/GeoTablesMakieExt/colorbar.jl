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

cbarlimits(values, colorrange) = colorrange isa NTuple{2} ? asfloat.(colorrange) : extrema(asfloat, skipinvalid(values))
cbarlimits(values::CategArray, colorrange) = (0.0, asfloat(length(levels(values))))

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

isinvalid(v) = ismissing(v) || (v isa Number && !isfinite(v))
skipinvalid(vals) = Iterators.filter(!isinvalid, vals)

function tick2level(tick, levels)
  i = trunc(Int, tick)
  isassigned(levels, i) ? asstring(levels[i]) : ""
end

asfloat(x) = float(x)
asfloat(x::Quantity) = float(ustrip(x))
asfloat(x::Distribution) = float(location(x))

asstring(x) = sprint(print, x, context=:compact => true)

asobservable(x) = Makie.Observable{Any}(x)
asobservable(x::Makie.Observable) = Makie.Observable{Any}(x[])
