local function trgu_menu_text_line(text, scale, colour)
	return {
		n = G.UIT.R,
		config = {
			align = "cl",
			padding = 0.035
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					text = text,
					scale = scale or 0.42,
					colour = colour or G.C.UI.TEXT_LIGHT,
					shadow = true
				}
			}
		}
	}
end

local function trgu_menu_title(text)
	return trgu_menu_text_line(text, 0.55, G.C.FILTER)
end

local function trgu_menu_spacer(height)
	return {
		n = G.UIT.R,
		config = {
			minh = height or 0.15
		},
		nodes = {}
	}
end

local function trgu_menu_page(lines)
	local nodes = {}

	for _, line in ipairs(lines) do
		if line == "" then
			nodes[#nodes + 1] = trgu_menu_spacer(0.12)
		elseif type(line) == "table" and line.title then
			nodes[#nodes + 1] = trgu_menu_title(line.title)
		elseif type(line) == "table" and line.text then
			nodes[#nodes + 1] = trgu_menu_text_line(line.text, line.scale, line.colour)
		else
			nodes[#nodes + 1] = trgu_menu_text_line(tostring(line))
		end
	end

	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 0.25,
			r = 0.1,
			colour = G.C.BLACK,
			minw = 7.5,
			minh = 5.5
		},
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cl",
					padding = 0.15,
					r = 0.08,
					colour = G.C.DYN_UI.MAIN,
					minw = 7,
					minh = 5
				},
				nodes = nodes
			}
		}
	}
end
TRGU = TRGU or {}

TRGU.version_log_index = 1

TRGU.VERSION_LOGS = {
	{
		title = "Hotfix Update v0.5.1 (14.07.2026)",
		lines = {
			"- Bug fixes"
		}
	},
	{
		title = "Pre-release Update v0.5.0 (13.07.2026)",
		lines = {
			"- 9 new jokers",
			"- Some rebalance changes and fixes"
		}
	},
	{
		title = "Huge Jokers Update v0.4.0 (01.06.2026)",
		lines = {
			"- 16 new jokers"
		}
	},
	{
		title = "Localization Update v0.3.1 (22.05.2026)",
		lines = {
			"- Added Russian localization"
		}
	},
    {
		title = "Owl Update v0.3.0 (21.05.2026)",
		lines = {
			"- 11 new jokers",
			"- 1 new boss blind",
			"- Some rebalance changes and fixes"
		}
	},
    {
		title = "UI Update v0.2.1 (20.05.2026)",
		lines = {
			"- 2 new jokers",
			"- Added version logs and credits tab"
		}
	},
	{
		title = "Corrupted Update v0.2.0 (19.05.2026)",
		lines = {
			"- 2 new jokers",
			"- 6 new admin cards",
			"- 2 new enhancements",
			"- 1 new deck",
		}
	},
	{
		title = "Small Jokers Update v0.1.2 (18.05.2026)",
		lines = {
			"- 6 new jokers"
		}
	},
	{
		title = "Arts Update v0.1.1 (17.05.2026)",
		lines = {
			"- 4 new jokers",
            "- 4 new booster packs",
			"- Admins has 2 texture variants in config"
		}
	},
	{
		title = "First Update v0.1.0 (16.05.2026)",
		lines = {
			"- 8 new jokers",
            "- New Card type: Admins",
            "- 6 brand new admins cards",
            "- 2 new tags",
            "- 1 new deck",
		}
	}
}

TRGU.version_log_display = {
	title = "",
	line_1 = "",
	line_2 = "",
	line_3 = "",
	line_4 = "",
	line_5 = "",
	line_6 = "",
	line_7 = "",
	page = ""
}

