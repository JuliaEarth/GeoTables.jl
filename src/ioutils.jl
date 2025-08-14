# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

# helper function to print the actual name of
# the object type inside a deep type hierarchy
prettyname(obj) = prettyname(typeof(obj))
function prettyname(T::Type)
  name = string(T)
  name = replace(name, r"{.*" => "")
  replace(name, r".*\." => "")
end
prettyname(::Type{<:Cartesian}) = "Cartesian"

# remove the module from type, it is displayed
# when the module is not imported in the session
rmmodule(T) = replace(string(T), r".*\." => "")
