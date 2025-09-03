local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
	height = 40,
	color = colors.bar.bg,
	padding_right = 5,
	padding_left = 8,
	margin = 7,
	corner_radius = 9,
	blur_radius = 40,
	y_offset = 3,
})
