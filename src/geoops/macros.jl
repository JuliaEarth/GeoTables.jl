# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function _split(expr::Expr, rowwise=true)
  if expr.head ≠ :(=)
    throw(ArgumentError("invalid expression syntax"))
  end

  colname = _colname(expr.args[1])
  colexpr = _colexpr(expr.args[2], rowwise)

  colname, colexpr
end

# returns a column name expression from the LHS expression
function _colname(expr)
  if _iscolname(expr)
    _nameexpr(expr)
  else
    throw(ArgumentError("invalid column name syntax"))
  end
end

# returns a column generator expression from the RHS expression
function _colexpr(expr, rowwise)
  if _iscolname(expr)
    # if the RHS expression is a column name expression
    # returns a get column expression
    _getcolexpr(expr)
  else
    colnames = _colnames(expr)
    if isempty(colnames)
      # if the RHS expression doesn't have column name expressions
      # returns a constant column expression
      constexpr = esc(expr)
      if rowwise
        :(fill($constexpr, nrow(geotable)))
      else
        constexpr
      end
    else
      # otherwise, returns a function expression
      funexpr = _funexpr(expr, colnames)
      columns = map(_getcolexpr, colnames)
      if rowwise
        :(map($funexpr, $(columns...)))
      else
        :($funexpr($(columns...)))
      end
    end
  end
end

# checks if expression is a column name expression
_iscolname(expr) = expr isa QuoteNode || Meta.isexpr(expr, :braces)

# creates the executable version of the column name expression 
_nameexpr(expr::QuoteNode) = expr
_nameexpr(expr::Expr) = :(Symbol($(esc(expr.args[1]))))

# creates the get column expression
_getcolexpr(expr) = :(getproperty(geotable, $(_nameexpr(expr))))

# collects all column name expressions from the RHS expression
function _colnames(expr)
  colnames = []
  if expr isa Expr
    _colargs!(colnames, expr)
  end
  colnames
end

function _colargs!(colnames, expr)
  if Meta.isexpr(expr, :., 2) && expr.args[2] isa QuoteNode # handle expressions of the form obj.field
    _colargs!(colnames, expr.args[1])
  else # descend on function/macro arguments
    start = Meta.isexpr(expr, [:call, :macrocall]) ? 2 : 1
    for i in start:length(expr.args)
      arg = expr.args[i]
      if _iscolname(arg)
        push!(colnames, arg)
      elseif arg isa Expr
        _colargs!(colnames, arg)
      end
    end
  end
end

# create the function expression from the RHS expression
function _funexpr(expr, colnames)
  funargs = [gensym() for _ in colnames]
  argsym = Dict(zip(colnames, funargs))
  funbody = _funbody(expr, argsym)
  :(($(funargs...),) -> $funbody)
end

function _funbody(expr, argsym)
  funbody = copy(expr)
  _funbody!(funbody, argsym)
  funbody
end

function _funbody!(expr, argsym)
  for (i, arg) in enumerate(expr.args)
    if haskey(argsym, arg)
      expr.args[i] = argsym[arg]
    elseif arg isa Symbol
      expr.args[i] = esc(arg)
    elseif arg isa Expr
      _funbody!(arg, argsym)
    end
  end
end
