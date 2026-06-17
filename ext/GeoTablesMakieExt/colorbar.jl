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

function cbarcolormap(values, colorscheme, colorrange)
  if elscitype(values) <: Categorical
    n = length(levels(values))
    c = get(colorscheme, 1:n, colorrange)
    Makie.cgrad(c, n, categorical=true)
  else
    colorscheme
  end
end

function cbarlimits(values, colorrange)
  if elscitype(values) <: Categorical
    promote(0.0, length(levels(values)))
  else
     # see Colorfy.getlimits for the logic behind these limits
     if colorrange == :clamp
       (0.0, 1.0)
     elseif colorrange == :extrema
       extrema(float, skipmissing(values))
     elseif colorrange == :centered
       maximum(float ∘ abs, skipmissing(values)) .* (-1, 1)
     else
       Tuple(Colorfy.nominal(collect(colorrange)))
     end
  end
end

function cbarticks(values, limits)
  if elscitype(values) <: Categorical
    0:length(levels(values))
  else
    range(limits..., 5)
  end
end

function cbartickformat(values)
  if elscitype(values) <: Categorical
    ticks -> map(t -> tick2level(t, levels(values)), ticks)
  else
    T = nonmissingtype(eltype(values))
    if T <: Quantity
      u = unit(T)
      ticks -> map(t -> asstring(t) * " " * asstring(u), ticks)
    else
      ticks -> map(asstring, ticks)
    end
  end
end

function tick2level(tick, levels)
  i = trunc(Int, tick)
  isassigned(levels, i) ? asstring(levels[i]) : ""
end