local function trgu_update_version_log_display()
	local logs = TRGU.VERSION_LOGS or {}
	local index = TRGU.version_log_index or 1

	if index < 1 then index = 1 end
	if index > #logs then index = #logs end

	TRGU.version_log_index = index

	local log = logs[index]

	if not log then
		TRGU.version_log_display.title = "No version logs"
		TRGU.version_log_display.line_1 = ""
		TRGU.version_log_display.line_2 = ""
		TRGU.version_log_display.line_3 = ""
		TRGU.version_log_display.line_4 = ""
		TRGU.version_log_display.line_5 = ""
		TRGU.version_log_display.line_6 = ""
		TRGU.version_log_display.line_7 = ""
		TRGU.version_log_display.page = "0 / 0"
		return
	end

	TRGU.version_log_display.title = log.title
	TRGU.version_log_display.page = tostring(index) .. " / " .. tostring(#logs)

	for i = 1, 7 do
		TRGU.version_log_display["line_" .. i] = log.lines[i] or ""
	end
end

trgu_update_version_log_display()

G.FUNCS.trgu_version_log_older = function(e)
	if not TRGU.VERSION_LOGS then return end

	TRGU.version_log_index = math.min(
		(TRGU.version_log_index or 1) + 1,
		#TRGU.VERSION_LOGS
	)

	trgu_update_version_log_display()
end

G.FUNCS.trgu_version_log_newest = function(e)
	TRGU.version_log_index = math.max((TRGU.version_log_index or 1) - 1, 1)
	trgu_update_version_log_display()
end

local function trgu_version_log_dynamic_text(ref_value, scale, colour)
	return {
		n = G.UIT.R,
		config = {
			align = "cl",
			padding = 0.04,
			minh = 0.28
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					ref_table = TRGU.version_log_display,
					ref_value = ref_value,
					scale = scale or 0.42,
					colour = colour or G.C.UI.TEXT_LIGHT,
					shadow = true
				}
			}
		}
	}
end

local function trgu_version_log_arrow_button(text, button_func)
	return {
		n = G.UIT.C,
		config = {
			align = "cm",
			padding = 0.12,
			r = 0.1,
			minw = 0.8,
			minh = 0.65,
			colour = G.C.DYN_UI.BOSS_DARK,
			hover = true,
			shadow = true,
			button = button_func
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					text = text,
					scale = 0.55,
					colour = G.C.UI.TEXT_LIGHT,
					shadow = true
				}
			}
		}
	}
end

local function trgu_version_logs_page()
	trgu_update_version_log_display()

	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 0.25,
			r = 0.1,
			colour = G.C.BLACK,
			minw = 7.5,
			minh = 4.8
		},
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					padding = 0.2,
					r = 0.08,
					colour = G.C.DYN_UI.MAIN,
					minw = 7,
					minh = 4.4
				},
				nodes = {
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.05
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = "Version Logs",
									scale = 0.58,
									colour = G.C.FILTER,
									shadow = true
								}
							}
						}
					},

					trgu_version_log_dynamic_text("title", 0.5, G.C.FILTER),

					{
						n = G.UIT.R,
						config = {
							minh = 0.12
						},
						nodes = {}
					},

					trgu_version_log_dynamic_text("line_1", 0.39, G.C.UI.TEXT_LIGHT),
					trgu_version_log_dynamic_text("line_2", 0.39, G.C.UI.TEXT_LIGHT),
					trgu_version_log_dynamic_text("line_3", 0.39, G.C.UI.TEXT_LIGHT),
					trgu_version_log_dynamic_text("line_4", 0.39, G.C.UI.TEXT_LIGHT),
					trgu_version_log_dynamic_text("line_5", 0.39, G.C.UI.TEXT_LIGHT),
					trgu_version_log_dynamic_text("line_6", 0.39, G.C.UI.TEXT_LIGHT),
					trgu_version_log_dynamic_text("line_7", 0.39, G.C.UI.TEXT_LIGHT),

					{
						n = G.UIT.R,
						config = {
							minh = 0.2
						},
						nodes = {}
					},

					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.08
						},
						nodes = {
							trgu_version_log_arrow_button("<", "trgu_version_log_newest"),

							{
								n = G.UIT.C,
								config = {
									align = "cm",
									padding = 0.08,
									minw = 1.4
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											ref_table = TRGU.version_log_display,
											ref_value = "page",
											scale = 0.38,
											colour = G.C.UI.TEXT_LIGHT,
											shadow = true
										}
									}
								}
							},

							trgu_version_log_arrow_button(">", "trgu_version_log_older")
						}
					}
				}
			}
		}
	}
end

TRGU.mod.extra_tabs = function()
	return {
		{
			label = "Credits",
			tab_definition_function = function()
				return trgu_menu_page({
					{ title = "Credits" },
					"",
					"Mod created by Mirkoi",
					"Admin Cards art: Starly",
                    "Tester: Ocitivka",
					"",
					{ title = "Resources" },
					"",
					"Steamodded / SMODS framework",
					"Balatro by LocalThunk",
					"Music, sfx and meme audio belong to their original creators",
					"All custom sprites are made for TrGu Mod"
				})
			end
		},
		{
            label = "Version Logs",
            tab_definition_function = function()
                return trgu_version_logs_page()
            end
        }
	}
end