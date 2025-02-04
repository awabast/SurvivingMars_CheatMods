return PlaceObj("ModDef", {
	"dependencies", {
		PlaceObj("ModDependency", {
			"id", "ChoGGi_Library",
			"title", "ChoGGi's Library",
			"version_major", 9,
			"version_minor", 6,
		}),
	},
	"title", "Hide Building Signs",
	"id", "ChoGGi_HideBuildingSigns",
	"lua_revision", 1001569,
	"steam_id", "2107647345",
	"pops_any_uuid", "872bf77b-dd93-46dd-932b-4284b3d533d6",
	"version", 2,
	"version_major", 0,
	"version_minor", 2,
	"image", "Preview.png",
	"author", "ChoGGi",
	"code", {
		"Code/Script.lua",
	},
	"has_options", true,
	"TagInterface", true,
	"description", [[Don't show signs above buildings.

Includes mod option to disable.
Press Numpad 8 to temporarily toggle the signs (resets after quit), change in Key Bindings.


Requested by Philippe.]],
})
