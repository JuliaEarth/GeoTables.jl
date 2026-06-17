# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

const CategArray{T,N} = Union{CategoricalArray{T,N},SubArray{T,N,<:CategoricalArray}}

maybecategorical(x) = elscitype(x) <: Categorical ? ascategorical(x) : x

ascategorical(x) = categorical(x)
ascategorical(x::CategArray) = x

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

isviewable(vals) = isviewable(elscitype(vals))
isviewable(::Type) = false
isviewable(::Type{Colorful}) = true
isviewable(::Type{Continuous}) = true
isviewable(::Type{Categorical}) = true
isviewable(::Type{Distributional}) = true
