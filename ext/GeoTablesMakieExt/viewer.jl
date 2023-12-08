# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function viewer(data::AbstractGeoTable; kwargs...)
  # retrieve domain and element table
  dom, tab = domain(data), values(data)

  # list of all variables
  cols = Tables.columns(tab)
  vars = Tables.columnnames(cols)

  # list of viewable variables
  viewable = filter(vars) do var
    vals = Tables.getcolumn(cols, var)
    isviewable(elscitype(vals))
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
  isconst = Dict(var => allequal(skipmissing(Tables.getcolumn(cols, var))) for var in viewable)

  # distributional variables
  isdist = Dict(var => elscitype(Tables.getcolumn(cols, var)) <: Distributional for var in viewable)

  # list of menu options
  options = map(viewable) do var
    opt = if isconst[var]
      vals = skipmissing(Tables.getcolumn(cols, var))
      val = isempty(vals) ? missing : first(vals)
      "$var = $val (constant)"
    else
      "$var"
    end
    if isdist[var]
      opt = opt * " (distribution)"
    end
    opt
  end |> collect

  # initialize figure and menu
  fig = Makie.Figure()
  label = Makie.Label(fig[1, 1], "Variable")
  menu = Makie.Menu(fig[1, 2], options=options)

  # initialize observables
  vals = Makie.Observable{Any}()
  cmap = Makie.Observable{Any}()
  lims = Makie.Observable{Any}()
  ticks = Makie.Observable{Any}()
  format = Makie.Observable{Any}()

  function setvals(var)
    vals[] = Tables.getcolumn(cols, var) |> asvalues
  end

  function setdefaults()
    cmap[] = defaultscheme(vals[])
    lims[] = defaultlimits(vals[])
    ticks[] = defaultticks(vals[])
    format[] = defaultformat(vals[])
  end

  colorbar() = Makie.Colorbar(fig[2, 3], colormap=cmap, limits=lims, ticks=ticks, tickformat=format)

  # select first viewable variable
  var = first(viewable)

  # initialize values for variable
  setvals(var)

  # initialize visualization
  Makie.plot(fig[2, 1:2], dom; color=vals, kwargs...)

  # initialize colorbar if necessary
  cbar = if !isconst[var]
    setdefaults()
    colorbar()
  else
    nothing
  end

  # map menu option to corresponding variable
  varfrom = Dict(zip(options, viewable))

  # update visualization if necessary
  Makie.on(menu.selection) do opt
    var = varfrom[opt]
    setvals(var)
    if !isconst[var]
      setdefaults()
      if isnothing(cbar)
        cbar = colorbar()
      end
    else
      if !isnothing(cbar)
        Makie.delete!(cbar)
        Makie.trim!(fig.layout)
        cbar = nothing
      end
    end
  end

  fig
end

defaultlimits(vals) = defaultlimits(elscitype(vals), vals)
defaultlimits(::Type, vals) = asfloat.(extrema(skipmissing(vals)))
defaultlimits(::Type{Distributional}, vals) = extrema(location.(skipmissing(vals)))
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

asvalues(x) = asvalues(nonmissingtype(eltype(x)), x)
asvalues(::Type, x) = elscitype(x) <: Categorical ? ascateg(x) : x
asvalues(::Type{<:Colorant}, x) = map(c -> ismissing(c) ? missing : Float64(Gray(c)), x)

ascateg(x) = categorical(x)
ascateg(x::CategArray) = x

asfloat(x) = float(x)
asfloat(x::Quantity) = float(ustrip(x))

function tick2level(tick, levels)
  i = trunc(Int, tick)
  isassigned(levels, i) ? asstring(levels[i]) : ""
end

asstring(x) = sprint(print, x, context=:compact => true)

isviewable(::Type) = false
isviewable(::Type{Continuous}) = true
isviewable(::Type{Categorical}) = true
isviewable(::Type{Distributional}) = true