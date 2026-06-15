# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

asfloat(x) = float(x)
asfloat(x::Quantity) = float(ustrip(x))
asfloat(x::Distribution) = float(location(x))

asstring(x) = sprint(print, x, context=:compact => true)

asobservable(x) = Makie.Observable{Any}(x)
asobservable(x::Makie.Observable) = Makie.Observable{Any}(x[])

isinvalid(v) = ismissing(v) || (v isa Number && !isfinite(v))

skipinvalid(vals) = Iterators.filter(!isinvalid, vals)

function uniquevalid(vals)
  u = unique(skipinvalid(vals))
  n = length(u)
  v = iszero(n) ? missing : first(u)
  (length=n, first=v)
end
