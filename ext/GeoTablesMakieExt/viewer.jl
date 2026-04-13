# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function viewer(
  data::AbstractGeoTable;
  alpha=nothing,
  colormap=nothing,
  colorrange=nothing,
  scalebar=nothing,
  kwargs...
)
  # retrieve domain and element table
  dom, tab = domain(data), values(data)

  # list of all variables
  cols = Tables.columns(tab)
  vars = Tables.columnnames(cols)

  # list of viewable variables
  viewable = filter(vars) do var
    vals = Tables.getcolumn(cols, var)
    isviewable(vals)
  end

  # throw error if there are no viewable variables
  if isempty(viewable)
    throw(AssertionError("""
      Could not find viewable variables, i.e., variables that can be
      converted to colors with the `ascolors` trait. Please make sure
      that the scientific type of variables is correct.
      """))
  end

  # constant variables
  isconst = Dict(var => allequal(skipinvalid(Tables.getcolumn(cols, var))) for var in viewable)

  # distributional variables
  isdist = Dict(var => elscitype(Tables.getcolumn(cols, var)) <: Distributional for var in viewable)

  # colorful variables
  iscolor = Dict(var => elscitype(Tables.getcolumn(cols, var)) <: Colorful for var in viewable)

  # list of menu options
  options = map(viewable) do var
    opt = if isconst[var]
      vals = Tables.getcolumn(cols, var)
      val = first(skipinvalid(vals))
      "$var = $val (constant)"
    else
      "$var"
    end
    if isdist[var]
      opt = opt * " (distribution)"
    end
    opt
  end |> collect

  # initialize figure
  fig = Makie.Figure()
  label = Makie.Label(fig[1, 1], "Variable")
  menu = Makie.Menu(fig[1, 2], options=options)
  axis = if embeddim(dom) === 3
    Makie.Axis3(fig[2, 1:2], perspectiveness=0.5, viewmode=:free, aspect=:data)
  else
    Makie.Axis(fig[2, 1:2], aspect=Makie.DataAspect())
  end

  # initialize observables
  vals = Makie.Observable{Any}()

  function setvals(var)
    vals[] = Tables.getcolumn(cols, var) |> asvalues
  end

  plot(vals) = Makie.plot!(axis, dom; color=vals, alpha, colormap, colorrange, kwargs...)

  needcbar(var) = !isconst[var] && !iscolor[var]

  colorbar(vals) = cbar(fig[2, 3], vals; alpha, colormap, colorrange)

  # select first viewable variable
  var = first(viewable)

  # initialize values for variable
  setvals(var)

  # initialize visualization
  plot(vals)

  # consider adding scale bar
  edim = embeddim(dom)
  sbar = isnothing(scalebar) ? edim === 2 : scalebar
  if sbar
    if edim !== 2
      @warn "scale bar is only implemented for 2D axis"
    else
      scalebar!(axis)
    end
  end

  # add colorbar if necessary
  varcbar = if needcbar(var)
    colorbar(vals)
  else
    nothing
  end

  # map menu option to corresponding variable
  varfrom = Dict(zip(options, viewable))

  # update visualization if necessary
  Makie.on(menu.selection) do opt
    var = varfrom[opt]
    setvals(var)
    if !isnothing(varcbar)
      Makie.delete!(varcbar)
    end
    if needcbar(var)
      varcbar = colorbar(vals)
    else
      if !isnothing(varcbar)
        Makie.trim!(fig.layout)
        varcbar = nothing
      end
    end
  end

  fig
end

asvalues(x) = elscitype(x) <: Categorical ? ascateg(x) : x

ascateg(x) = categorical(x)
ascateg(x::CategArray) = x

isviewable(vals) = isviewable(elscitype(vals), vals)
isviewable(::Type, vals) = false
isviewable(::Type{Colorful}, vals) = true
isviewable(::Type{Continuous}, vals) = !all(isinvalid, vals)
isviewable(::Type{Categorical}, vals) = true
isviewable(::Type{Distributional}, vals) = true

function scalebar!(axis; position=(0.85, 0.05), targetaxfrac=0.25, color=:black, linewidth=3.0, fontsize=16)
  # Generate a comprehensive array of valid multiplier values for the scale bar lengths.
  # This creates intervals following the standard 1-2-5 cartographic rule across a vast range of magnitudes.
  muls = [
    # Evaluate the product of the base step (x) and the magnitude (p).
    # - If 'p' is an Integer, perform exact multiplication.
    # - If 'p' is a Float, multiply and round to 4 significant digits to prevent floating-point representation errors (e.g., avoiding 0.20000000000000004).
    p isa Int ? x * p : round(x * p, sigdigits=4) for
    # Generate the magnitude array (powers of 10) ranging from 10^-50 to 10^50.
    # The concatenated array is cast to 'Real' to support mixed types (Int and Float).
    p in Real[
      [10.0^p for p in -50:-1]   # Micro/fractional magnitudes (Floats)
      [1, 10, 100, 1000, 10000]  # Common human-scale magnitudes (Integers)
      [10.0^p for p in 5:50]      # Macro/astronomical magnitudes (Floats)
    ]
    # Iterate over the standard scale increments for each magnitude 'p'
    for x in [1, 2, 5]
  ]

  scaledata = Makie.lift(axis.finallimits) do rect
    widthx = rect.widths[1]
    safewidth = isfinite(widthx) && widthx > 0 ? widthx : 1.0

    # find the best multiplier in axis units
    mul = argmin(m -> abs(m - targetaxfrac * safewidth), muls)
    lengthdata = mul

    # relative length (0-1)
    lengthrel = lengthdata / safewidth

    avgpos = Makie.Point2f(position)
    p1 = avgpos - Makie.Vec2f(lengthrel / 2, 0)
    p2 = avgpos + Makie.Vec2f(lengthrel / 2, 0)

    (points=[p1, p2], text="$(mul)", textpos=avgpos)
  end

  # draw lines and text directly on the axis
  Makie.lines!(
    axis,
    Makie.lift(x -> x.points, scaledata);
    space=:relative,
    color=color,
    linewidth=linewidth,
    xautolimits=false,
    yautolimits=false
  )
  Makie.text!(
    axis,
    Makie.lift(x -> x.textpos, scaledata);
    text=Makie.lift(x -> x.text, scaledata),
    space=:relative,
    align=(:center, :bottom),
    offset=(0, 5),
    color=color,
    fontsize=fontsize,
    xautolimits=false,
    yautolimits=false
  )
end
