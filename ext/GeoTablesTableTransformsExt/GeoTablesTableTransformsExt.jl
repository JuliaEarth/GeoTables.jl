# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTablesTableTransformsExt

using Meshes
using GeoTables
using TableTransforms

import TableTransforms: divide, attach
import TableTransforms: applymeta, apply, revert, reapply

# -----------------------
# TABLE TRANSFORM TRAITS
# -----------------------

divide(geotable::AbstractGeoTable) = values(geotable), domain(geotable)
attach(table, dom::Domain) = georef(table, dom)

# -------------------
# FEATURE TRANSFORMS
# -------------------

# transforms that change the order or number of
# rows in the table need a special treatment

function applymeta(::Sort, dom::Domain, prep)
  sinds = prep
  sdom = view(dom, sinds)
  sdom, nothing
end

# --------------------------------------------------

function applymeta(::Filter, dom::Domain, prep)
  sinds = prep
  sdom = view(dom, sinds)
  sdom, nothing
end

# --------------------------------------------------

function applymeta(::DropMissing, dom::Domain, prep)
  ftrans, fprep, _ = prep
  newmeta, _ = applymeta(ftrans, dom, fprep)
  newmeta, nothing
end

# --------------------------------------------------

function applymeta(::DropNaN, dom::Domain, prep)
  ftrans, fprep = prep
  newmeta, _ = applymeta(ftrans, dom, fprep)
  newmeta, nothing
end

# --------------------------------------------------

function applymeta(::DropExtrema, dom::Domain, prep)
  ftrans, fprep = prep
  newmeta, _ = applymeta(ftrans, dom, fprep)
  newmeta, nothing
end

# --------------------------------------------------

function applymeta(::Sample, dom::Domain, prep)
  sinds = prep
  sdom = view(dom, sinds)
  sdom, nothing
end

end
