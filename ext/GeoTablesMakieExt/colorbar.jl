# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function cbar(fig, values; alpha=nothing, colormap=nothing, colorrange=nothing)
  vals = Makie.to_value(values)
  alphas = asobservable(isnothing(alpha) ? Colorfy.defaultalphas(vals) : alpha)
  cscheme = asobservable(isnothing(colormap) ? Colorfy.defaultcolorscheme(vals) : colormap)
  crange = asobservable(isnothing(colorrange) ? Colorfy.defaultcolorrange(vals) : colorrange)
  colorfier = Makie.@lift Colorfier(vals; alphas=($alphas), colorscheme=($cscheme), colorrange=($crange))

  args = Makie.@lift cbarargs($colorfier)
  cmap = Makie.@lift $args[1]
  limits = Makie.@lift $args[2]
  ticks = Makie.@lift $args[3]
  tickformat = Makie.@lift $args[4]

  Makie.Colorbar(fig; colormap=cmap, limits, ticks, tickformat)
end

function cbarargs(colorfier)
  values = Colorfy.values(colorfier)
  colorscheme = Colorfy.colorscheme(colorfier)
  colorrange = Colorfy.colorrange(colorfier)
  colormap = cbarcolormap(values, colorscheme)
  limits = cbarlimits(values, colorrange)
  ticks = cbarticks(values, limits)
  tickformat = cbartickformat(values)
  (colormap, limits, ticks, tickformat)
end

cbarcolormap(values, colorscheme) = colorscheme
function cbarcolormap(values::CategArray, colorscheme)
  nlevels = length(levels(values))
  categcolors = colorscheme[range(0, nlevels > 1 ? 1 : 0, length=nlevels)]
  Makie.cgrad(categcolors, nlevels, categorical=true)
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

asobservable(x) = Makie.Observable(x)
asobservable(x::Makie.Observable) = x
