# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

module GeoTablesStatsLearnModelsExt

using GeoTables
using StatsLearnModels

import GeoTables: _istarget
import StatsLearnModels: label
import StatsLearnModels: Learn

_istarget(table::LabeledTable, label) = label ∈ targets(table)

label(geotable::AbstractGeoTable, names) = georef(label(values(geotable), names), domain(geotable))

Learn(geotable::AbstractGeoTable; kwargs...) = Learn(values(geotable); kwargs...)

end
