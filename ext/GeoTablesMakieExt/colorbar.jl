# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

cbar(fig, values; kwargs...) = _cbar(fig, Colorfier(values; kwargs...))

function _cbar(fig, colorfier)
  values = Colorfy.values(colorfier)
  colorscheme = Colorfy.colorscheme(colorfier)
  colorrange = Colorfy.colorrange(colorfier)
  colormap = cbarcolormap(values, colorscheme)
  limits = cbarlimits(values, colorrange)
  ticks = cbarticks(values, limits)
  tickformat = cbartickformat(values)
  Makie.Colorbar(fig; colormap, limits, ticks, tickformat)
end

cbarcolormap(values, colorscheme) = colorscheme
function cbarcolormap(values::CategArray, colorscheme)
  nlevels = length(levels(values))
  Makie.cgrad(colorscheme[1:nlevels], nlevels, categorical=true)
end

cbarlimits(values, colorrange) = asfloat.(colorrange isa NTuple{2} ? colorrange : extrema(skipinvalid(values)))
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

function tick2level(tick, levels)
  i = trunc(Int, tick)
  isassigned(levels, i) ? asstring(levels[i]) : ""
end

asfloat(x) = float(x)
asfloat(x::Quantity) = float(ustrip(x))
asfloat(x::Distribution) = float(location(x))

asstring(x) = sprint(print, x, context=:compact => true)
