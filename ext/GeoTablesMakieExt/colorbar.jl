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
    if colorrange == :extrema
      extrema(float, skipmissing(Colorfy.nominal(values)))
    elseif colorrange == :centered
      maximum(abs, skipmissing(Colorfy.nominal(values))) .* (-1, 1)
    else
      crange = promote(colorrange...)
      Tuple(Colorfy.nominal(collect(crange)))
    end
  end
end

function cbarticks(values, limits)
  n = Colorfy.nlevels(values)
  n > 1 ? range(1, n) .- 0.5 : range(limits..., 5)
end

function cbartickformat(values)
  n = Colorfy.nlevels(values)
  if n > 1
    l = Colorfy.levels(values)
    ticks -> map(t -> asstring(l[ceil(Int, t)]), ticks)
  elseif elscitype(values) <: Continuous
    u = unit(eltype(values))
    ticks -> map(t -> asstring(t) * " " * asstring(u), ticks)
  else
    ticks -> map(t -> asstring(t), ticks)
  end
end
