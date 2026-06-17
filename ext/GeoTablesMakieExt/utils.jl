# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

const CategVector = AbstractVector{<:CategoricalValue}

# -------------------------------
# utilities for vector of values
# -------------------------------

maybecategorical(v) = elscitype(v) <: Categorical ? ascategorical(v) : v

ascategorical(v) = categorical(v)
ascategorical(v::CategVector) = v

function uniquevalid(v)
  u = unique(skipinvalid(v))
  n = length(u)
  f = iszero(n) ? missing : first(u)
  (length=n, first=f)
end

skipinvalid(v) = Iterators.filter(!isinvalid, v)

isviewable(v) = isviewable(elscitype(v))
isviewable(::Type) = false
isviewable(::Type{Colorful}) = true
isviewable(::Type{Continuous}) = true
isviewable(::Type{Categorical}) = true
isviewable(::Type{Distributional}) = true

# ---------------------------
# utilities for single value
# ---------------------------

isinvalid(x) = ismissing(x) || (x isa Number && !isfinite(x))

asstring(x) = sprint(print, x, context=:compact => true)

asobservable(x) = Makie.Observable{Any}(x)
asobservable(x::Makie.Observable) = Makie.Observable{Any}(x[])
