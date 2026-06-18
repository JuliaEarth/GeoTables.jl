# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function cbar(fig, values; colormap=:viridis, colorrange=:extrema)
  v = asobservable(values)
  s = asobservable(colormap)
  r = asobservable(colorrange)

  args = Makie.@lift begin
    v′, _, s′, r′ = Colorfy.preprocess($v, 1.0, $s, $r)
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

function cbarcolormap(values, colorscheme, colorrange)
  n = Colorfy.nlevels(values)
  if n > 1
    # build discrete color scheme
    c = get(colorscheme, 1:n, colorrange)
    Makie.cgrad(c, n, categorical=true)
  else
    # return color scheme as is
    colorscheme
  end
end

function cbarlimits(values, colorrange)
  n = Colorfy.nlevels(values)
  if n > 1
    (0.0, float(n))
  else
    # see Colorfy.get for the logic behind these limits
    if colorrange == :clamp
      (0.0, 1.0)
    elseif colorrange == :extrema
      n = skipmissing(Colorfy.nominal(values))
      extrema(float, n)
    elseif colorrange == :centered
      n = skipmissing(Colorfy.nominal(values))
      maximum(float ∘ abs, n) .* (-1, 1)
    else
      Tuple(Colorfy.nominal(collect(colorrange)))
    end
  end
end

function cbarticks(values, limits)
  n = Colorfy.nlevels(values)
  n > 1 ? (0:n) : range(limits..., 5)
end

function cbartickformat(values)
  n = Colorfy.nlevels(values)
  if n > 1
    l = Colorfy.levels(values)
    ticks -> map(t -> tick2level(t, l), ticks)
  elseif elscitype(values) <: Continuous
    u = unit(eltype(values))
    ticks -> map(t -> asstring(t) * " " * asstring(u), ticks)
  else
    ticks -> map(t -> asstring(t), ticks)
  end
end

function tick2level(tick, levels)
  i = trunc(Int, tick)
  isassigned(levels, i) ? asstring(levels[i]) : ""
end
