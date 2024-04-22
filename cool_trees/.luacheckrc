allow_defined_top = true
unused_args = false
quiet = 1
codes = true

exclude_files = {
	".luarocks/*",
	"worldeditadditions/utils/bit.lua"
}


ignore = {
	"631","61[124]",
	"542",
	"412",
	"321/bit",
	"21[123]"
}

-- Read-only globals
read_globals = {
	"minetest",
	"default",
	"doors",
	"stairsplus",
	"stairs",
	"bonemeal",
	"flowerpot",
	"table.copy",
}

std = "max"
