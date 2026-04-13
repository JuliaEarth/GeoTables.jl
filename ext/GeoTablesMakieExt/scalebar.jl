# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

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
