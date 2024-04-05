# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

function viewer(data::AbstractGeoTable; alpha=nothing, colormap=nothing, colorrange=nothing, kwargs...)
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

  # initialize figure and menu
  fig = Makie.Figure()
  label = Makie.Label(fig[1, 1], "Variable")
  menu = Makie.Menu(fig[1, 2], options=options)

  # initialize observables
  vals = Makie.Observable{Any}()

  function setvals(var)
    vals[] = Tables.getcolumn(cols, var) |> asvalues
  end

  function colorbar(vals)
    valphas = isnothing(alpha) ? Colorfy.defaultalphas(vals) : alpha
    vcolorscheme = isnothing(colormap) ? Colorfy.defaultcolorscheme(vals) : colormap
    vcolorrange = isnothing(colorrange) ? Colorfy.defaultcolorrange(vals) : colorrange
    cbar(fig[2, 3], vals, alphas=valphas, colorscheme=vcolorscheme, colorrange=vcolorrange)
  end

  # select first viewable variable
  var = first(viewable)

  # initialize values for variable
  setvals(var)

  # initialize visualization
  Makie.plot(fig[2, 1:2], dom; color=vals, alpha, colormap, colorrange, kwargs...)

  # initialize colorbar if necessary
  varcbar = if !isconst[var]
    colorbar(vals[])
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
    if !isconst[var]
      varcbar = colorbar(vals[])
    else
      if !isnothing(varcbar)
        Makie.trim!(fig.layout)
        varcbar = nothing
      end
    end
  end

  fig
end

asvalues(x) = asvalues(nonmissingtype(eltype(x)), x)
asvalues(::Type, x) = elscitype(x) <: Categorical ? ascateg(x) : x
asvalues(::Type{<:Colorant}, x) = map(c -> ismissing(c) ? missing : Float64(Gray(c)), x)

ascateg(x) = categorical(x)
ascateg(x::CategArray) = x

isinvalid(v) = ismissing(v) || (v isa Number && !isfinite(v))
skipinvalid(vals) = Iterators.filter(!isinvalid, vals)

isviewable(vals) = isviewable(elscitype(vals), vals)
isviewable(::Type, vals) = false
isviewable(::Type{Unknown}, vals) = iscolor(vals)
isviewable(::Type{Continuous}, vals) = !all(isinvalid, vals)
isviewable(::Type{Categorical}, vals) = true
isviewable(::Type{Distributional}, vals) = true

iscolor(vals) = iscolor(nonmissingtype(eltype(vals)))
iscolor(::Type) = false
iscolor(::Type{Union{}}) = false
iscolor(::Type{<:Colorant}) = true
