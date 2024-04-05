# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

cbar(fig, values; kwargs...) = _cbar(fig, Colorfier(values; kwargs...))

function _cbar(fig, colorfier)
  values = Colorfy.values(colorfier)
  colormap = Colorfy.colorscheme(colorfier)
  limits = defaultlimits(values)
  ticks = defaultticks(values)
  tickformat = defaultformat(values)
  Makie.Colorbar(fig; colormap, limits, ticks, tickformat)
end

defaultlimits(vals) = defaultlimits(elscitype(vals), vals)
defaultlimits(::Type, vals) = asfloat.(extrema(skipinvalid(vals)))
defaultlimits(::Type{Distributional}, vals) = extrema(location.(skipinvalid(vals)))
defaultlimits(vals::CategArray) = (0.0, asfloat(length(levels(vals))))

defaultticks(vals) = range(defaultlimits(vals)..., 5)
defaultticks(vals::CategArray) = 0:length(levels(vals))

defaultformat(vals::CategArray) = ticks -> map(t -> tick2level(t, levels(vals)), ticks)
function defaultformat(vals)
  T = nonmissingtype(eltype(vals))
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

asstring(x) = sprint(print, x, context=:compact => true)
