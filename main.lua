TRGU = TRGU or {}
TRGU.mod = SMODS.current_mod
TRGU.config = TRGU.mod.config or {}
TRGU.config.admin_textures = TRGU.config.admin_textures or 1
TRGU.mod.config = TRGU.config

local file_names = {
	"lang_helpers",
    "adminscards",
	"mod_info",
    "deckstags",
	"editionsenhances",
	"bossblinds"
}

for _, file_name in ipairs(file_names) do
    assert(SMODS.load_file(file_name .. ".lua"))()
end

-- ИКОНКА МОДА
if SMODS.Atlas then
    SMODS.Atlas({
        key = "modicon",
        path = "modicon.png",
        px = 32,
        py = 32
    })
end

-- ОБЩИЕ ФУНКЦИИ
local function trgu_rank_id(card)
	if not card then return nil end

	if card.get_id then
		local id = card:get_id()
		if id then return id end
	end

	if card.base and card.base.id then
		return card.base.id
	end

	return nil
end

local function trgu_rank_mult_value(card)
	local id = trgu_rank_id(card)

	if id == 11 then return 10 end -- Jack
	if id == 12 then return 11 end -- Queen
	if id == 13 then return 12 end -- King
	if id == 14 then return 13 end -- Ace

	return id or 0
end


-- ГУГЛ ТАБЛИЦЫ ДЖОКЕР
SMODS.Atlas {
	key = "googlesheet",
	path = "GoogleSheet.png",
	px = 71,
	py = 95
}

local function google_sheets_utf8_len(text)
	if not text then return 0 end

	text = tostring(text)

	local count = 0
	local i = 1
	local len = #text

	while i <= len do
		local byte = text:byte(i)

		if not byte then
			break
		end

		if byte < 0x80 then
			i = i + 1

		elseif byte < 0xE0 then
			i = i + 2

		elseif byte < 0xF0 then
			i = i + 3

		elseif byte < 0xF8 then
			i = i + 4

		else
			i = i + 1
		end

		count = count + 1
	end

	return count
end

local function google_sheets_count_text(desc, vars)
	local total = 0

	if type(desc) == 'string' then
		local clean = desc
		clean = clean:gsub("#(%d+)#", function(n)
			return tostring(vars and vars[tonumber(n)] or "")
		end)
		clean = clean:gsub("%b{}", "")
		clean = clean:gsub("%s+", "")

		return google_sheets_utf8_len(clean)
	end

	if type(desc) == 'table' then
		for _, line in ipairs(desc) do
			total = total + google_sheets_count_text(line, vars)
		end
	end

	return total
end

local function google_sheets_get_boss_blind_mult()
	if not (G and G.GAME and G.P_BLINDS) then return 0 end

	local boss_key =
		G.GAME.round_resets
		and G.GAME.round_resets.blind_choices
		and G.GAME.round_resets.blind_choices.Boss
	if not boss_key
		and G.GAME.blind
		and G.GAME.blind.config
		and G.GAME.blind.config.blind
	then
		boss_key = G.GAME.blind.config.blind.key
	end

	if not boss_key then return 0 end

	local blind_center = G.P_BLINDS[boss_key]
	if not blind_center then return 0 end

	local vars = blind_center.vars or {}

	if type(blind_center.loc_vars) == 'function' then
		local ok, ret = pcall(function()
			return blind_center:loc_vars()
		end)

		if ok and ret and ret.vars then
			vars = ret.vars
		end
	end

	local raw_desc

	if localize then
		local ok, result = pcall(function()
			return localize {
				type = 'raw_descriptions',
				set = 'Blind',
				key = boss_key,
				vars = vars
			}
		end)

		if ok then raw_desc = result end
	end

	if not raw_desc
		and G.localization
		and G.localization.descriptions
		and G.localization.descriptions.Blind
		and G.localization.descriptions.Blind[boss_key]
	then
		raw_desc = G.localization.descriptions.Blind[boss_key].text
	end

	return google_sheets_count_text(raw_desc, vars)
end

SMODS.Joker {
	key = 'googlesheetjoker',
	loc_txt = {
		['en-us'] = {
			name = 'Google Sheets',
			text = {
				"{C:red}+0.5{} Mult for each character",
				"in the {C:attention}Boss Blind{} description",
				"for this Ante",
				"{C:inactive}(Currently: {C:mult}+#1#{C:inactive} Mult)"
			}
		},
		ru = {
			name = 'Google Таблицы',
			text = {
				"{C:red}+0.5{} множ. за каждый символ",
				"в описании {C:attention}босс-блайнда{}",
				"на этом анте",
				"{C:inactive}(Сейчас: {C:mult}+#1#{C:inactive} множ.)"
			}
		}
	},
	config = { extra = { mult = 0 } },

	loc_vars = function(self, info_queue, card)
		local mult = google_sheets_get_boss_blind_mult() / 2

		if card and card.ability and card.ability.extra then
			card.ability.extra.mult = mult
		end

		return { vars = { mult } }
	end,

	rarity = 2,
	atlas = 'googlesheet',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main then
			local mult = google_sheets_get_boss_blind_mult() / 2
			card.ability.extra.mult = mult
			return {
				mult = mult
			}
		end
	end
}

-- TDoT ДЖОКЕР
SMODS.Atlas {
	key = "tdotsheet",
	path = "TDoT.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'tdotjoker',
	loc_txt = {
		['en-us'] = {
			name = 'TDoT',
			text = {
				"Spends {C:money}$#1#{} for",
				"{C:chips}+#2#{} Chips or {C:mult}+#3#{} Mult",
				"each played hand",
				"{C:inactive}(if you have enough money)"
			}
		},
		ru = {
			name = 'TDoT',
			text = {
				"Тратит {C:money}$#1#{} на",
				"{C:chips}+#2#{} фишек либо {C:mult}+#3#{} множ.",
				"за каждую сыгранную руку",
				"{C:inactive}(если хватает денег)"
			}
		}
	},
	config = {
		extra = {
			cost = 3,
			chips = 50,
			mult = 10
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.cost,
				card.ability.extra.chips,
				card.ability.extra.mult
			}
		}
	end,

	rarity = 1,
	atlas = 'tdotsheet',
	pos = { x = 0, y = 0 },
	cost = 4,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.joker_main then
			local dollars = G.GAME and G.GAME.dollars or 0
			local trigger_cost = card.ability.extra.cost

			if dollars >= trigger_cost then
				ease_dollars(-trigger_cost)

				if pseudorandom('tdot_joker') < 0.5 then
					return {
						chips = card.ability.extra.chips
					}
				else
					return {
						mult = card.ability.extra.mult
					}
				end
			end
		end
	end
}

-- MP3-БРЕД ДЖОКЕР
SMODS.Atlas {
	key = "mp3joker",
	path = "Mp3Pleer.png",
	px = 71,
	py = 95,
	atlas_table = "ANIMATION_ATLAS",
	frames = 2,
	fps = 2
}

SMODS.Sound {
	key = 'mp3_21',
	path = '21-meme-kid.mp3'
}

SMODS.Sound {
	key = 'mp3_sixseven',
	path = 'six-seven.mp3'
}

SMODS.Sound {
	key = 'mp3_pyat',
	path = 'pyat.mp3'
}

SMODS.Sound {
	key = 'mp3_vosem',
	path = 'vosem.mp3'
}

local MP3_JOKER_MOD_PREFIX = 'trgu'

local mp3_joker_sounds = {
	{
		mult = 21,
		name = '21-meme-kid.mp3',
		sound_key = 'mp3_21'
	},
    {
		mult = 5,
		name = 'pyat.mp3',
		sound_key = 'mp3_pyat'
	},
    {
		mult = 8,
		name = 'vosem.mp3',
		sound_key = 'mp3_vosem'
	},
	{
		mult = 67,
		name = 'six-seven.mp3',
		sound_key = 'mp3_sixseven'
	}
}

local function mp3_joker_get_random_sound()
	return pseudorandom_element(mp3_joker_sounds, pseudoseed('mp3_joker_sound'))
end

SMODS.Joker {
	key = 'mp3joker',
	loc_txt = {
		['en-us'] = {
			name = 'MemeWax',
			text = {
				"Plays a random meme",
				"and gives {C:mult}+#1#{} to {C:mult}+#2#{} Mult",
				"mentioned in the sound"
			}
		},
		ru = {
			name = 'MP3-БРЕД',
			text = {
				"Проигрывает случайный мем",
				"и даёт от {C:mult}+#1#{} до {C:mult}+#2#{} множ.",
				"упомянутые в звуке"
			}
		}
	},
	config = {
		extra = {
			min_mult = 5,
			max_mult = 67
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.min_mult,
				card.ability.extra.max_mult
			}
		}
	end,

	rarity = 2,
	atlas = 'mp3joker',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.joker_main then
			local selected_sound = mp3_joker_get_random_sound()

			return {
				mult = selected_sound.mult,
				message = selected_sound.name,
				sound = MP3_JOKER_MOD_PREFIX .. '_' .. selected_sound.sound_key
			}
		end
	end
}

-- Face Holding Back Tears ДЖОКЕР
SMODS.Atlas {
	key = "cryjoker",
	path = "Fhbt.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'cryjoker',
	loc_txt = {
		['en-us'] = {
			name = 'Face Holding Back Tears',
			text = {
				"{X:mult,C:white} X#1# {} Mult",
				"{C:green}#2# in #3#{} chance each scoring",
				"card becomes {C:red}eternally{}",
				"{C:red}debuffed{} when hand is played"
			}
		},
		ru = {
			name = 'Face Holding Back Tears',
			text = {
				"{X:mult,C:white} X#1# {} множ.",
				"{C:green}#2# из #3#{} шанс, что каждая",
				"подсчитываемая карта станет",
				"{C:red}навсегда ослабленной{}"
			}
		}
	},
	config = {
		extra = {
			Xmult = 3,
			odds = 4
		}
	},

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'cryjoker')
		return {
			vars = {
				card.ability.extra.Xmult,
				numerator,
				denominator
			}
		}
	end,

	rarity = 3,
	atlas = 'cryjoker',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.before and context.scoring_hand and not context.blueprint then
			for _, scored_card in ipairs(context.scoring_hand) do
				if not scored_card.debuff and SMODS.pseudorandom_probability(
					card,
					'cryjoker_debuff',
					1,
					card.ability.extra.odds
				) then
					SMODS.debuff_card(scored_card, true, 'cryjoker')
					scored_card:juice_up()

					SMODS.calculate_effect({
						message = localize('trgu_fhbt'),
						colour = G.C.RED
					}, scored_card)
				end
			end
		end

		if context.joker_main then
			return {
				xmult = card.ability.extra.Xmult
			}
		end
	end
}

-- ОЧЕНЬ СПЕЛЫЙ БАНАН ДЖОКЕР
SMODS.Atlas {
	key = "ripebanana",
	path = "RipeBanana.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'ripebananajoker',
	loc_txt = {
		['en-us'] = {
			name = 'Very Ripe Banana',
			text = {
				"{C:mult}+#1#{} Mult",
				"{C:green}#2# in #3#{} chance this",
				"card is destroyed",
				"at end of round"
			}
		},
		ru = {
			name = 'Очень спелый банан',
			text = {
				"{C:mult}+#1#{} множ.",
				"{C:green}#2# из #3#{} шанс, что эта",
				"карта уничтожится",
				"в конце раунда"
			}
		}
	},

	no_pool_flag = 'ripe_banana_extinct',

	config = {
		extra = {
			mult = 12,
			odds = 8
		}
	},

	rarity = 1,
	atlas = 'ripebanana',
	pos = { x = 0, y = 0 },
	cost = 5,
	eternal_compat = false,

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'ripebananajoker'
		)

		return {
			vars = {
				card.ability.extra.mult,
				numerator,
				denominator
			}
		}
	end,

	calculate = function(self, card, context)
		if context.joker_main then
			return {
				mult = card.ability.extra.mult
			}
		end

		if context.end_of_round
			and context.main_eval
			and context.game_over == false
			and not context.blueprint
		then
			if SMODS.pseudorandom_probability(
				card,
				'ripebananajoker',
				1,
				card.ability.extra.odds
			) then
				SMODS.destroy_cards(card, nil, nil, true)

				G.GAME.pool_flags.ripe_banana_extinct = true

				return {
					message = localize('trgu_extinct')
				}
			else
				return {
					message = localize('trgu_safe')
				}
			end
		end
	end
}

-- БРЕДОВУХА ДЖОКЕР
SMODS.Atlas {
	key = "fibbagefour",
	path = "Fibbage4.png",
	px = 71,
	py = 95
}

local fibbage_joker_active = nil
local fibbage_joker_menu_open = false

local function fibbage_joker_get_questions()
	return TRGU.load_lang_content('content/fibbage_questions')
end

local function fibbage_joker_pick_question()
	local questions = fibbage_joker_get_questions()

	if not questions or #questions <= 0 then
		print("Fibbage: missing questions")
		return {
			text = {
				"Missing Fibbage questions"
			},
			answer = true
		}
	end

	return pseudorandom_element(
		questions,
		pseudoseed('fibbage_joker_question')
	)
end

local function fibbage_joker_text_rows(lines, scale, colour)
	local rows = {}

	for _, line in ipairs(lines) do
		rows[#rows + 1] = {
			n = G.UIT.R,
			config = {
				align = "cm",
				padding = 0.04
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = line,
						scale = scale or 0.45,
						colour = colour or G.C.UI.TEXT_LIGHT,
						shadow = true
					}
				}
			}
		}
	end

	return rows
end

G.UIDEF.fibbage_joker_question_box = function(question)
	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 0.1,
			r = 0.1,
			colour = G.C.CLEAR
		},
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					padding = 0.25,
					r = 0.15,
					colour = G.C.DYN_UI.MAIN,
					emboss = 0.05,
					minw = 6,
					minh = 3.2
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
									text = localize('trgu_f4_joker'),
									scale = 0.65,
									colour = G.C.FILTER,
									shadow = true
								}
							}
						}
					},
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.1
						},
						nodes = {
							{
								n = G.UIT.C,
								config = {
									align = "cm",
									padding = 0.1,
									r = 0.1,
									colour = G.C.DYN_UI.BOSS_DARK,
									minw = 5.5
								},
								nodes = fibbage_joker_text_rows(question.text, 0.45, G.C.UI.TEXT_LIGHT)
							}
						}
					},
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.15
						},
						nodes = {
							{
								n = G.UIT.C,
								config = {
									align = "cm",
									padding = 0.12,
									r = 0.1,
									colour = G.C.GREEN,
									hover = true,
									shadow = true,
									button = "fibbage_joker_answer",
									fibbage_answer = true,
									minw = 2.2,
									minh = 0.7
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = localize('trgu_true'),
											scale = 0.5,
											colour = G.C.UI.TEXT_LIGHT,
											shadow = true
										}
									}
								}
							},
							{
								n = G.UIT.B,
								config = {
									w = 0.25,
									h = 0.1
								}
							},
							{
								n = G.UIT.C,
								config = {
									align = "cm",
									padding = 0.12,
									r = 0.1,
									colour = G.C.RED,
									hover = true,
									shadow = true,
									button = "fibbage_joker_answer",
									fibbage_answer = false,
									minw = 2.2,
									minh = 0.7
								},
								nodes = {
									{
										n = G.UIT.T,
										config = {
											text = localize('trgu_false'),
											scale = 0.5,
											colour = G.C.UI.TEXT_LIGHT,
											shadow = true
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
end

local function fibbage_joker_open_question(card, question)
	fibbage_joker_active = {
		card = card,
		question = question
	}

	fibbage_joker_menu_open = true

	G.FUNCS.overlay_menu({
		definition = G.UIDEF.fibbage_joker_question_box(question)
	})
end

G.FUNCS.fibbage_joker_answer = function(e)
	if not fibbage_joker_active then return end

	local card = fibbage_joker_active.card
	local question = fibbage_joker_active.question
	local chosen_answer = e.config.fibbage_answer
	local correct = chosen_answer == question.answer

	fibbage_joker_menu_open = false
	fibbage_joker_active = nil

	if G.OVERLAY_MENU then
		G.FUNCS.exit_overlay_menu()
	end

	if not card or not card.ability or not card.ability.extra then
		return
	end

	if correct then
		card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_gain
		card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_gain
		SMODS.calculate_effect({
			message = localize('trgu_correct'),
			colour = G.C.GREEN
		}, card)
	else
		card.ability.extra.chips = card.ability.extra.chips - card.ability.extra.chip_gain
		card.ability.extra.mult = card.ability.extra.mult - card.ability.extra.mult_gain
		if card.ability.extra.mult < 1 then
			card.ability.extra.mult = 0
			card.ability.extra.chips = 0
		end
		SMODS.calculate_effect({
			message = localize('trgu_wrong'),
			colour = G.C.RED
		}, card)
	end

	card:juice_up()

	card.ability.extra.awaiting_answer = false
end

local function fibbage_joker_start_blind_question(card)
	if not card or not card.ability or not card.ability.extra then return end
	if card.ability.extra.awaiting_answer then return end

	local question = fibbage_joker_pick_question()

	card.ability.extra.awaiting_answer = true

	G.E_MANAGER:add_event(Event({
		trigger = "after",
		delay = 0.1,
		blocking = true,
		blockable = false,
		pause_force = true,
		func = function()
			if not card or not card.ability or not card.ability.extra then
				fibbage_joker_active = nil
				fibbage_joker_menu_open = false
				return true
			end

			if not card.ability.extra.awaiting_answer then
				return true
			end

			if fibbage_joker_menu_open and not G.OVERLAY_MENU then
				fibbage_joker_menu_open = false
				fibbage_joker_active = nil
			end

			if not G.OVERLAY_MENU and not fibbage_joker_menu_open then
				fibbage_joker_open_question(card, question)
			end

			return false
		end
	}))
end

SMODS.Joker {
	key = 'fibbagejoker',
	loc_txt = {
		['en-us'] = {
			name = 'Fibbage 4',
			text = {
				"Answer a {C:attention}True/False{} question",
				"before round is started",
				"Answer permanently gains or losses",
				"{C:chips}#3#{} Chips and {C:mult}#4#{} Mult",
				"{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips, {C:mult}+#2#{C:inactive} Mult)"
			}
		},
		ru = {
			name = 'Бредовуха 4',
			text = {
				"Ответьте является ли факт {C:attention}правдой{}",
				"или {C:attention}ложью{} перед началом раунда",
				"Ответ навсегда принесёт или отнимет",
				"{C:chips}#3#{} фишек и {C:mult}#4#{} множ.",
				"{C:inactive}(Сейчас: {C:chips}+#1#{C:inactive} фишек, {C:mult}+#2#{C:inactive} множ.)"
			}
		}
	},
	config = {
		extra = {
			chips = 0,
			mult = 0,
			chip_gain = 4,
			mult_gain = 1,
			awaiting_answer = false
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.chips,
				card.ability.extra.mult,
				card.ability.extra.chip_gain,
				card.ability.extra.mult_gain
			}
		}
	end,

	rarity = 2,
	atlas = 'fibbagefour',
	pos = { x = 0, y = 0 },
	cost = 6,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			fibbage_joker_start_blind_question(card)
		end

		if context.joker_main then
			if card.ability.extra.chips > 0 or card.ability.extra.mult > 0 then
				return {
					chips = card.ability.extra.chips,
					mult = card.ability.extra.mult
				}
			end
		end
	end
}

-- ПИЗДА С УШАМИ ДЖОКЕР
SMODS.Atlas {
	key = "bunnywitch",
	path = "Ushami.png",
	px = 71,
	py = 95
}

local bunnywitch_edible_jokers = {
	'j_gros_michel',
	'j_cavendish',
	'j_ice_cream',
	'j_popcorn',
	'j_ramen',
	'j_turtle_bean',
	'j_diet_cola',
	'j_selzer',
	'j_egg',
	'ripebananajoker',
	'sosisnik',
	'redbanana',
	'teftelya',
	'mishburger'
}

local function bunnywitch_string_ends_with(text, ending)
	return ending == "" or text:sub(-#ending) == ending
end

local function bunnywitch_is_edible_joker(joker_card)
	if not joker_card
		or not joker_card.config
		or not joker_card.config.center
		or not joker_card.config.center.key
	then
		return false
	end

	local center_key = joker_card.config.center.key

	for _, edible_key in ipairs(bunnywitch_edible_jokers) do
		if center_key == edible_key then
			return true
		end

		if center_key == 'j_' .. edible_key then
			return true
		end

		if bunnywitch_string_ends_with(center_key, '_' .. edible_key) then
			return true
		end
	end

	return false
end

local function bunnywitch_eat_jokers(card)
	local eaten_jokers = {}

	if not G.jokers or not G.jokers.cards then
		return 0
	end

	for _, other_joker in ipairs(G.jokers.cards) do
		if other_joker ~= card
			and bunnywitch_is_edible_joker(other_joker)
			and not SMODS.is_eternal(other_joker, card)
		then
			eaten_jokers[#eaten_jokers + 1] = other_joker
		end
	end

	if #eaten_jokers > 0 then
		SMODS.destroy_cards(eaten_jokers, false, false, true)
	end

	return #eaten_jokers
end

SMODS.Joker {
	key = 'bunnywitch',
	loc_txt = {
		['en-us'] = {
			name = 'BunnyWitch',
			text = {
				"At start of blind,",
				"eats all {C:attention}edible Jokers{}",
				"and gains {X:mult,C:white} X#2# {} Mult",
				"for each eaten Joker",
				"{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)"
			}
		},
		ru = {
			name = 'С ушами',
			text = {
				"В начале блайнда",
				"съедает всех {C:attention}съедобных джокеров{}",
				"и получает {X:mult,C:white} X#2# {} множ.",
				"за каждого съеденного джокера",
				"{C:inactive}(Сейчас: {X:mult,C:white} X#1# {C:inactive} множ.)"
			}
		}
	},
	config = {
		extra = {
			Xmult = 1,
			Xmult_gain = 0.5
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.Xmult,
				card.ability.extra.Xmult_gain
			}
		}
	end,

	rarity = 2,
	atlas = 'bunnywitch',
	pos = { x = 0, y = 0 },
	cost = 7,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			local eaten_count = bunnywitch_eat_jokers(card)

			if eaten_count > 0 then
				card.ability.extra.Xmult =
					card.ability.extra.Xmult + card.ability.extra.Xmult_gain * eaten_count

				return {
					message = localize{
					type = 'variable',
					key = 'trgu_eaten',
					vars = { eaten_count }
				},
					colour = G.C.MULT
				}
			end
		end

		if context.joker_main then
			return {
				xmult = card.ability.extra.Xmult
			}
		end
	end
}

-- СТАТИЧНЫЙ РЕБОРН ДЖОКЕР
SMODS.Atlas {
	key = "tmwreborn",
	path = "TMWReborn.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'tmwreborn',
	loc_txt = {
		['en-us'] = {
			name = 'Static TMWReborn',
			text = {
				"{C:mult}+#1#{} Mult",
				"if played hand",
				"does not contain a {C:attention}Pair{}"
			}
		},
		ru = {
			name = 'Статичный Реборн',
			text = {
				"{C:mult}+#1#{} множ.,",
				"если сыгранная рука",
				"не содержит {C:attention}Пару{}"
			}
		}
	},
	config = {
		extra = {
			mult = 12
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult
			}
		}
	end,

	rarity = 1,
	atlas = 'tmwreborn',
	pos = { x = 0, y = 0 },
	cost = 3,

	calculate = function(self, card, context)
		if context.joker_main then
			if not next(context.poker_hands['Pair']) then
				return {
					mult = card.ability.extra.mult
				}
			end
		end
	end
}

-- МИСТЕР КУПИЛ ТГ ДЖОКЕР
SMODS.Atlas {
	key = "kank",
	path = "Kank.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'kank',
	loc_txt = {
		['en-us'] = {
			name = 'Mr. Bought TG',
			text = {
				"Earn {C:money}$#1#{} at",
				"end of round if",
				"you have less than {C:money}$#2#{}"
			}
		},
		ru = {
			name = 'Мистер Купил ТГ',
			text = {
				"Получите {C:money}$#1#{}",
				"в конце раунда, если",
				"у вас меньше {C:money}$#2#{}"
			}
		}
	},
	config = {
		extra = {
			money = 6,
			threshold = 5
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.money,
				card.ability.extra.threshold
			}
		}
	end,

	rarity = 1,
	atlas = 'kank',
	pos = { x = 0, y = 0 },
	cost = 5,

	blueprint_compat = false,

	calc_dollar_bonus = function(self, card)
		local dollars = G.GAME and G.GAME.dollars or 0

		if dollars < card.ability.extra.threshold then
			return card.ability.extra.money
		end
	end
}

-- ГРОМКОСТНОЙ ДЖОКЕР
SMODS.Atlas {
	key = "volumejoker",
	path = "Mp3Joker.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'volumejoker',
	loc_txt = {
		['en-us'] = {
			name = 'Joker.mp3',
			text = {
				"{X:mult,C:white} X#1# {} Mult",
				"if {C:attention}Master Volume{}",
				"and {C:attention}Music Volume{}",
				"are above {C:attention}#2#{}"
			}
		},
		ru = {
			name = 'Джокер.mp3',
			text = {
				"{X:mult,C:white} X#1# {} множ.",
				"если {C:attention}общая громкость{}",
				"и {C:attention}громкость музыки{}",
				"выше {C:attention}#2#{}"
			}
		}
	},
	config = {
		extra = {
			Xmult = 1.5,
			volume_needed = 90
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.Xmult,
				card.ability.extra.volume_needed
			}
		}
	end,

	rarity = 1,
	atlas = 'volumejoker',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main then
			local master_volume = 0
			local music_volume = 0

			if G.SETTINGS and G.SETTINGS.SOUND then
				master_volume = G.SETTINGS.SOUND.volume or 0
				music_volume = G.SETTINGS.SOUND.music_volume or 0
			end

			if master_volume > card.ability.extra.volume_needed
				and music_volume > card.ability.extra.volume_needed
			then
				return {
					xmult = card.ability.extra.Xmult
				}
			end
		end
	end
}

-- ПАСС-ВИТАЛЬ ДЖОКЕР
SMODS.Atlas {
	key = "passvital",
	path = "PassVital.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'passvital',
	loc_txt = {
		['en-us'] = {
			name = 'Pass-Vital',
			text = {
				"{C:purple}Admin{} cards",
				"can appear",
				"in the {C:attention}shop{}"
			}
		},
		ru = {
			name = 'Пасс-Виталь',
			text = {
				"{C:purple}Админские{} карты",
				"могут появляться",
				"в {C:attention}магазине{}"
			}
		}
	},

	config = {
		extra = {
			admin_shop_rate = 4
		}
	},

	rarity = 2,
	atlas = 'passvital',
	pos = { x = 0, y = 0 },
	cost = 6,

	add_to_deck = function(self, card, from_debuff)
		if not G.GAME then return end

		G.GAME.trgu_passvital_count = (G.GAME.trgu_passvital_count or 0) + 1
		G.GAME.admin_rate = card.ability.extra.admin_shop_rate
	end,

	remove_from_deck = function(self, card, from_debuff)
		if not G.GAME then return end

		G.GAME.trgu_passvital_count = math.max((G.GAME.trgu_passvital_count or 1) - 1, 0)

		if G.GAME.trgu_passvital_count <= 0 then
			G.GAME.admin_rate = 0
		end
	end
}

-- МИРКОЙ ПЛЮША ДЖОКЕР
SMODS.Atlas {
	key = "mirkoiplush",
	path = "MirkoiPlush.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'mirkoiplush',
	loc_txt = {
		['en-us'] = {
			name = 'Mirkoi Plush',
			text = {
				"Each scored",
				"{C:hearts}Heart{} card gives",
				"{C:chips}+#1#{} Chips"
			}
		},
		ru = {
			name = 'Миркой Плюша',
			text = {
				"Каждая подсчитанная",
				"{C:hearts}червовая{} карта даёт",
				"{C:chips}+#1#{} фишек"
			}
		}
	},
	config = {
		extra = {
			chips = 25
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.chips
			}
		}
	end,

	rarity = 1,
	atlas = 'mirkoiplush',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.individual
			and context.cardarea == G.play
			and context.other_card
			and context.other_card:is_suit('Hearts')
		then
			return {
				chips = card.ability.extra.chips
			}
		end
	end
}

-- ВОТИФ ДЖОКЕР
SMODS.Atlas {
	key = "wifhat",
	path = "WifHat.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'wifhat',
	loc_txt = {
		['en-us'] = {
			name = 'WifHat',
			text = {
				"Earn {C:money}$#1#{} if",
				"played hand contains",
				"no {C:attention}face cards{}"
			}
		},
		ru = {
			name = 'WifHat',
			text = {
				"Получите {C:money}$#1#{}, если",
				"сыгранная рука",
				"не содержит {C:attention}карт с лицом{}"
			}
		}
	},
	config = {
		extra = {
			money = 4
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.money
			}
		}
	end,

	rarity = 1,
	atlas = 'wifhat',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.before then
			local has_face_card = false

			for _, played_card in ipairs(context.full_hand) do
				if played_card:is_face() then
					has_face_card = true
					break
				end
			end

			if not has_face_card then
				ease_dollars(card.ability.extra.money)

				return {
					message = "+$" .. card.ability.extra.money,
					colour = G.C.MONEY
				}
			end
		end
	end
}

-- М БАБЗ ДЖОКЕР
SMODS.Atlas {
	key = "jobjob",
	path = "JobJob.png",
	px = 71,
	py = 95
}

local trgu_old_optional_features = SMODS.current_mod.optional_features

SMODS.current_mod.optional_features = function()
	local ret = {}

	if trgu_old_optional_features then
		ret = trgu_old_optional_features() or {}
	end

	ret.retrigger_joker = true

	return ret
end

SMODS.Joker {
	key = 'jobjob',
	loc_txt = {
		['en-us'] = {
			name = 'M. Bubz',
			text = {
				"Gives {C:mult}+#1#{} Mult",
				"and {C:chips}+#2#{} Chips",
				"Retriggers itself {C:attention}#3#{} times",
				"{C:inactive}(Numbers shuffle for each hand)"
			}
		},
		ru = {
			name = 'М. Бутля',
			text = {
				"Даёт {C:mult}+#1#{} множ.",
				"и {C:chips}+#2#{} фишек",
				"перезапускает себя {C:attention}#3#{} раз(а)",
				"{C:inactive}(Числа меняются каждую руку)"
			}
		}
	},
	config = {
		extra = {
			mult = 3,
			chips = 3,
			repetitions = 2
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				card.ability.extra.chips,
				card.ability.extra.repetitions
			}
		}
	end,

	rarity = 2,
	atlas = 'jobjob',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
	if context.before and not context.blueprint then
		card.ability.extra.mult = math.floor(pseudorandom('jobjob_mult') * 4) + 1
		card.ability.extra.chips = math.floor(pseudorandom('jobjob_chips') * 4) + 2
		card.ability.extra.repetitions = math.floor(pseudorandom('jobjob_reps') * 3)

		return {
			message = localize('trgu_shuffled'),
			colour = G.C.FILTER
		}
	end

	if context.joker_main then
		return {
			mult = card.ability.extra.mult,
			chips = card.ability.extra.chips
		}
	end

	if context.retrigger_joker_check
		and context.other_card == card
		and context.other_context
		and context.other_context.joker_main
		and card.ability.extra.repetitions > 0
	then
		return {
			repetitions = card.ability.extra.repetitions,
			message = localize('trgu_again')
		}
	end
	end
}

-- ЗИПЕР ДЖОКЕР
SMODS.Atlas {
	key = "ziper",
	path = "Ziper.png",
	px = 71,
	py = 95
}

local ziper_ranks = {
	'2', '3', '4', '5', '6', '7', '8', '9', '10',
	'Jack', 'Queen', 'King', 'Ace'
}

local ziper_suits = {
	'Hearts',
	'Diamonds',
	'Clubs',
	'Spades'
}

local ziper_enhancements = {
	'm_bonus',
	'm_mult',
	'm_wild',
	'm_glass',
	'm_steel',
	'm_gold',
	'm_lucky'
}

local ziper_editions = {
	{ foil = true },
	{ holo = true },
	{ polychrome = true }
}

local ziper_seals = {
	'Red',
	'Blue',
	'Gold',
	'Purple'
}

local function ziper_random_from(list, seed)
	local index = math.floor(pseudorandom(seed) * #list) + 1
	return list[index]
end

SMODS.Joker {
	key = 'ziper',
	loc_txt = {
		['en-us'] = {
			name = 'Ziper',
			text = {
				"When {C:attention}Small Blind{} or",
				"{C:attention}Big Blind{} is selected,",
				"add a random playing card",
				"to your deck"
			}
		},
		ru = {
			name = 'Зипер',
			text = {
				"При выборе {C:attention}малого{}",
				"или {C:attention}большого блайнда{}",
				"добавляет случайную игральную карту",
				"в вашу колоду"
			}
		}
	},

	rarity = 1,
	atlas = 'ziper',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.setting_blind
			and context.blind
			and not context.blind.boss
			and not context.blueprint
		then
			local rank = ziper_random_from(ziper_ranks, 'ziper_rank')
			local suit = ziper_random_from(ziper_suits, 'ziper_suit')

			local enhancement = nil
			local edition = nil
			local seal = nil

			if pseudorandom('ziper_enhancement_chance') < 0.15 then
				enhancement = ziper_random_from(ziper_enhancements, 'ziper_enhancement')
			end

			if pseudorandom('ziper_edition_chance') < 0.15 then
				edition = ziper_random_from(ziper_editions, 'ziper_edition')
			end

			if pseudorandom('ziper_seal_chance') < 0.15 then
				seal = ziper_random_from(ziper_seals, 'ziper_seal')
			end

			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.2,
				func = function()
					local new_card = SMODS.add_card({
					set = 'Playing Card',
					area = G.deck,
					rank = rank,
					suit = suit,
					enhancement = enhancement,
					edition = edition,
					seal = seal,
					allow_duplicates = true,
					key_append = 'ziper'
				})
						if new_card then
							new_card:start_materialize()
							new_card:juice_up()
							if G.play and draw_card then
								draw_card(G.deck, G.play, 1, 'up', nil, new_card)

								G.E_MANAGER:add_event(Event({
									trigger = 'after',
									delay = 1.0,
									func = function()
										if new_card and not new_card.removed then
											draw_card(G.play, G.deck, 1, 'down', nil, new_card)
										end

										return true
									end
								}))
							end

							if playing_card_joker_effects then
								playing_card_joker_effects({ new_card })
							end
						end
					return true
				end
			}))

			return {
				message = localize('trgu_card_added'),
				colour = G.C.FILTER
			}
		end
	end
}

-- МИРКОШКА БОТ
SMODS.Atlas {
	key = "mirkoshkabot",
	path = "MirkoshkaBot.png",
	px = 71,
	py = 95
}

local function mirkoshka_get_profile_username()
	local candidates = {}

	if G then
		if G.PROFILES and G.SETTINGS and G.SETTINGS.profile and G.PROFILES[G.SETTINGS.profile] then
			candidates[#candidates + 1] = G.PROFILES[G.SETTINGS.profile]
		end

		if G.PROFILE then
			candidates[#candidates + 1] = G.PROFILE
		end

		if G.SETTINGS and G.SETTINGS.profile then
			candidates[#candidates + 1] = G.SETTINGS.profile
		end
	end

	for _, profile in ipairs(candidates) do
		if type(profile) == "table" then
			local name =
				profile.name
				or profile.username
				or profile.profile_name
				or profile.display_name
				or profile.player_name

			if name then
				return tostring(name)
			end
		elseif type(profile) == "string" then
			return profile
		end
	end

	return ""
end

SMODS.Joker {
	key = 'mirkoshkabot',
	loc_txt = {
		['en-us'] = {
			name = 'Mirkoshka Bot',
			text = {
				"{C:mult}+#1#{} Mult",
				"If your profile username",
				"is {C:attention}Draserg{},",
				"gives another {C:mult}+#2#{} Mult"
			}
		},
		ru = {
			name = 'Миркошка Бот',
			text = {
				"{C:mult}+#1#{} множ.",
				"Если имя вашего профиля",
				"{C:attention}Draserg{},",
				"даёт ещё {C:mult}+#2#{} множ."
			}
		}
	},
	config = {
		extra = {
			mult = 10,
			draserg_bonus = 10
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				card.ability.extra.draserg_bonus
			}
		}
	end,

	rarity = 1,
	atlas = 'mirkoshkabot',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
	if context.joker_main then
		local total_mult = card.ability.extra.mult
		local username = mirkoshka_get_profile_username()
		local is_draserg = username == 'Draserg'

		if is_draserg then
			total_mult = total_mult + card.ability.extra.draserg_bonus
		end

		if is_draserg then
			return {
				mult = total_mult,
				message = localize('trgu_draserg_love'),
				colour = G.C.PURPLE
			}
		else
			return {
				mult = total_mult
			}
		end
	end
end
}

-- НЕВИНОВНЫЙ ДЖОКЕР
SMODS.Atlas {
	key = "innocent",
	path = "Innocent.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'innocent',
	loc_txt = {
		['en-us'] = {
			name = 'Innocent',
			text = {
				"Sets {C:chips}Chips{} to {C:chips}#1#{},",
				"but gives {C:mult}+#2#{} Mult"
			}
		},
		ru = {
			name = 'Невинный',
			text = {
				"Устанавливает {C:chips}фишки{} на {C:chips}#1#{},",
				"но даёт {C:mult}+#2#{} множ."
			}
		}
	},
	config = {
		extra = {
			set_chips = 1,
			mult = 25
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.set_chips,
				card.ability.extra.mult
			}
		}
	end,

	rarity = 3,
	atlas = 'innocent',
	pos = { x = 0, y = 0 },
	soul_pos = { x = 1, y = 0 },
	cost = 8,

	calculate = function(self, card, context)
	if context.joker_main then
		local chips_to_set = card.ability.extra.set_chips
		local chip_delta = chips_to_set - hand_chips

		return {
			chips = chip_delta,
			mult = card.ability.extra.mult,
			remove_default_message = true,
			message = localize('trgu_one_chip'),
			colour = G.C.CHIPS,
			extra = {
				message = "+" .. card.ability.extra.mult .. " Mult",
				colour = G.C.MULT
			}
		}
	end
end
}

-- СИМФОНИЯ ГЕНШИН ИМПАКТ ДЖОКЕР
SMODS.Atlas {
	key = "genshin",
	path = "Genshin.png",
	px = 71,
	py = 95
}

local function trgu_has_joker_ending_with(short_key)
	if not G or not G.jokers or not G.jokers.cards then return false end

	for _, joker in ipairs(G.jokers.cards) do
		local key = joker
			and joker.config
			and joker.config.center
			and joker.config.center.key

		if type(key) == 'string' and key:sub(-#short_key) == short_key then
			return true
		end
	end

	return false
end

local function trgu_state_is(name)
	return G and G.STATES and G.STATES[name] and G.STATE == G.STATES[name]
end

local function trgu_is_booster_pack_state()
	local pack_states = {
		'STANDARD_PACK',
		'TAROT_PACK',
		'PLANET_PACK',
		'SPECTRAL_PACK',
		'BUFFOON_PACK',
		'SMODS_BOOSTER_OPENED'
	}

	for _, state_name in ipairs(pack_states) do
		if trgu_state_is(state_name) then
			return false
		end
	end

	if G.pack_cards and G.pack_cards.cards and #G.pack_cards.cards > 0 then
		return false
	end

	return false
end

local function trgu_should_play_genshin_music()
	if not G or not G.STATE or not G.STATES then return false end

	if trgu_state_is('MENU')
		or trgu_state_is('SPLASH')
		or trgu_state_is('TUTORIAL')
		or trgu_state_is('GAME_OVER')
	then
		return false
	end

	if trgu_is_booster_pack_state() then
		return false
	end

	return G.jokers ~= nil
end

SMODS.Sound {
	key = 'music_genshin_symphony',
	path = 'genshin_symphony.ogg',
	pitch = 1,
	volume = 0.7,
	sync = false,

	select_music_track = function(self)
		if trgu_has_joker_ending_with('genshin')
			and trgu_should_play_genshin_music()
		then
			return 100
		end
	end
}

SMODS.Joker {
	key = 'genshin',
	loc_txt = {
		['en-us'] = {
			name = 'Genshin Impact Symphony',
			text = {
				"Replaces the usual {C:attention}music{}",
				"with {C:blue}Symphony{} music",
				"from {C:attention}Genshin Impact{}",
				"{C:inactive}(Fontaine, Sumeru (Live) - HOYO-MiX)"
			}
		},
		ru = {
			name = 'Симфония Genshin Impact',
			text = {
				"Заменяет обычную {C:attention}музыку{}",
				"на {C:blue}симфоническую{} музыку",
				"из {C:attention}Genshin Impact{}",
				"{C:inactive}(Fontaine, Sumeru (Live) - HOYO-MiX)"
			}
		}
	},

	rarity = 2,
	atlas = 'genshin',
	pos = { x = 0, y = 0 },
	cost = 6
}

-- СОСИСНИК ДЖОКЕР
SMODS.Atlas {
	key = "sosisnik",
	path = "Sosisnik.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'sosisnik',
	loc_txt = {
		['en-us'] = {
			name = 'Sosisnik',
			text = {
				"After scoring, if played hand",
				"has {C:attention}4{} scored cards, {C:red}destroy{}",
				"a random played card and",
				"gain {X:mult,C:white} X#2# {} Mult",
				"{C:inactive}(Currently: {X:mult,C:white} X#1# {C:inactive} Mult)"
			}
		},
		ru = {
			name = 'Сосисник',
			text = {
				"После подсчёта, если в руке",
				"{C:attention}4{} подсчитанные карты, {C:red}уничтожает{}",
				"случайную сыгранную карту и",
				"получает {X:mult,C:white} X#2# {} множ.",
				"{C:inactive}(Сейчас: {X:mult,C:white} X#1# {C:inactive} множ.)"
			}
		}
	},
	config = {
		extra = {
			Xmult = 1.0,
			Xmult_gain = 0.1,
			sosisnik_target = nil
		}
	},

	loc_vars = function(self, info_queue, card)
	return {
		vars = {
			string.format("%.1f", card.ability.extra.Xmult),
			string.format("%.1f", card.ability.extra.Xmult_gain)
		}
	}
	end,

	rarity = 2,
	atlas = 'sosisnik',
	pos = { x = 0, y = 0 },
	cost = 6,

	blueprint_compat = true,

	calculate = function(self, card, context)
	if context.before
		and context.full_hand
		and #context.full_hand == 4
		and not context.blueprint
	then
		card.ability.extra.sosisnik_target = pseudorandom_element(
			context.full_hand,
			pseudoseed('sosisnik_destroy')
		)
	end

	if context.joker_main then
		return {
			xmult = card.ability.extra.Xmult
		}
	end

	if context.destroying_card
		and context.cardarea == G.play
		and card.ability.extra.sosisnik_target
		and context.destroying_card == card.ability.extra.sosisnik_target
		and not context.blueprint
	then
		card.ability.extra.sosisnik_target = nil
		card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_gain

		SMODS.calculate_effect({
			message = localize('trgu_sausaged'),
			colour = G.C.RED
		}, context.destroying_card)

		SMODS.calculate_effect({
			message = "+X" .. string.format("%.1f", card.ability.extra.Xmult_gain),
			colour = G.C.MULT
		}, card)

		return {
			remove = true
		}
	end
	end
}

-- ЦЕРАЦ ДЖОКЕР
local trgu_cerac_rank_by_id = {
	[2] = '2',
	[3] = '3',
	[4] = '4',
	[5] = '5',
	[6] = '6',
	[7] = '7',
	[8] = '8',
	[9] = '9',
	[10] = '10',
	[11] = 'Jack',
	[12] = 'Queen',
	[13] = 'King',
	[14] = 'Ace'
}

local function trgu_find_corrupted_enhancement()
	if not G or not G.P_CENTERS then return nil end

	local candidates = {
		'm_trgu_corrupted',
		'm_trgumod_corrupted',
		'm_corrupted'
	}

	for _, key in ipairs(candidates) do
		if G.P_CENTERS[key] then
			return G.P_CENTERS[key]
		end
	end

	for key, center in pairs(G.P_CENTERS) do
		if type(key) == 'string'
			and key:sub(1, 2) == 'm_'
			and key:sub(-9) == 'corrupted'
		then
			return center
		end
	end

	return nil
end

local function trgu_cerac_get_rank_id(card)
	if not card then return nil end

	if card.get_id then
		local id = card:get_id()
		if id and id >= 2 and id <= 14 then
			return id
		end
	end

	if card.base and card.base.id then
		return card.base.id
	end

	return nil
end

local function trgu_cerac_corrupt_card(playing_card)
	local corrupted_center = trgu_find_corrupted_enhancement()

	if not corrupted_center then
		print("Cerac: Corrupted enhancement not found")
		return false
	end

	playing_card:set_ability(corrupted_center, nil, false)

	if playing_card.children and playing_card.children.front then
		playing_card.children.front:remove()
		playing_card.children.front = nil
	end

	playing_card:set_sprites(playing_card.config.center)
	playing_card:juice_up()

	return true
end

SMODS.Atlas {
	key = "cerac",
	path = "Cerac.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'cerac',
	loc_txt = {
		['en-us'] = {
			name = 'Rehtaf Aruof',
			text = {
				"Before scoring, increases",
				"the first scoring card's",
				"rank by {C:attention}1{} or {C:attention}2{}"
			}
		},
		ru = {
			name = 'Церац Аруф',
			text = {
				"Перед подсчётом повышает",
				"значение первой подсчитываемой",
				"карты на {C:attention}1{} или {C:attention}2{}"
			}
		}
	},

	rarity = 3,
	atlas = 'cerac',
	pos = { x = 0, y = 0 },
	cost = 7,

	calculate = function(self, card, context)
	if context.before and context.scoring_hand and not context.blueprint then
		local target = context.scoring_hand[1]
		if not target then return end

		local rank_id = trgu_cerac_get_rank_id(target)
		if not rank_id then
			return {
				message = localize('trgu_oops'),
				colour = G.C.RED
			}
		end

		local increase = math.floor(pseudorandom('cerac_increase_' .. tostring(card.ID or '')) * 2) + 1
		local new_rank_id = rank_id + increase

		if new_rank_id > 14 then
			trgu_cerac_corrupt_card(target)

			return {
				message = localize('trgu_oops'),
				colour = G.C.RED
			}
		else
			local new_rank = trgu_cerac_rank_by_id[new_rank_id]
			local changed, err = SMODS.change_base(target, nil, new_rank, true)

			if changed then
				target:set_sprites(nil, target.config.card)
				target:juice_up()
			else
				print("Cerac failed: " .. tostring(err))
			end

			return {
				message = localize{
					type = 'variable',
					key = 'trgu_rank_up',
					vars = { increase }
				},
				colour = G.C.GREEN
			}
		end
	end
end
}

-- УТКА ОМОН ДЖОКЕР
SMODS.Atlas {
	key = "omonduck",
	path = "OmonDuck.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'omonduck',
	loc_txt = {
		['en-us'] = {
			name = 'Omon Duck',
			text = {
				"{C:chips}+#1#{} Chips",
				"if you have an",
				"empty {C:attention}Joker{} slot"
			}
		},
		ru = {
			name = 'Утка ОМОН',
			text = {
				"{C:chips}+#1#{} фишек",
				"если у вас есть",
				"свободный слот {C:attention}джокера{}"
			}
		}
	},
	config = {
		extra = {
			chips = 65
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.chips
			}
		}
	end,

	rarity = 1,
	atlas = 'omonduck',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main then
			if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
				return {
					chips = card.ability.extra.chips
				}
			end
		end
	end
}

-- FFF ДЖОКЕР
SMODS.Atlas {
	key = "fffjoker",
	path = "FFF.png",
	px = 71,
	py = 95
}

local function trgu_fff_roll_role(seed)
	if pseudorandom(seed) < 0.5 then
		return {
			name = localize('trgu_liberal'),
			colour = G.C.CHIPS,
			chips = true
		}
	else
		return {
			name = localize('trgu_fascist'),
			colour = G.C.MULT,
			mult = true
		}
	end
end

SMODS.Joker {
	key = 'fffjoker',
	loc_txt = {
		['en-us'] = {
			name = 'FFF Joker',
			text = {
				"Reveal {C:attention}3{} roles",
				"Each {C:chips}Liberal{} gives {C:chips}+#1#{} Chips",
				"Each {C:mult}Fascist{} gives {C:mult}+#2#{} Mult"
			}
		},
		ru = {
			name = 'FFF Джокер',
			text = {
				"Открывает {C:attention}3{} роли",
				"Каждый {C:chips}Либерал{} даёт {C:chips}+#1#{} фишек",
				"Каждый {C:mult}Фашист{} даёт {C:mult}+#2#{} множ."
			}
		}
	},
	config = {
		extra = {
			chips = 10,
			mult = 4,
			triggers_this_hand = 0
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.chips,
				card.ability.extra.mult
			}
		}
	end,

	rarity = 1,
	atlas = 'fffjoker',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.before and not context.blueprint then
			card.ability.extra.triggers_this_hand = 0
		end

		if context.joker_main then
			card.ability.extra.triggers_this_hand = card.ability.extra.triggers_this_hand + 1

			local trigger_number = card.ability.extra.triggers_this_hand

			local role = trgu_fff_roll_role(
				'fffjoker_role_'
				.. tostring(card.ID or '')
				.. '_'
				.. tostring(G.GAME.hands_played or 0)
				.. '_'
				.. tostring(trigger_number)
			)

			if role.chips then
				return {
					message = role.name,
					colour = role.colour,
					chips = card.ability.extra.chips
				}
			else
				return {
					message = role.name,
					colour = role.colour,
					mult = card.ability.extra.mult
				}
			end
		end

		if context.retrigger_joker_check
			and context.other_card == card
			and context.other_context
			and context.other_context.joker_main
			and not context.other_context.retrigger_joker
		then
			return {
				repetitions = 2,
				remove_default_message = true
			}
		end
	end
}

-- МАРКОЙ ДЖОКЕР
SMODS.Atlas {
	key = "markoi",
	path = "Markoi.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'markoi',
	loc_txt = {
		['en-us'] = {
			name = 'Markoi',
			text = {
				"Freezes for {C:attention}1{} to {C:attention}6{} seconds",
				"then gives {C:chips}+10{} to {C:chips}+60{} Chips"
			}
		},
		ru = {
			name = 'Маркой',
			text = {
				"Замораживает игру",
				"на {C:attention}1{}–{C:attention}6{} секунд",
				"затем даёт",
				"от {C:chips}+10{} до {C:chips}+60{} фишек"
			}
		}
	},
	config = {
		extra = {
			min_delay = 1,
			max_delay = 6,
			chips_per_second = 10
		}
	},

	rarity = 1,
	atlas = 'markoi',
	pos = { x = 0, y = 0 },
	cost = 4,

	calculate = function(self, card, context)
		if context.joker_main then
			local roll = math.floor(
				pseudorandom('markoi_delay_' .. tostring(card.ID or '')) * 6
			) + 1

			local game_speed = 1

			if G.SETTINGS and G.SETTINGS.GAMESPEED then
				game_speed = G.SETTINGS.GAMESPEED
			end

			return {
				chips = roll * card.ability.extra.chips_per_second,
				message = "..." .. roll .. "s",
				colour = G.C.CHIPS,
				delay = roll * game_speed
			}
		end
	end
}

-- БИНГО ДЖОКЕР
SMODS.Atlas {
	key = "bingo",
	path = "Bingo.png",
	px = 71,
	py = 95
}

local function trgu_bingo_get_rarity(joker)
	if not joker or not joker.config or not joker.config.center then return nil end

	local rarity = joker.config.center.rarity

	if rarity == "Common" then return 1 end
	if rarity == "Uncommon" then return 2 end
	if rarity == "Rare" then return 3 end
	if rarity == "Legendary" then return 4 end

	return rarity
end

local function trgu_bingo_rarity_name(rarity)
	if rarity == 1 then return "Common" end
	if rarity == 2 then return "Uncommon" end
	if rarity == 3 then return "Rare" end
	if rarity == 4 then return "Legendary" end
	return "Unknown"
end

local function trgu_bingo_get_best_chain()
	if not G.jokers or not G.jokers.cards then
		return {
			rarity = nil,
			count = 0,
			active = false
		}
	end

	local best_rarity = nil
	local best_count = 0

	local current_rarity = nil
	local current_count = 0

	for _, joker in ipairs(G.jokers.cards) do
		local rarity = trgu_bingo_get_rarity(joker)

		if rarity and rarity == current_rarity then
			current_count = current_count + 1
		else
			current_rarity = rarity
			current_count = rarity and 1 or 0
		end

		if current_count > best_count then
			best_count = current_count
			best_rarity = current_rarity
		end
	end

	return {
		rarity = best_rarity,
		count = best_count,
		active = best_count >= 4
	}
end

SMODS.Joker {
	key = 'bingo',
	loc_txt = {
		['en-us'] = {
			name = 'Bingo',
			text = {
				"{X:mult,C:white} X#1# {} Mult",
				"if there is a chain",
				"of {C:attention}4{} adjacent Jokers",
				"with the same {C:attention}rarity{}",
				"{C:inactive}(Currently: {C:attention}#2#{C:inactive} x#3#)"
			}
		},
		ru = {
			name = 'Бинго',
			text = {
				"{X:mult,C:white} X#1# {} множ.",
				"если есть цепочка",
				"из {C:attention}4{} соседних джокеров",
				"одной {C:attention}редкости{}",
				"{C:inactive}(Сейчас: {C:attention}#2#{C:inactive} x#3#)"
			}
		}
	},
	config = {
		extra = {
			Xmult = 3
		}
	},

	loc_vars = function(self, info_queue, card)
		local chain = trgu_bingo_get_best_chain()

		return {
			vars = {
				card.ability.extra.Xmult,
				trgu_bingo_rarity_name(chain.rarity),
				chain.count
			}
		}
	end,

	rarity = 3,
	atlas = 'bingo',
	pos = { x = 0, y = 0 },
	cost = 8,

	calculate = function(self, card, context)
		if context.joker_main then
			local chain = trgu_bingo_get_best_chain()

			if chain.active then
				return {
					xmult = card.ability.extra.Xmult
				}
			end
		end
	end
}

-- ЖУНИПЕР БОТ ДЖОКЕР
SMODS.Atlas {
	key = "juniperbot",
	path = "JuniperBot.png",
	px = 71,
	py = 95
}

local function trgu_juniper_breaks_rules(context)
	local full_hand = context.full_hand or {}

	local has_face = false
	local has_spade = false
	local has_ace = false

	for _, playing_card in ipairs(full_hand) do
		if playing_card:is_face() then
			has_face = true
		end

		if playing_card:is_suit('Spades') then
			has_spade = true
		end

		if trgu_rank_id(playing_card) == 14 then
			has_ace = true
		end
	end

	local has_pair = context.poker_hands
		and context.poker_hands['Pair']
		and next(context.poker_hands['Pair'])

	if has_face then return true end
	if has_spade then return true end
	if #full_hand <= 3 then return true end
	if not has_ace then return true end
	if has_pair then return true end

	return false
end

SMODS.Joker {
	key = 'juniperbot',
	loc_txt = {
		['en-us'] = {
			name = 'JuniperBot',
			text = {
				"Gives {C:mult}+#1#{} Mult, unless",
				"your hand breaks server rules",
				"{C:attention}Server Rules:{}",
				"1. No face cards",
				"2. No Spades",
				"3. >3 cards played",
				"4. Must contain an Ace",
				"5. No Pair",
				"{C:inactive}(Currently: #2#/#3# warns)"
			}
		},
		ru = {
			name = 'JuniperBot',
			text = {
				"Даёт {C:mult}+#1#{} множ., если",
				"рука не нарушает правила сервера",
				"{C:attention}Правила сервера:{}",
				"1. Без карт с лицом",
				"2. Без пиковых",
				"3. Сыграно >3 карт",
				"4. Присутствует туз",
				"5. Без пары",
				"{C:inactive}(Сейчас: #2#/#3# предов)"
			}
		}
	},
	config = {
		extra = {
			mult = 20,
			warns = 0,
			max_warns = 5
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				card.ability.extra.warns,
				card.ability.extra.max_warns
			}
		}
	end,

	rarity = 2,
	atlas = 'juniperbot',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.joker_main then
			if trgu_juniper_breaks_rules(context) then
				card.ability.extra.warns = card.ability.extra.warns + 1

				if card.ability.extra.warns >= card.ability.extra.max_warns then
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.2,
						func = function()
							SMODS.destroy_cards(card, false, false, true)
							return true
						end
					}))

					return {
						message = localize('trgu_ban'),
						colour = G.C.RED
					}
				end

				return {
					message = localize('trgu_warn'),
					colour = G.C.RED
				}
			end

			return {
				mult = card.ability.extra.mult
			}
		end
	end
}

-- ГУГЛ ТРАНСЛЕЙТ ДЖОКЕР
SMODS.Atlas {
	key = "googletranslate",
	path = "GoogleTranslate.png",
	px = 71,
	py = 95
}

local function trgu_count_words(text)
	local count = 0

	for _ in tostring(text or ""):gmatch("%S+") do
		count = count + 1
	end

	return count
end

SMODS.Joker {
	key = 'googletranslate',
	loc_txt = {
		['en-us'] = {
			name = 'Google Translate',
			text = {
				"Gives {C:mult}+#1#{} Mult",
				"for each word in",
				"played hand name",
				"{C:inactive}(Currently: {C:mult}+#2#{C:inactive} Mult)"
			}
		},
		ru = {
			name = 'Google Переводчик',
			text = {
				"Даёт {C:mult}+#1#{} множ.",
				"за каждое слово в",
				"названии сыгранной руки",
				"{C:inactive}(Сейчас: {C:mult}+#2#{C:inactive} множ.)"
			}
		}
	},
	config = {
		extra = {
			mult_per_word = 8
		}
	},

	loc_vars = function(self, info_queue, card)
		local hand_name = G.GAME and G.GAME.current_round and G.GAME.current_round.current_hand and G.GAME.current_round.current_hand.handname
		local words = trgu_count_words(hand_name)
		local current = words * card.ability.extra.mult_per_word

		return {
			vars = {
				card.ability.extra.mult_per_word,
				current
			}
		}
	end,

	rarity = 1,
	atlas = 'googletranslate',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main then
			local hand_name = context.scoring_name or ""
			local words = trgu_count_words(hand_name)
			local mult = words * card.ability.extra.mult_per_word

			if mult > 0 then
				return {
					mult = mult
				}
			end
		end
	end
}

-- БЮСТ ЛЕНИНА ДЖОКЕР
SMODS.Atlas {
	key = "leninbust",
	path = "LeninBust.png",
	px = 71,
	py = 95
}

local function trgu_full_hand_rank_signature(full_hand)
	if not full_hand then return "" end

	local ranks = {}

	for _, playing_card in ipairs(full_hand) do
		local id = trgu_rank_id(playing_card)

		if id then
			ranks[#ranks + 1] = tostring(id)
		end
	end

	table.sort(ranks)

	return table.concat(ranks, "-")
end

local function trgu_rank_display_name(id)
	if id == 11 then return "J" end
	if id == 12 then return "Q" end
	if id == 13 then return "K" end
	if id == 14 then return "A" end
	return tostring(id or "?")
end

local function trgu_full_hand_rank_display_signature(full_hand)
	if not full_hand then return "None" end

	local ranks = {}

	for _, playing_card in ipairs(full_hand) do
		local id = trgu_rank_id(playing_card)

		if id then
			ranks[#ranks + 1] = id
		end
	end

	table.sort(ranks)

	local display = {}

	for _, id in ipairs(ranks) do
		display[#display + 1] = trgu_rank_display_name(id)
	end

	if #display <= 0 then
		return "None"
	end

	return table.concat(display, ", ")
end

SMODS.Joker {
	key = 'leninbust',
	loc_txt = {
		['en-us'] = {
			name = 'Lenin Bust',
			text = {
				"First hand of each blind",
				"remembers played ranks",
				"Later matching rank",
				"combination gives",
				"{X:mult,C:white} X#1# {} Mult",
				"{C:inactive}(Remembered: #2#)"
			}
		},
		ru = {
			name = 'Бюст Ленина',
			text = {
				"Первая рука каждого блайнда",
				"запоминает значения карт",
				"Повтор той же комбинации",
				"значений даёт",
				"{X:mult,C:white} X#1# {} множ.",
				"{C:inactive}(Запомнено: #2#)"
			}
		}
	},
	config = {
		extra = {
			Xmult = 3.5,
			remembered_signature = nil,
			remembered_display = nil,
			hands_seen_this_blind = 0,
			blind_id = nil
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.Xmult,
				card.ability.extra.remembered_display or "None"
			}
		}
	end,

	rarity = 2,
	atlas = 'leninbust',
	pos = { x = 0, y = 0 },
	cost = 7,

	calculate = function(self, card, context)
		if context.before and not context.blueprint then
			local current_blind_id = G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante
			current_blind_id = tostring(current_blind_id or "") .. "_" .. tostring(G.GAME and G.GAME.blind and G.GAME.blind.name or "")

			if card.ability.extra.blind_id ~= current_blind_id then
				card.ability.extra.blind_id = current_blind_id
				card.ability.extra.hands_seen_this_blind = 0
				card.ability.extra.remembered_signature = nil
				card.ability.extra.remembered_display = nil
			end

			card.ability.extra.hands_seen_this_blind = card.ability.extra.hands_seen_this_blind + 1

			if card.ability.extra.hands_seen_this_blind == 1 then
				card.ability.extra.remembered_signature = trgu_full_hand_rank_signature(context.full_hand)
				card.ability.extra.remembered_display = trgu_full_hand_rank_display_signature(context.full_hand)

				return {
					message = "Remembered",
					colour = G.C.FILTER
				}
			end
		end

		if context.joker_main then
			if card.ability.extra.hands_seen_this_blind <= 1 then
				return
			end

			local current_signature = trgu_full_hand_rank_signature(context.full_hand)

			if card.ability.extra.remembered_signature
				and current_signature == card.ability.extra.remembered_signature
			then
				return {
					xmult = card.ability.extra.Xmult
				}
			end
		end
	end
}

-- АЛЖИРСКОЕ ТЕРПЕНИЕ ДЖОКЕР
SMODS.Atlas {
	key = "algerianpatience",
	path = "AlgerianPatience.png",
	px = 71,
	py = 95
}

local function trgu_algerian_is_ordered_house(full_hand)
	if not full_hand or #full_hand ~= 5 then return false end

	local r1 = trgu_rank_id(full_hand[1])
	local r2 = trgu_rank_id(full_hand[2])
	local r3 = trgu_rank_id(full_hand[3])
	local r4 = trgu_rank_id(full_hand[4])
	local r5 = trgu_rank_id(full_hand[5])

	return r1
		and r2
		and r1 ~= r2
		and r1 == r3
		and r1 == r5
		and r2 == r4
end

SMODS.Joker {
	key = 'algerianpatience',
	loc_txt = {
		['en-us'] = {
			name = 'Algerian Patience',
			text = {
				"If {C:attention}Full House{}",
				"is played in order {C:attention}1,2,1,2,1{},",
				"gives {C:mult}+Mult{} equal to",
				"the first and second cards' ranks"
			}
		},
		ru = {
			name = 'Алжирское терпение',
			text = {
				"Если {C:attention}Фулл-хаус{} сыгран",
				"в порядке чередования ({C:attention}1,2,1,2,1{}),",
				"даёт {C:mult}+множ.{} равный сумме",
				"значений первой и второй карты"
			}
		}
	},

	rarity = 1,
	atlas = 'algerianpatience',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.joker_main then
			local is_full_house = context.poker_hands
				and context.poker_hands['Full House']
				and next(context.poker_hands['Full House'])

			if is_full_house and trgu_algerian_is_ordered_house(context.full_hand) then
				local mult = trgu_rank_mult_value(context.full_hand[1])
					+ trgu_rank_mult_value(context.full_hand[2])

				return {
					mult = mult,
					message = localize('trgu_house'),
					colour = G.C.MULT
				}
			end
		end
	end
}

-- КУБИКИ УПАЛИ ДЖОКЕР
SMODS.Atlas {
	key = "fallendices",
	path = "FallenDices.png",
	px = 71,
	py = 95
}

local function trgu_fallen_dices_random_roll(seed)
	return math.floor(pseudorandom(seed) * 6) + 1
end

SMODS.Joker {
	key = 'fallendices',
	loc_txt = {
		['en-us'] = {
			name = 'Fallen Dice',
			text = {
				"Rolls a die when scored",
				"{C:attention}1{}: Nothing",
				"{C:attention}2{}: {C:mult}+#1#{} Mult",
				"{C:attention}3{}: {C:chips}+#2#{} Chips",
				"{C:attention}4{}: {X:mult,C:white} X#3# {} Mult",
				"{C:attention}5{}: {C:money}+$#4#{}",
				"{C:attention}6{}: All of the above",
				"{C:inactive}(Last roll: #5#)"
			}
		},
		ru = {
			name = 'Кубики упали',
			text = {
				"Бросает кубик при подсчёте",
				"{C:attention}1{}: ничего",
				"{C:attention}2{}: {C:mult}+#1#{} множ.",
				"{C:attention}3{}: {C:chips}+#2#{} фишек",
				"{C:attention}4{}: {X:mult,C:white} X#3# {} множ.",
				"{C:attention}5{}: {C:money}+$#4#{}",
				"{C:attention}6{}: всё перечисленное",
				"{C:inactive}(Последний бросок: #5#)"
			}
		}
	},

	config = {
		extra = {
			mult = 5,
			chips = 15,
			xmult = 1.5,
			dollars = 3,
			last_roll = 0
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				card.ability.extra.chips,
				card.ability.extra.xmult,
				card.ability.extra.dollars,
				card.ability.extra.last_roll
			}
		}
	end,

	rarity = 1,
	atlas = 'fallendices',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.before and not context.blueprint then
			local roll = trgu_fallen_dices_random_roll(
				'fallen_dices_roll_' ..
				tostring(card.ID or '') ..
				'_' ..
				tostring(G.GAME.hands_played or 0)
			)

			card.ability.extra.last_roll = roll

		return {
			message = localize({
				type = 'variable',
				key = 'trgu_roll',
				vars = { roll }
			}),
			colour = roll == 1 and G.C.RED or G.C.GOLD
		}
		end

		if context.joker_main then
			local roll = card.ability.extra.last_roll or 1

			if roll == 1 then
				return {
					message = localize('trgu_nothing'),
					colour = G.C.RED
				}
			elseif roll == 2 then
				return {
					mult = card.ability.extra.mult
				}
			elseif roll == 3 then
				return {
					chips = card.ability.extra.chips
				}
			elseif roll == 4 then
				return {
					xmult = card.ability.extra.xmult
				}
			elseif roll == 5 then
				return {
					dollars = card.ability.extra.dollars
				}
			else
				return {
					mult = card.ability.extra.mult,
					chips = card.ability.extra.chips,
					xmult = card.ability.extra.xmult,
					dollars = card.ability.extra.dollars,
					message = localize('trgu_all'),
					colour = G.C.GOLD
				}
			end
		end
	end
}

-- МИРКОЙ АДВОКАТ ДЖОКЕР
local function trgu_is_mirkoi_lawyer(card)
	if not card or not card.config or not card.config.center then return false end

	local center = card.config.center
	local key = tostring(center.key or "")
	local original_key = tostring(center.original_key or "")

	return original_key == 'mirkoilawyer'
		or key == 'mirkoilawyer'
		or key:sub(-12) == 'mirkoilawyer'
end

local function trgu_is_owned_joker_card(card)
	return card
		and card.config
		and card.config.center
		and card.config.center.set == 'Joker'
		and G
		and G.jokers
		and (
			card.area == G.jokers
			or card.parent == G.jokers
		)
end

local function trgu_joker_display_name(center)
    if not center then return "None" end

    if center.key and localize then
        local ok, localized_name = pcall(function()
            return localize({
                type = 'name_text',
                set = center.set or 'Joker',
                key = center.key
            })
        end)

        if ok
            and type(localized_name) == 'string'
            and localized_name ~= ''
            and localized_name ~= center.key
        then
            return localized_name
        end
    end

    -- Запасной способ для loc_txt
    if center.loc_txt then
        local language =
            G
            and G.SETTINGS
            and G.SETTINGS.language
            or 'en-us'

        local language_loc =
            center.loc_txt[language]
            or center.loc_txt.ru
            or center.loc_txt['en-us']

        if type(language_loc) == 'table' and language_loc.name then
            return language_loc.name
        end
    end

    return center.name or center.key or "Unknown"
end

local function trgu_remember_last_lost_joker(card)
	if not G or not G.GAME then return end
	if not trgu_is_owned_joker_card(card) then return end
	if trgu_is_mirkoi_lawyer(card) then return end

	local center = card.config.center
	if not center or not center.key then return end

	G.GAME.trgu_last_lost_joker_key = center.key
	G.GAME.trgu_last_lost_joker_name = trgu_joker_display_name(center)
end

local function trgu_lawyer_current_name()
    if not G or not G.GAME then return "None" end

    local key = G.GAME.trgu_last_lost_joker_key

    if key and G.P_CENTERS and G.P_CENTERS[key] then
        return trgu_joker_display_name(G.P_CENTERS[key])
    end

    return "None"
end

local function trgu_lawyer_can_resurrect()
	return G
		and G.GAME
		and G.GAME.trgu_last_lost_joker_key
		and G.P_CENTERS
		and G.P_CENTERS[G.GAME.trgu_last_lost_joker_key]
		and G.jokers
		and #G.jokers.cards < G.jokers.config.card_limit
end

local function trgu_lawyer_resurrect_last()
	if not trgu_lawyer_can_resurrect() then return false end

	local key = G.GAME.trgu_last_lost_joker_key

	local returned = SMODS.add_card({
		set = 'Joker',
		area = G.jokers,
		key = key,
		allow_duplicates = true,
		key_append = 'mirkoi_lawyer'
	})

	if returned then
		returned:juice_up()
		return true
	end

	return false
end

if not TRGU.mirkoi_lawyer_hooks then
	TRGU.mirkoi_lawyer_hooks = true

	if Card.start_dissolve then
		local trgu_card_start_dissolve_ref = Card.start_dissolve

		function Card:start_dissolve(dissolve_colours, silent, dissolve_time_fac, no_juice)
			trgu_remember_last_lost_joker(self)

			return trgu_card_start_dissolve_ref(
				self,
				dissolve_colours,
				silent,
				dissolve_time_fac,
				no_juice
			)
		end
	end

	local trgu_card_remove_ref = Card.remove
	function Card:remove()
		trgu_remember_last_lost_joker(self)
		return trgu_card_remove_ref(self)
	end

	if Card.sell_card then
		local trgu_card_sell_ref = Card.sell_card

		function Card:sell_card()
			local is_lawyer = trgu_is_mirkoi_lawyer(self)

			if not is_lawyer then
				trgu_remember_last_lost_joker(self)
			end

			local ret = trgu_card_sell_ref(self)

			if is_lawyer then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.2,
					func = function()
						local resurrected = trgu_lawyer_resurrect_last()

						if resurrected then
							attention_text({
								text = localize('trgu_objection'),
								scale = 1,
								hold = 1,
								major = G.play,
								backdrop_colour = G.C.FILTER,
								align = 'cm',
								offset = { x = 0, y = -2.7 }
							})
						end

						return true
					end
				}))
			end

			return ret
		end
	end
end

SMODS.Atlas {
	key = "mirkoilawyer",
	path = "MirkoiLawyer.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'mirkoilawyer',
	loc_txt = {
		['en-us'] = {
			name = 'Mirkoi Lawyer',
			text = {
				"When sold, returns",
				"the last {C:attention}sold{} or",
				"{C:red}destroyed{} Joker",
				"{C:inactive}(Currently: {C:attention}#1#{C:inactive})",
				"{C:inactive}(Must have room and no copy)"
			}
		},
		ru = {
			name = 'Адвокат Миркой',
			text = {
				"При продаже возвращает",
				"последнего {C:attention}проданного{} или",
				"{C:red}уничтоженного{} джокера",
				"{C:inactive}(Сейчас: {C:attention}#1#{C:inactive})",
				"{C:inactive}(Нужен слот и отсутствие копии)"
			}
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				trgu_lawyer_current_name()
			}
		}
	end,

	rarity = 2,
	atlas = 'mirkoilawyer',
	pos = { x = 0, y = 0 },
	cost = 7
}

-- АЛМАЗНАЯ РУДА ДЖОКЕР
SMODS.Atlas {
	key = "diamondore",
	path = "DiamondOre.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'diamondore',
	loc_txt = {
		['en-us'] = {
			name = 'Diamond Ore',
			text = {
				"Retrigger scored",
				"{C:diamonds}Diamond{} cards",
				"Cards left: {C:attention}#1#{}"
			}
		},
		ru = {
			name = 'Бубновая руда',
			text = {
				"Повторно срабатывают",
				"подсчитываемые {C:diamonds}бубновые{} карты",
				"Карт осталось: {C:attention}#1#{}"
			}
		}
	},
	config = {
		extra = {
			uses = 15
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.uses
			}
		}
	end,

	rarity = 1,
	atlas = 'diamondore',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.repetition
			and context.cardarea == G.play
			and context.other_card
			and context.other_card:is_suit('Diamonds')
			and card.ability.extra.uses > 0
		then
			if not context.blueprint then
				card.ability.extra.uses = card.ability.extra.uses - 1
			end

			if card.ability.extra.uses <= 0 and not context.blueprint then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.2,
					func = function()
						SMODS.destroy_cards(card, false, false, true)
						return true
					end
				}))
			end

			return {
				repetitions = 1,
				card = context.other_card,
				message = card.ability.extra.uses <= 0 and localize('trgu_last_one') or localize('trgu_again')
			}
		end
	end
}

-- НУРЛАН САБУРОВ ДЖОКЕР
SMODS.Atlas {
	key = "burlannaburov",
	path = "BurlanNaburov.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'burlannaburov',
	loc_txt = {
		['en-us'] = {
			name = 'Burlan Naburov',
			text = {
				"When an {C:purple}Admin{} card",
				"is used, {C:green}#1#%{} chance",
				"to create a {C:dark_edition}Negative{}",
				"copy in inventory",
				"{C:inactive}(Chance is fixed and",
				"{C:inactive}cannot be increased)"
			}
		},
		ru = {
			name = 'Бурлан Набуров',
			text = {
				"Когда используется {C:purple}админская{} карта,",
				"{C:green}#1#%{} шанс создать",
				"{C:dark_edition}негативную{} копию",
				"в инвентаре",
				"{C:inactive}(Шанс фиксированный и",
				"{C:inactive}не может быть увеличен)"
			}
		}
	},
	config = {
		extra = {
			chance = 10
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.chance
			}
		}
	end,

	rarity = 3,
	atlas = 'burlannaburov',
	pos = { x = 0, y = 0 },
	cost = 8,

	calculate = function(self, card, context)
		if context.using_consumeable
			and context.consumeable
			and context.consumeable.config
			and context.consumeable.config.center
			and context.consumeable.config.center.set == 'Admin'
			and not context.blueprint
		then
			if pseudorandom('burlan_admin_copy') < (card.ability.extra.chance / 100) then
				local admin_copy = copy_card(context.consumeable, nil)

				if admin_copy then
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.2,
						func = function()
							admin_copy:set_edition('e_negative', true)
							admin_copy:add_to_deck()
							G.consumeables:emplace(admin_copy)
							admin_copy:juice_up()

							return true
						end
					}))
				end

				return {
					message = localize('trgu_negative'),
					colour = G.C.DARK_EDITION
				}
			end
		end
	end
}

-- КРАСНЫЙ БАНАН
SMODS.Atlas {
	key = "redbanana",
	path = "RedBanana.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'redbananajoker',
	loc_txt = {
		['en-us'] = {
			name = 'Red Banana',
			text = {
				"{X:mult,C:white} X#1# {} Mult",
				"{C:green}#2# in #3#{} chance this",
				"card is destroyed",
				"at end of round"
			}
		},
		ru = {
			name = 'Красный банан',
			text = {
				"{X:mult,C:white} X#1# {} множ.",
				"{C:green}#2# из #3#{} шанс, что эта",
				"карта уничтожится",
				"в конце раунда"
			}
		}
	},

	yes_pool_flag = 'ripe_banana_extinct',

	config = {
		extra = {
			Xmult = 2.5,
			odds = 1500
		}
	},

	rarity = 1,
	atlas = 'redbanana',
	pos = { x = 0, y = 0 },
	cost = 6,
	eternal_compat = false,

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'redbananajoker'
		)

		return {
			vars = {
				card.ability.extra.Xmult,
				numerator,
				denominator
			}
		}
	end,

	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.Xmult
			}
		end

		if context.end_of_round
			and context.main_eval
			and context.game_over == false
			and not context.blueprint
		then
			if SMODS.pseudorandom_probability(
				card,
				'redbananajoker',
				1,
				card.ability.extra.odds
			) then
				SMODS.destroy_cards(card, nil, nil, true)

				return {
					message = localize('trgu_extinct')
				}
			else
				return {
					message = localize('trgu_safe')
				}
			end
		end
	end
}


-- Промежуточные функции для следующих джокеров
TRGU.u_joker_handlers = TRGU.u_joker_handlers or {}

local function trgu_joker_matches_key(card, short_key)
	local center = card and card.config and card.config.center
	if not center then return false end

	local key = tostring(center.key or "")
	local original_key = tostring(center.original_key or "")

	return key == short_key
		or original_key == short_key
		or key:sub(-#short_key) == short_key
		or original_key:sub(-#short_key) == short_key
end

local function trgu_get_selected_joker()
	if G.jokers and G.jokers.highlighted and #G.jokers.highlighted == 1 then
		return G.jokers.highlighted[1]
	end
end

local function trgu_handle_u_joker_press()
	local selected = trgu_get_selected_joker()
	if not selected then return end

	for short_key, handler in pairs(TRGU.u_joker_handlers) do
		if trgu_joker_matches_key(selected, short_key) then
			handler(selected)
			return
		end
	end
end

if not TRGU.u_key_hooked then
	TRGU.u_key_hooked = true
	TRGU.u_key_down = false
	TRGU.u_key_game_update_ref = Game.update

	function Game:update(dt)
		TRGU.u_key_game_update_ref(self, dt)

		local down = love.keyboard.isDown('u')

		if down and not TRGU.u_key_down then
			trgu_handle_u_joker_press()
		end

		TRGU.u_key_down = down
	end
end

local function trgu_card_has_edition(card)
	return card and card.edition and type(card.edition) == 'table' and next(card.edition) ~= nil
end

local function trgu_round_to_tens(value)
	value = tonumber(value) or 0
	return math.floor((value + 5) / 10) * 10
end

local function trgu_shuffle_joker_area(seed)
	if not G.jokers or not G.jokers.cards then return end

	local cards = G.jokers.cards

	for i = #cards, 2, -1 do
		local j = math.floor(pseudorandom(seed .. '_' .. tostring(i)) * i) + 1
		cards[i], cards[j] = cards[j], cards[i]
	end

	if G.jokers.align_cards then
		G.jokers:align_cards()
	end
end

local function trgu_get_joker_index(card)
	if not G.jokers or not G.jokers.cards then return nil end

	for i, joker in ipairs(G.jokers.cards) do
		if joker == card then
			return i
		end
	end
end

local function trgu_random_from(list, seed)
	if not list or #list <= 0 then return nil end
	local index = math.floor(pseudorandom(seed) * #list) + 1
	return list[index]
end

local function trgu_card_enhancement_key(card)
	local center = card and card.config and card.config.center
	local key = center and center.key

	if type(key) == 'string' and key:sub(1, 2) == 'm_' then
		return key
	end

	return nil
end

local function trgu_copy_edition_value(card)
	local edition = card and card.edition
	if not edition then return nil end

	if edition.key then return edition.key end
	if edition.foil then return { foil = true } end
	if edition.holo then return { holo = true } end
	if edition.polychrome then return { polychrome = true } end
	if edition.negative then return 'e_negative' end

	return nil
end

local function trgu_pick_property(a, b, seed)
	if a and b then
		return pseudorandom(seed) < 0.5 and a or b
	end

	return a or b
end

-- ГОЛОСУЙ ЗА 2 ДЖОКЕР
SMODS.Atlas {
	key = "votefor2",
	path = "VoteFor2.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'votefor2',
	loc_txt = {
		['en-us'] = {
			name = 'Vote for 2',
			text = {
				"{X:mult,C:white} X#1# {} Mult",
				"if current {C:mult}Mult{}",
				"ends with an {C:attention}odd{} number"
			}
		},
		ru = {
			name = 'Голосуй за 2',
			text = {
				"{X:mult,C:white} X#1# {} множ.",
				"если текущий {C:mult}множ.{}",
				"заканчивается на {C:attention}нечётное{} число"
			}
		}
	},
	config = {
		extra = {
			xmult = 2
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.xmult
			}
		}
	end,

	rarity = 1,
	atlas = 'votefor2',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.joker_main then
			local current_mult = math.floor(tonumber(mult) or 0)

			if current_mult % 2 == 1 then
				return {
					xmult = card.ability.extra.xmult
				}
			end
		end
	end
}

-- ТЕФТЕЛЯ ДЖОКЕР
SMODS.Atlas {
	key = "teftelya",
	path = "Teftelya.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'teftelya',
	loc_txt = {
		['en-us'] = {
			name = 'Meatball',
			text = {
				"{X:mult,C:white} X#1# {} Mult",
				"Before each hand,",
				"randomly rearranges",
				"your {C:attention}Jokers{}"
			}
		},
		ru = {
			name = 'Тефтеля',
			text = {
				"{X:mult,C:white} X#1# {} множ.",
				"Перед каждой рукой",
				"случайно перемешивает",
				"ваших {C:attention}джокеров{}"
			}
		}
	},
	config = {
		extra = {
			xmult = 1.5,
			last_shuffle_hand = -1
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.xmult
			}
		}
	end,

	rarity = 1,
	atlas = 'teftelya',
	pos = { x = 0, y = 0 },
	cost = 7,

	calculate = function(self, card, context)
		if context.before and not context.blueprint then
			local hand_id = G.GAME.hands_played or 0

			if card.ability.extra.last_shuffle_hand == hand_id then
				return nil
			end

			card.ability.extra.last_shuffle_hand = hand_id

			trgu_shuffle_joker_area('teftelya_' .. tostring(hand_id))

			return {
				message = localize('trgu_rearrange'),
				colour = G.C.FILTER
			}
		end

		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult
			}
		end
	end
}

-- ТРГУ АВАРД ДЖОКЕР
SMODS.Atlas {
	key = "trguaward",
	path = "TrGuAward1-sheet.png",
	px = 71,
	py = 95,
	atlas_table = "ANIMATION_ATLAS",
	frames = 9,
	fps = 5
}

local function trgu_award_polychrome_neighbors(card)
	if not G.jokers or not G.jokers.cards then return 0 end

	local index = nil

	for i, joker in ipairs(G.jokers.cards) do
		if joker == card then
			index = i
			break
		end
	end

	if not index then return 0 end

	local changed = 0
	local neighbors = {
		G.jokers.cards[index - 1],
		G.jokers.cards[index + 1]
	}

	for _, joker in ipairs(neighbors) do
		if joker and not trgu_card_has_edition(joker) then
			joker:set_edition('e_polychrome', true)
			joker:juice_up()
			changed = changed + 1
		end
	end

	return changed
end

SMODS.Joker {
	key = 'trguaward',
	loc_txt = {
		['en-us'] = {
			name = 'TrGu Award',
			text = {
				"After {C:attention}#2#{} rounds,",
				"sell this Joker to give",
				"{C:dark_edition}Polychrome{} to adjacent",
				"Jokers without Editions",
				"{C:inactive}(Currently: #1#/#2# rounds)"
			}
		},
		ru = {
			name = 'TrGu Награда',
			text = {
				"После {C:attention}#2#{} раундов",
				"продайте этого джокера,",
				"чтобы соседние джокеры",
				"без изданий стали {C:dark_edition}Полихромными{}",
				"{C:inactive}(Сейчас: #1#/#2# раундов)"
			}
		}
	},
	config = {
		extra = {
			rounds = 0,
			needed = 5
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				math.min(card.ability.extra.rounds, card.ability.extra.needed),
				card.ability.extra.needed
			}
		}
	end,

	rarity = 3,
	atlas = 'trguaward',
	pos = { x = 0, y = 0 },
	cost = 8,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.end_of_round and context.main_eval and not context.blueprint then
			card.ability.extra.rounds = math.min(
				card.ability.extra.rounds + 1,
				card.ability.extra.needed
			)

			return {
				message = card.ability.extra.rounds .. "/" .. card.ability.extra.needed,
				colour = G.C.FILTER
			}
		end

		if context.selling_self and not context.blueprint then
			if card.ability.extra.rounds >= card.ability.extra.needed then
				local changed = trgu_award_polychrome_neighbors(card)

				return {
					message = changed > 0 and localize('trgu_award') or localize('trgu_no_target'),
					colour = changed > 0 and G.C.DARK_EDITION or G.C.RED
				}
			end
		end
	end
}

-- СПАСАЛКА ОТ ФРОЗЕНА ДЖОКЕР
SMODS.Atlas {
	key = "frozenrescue",
	path = "FrozenRescue.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'frozenrescue',
	loc_txt = {
		['en-us'] = {
			name = 'Auto-save by mrfrozen',
			text = {
				"At start of Blind,",
				"randomly gain {C:attention}1{} to {C:attention}2{}:",
				"{C:blue}Hands{}, {C:red}Discards{},",
				"or {C:attention}hand size{} this round",
				"{C:inactive}(Currently: {C:attention}#1#{C:inactive})"
			}
		},
		ru = {
			name = 'Спасалка от Фрозена',
			text = {
				"В начале блайнда",
				"случайно даёт от {C:attention}1{} до {C:attention}2{}:",
				"{C:blue}руки{}, {C:red}сбросы{}",
				"или {C:attention}размер руки{} на раунд",
				"{C:inactive}(Сейчас: {C:attention}#1#{C:inactive})"
			}
		}
	},
	config = {
		extra = {
			active_hand_size = 0,
			current_text = "-"
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.current_text or localize('trgu_none')
			}
		}
	end,

	rarity = 1,
	atlas = 'frozenrescue',
	pos = { x = 0, y = 0 },
	cost = 6,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			local amount = math.floor(pseudorandom('frozenrescue_amount') * 2) + 1
			local bonus_type = math.floor(pseudorandom('frozenrescue_type') * 3) + 1

			if bonus_type == 1 then
				ease_hands_played(amount)

				card.ability.extra.current_text = localize{
					type = 'variable',
					key = 'trgu_frozen_hands',
					vars = { amount }
				}

				return {
					message = localize{
					type = 'variable',
					key = 'trgu_frozen_hands',
					vars = { amount }
				},
					colour = G.C.BLUE
				}
			elseif bonus_type == 2 then
				ease_discard(amount)

				card.ability.extra.current_text = localize{
					type = 'variable',
					key = 'trgu_frozen_discards',
					vars = { amount }
				}

				return {
					message = localize{
					type = 'variable',
					key = 'trgu_frozen_discards',
					vars = { amount }
				},
					colour = G.C.RED
				}
			else
				if G.hand and G.hand.change_size then
					G.hand:change_size(amount)
					card.ability.extra.active_hand_size = card.ability.extra.active_hand_size + amount
				end

				card.ability.extra.current_text = localize{
					type = 'variable',
					key = 'trgu_frozen_hand_size',
					vars = { amount }
				}

				return {
					message = localize{
					type = 'variable',
					key = 'trgu_frozen_hand_size',
					vars = { amount }
				},
					colour = G.C.FILTER
				}
			end
		end

		if context.end_of_round and context.main_eval and not context.blueprint then
			if card.ability.extra.active_hand_size ~= 0 then
				if G.hand and G.hand.change_size then
					G.hand:change_size(-card.ability.extra.active_hand_size)
				end

				card.ability.extra.active_hand_size = 0
			end

			card.ability.extra.current_text = localize('trgu_none')
		end
	end,

	remove_from_deck = function(self, card, from_debuff)
		if card.ability and card.ability.extra and card.ability.extra.active_hand_size ~= 0 then
			if G.hand and G.hand.change_size then
				G.hand:change_size(-card.ability.extra.active_hand_size)
			end

			card.ability.extra.active_hand_size = 0
		end

		if card.ability and card.ability.extra then
			card.ability.extra.current_text = localize('trgu_none')
		end
	end
}

-- СМЕХЛЫСТ 3 ДЖОКЕР
SMODS.Atlas {
	key = "smekhlyst3",
	path = "Quiplash3.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'smekhlyst3',
	loc_txt = {
		['en-us'] = {
			name = 'Quiplash 3',
			text = {
				"Retrigger all scored cards",
				"{C:attention}1{} additional time",
				"At final scoring step,",
				"{C:red}-20%{} Chips and Mult"
			}
		},
		ru = {
			name = 'Смехлыст 3',
			text = {
				"Перезапускает все",
				"подсчитанные карты ещё {C:attention}1{} раз",
				"в финальном шаге подсчёта:",
				"{C:red}-20%{} фишек и множ."
			}
		}
	},

	rarity = 3,
	atlas = 'smekhlyst3',
	pos = { x = 0, y = 0 },
	cost = 8,

	calculate = function(self, card, context)
		if context.repetition and context.cardarea == G.play then
			return {
				repetitions = 1,
				message = localize('trgu_again')
			}
		end

		if context.final_scoring_step then
			hand_chips = mod_chips(math.floor((tonumber(hand_chips) or 0) * 0.20))
			mult = mod_mult(math.floor((tonumber(mult) or 0) * 0.20))

			update_hand_text(
				{ delay = 0 },
				{
					chips = hand_chips,
					mult = mult
				}
			)

			return {
				message = "-20%",
				colour = G.C.RED
			}
		end
	end
}

-- КИБЕРБОКС 2077 ДЖОКЕР
SMODS.Atlas {
	key = "cyberbox2077",
	path = "Cyberbox2077.png",
	px = 71,
	py = 95
}

local function trgu_has_exactly_four_real_suits(cards)
	if not cards or #cards ~= 4 then return false end

	local suits = {}

	for _, c in ipairs(cards) do
		local suit = c and c.base and c.base.suit
		if not suit then return false end
		if suits[suit] then return false end

		suits[suit] = true
	end

	return suits.Hearts and suits.Diamonds and suits.Clubs and suits.Spades
end

SMODS.Joker {
	key = 'cyberbox2077',
	loc_txt = {
		['en-us'] = {
			name = 'Cyberbox 2077',
			text = {
				"{X:mult,C:white} X#1# {} Mult",
				"Gains {X:mult,C:white} X#2# {} Mult if",
				"hand of exactly {C:attention}4{} scored cards",
				"contain all {C:attention}4{} suits",
				"{C:inactive}(Ignores Wild Cards)"
			}
		},
		ru = {
			name = 'Кибербокс 2077',
			text = {
				"{X:mult,C:white} X#1# {} множ.",
				"Получает {X:mult,C:white} X#2# {} множ.",
				"если рука из {C:attention}4{} подсчитанных карт",
				"содержит все {C:attention}4{} масти",
				"{C:inactive}(Игнорирует дикие карты)"
			}
		}
	},
	config = {
		extra = {
			xmult = 1.0,
			xmult_gain = 0.25
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.xmult,
				card.ability.extra.xmult_gain
			}
		}
	end,

	rarity = 1,
	atlas = 'cyberbox2077',
	pos = { x = 0, y = 0 },
	cost = 7,

	calculate = function(self, card, context)
		if context.before and not context.blueprint then
			if trgu_has_exactly_four_real_suits(context.scoring_hand or context.full_hand) then
				card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.xmult_gain

				return {
					message = localize('trgu_upgrade'),
					colour = G.C.MULT
				}
			end
		end

		if context.joker_main then
			return {
				xmult = card.ability.extra.xmult
			}
		end
	end
}

-- АНИТА ДЖОКЕР
SMODS.Atlas {
	key = "anitavitek",
	path = "AnitaVitec.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'anitavitek',
	loc_txt = {
		['en-us'] = {
			name = 'AnitaVitec',
			text = {
				"At final scoring step,",
				"rounds {C:chips}Chips{} and",
				"{C:mult}Mult{} to nearest {C:attention}10{}",
				"{C:inactive}(0-4 down, 5-9 up)"
			}
		},
		ru = {
			name = 'АнитаВитёк',
			text = {
				"В финальном шаге подсчёта",
				"округляет {C:chips}фишки{} и {C:mult}множ.{}",
				"до ближайшего {C:attention}десятка{}",
				"{C:inactive}(0-4 вниз, 5-9 вверх)"
			}
		}
	},

	rarity = 1,
	atlas = 'anitavitek',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.final_scoring_step then
			local rounded_chips = trgu_round_to_tens(hand_chips)
			local rounded_mult = trgu_round_to_tens(mult)

			hand_chips = mod_chips(rounded_chips)
			mult = mod_mult(rounded_mult)

			update_hand_text(
				{ delay = 0 },
				{
					chips = hand_chips,
					mult = mult
				}
			)

			return {
				message = localize('trgu_rounded'),
				colour = G.C.FILTER
			}
		end
	end
}

-- КАПИБАРА ДЭНС ДЖОКЕР
SMODS.Atlas {
	key = "capybaradance",
	path = "CapybaraDance.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'capybaradance',
	loc_txt = {
		['en-us'] = {
			name = 'Capybara Dance',
			text = {
				"{C:mult}+#1#{} Mult",
				"if this Joker is in",
				"its favourite slot",
				"{C:inactive}(Favourite slot: #2#)"
			}
		},
		ru = {
			name = 'Капибара Дэнс',
			text = {
				"{C:mult}+#1#{} множ.",
				"если этот джокер",
				"находится в любимом слоте",
				"{C:inactive}(Любимый слот: #2#)"
			}
		}
	},
	config = {
		extra = {
			mult = 9,
			favourite_slot = 1
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				card.ability.extra.favourite_slot
			}
		}
	end,

	rarity = 1,
	atlas = 'capybaradance',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main then
			local index = trgu_get_joker_index(card)

			if index == card.ability.extra.favourite_slot then
				return {
					mult = card.ability.extra.mult
				}
			end
		end

		if context.after and not context.blueprint then
			local limit = G.jokers and G.jokers.config.card_limit or 1
			card.ability.extra.favourite_slot = math.floor(
				pseudorandom('capybara_slot_' .. tostring(G.GAME.hands_played or 0)) * limit
			) + 1

			return {
				message = localize('trgu_slot') .. ' ' .. tostring(card.ability.extra.favourite_slot),
				colour = G.C.FILTER
			}
		end
	end
}

-- Я ЖАЖДУ ТВОЕЙ СМЕРТИ ДЖОКЕР
SMODS.Atlas {
	key = "ieytd",
	path = "Expect.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'ieytd',
	loc_txt = {
		['en-us'] = {
			name = 'I Expect You To Die',
			text = {
				"{X:chips,C:white} X#1# {} Chips",
				"{C:green}#2# in #3#{} chance",
				"to destroy itself"
			}
		},
		ru = {
			name = 'Я жажду твоей смерти',
			text = {
				"{X:chips,C:white} X#1# {} фишек",
				"{C:green}#2# из #3#{} шанс",
				"уничтожиться"
			}
		}
	},
	config = {
		extra = {
			xchips = 1.5,
			odds = 6
		}
	},

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'ieytd_destroy'
		)

		return {
			vars = {
				card.ability.extra.xchips,
				numerator,
				denominator
			}
		}
	end,

	rarity = 2,
	atlas = 'ieytd',
	pos = { x = 0, y = 0 },
	cost = 6,
	eternal_compat = false,

	calculate = function(self, card, context)
		if context.joker_main then
			hand_chips = mod_chips(math.floor((tonumber(hand_chips) or 0) * card.ability.extra.xchips))

			update_hand_text(
				{ delay = 0 },
				{ chips = hand_chips }
			)

			if not context.blueprint and SMODS.pseudorandom_probability(
				card,
				'ieytd_destroy',
				1,
				card.ability.extra.odds
			) then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.2,
					func = function()
						SMODS.destroy_cards(card, nil, nil, true)
						return true
					end
				}))

				return {
					message = localize('trgu_destroyed'),
					colour = G.C.RED
				}
			end

			return {
				message = "X" .. card.ability.extra.xchips .. " Chips",
				colour = G.C.CHIPS
			}
		end
	end
}

-- 100% КРИНЖ ДЖОКЕР
SMODS.Atlas {
	key = "hundredpercentjoker",
	path = "HundredPercentJoker.png",
	px = 71,
	py = 95
}

TRGU.u_joker_handlers.hundredpercentjoker = function(card)
	if not (G and G.STATE == G.STATES.SELECTING_HAND) then return end
	if not G.hand or not G.hand.cards or #G.hand.cards <= 0 then return end
	if not G.GAME or (G.GAME.dollars or 0) < 10 then
		SMODS.calculate_effect({
			message = localize('trgu_need_money'),
			colour = G.C.RED
		}, card)
		return
	end

	local target = trgu_random_from(
		G.hand.cards,
		'hundred_percent_card_' .. tostring(G.GAME.hands_played or 0)
	)

	if not target then return end

	local enhancement_key = pseudorandom('hundred_percent_enhancement') < 0.5 and 'm_bonus' or 'm_mult'
	local center = G.P_CENTERS[enhancement_key]

	if not center then return end

	ease_dollars(-10)

	target:set_ability(center, nil, true)
	target:juice_up()

	SMODS.calculate_effect({
		message = "100%!",
		colour = G.C.MONEY
	}, card)
end

SMODS.Joker {
	key = 'hundredpercentjoker',
	loc_txt = {
		['en-us'] = {
			name = '100% JOKER',
			text = {
				"{C:inactive}(Press {C:attention}U{C:inactive} to Use,",
				"{C:inactive}when Joker selected)",
				"During Blind, pay {C:money}$#1#{}",
				"to turn a random card",
				"in hand into {C:attention}Bonus{}",
				"or {C:attention}Mult{} Card"
			}
		},
		ru = {
			name = '100% ДЖОКЕР',
			text = {
				"{C:inactive}(Нажмите {C:attention}U{C:inactive},",
				"{C:inactive}когда джокер выбран)",
				"Во время блайнда заплатите {C:money}$#1#{},",
				"чтобы случайная карта в руке",
				"стала {C:attention}Бонусной{}",
				"или {C:attention}Множительной{} картой"
			}
		}
	},
	config = {
		extra = {
			cost = 10
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.cost
			}
		}
	end,

	rarity = 2,
	atlas = 'hundredpercentjoker',
	pos = { x = 0, y = 0 },
	cost = 6
}

-- СЦЕНАРНЫЙ ГУСЬ
SMODS.Atlas {
	key = "plotgoose",
	path = "PlotGoose.png",
	px = 71,
	py = 95
}

TRGU.u_joker_handlers.plotgoose = function(card)
	if not (G and G.STATE == G.STATES.SELECTING_HAND) then return end
	if not card or not card.ability or not card.ability.extra then return end
	if card.ability.extra.used then return end

	card.ability.extra.active = true
	card.ability.extra.used = true
	card:juice_up()

	SMODS.calculate_effect({
		message = localize('trgu_armed'),
		colour = G.C.MULT
	}, card)
end

SMODS.Joker {
	key = 'plotgoose',
	loc_txt = {
		['en-us'] = {
			name = 'Plot Goose',
			text = {
				"{C:inactive}(Press {C:attention}U{C:inactive} to Use,",
				"{C:inactive}when Joker selected)",
				"{X:mult,C:white} X#1# {} Mult",
				"for one hand",
				"Destroys itself after use",
				"{C:inactive}(Currently: #2#{C:inactive})"
			}
		},
		ru = {
			name = 'Сценарный гусь',
			text = {
				"{C:inactive}(Нажмите {C:attention}U{C:inactive},",
				"{C:inactive}когда джокер выбран)",
				"{X:mult,C:white} X#1# {} множ.",
				"на одну руку",
				"уничтожается после использования",
				"{C:inactive}(Сейчас: {C:attention}#2#{}{C:inactive})"
			}
		}
	},
	config = {
		extra = {
			xmult = 4,
			active = false,
			used = false
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.xmult,
				card.ability.extra.active
					and localize('trgu_active_coloured')
					or localize('trgu_inactive_coloured')
			}
		}
	end,

	rarity = 3,
	atlas = 'plotgoose',
	pos = { x = 0, y = 0 },
	cost = 8,

	calculate = function(self, card, context)
		if context.joker_main and card.ability.extra.active then
			return {
				xmult = card.ability.extra.xmult
			}
		end

		if context.after and card.ability.extra.active and not context.blueprint then
			card.ability.extra.active = false

			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.2,
				func = function()
					SMODS.destroy_cards(card, false, false, false)
					return true
				end
			}))

			return {
				message = localize('trgu_honk'),
				colour = G.C.RED
			}
		end
	end
}

-- ТЫ НЕ ЗНАЕШЬ МИРКОЯ ДЖОКЕР
SMODS.Atlas {
	key = "ydkm",
	path = "YDKM.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'ydkm',
	loc_txt = {
		['en-us'] = {
			name = 'YDKJ',
			text = {
				"On the {C:attention}first played hand{}",
				"of each Blind:",
				"{C:attention}Straight{} levels down",
				"and {C:attention}Flush{} levels up",
				"{C:attention}Flush{} levels down",
				"and {C:attention}Straight{} levels up"
			}
		},
		ru = {
			name = 'Ты не знаешь джокера',
			text = {
				"На {C:attention}первой сыгранной руке{}",
				"каждого блайнда:",
				"{C:attention}Стрит{} теряет уровень,",
				"а {C:attention}Флеш{} получает уровень",
				"{C:attention}Флеш{} теряет уровень,",
				"а {C:attention}Стрит{} получает уровень"
			}
		}
	},
	config = {
		extra = {
			used_this_blind = false
		}
	},

	rarity = 1,
	atlas = 'ydkm',
	pos = { x = 0, y = 0 },
	cost = 6,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			card.ability.extra.used_this_blind = false
		end

		if context.before and not context.blueprint then
			if card.ability.extra.used_this_blind then
				return
			end

			card.ability.extra.used_this_blind = true

			local has_straight = context.poker_hands
				and context.poker_hands['Straight']
				and next(context.poker_hands['Straight'])

			local has_flush = context.poker_hands
				and context.poker_hands['Flush']
				and next(context.poker_hands['Flush'])
			if has_straight and has_flush then
				return {
					message = "???",
					colour = G.C.FILTER
				}
			end

			if has_straight then
				if G.GAME.hands['Straight'] and G.GAME.hands['Straight'].level > 1 then
					level_up_hand(card, 'Straight', nil, -1)
				end

				level_up_hand(card, 'Flush', nil, 1)

				return {
					message = localize('trgu_flush_up'),
					colour = G.C.FILTER
				}
			end

			if has_flush then
				if G.GAME.hands['Flush'] and G.GAME.hands['Flush'].level > 1 then
					level_up_hand(card, 'Flush', nil, -1)
				end

				level_up_hand(card, 'Straight', nil, 1)

				return {
					message = localize('trgu_straight_up'),
					colour = G.C.FILTER
				}
			end
		end
	end
}

-- БУСТИ ДЖОКЕР
SMODS.Atlas {
	key = "boosty",
	path = "Boosty.png",
	px = 71,
	py = 95
}

TRGU.boosty = TRGU.boosty or {}

local function trgu_boosty_find()
	if not G or not G.jokers or not G.jokers.cards then return nil end

	for _, joker in ipairs(G.jokers.cards) do
		local center = joker and joker.config and joker.config.center
		local key = center and tostring(center.key or "") or ""
		local original_key = center and tostring(center.original_key or "") or ""

		if key:sub(-6) == "boosty" or original_key == "boosty" then
			return joker
		end
	end

	return nil
end

local function trgu_boosty_active()
	return trgu_boosty_find() ~= nil
end

local function trgu_boosty_in_shop()
	return G and G.STATE and G.STATES and G.STATE == G.STATES.SHOP
end

local function trgu_boosty_remove_blocker()
	if TRGU.boosty.exit_blocker_ui then
		TRGU.boosty.exit_blocker_ui:remove()
		TRGU.boosty.exit_blocker_ui = nil
	end
end

local function trgu_boosty_mark_purchase()
	if not G or not G.GAME then return end
	if not trgu_boosty_active() then return end

	G.GAME.trgu_boosty_purchases_this_shop =
		(G.GAME.trgu_boosty_purchases_this_shop or 0) + 1

	G.GAME.trgu_boosty_bought_this_shop =
		G.GAME.trgu_boosty_purchases_this_shop > 0

	trgu_boosty_remove_blocker()
end

G.FUNCS.trgu_boosty_block_exit = function(e)
	local boosty = trgu_boosty_find()

	if boosty then
		SMODS.calculate_effect({
			message = localize('trgu_buy_first') or "Buy first!",
			colour = G.C.RED
		}, boosty)

		boosty:juice_up()
	end

	if play_sound then
		play_sound('cancel')
	end
end

G.UIDEF.trgu_boosty_exit_blocker = function()
	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 0,
			colour = G.C.CLEAR
		},
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					padding = 0.12,
					r = 0.1,
					minw = 2.85,
					minh = 1.65,
					colour = G.C.RED,
					hover = true,
					shadow = true,
					button = "trgu_boosty_block_exit"
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize('trgu_buy_first') or "Buy first!",
							scale = 0.38,
							colour = G.C.UI.TEXT_LIGHT,
							shadow = true
						}
					}
				}
			}
		}
	}
end

local function trgu_boosty_create_blocker()
	if TRGU.boosty.exit_blocker_ui then return end
	if not trgu_boosty_in_shop() then return end
	if not trgu_boosty_active() then return end
	if G.GAME and (G.GAME.trgu_boosty_purchases_this_shop or 0) > 0 then return end

	TRGU.boosty.exit_blocker_ui = UIBox {
		definition = G.UIDEF.trgu_boosty_exit_blocker(),
		config = {
			align = "bri",
			major = G.ROOM_ATTACH,

			offset = {
				x = -11.70,
				y = -5.95
			}
		}
	}
end

local function trgu_boosty_refresh_shop_costs()
	if not G then return end

	local areas = {
		G.shop_jokers,
		G.shop_vouchers,
		G.shop_booster
	}

	for _, area in ipairs(areas) do
		if area and area.cards then
			for _, shop_card in ipairs(area.cards) do
				if shop_card and shop_card.set_cost then
					shop_card:set_cost()
				end
			end
		end
	end
end

local function trgu_boosty_card_is_shop_booster(card)
	if not card then return false end

	if G.shop_booster and G.shop_booster.cards then
		for _, shop_pack in ipairs(G.shop_booster.cards) do
			if shop_pack == card then
				return true
			end
		end
	end

	if card.area and G.shop_booster and card.area == G.shop_booster then
		return true
	end

	local center = card.config and card.config.center
	local key = center and tostring(center.key or "") or ""

	if key:sub(1, 2) == "p_" and trgu_boosty_in_shop() then
		return true
	end

	return false
end

local function trgu_boosty_install_buy_hooks()
	if not G or not G.FUNCS then return end
	if TRGU.boosty.buy_hooks_done then return end

	TRGU.boosty.buy_hooks_done = true
	if G.FUNCS.use_card then
		TRGU.boosty_use_card_ref = G.FUNCS.use_card

		G.FUNCS.use_card = function(e)
			local card = e and e.config and e.config.ref_table

			local should_count_booster =
				trgu_boosty_active()
				and trgu_boosty_card_is_shop_booster(card)

			local ret = TRGU.boosty_use_card_ref(e)

			if should_count_booster then
				trgu_boosty_mark_purchase()
			end

			return ret
		end
	end
end

local function trgu_boosty_update()
	trgu_boosty_install_buy_hooks()

	if not trgu_boosty_active() then
		TRGU.boosty.was_in_shop = false
		trgu_boosty_remove_blocker()
		return
	end

	if trgu_boosty_in_shop() then
		if not TRGU.boosty.was_in_shop then
			TRGU.boosty.was_in_shop = true

			if G.GAME and G.GAME.trgu_boosty_purchases_this_shop == nil then
				G.GAME.trgu_boosty_purchases_this_shop = 0
			end
		end

		if G.GAME and not G.GAME.trgu_boosty_bought_this_shop then
			trgu_boosty_create_blocker()
		else
			trgu_boosty_remove_blocker()
		end
	else
		TRGU.boosty.was_in_shop = false
		trgu_boosty_remove_blocker()
	end
end

if not TRGU.boosty_update_hooked then
	TRGU.boosty_update_hooked = true
	TRGU.boosty_game_update_ref = Game.update

	function Game:update(dt)
		TRGU.boosty_game_update_ref(self, dt)
		trgu_boosty_update()
	end
end

SMODS.Joker {
	key = 'boosty',
	loc_txt = {
		['en-us'] = {
			name = 'Boosty',
			text = {
				"Shop exit is blocked",
				"until you make",
				"any {C:attention}purchase{}",
				"{C:attention}25%{} discount in shop",
				"{C:inactive}(Purchases made: #1#)"
			}
		},
		ru = {
			name = 'Boosty',
			text = {
				"Выход из магазина заблокирован,",
				"пока вы не совершите",
				"любую {C:attention}покупку{}",
				"{C:attention}25%{} скидка в магазине",
				"{C:inactive}(Покупок совершено: #1#)"
			}
		}
	},

	config = {
		extra = {
			purchases = 0
		}
	},

	loc_vars = function(self, info_queue, card)
		local purchases = 0

		if G and G.GAME then
			purchases = G.GAME.trgu_boosty_purchases_this_shop or 0
		end

		if card and card.ability and card.ability.extra then
			card.ability.extra.purchases = purchases
		end

		return {
			vars = {
				purchases
			}
		}
	end,

	rarity = 1,
	atlas = 'boosty',
	pos = { x = 0, y = 0 },
	cost = 7,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.starting_shop and not context.blueprint then
			G.GAME.trgu_boosty_purchases_this_shop = 0
			G.GAME.trgu_boosty_bought_this_shop = false
		end

		if context.buying_card and not context.blueprint then
			trgu_boosty_mark_purchase()
		end
	end,

	add_to_deck = function(self, card, from_debuff)
		if not G.GAME then return end

		G.GAME.trgu_boosty_count = (G.GAME.trgu_boosty_count or 0) + 1

		if G.GAME.trgu_boosty_count == 1 then
			G.GAME.discount_percent = (G.GAME.discount_percent or 0) + 25
			trgu_boosty_refresh_shop_costs()
		end

		if trgu_boosty_in_shop() then
			G.GAME.trgu_boosty_purchases_this_shop =
				(G.GAME.trgu_boosty_purchases_this_shop or 0) + 1

			G.GAME.trgu_boosty_bought_this_shop = true
			trgu_boosty_remove_blocker()
		end
	end,

	remove_from_deck = function(self, card, from_debuff)
		if not G.GAME then return end

		G.GAME.trgu_boosty_count = math.max((G.GAME.trgu_boosty_count or 1) - 1, 0)

		if G.GAME.trgu_boosty_count <= 0 then
			G.GAME.discount_percent = math.max((G.GAME.discount_percent or 25) - 25, 0)
			G.GAME.trgu_boosty_bought_this_shop = nil
			trgu_boosty_remove_blocker()
			trgu_boosty_refresh_shop_costs()
		end
	end
}

-- РЕПОРНО ДЖОКЕР
SMODS.Atlas {
	key = "censuramoment",
	path = "Reporno.png",
	px = 71,
	py = 95
}

TRGU.censura = TRGU.censura or {
	active = false,
	kind = nil
}

if not TRGU.censura_update_hand_text_hooked then
	TRGU.censura_update_hand_text_hooked = true
	TRGU.censura_update_hand_text_ref = update_hand_text

	function update_hand_text(config, vals)
		if TRGU
			and TRGU.censura
			and TRGU.censura.active
			and vals
		then
			vals = copy_table(vals)

			if TRGU.censura.kind == 'chips' and vals.chips ~= nil then
				vals.chips = "????"
			end

			if TRGU.censura.kind == 'mult' and vals.mult ~= nil then
				vals.mult = "????"
			end
		end

		return TRGU.censura_update_hand_text_ref(config, vals)
	end
end

SMODS.Joker {
	key = 'censuramoment',
	loc_txt = {
		['en-us'] = {
			name = 'TMWReporn',
			text = {
				"At start of scoring,",
				"censors {C:chips}Chips{} or {C:mult}Mult{}",
				"as {C:attention}????{}",
				"At final scoring step,",
				"{X:mult,C:white} X#1# {} Mult"
			}
		},
		ru = {
			name = 'РеПорно',
			text = {
				"В начале подсчёта",
				"цензурирует {C:chips}фишки{}",
				"или {C:mult}множ.{} как {C:attention}????{}",
				"в финальном шаге подсчёта:",
				"{X:mult,C:white} X#1# {} множ."
			}
		}
	},
	config = {
		extra = {
			xmult = 1.5
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.xmult
			}
		}
	end,

	rarity = 1,
	atlas = 'censuramoment',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.before and not context.blueprint then
			TRGU.censura.active = true
			TRGU.censura.kind = pseudorandom('censura_kind_' .. tostring(G.GAME.hands_played or 0)) < 0.5
				and 'chips'
				or 'mult'

			update_hand_text(
				{ delay = 0 },
				{
					chips = hand_chips,
					mult = mult
				}
			)

			return {
				message = localize('trgu_censored') or "Censored!",
				colour = G.C.RED
			}
		end

		if context.final_scoring_step then
			mult = mod_mult((tonumber(mult) or 0) * card.ability.extra.xmult)

			TRGU.censura.active = false
			TRGU.censura.kind = nil

			update_hand_text(
				{ delay = 0 },
				{
					chips = hand_chips,
					mult = mult
				}
			)

			return {
				message = "X" .. card.ability.extra.xmult,
				colour = G.C.MULT
			}
		end

		if context.after and not context.blueprint then
			TRGU.censura.active = false
			TRGU.censura.kind = nil
		end
	end,

	remove_from_deck = function(self, card, from_debuff)
		TRGU.censura.active = false
		TRGU.censura.kind = nil
	end
}

-- ПНХ ДЖОКЕР
SMODS.Atlas {
	key = "pnh",
	path = "PNH.png",
	px = 71,
	py = 95
}

TRGU.pnh = TRGU.pnh or {
	pending = false,
	forced_hand = false,
	source_card = nil,
	last_auto_hand = -1
}

local function trgu_pnh_clear_lock()
	if G and G.CONTROLLER and G.CONTROLLER.locks then
		G.CONTROLLER.locks.trgu_pnh = nil
	end
end

local function trgu_pnh_blind_is_still_playable()
	if not (G and G.GAME and G.GAME.blind) then
		return false
	end

	if (G.GAME.chips or 0) >= (G.GAME.blind.chips or math.huge) then
		return false
	end

	if G.GAME.current_round
		and G.GAME.current_round.hands_left
		and G.GAME.current_round.hands_left <= 0
	then
		return false
	end

	return true
end

local function trgu_pnh_can_autoplay_now()
	return G
		and G.STATE
		and G.STATES
		and G.STATE == G.STATES.SELECTING_HAND
		and G.hand
		and G.hand.cards
		and #G.hand.cards > 0
		and trgu_pnh_blind_is_still_playable()
end

local function trgu_pnh_unhighlight_all()
	if G.hand and G.hand.unhighlight_all then
		G.hand:unhighlight_all()
	elseif G.hand and G.hand.highlighted then
		for i = #G.hand.highlighted, 1, -1 do
			local c = G.hand.highlighted[i]
			if c and c.highlight then c:highlight(false) end
		end
		G.hand.highlighted = {}
	end
end

local function trgu_pnh_select_random_cards()
	if not G.hand or not G.hand.cards then return 0 end

	trgu_pnh_unhighlight_all()

	local pool = {}
	for _, c in ipairs(G.hand.cards) do
		pool[#pool + 1] = c
	end

	local amount = math.min(5, #pool)

	for i = 1, amount do
		local index = math.floor(
			pseudorandom('pnh_card_' .. tostring(G.GAME.hands_played or 0) .. '_' .. tostring(i)) * #pool
		) + 1

		local selected = table.remove(pool, index)

		if selected then
			if G.hand.add_to_highlighted then
				G.hand:add_to_highlighted(selected, true)
			elseif selected.highlight then
				selected:highlight(true)
			end
		end
	end

	return amount
end

local function trgu_pnh_press_play()
	if G.FUNCS and G.FUNCS.play_cards_from_highlighted then
		return G.FUNCS.play_cards_from_highlighted({ config = {} })
	end

	if G.FUNCS and G.FUNCS.play_cards then
		return G.FUNCS.play_cards({ config = {} })
	end

	print("PNH: play function not found")
end

local function trgu_pnh_do_autoplay()
	if not trgu_pnh_can_autoplay_now() then
		TRGU.pnh.pending = false
		TRGU.pnh.forced_hand = false
		TRGU.pnh.source_card = nil
		trgu_pnh_clear_lock()
		return
	end

	TRGU.pnh.pending = false
	TRGU.pnh.forced_hand = true
	TRGU.pnh.last_auto_hand = G.GAME.hands_played or 0

	if G.CONTROLLER and G.CONTROLLER.locks then
		G.CONTROLLER.locks.trgu_pnh = true
	end

	local selected_count = trgu_pnh_select_random_cards()

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.25,
		func = function()
			trgu_pnh_clear_lock()

			if selected_count > 0 then
				local ok, err = pcall(function()
					trgu_pnh_press_play()
				end)

				if not ok then
					print("PNH autoplay failed:")
					print(tostring(err))

					TRGU.pnh.forced_hand = false
					TRGU.pnh.source_card = nil
				end
			else
				TRGU.pnh.forced_hand = false
				TRGU.pnh.source_card = nil
			end

			return true
		end
	}))
end

if not TRGU.pnh_update_hooked then
	TRGU.pnh_update_hooked = true
	TRGU.pnh_game_update_ref = Game.update

	function Game:update(dt)
		TRGU.pnh_game_update_ref(self, dt)

		if TRGU.pnh.pending and trgu_pnh_can_autoplay_now() then
			trgu_pnh_do_autoplay()
		end
	end
end

SMODS.Joker {
	key = 'pnh',
	loc_txt = {
		['en-us'] = {
			name = 'FY',
			text = {
				"After a non-winning hand,",
				"{C:green}#2# in #3#{} chance to",
				"take control and play",
				"{C:attention}5{} random cards",
				"That hand gives",
				"{X:mult,C:white} X#1# {} Mult"
			}
		},
		ru = {
			name = 'ПНХ',
			text = {
				"После непобедной руки",
				"{C:green}#2# из #3#{} шанс",
				"захватить управление",
				"и сыграть {C:attention}5{} случайных карт",
				"эта рука даёт",
				"{X:mult,C:white} X#1# {} множ."
			}
		}
	},
	config = {
		extra = {
			xmult = 2.5,
			odds = 4,
			last_checked_hand = -1
		}
	},

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'pnh_autoplay'
		)

		return {
			vars = {
				card.ability.extra.xmult,
				numerator,
				denominator
			}
		}
	end,

	rarity = 3,
	atlas = 'pnh',
	pos = { x = 0, y = 0 },
	cost = 8,

	calculate = function(self, card, context)
		if context.joker_main then
			if TRGU.pnh.forced_hand and TRGU.pnh.source_card == card then
				return {
					xmult = card.ability.extra.xmult
				}
			end
		end

		if context.before and TRGU.pnh.forced_hand and TRGU.pnh.source_card == card then
			trgu_pnh_clear_lock()
		end

		if context.after and TRGU.pnh.forced_hand and TRGU.pnh.source_card == card then
			TRGU.pnh.forced_hand = false
			TRGU.pnh.source_card = nil
			return
		end

		if context.after and not context.blueprint then
			if TRGU.pnh.forced_hand then
				return
			end

			local hand_id = G.GAME.hands_played or 0

			if card.ability.extra.last_checked_hand == hand_id then
				return
			end

			card.ability.extra.last_checked_hand = hand_id

			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.45,
				func = function()
					if not trgu_pnh_blind_is_still_playable() then
						return true
					end

					if SMODS.pseudorandom_probability(
						card,
						'pnh_autoplay',
						1,
						card.ability.extra.odds
					) then
						TRGU.pnh.pending = true
						TRGU.pnh.source_card = card

						SMODS.calculate_effect({
							message = localize('trgu_autoplay') or "Auto Play!",
							colour = G.C.RED
						}, card)
					end

					return true
				end
			}))
		end
	end,

	remove_from_deck = function(self, card, from_debuff)
		if TRGU.pnh.source_card == card then
			TRGU.pnh.pending = false
			TRGU.pnh.forced_hand = false
			TRGU.pnh.source_card = nil
			trgu_pnh_clear_lock()
		end
	end
}

-- ВЕДУЩАЯ ОТКРЫТОЧНОЙ ДЖОКЕР
SMODS.Atlas {
	key = "postcardhost",
	path = "PostcardHost.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'postcardhost',
	loc_txt = {
		['en-us'] = {
			name = 'Postcard Host',
			text = {
				"{C:chips}+#1#{} Chips for each",
				"{C:attention}consumable{} in your inventory",
				"{C:inactive}(Currently: {C:chips}+#3#{C:inactive} Chips)"
			}
		},
		ru = {
			name = 'Ведущая Открыточной',
			text = {
				"{C:chips}+#1#{} фишек за каждый",
				"{C:attention}расходник{} в инвентаре",
				"{C:inactive}(Сейчас: {C:chips}+#3#{C:inactive} фишек)"
			}
		}
	},
	config = {
		extra = {
			chips_per_consumable = 40
		}
	},

	loc_vars = function(self, info_queue, card)
		local count = G.consumeables and G.consumeables.cards and #G.consumeables.cards or 0
		local total = count * card.ability.extra.chips_per_consumable

		return {
			vars = {
				card.ability.extra.chips_per_consumable,
				count,
				total
			}
		}
	end,

	rarity = 1,
	atlas = 'postcardhost',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main then
			local count = G.consumeables and G.consumeables.cards and #G.consumeables.cards or 0
			local total = count * card.ability.extra.chips_per_consumable

			if total > 0 then
				return {
					chips = total
				}
			end
		end
	end
}

-- Я СИЖУ НА КАРАНТИНЕ ДЖОКЕР
SMODS.Atlas {
	key = "quarantine",
	path = "Quarantine.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'quarantine',
	loc_txt = {
		['en-us'] = {
			name = "I'm in Quarantine",
			text = {
				"Gains {C:chips}+#2#{} Chips",
				"after each round",
				"{C:inactive}(Currently: {C:chips}+#1#{C:inactive} Chips)",
				"{C:inactive}(Weeks passed: #3#)"
			}
		},
		ru = {
			name = 'Я сижу на карантине',
			text = {
				"Получает {C:chips}+#2#{} фишек",
				"после каждого раунда",
				"{C:inactive}(Сейчас: {C:chips}+#1#{C:inactive} фишек)",
				"{C:inactive}(Прошло недель: #3#)"
			}
		}
	},
	config = {
		extra = {
			chips = 0,
			chip_gain = 7,
			weeks = 0
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.chips,
				card.ability.extra.chip_gain,
				card.ability.extra.weeks
			}
		}
	end,

	rarity = 1,
	atlas = 'quarantine',
	pos = { x = 0, y = 0 },
	cost = 4,

	calculate = function(self, card, context)
		if context.joker_main and card.ability.extra.chips > 0 then
			return {
				chips = card.ability.extra.chips
			}
		end

		if context.end_of_round
			and context.main_eval
			and context.game_over == false
			and not context.blueprint
		then
			card.ability.extra.weeks = card.ability.extra.weeks + 1
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_gain

			return {
				message = localize {
					type = 'variable',
					key = 'trgu_week_passed',
					vars = { card.ability.extra.weeks }
				},
				colour = G.C.CHIPS
			}
		end
	end
}

-- МИРКОТИК ДЖОКЕР
SMODS.Atlas {
	key = "mirkotik",
	path = "Mirkotik.png",
	px = 71,
	py = 95
}

SMODS.Sound {
	key = 'mirkoi_meow',
	path = 'mirkoi_meow.ogg'
}

SMODS.Joker {
	key = 'mirkotik',
	loc_txt = {
		['en-us'] = {
			name = 'Mirkotik',
			text = {
				"Earn {C:money}$#1#{} for each",
				"destroyed {C:attention}playing card{}"
			}
		},
		ru = {
			name = 'Миркотик',
			text = {
				"Получите {C:money}$#1#{} за каждую",
				"уничтоженную {C:attention}игральную карту{}"
			}
		}
	},
	config = {
		extra = {
			money = 3
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.money
			}
		}
	end,

	rarity = 2,
	atlas = 'mirkotik',
	pos = { x = 0, y = 0 },
	cost = 6,

	calculate = function(self, card, context)
		if context.remove_playing_cards
			and context.removed
			and #context.removed > 0
		then
			local total = #context.removed * card.ability.extra.money

			return {
				dollars = total,
				message = localize {
					type = 'variable',
					key = 'trgu_mirkotik_meow',
					vars = { total }
				},
				colour = G.C.MONEY,
				sound = 'trgu_mirkoi_meow'
			}
		end
	end
}

-- ДЕВУШКА НА ЧАС ДЖОКЕР
SMODS.Atlas {
	key = "girlfriendforhour",
	path = "GirlfriendForHour.png",
	px = 71,
	py = 95
}

local function trgu_revoke_last_tag()
	if not G or not G.GAME or not G.GAME.tags or #G.GAME.tags <= 0 then
		return false
	end

	local tag = G.GAME.tags[#G.GAME.tags]
	if not tag or tag.triggered then return false end

	if tag.remove then
		local ok = pcall(function()
			tag:remove()
		end)

		if not ok then
			print('Girlfriend for an Hour: Tag:remove() failed')
		end
	end

	for i = #G.GAME.tags, 1, -1 do
		if G.GAME.tags[i] == tag then
			table.remove(G.GAME.tags, i)
			break
		end
	end

	return true
end

SMODS.Joker {
	key = 'girlfriendforhour',
	loc_txt = {
		['en-us'] = {
			name = 'Furry Boy for an Hour',
			text = {
				"Retracts the last queued {C:attention}Tag{}",
				"without activating it",
				"If successful, gives",
				"{X:mult,C:white} X#1# {} Mult for this hand"
			}
		},
		ru = {
			name = 'Фурри-бой на час',
			text = {
				"Отзывает последний тэг",
				"из очереди, не активируя его",
				"Если получилось, даёт",
				"{X:mult,C:white} X#1# {} множ. на эту руку"
			}
		}
	},
	config = {
		extra = {
			xmult = 3,
			last_hand = -1
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.xmult
			}
		}
	end,

	rarity = 3,
	atlas = 'girlfriendforhour',
	pos = { x = 0, y = 0 },
	cost = 8,
	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.joker_main and not context.blueprint then
			local hand_id = G.GAME and G.GAME.hands_played or 0
			if card.ability.extra.last_hand == hand_id then return end

			card.ability.extra.last_hand = hand_id

			if trgu_revoke_last_tag() then
				return {
					xmult = card.ability.extra.xmult,
					message = localize('trgu_tag_revoked'),
					colour = G.C.MULT
				}
			end
		end
	end
}

-- МИСТИЧЕСКАЯ КОРОБКА ДЖОКЕР
SMODS.Atlas {
	key = "mysterybox",
	path = "MysteryBox.png",
	px = 71,
	py = 95
}

local TRGU_MYSTERY_BOX_EDITIONS = {
	'e_foil',
	'e_holo',
	'e_polychrome',
	'e_negative'
}

local function trgu_mystery_box_any_edition()
	if not G.jokers or not G.jokers.cards then return false end

	for _, joker in ipairs(G.jokers.cards) do
		if joker.edition and type(joker.edition) == 'table' and next(joker.edition) ~= nil then
			return true
		end
	end

	return false
end

SMODS.Joker {
	key = 'mysterybox',
	loc_txt = {
		['en-us'] = {
			name = 'Mystery Box',
			text = {
				"At start of Blind, if no Joker",
				"has an {C:dark_edition}Edition{}, apply a",
				"random Edition to a random Joker"
			}
		},
		ru = {
			name = 'Мистическая коробка',
			text = {
				"В начале блайнда, если ни у одного",
				"джокера нет {C:dark_edition}издания{},",
				"накладывает случайное издание",
				"на случайного джокера"
			}
		}
	},

	rarity = 3,
	atlas = 'mysterybox',
	pos = { x = 0, y = 0 },
	cost = 9,
	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			if not G.jokers or not G.jokers.cards or #G.jokers.cards <= 0 then return end
			if trgu_mystery_box_any_edition() then return end

			local target = pseudorandom_element(
				G.jokers.cards,
				pseudoseed('mystery_box_target')
			)

			local edition = pseudorandom_element(
				TRGU_MYSTERY_BOX_EDITIONS,
				pseudoseed('mystery_box_edition')
			)

			if target and edition then
				target:set_edition(edition, true)
				target:juice_up()

				return {
					message = localize('trgu_edition_applied'),
					colour = G.C.DARK_EDITION
				}
			end
		end
	end
}

-- МИШБУРГЕР ДЖОКЕР
SMODS.Atlas {
	key = "mishburger",
	path = "Mishburger.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'mishburger',
	loc_txt = {
		['en-us'] = {
			name = 'Mishburger',
			text = {
				"{C:mult}+#1#{} Mult"
			}
		},
		ru = {
			name = 'Мишбургер',
			text = {
				"{C:mult}+#1#{} множ."
			}
		}
	},
	config = {
		extra = {
			mult = 1
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult
			}
		}
	end,

	rarity = 1,
	atlas = 'mishburger',
	pos = { x = 0, y = 0 },
	cost = 2,

	calculate = function(self, card, context)
		if context.joker_main then
			return {
				mult = card.ability.extra.mult
			}
		end
	end
}

-- ЕСТЬ 2 СТУЛА ДЖОКЕР
SMODS.Atlas {
	key = "twochairs",
	path = "TwoChairs.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'twochairs',
	loc_txt = {
		['en-us'] = {
			name = 'There Are 2 Chairs',
			text = {
				"{C:green}#3# in #4#{} chance",
				"to give {X:mult,C:white} X#1# {} Mult,",
				"otherwise gives",
				"{X:mult,C:white} X#2# {} Mult"
			}
		},
		ru = {
			name = 'Есть 2 стула',
			text = {
				"{C:green}#3# из #4#{} шанс",
				"дать {X:mult,C:white} X#1# {} множ.,",
				"иначе даёт",
				"{X:mult,C:white} X#2# {} множ."
			}
		}
	},

	config = {
		extra = {
			good_xmult = 2,
			bad_xmult = 0.5,
			odds = 2
		}
	},

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'twochairs_good'
		)

		return {
			vars = {
				card.ability.extra.good_xmult,
				card.ability.extra.bad_xmult,
				numerator,
				denominator
			}
		}
	end,

	rarity = 1,
	atlas = 'twochairs',
	pos = { x = 0, y = 0 },
	cost = 4,

	calculate = function(self, card, context)
		if context.joker_main then
			local good = SMODS.pseudorandom_probability(
				card,
				'twochairs_good_' .. tostring(G.GAME.hands_played or 0),
				1,
				card.ability.extra.odds
			)

			local xmult = good
				and card.ability.extra.good_xmult
				or card.ability.extra.bad_xmult

			return {
				xmult = xmult,
				colour = good and G.C.MULT or G.C.RED
			}
		end
	end
}

-- РУЛЕТКА ЖЁЛТОГО ЦВЕТА ДЖОКЕР
SMODS.Atlas {
	key = "yellowroulette",
	path = "YellowRoulette.png",
	px = 71,
	py = 95
}

local function trgu_yellow_roulette_has_room()
	if not G.consumeables or not G.GAME then return false end

	local buffer = G.GAME.consumeable_buffer or 0
	local limit = G.consumeables.config.card_limit or 0

	return #G.consumeables.cards + buffer < limit
end

SMODS.Joker {
	key = 'yellowroulette',
	loc_txt = {
		['en-us'] = {
			name = 'Yellow Roulette',
			text = {
				"At end of Blind, creates",
				"a {C:tarot}Wheel of Fortune{}",
				"{C:inactive}(Must have room)"
			}
		},
		ru = {
			name = 'Рулетка Жёлтого Цвета',
			text = {
				"В конце блайнда создаёт",
				"{C:tarot}Колесо Фортуны{}",
				"{C:inactive}(Нужно место)"
			}
		}
	},

	rarity = 2,
	atlas = 'yellowroulette',
	pos = { x = 0, y = 0 },
	cost = 6,
	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.end_of_round
			and context.main_eval
			and context.game_over == false
			and not context.blueprint
			and trgu_yellow_roulette_has_room()
		then
			G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1

			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.2,
				func = function()
					SMODS.add_card({
						set = 'Tarot',
						area = G.consumeables,
						key = 'c_wheel_of_fortune',
						allow_duplicates = true,
						key_append = 'yellow_roulette'
					})

					G.GAME.consumeable_buffer = math.max(
						(G.GAME.consumeable_buffer or 1) - 1,
						0
					)

					return true
				end
			}))

			return {
				message = localize('trgu_wheel_created'),
				colour = G.C.SECONDARY_SET.Tarot
			}
		end
	end
}

-- УРА!!!!!! ПЯТНИЦА! ДЖОКЕР
SMODS.Atlas {
	key = "friday",
	path = "Friday.png",
	px = 71,
	py = 95
}

local function trgu_today_is_friday()
	local date = os.date('*t')
	return date and date.wday == 6
end

SMODS.Joker {
	key = 'friday',
	loc_txt = {
		['en-us'] = {
			name = 'HOORAY!!!!!! FRIDAY =)',
			text = {
				"{C:mult}+#1#{} Mult",
				"if today is {C:attention}Friday{}",
				"{C:inactive}(Currently: #2#)"
			}
		},
		ru = {
			name = 'УРА!!!!!! ПЯТНИЦА =)',
			text = {
				"{C:mult}+#1#{} множ.,",
				"если сегодня {C:attention}пятница{}",
				"{C:inactive}(Сейчас: #2#)"
			}
		}
	},
	config = {
		extra = {
			mult = 25
		}
	},

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				trgu_today_is_friday() and localize('trgu_friday_yes') or localize('trgu_friday_no')
			}
		}
	end,

	rarity = 1,
	atlas = 'friday',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main and trgu_today_is_friday() then
			return {
				mult = card.ability.extra.mult
			}
		end
	end
}

-- ПРЛ ДЖОКЕР
SMODS.Atlas {
	key = "prl",
	path = "PRL.png",
	px = 71,
	py = 95
}

SMODS.Joker {
	key = 'prl',
	loc_txt = {
		['en-us'] = {
			name = 'PRL',
			text = {
				"At final scoring step,",
				"{C:green}#1# in #2#{} chance for",
				"{C:red}-70%{} Chips, otherwise",
				"{C:chips}+10%{} Chips"
			}
		},
		ru = {
			name = 'ПРЛ',
			text = {
				"В финальном шаге подсчёта",
				"с шансом {C:green}#1# из #2#{} даёт",
				"{C:red}-60%{} фишек, иначе",
				"{C:chips}+25%{} фишек"
			}
		}
	},
	config = {
		extra = {
			odds = 4,
			bad_factor = 0.4,
			good_factor = 1.25
		}
	},

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'prl_result'
		)

		return {
			vars = {
				numerator,
				denominator
			}
		}
	end,

	rarity = 2,
	atlas = 'prl',
	pos = { x = 0, y = 0 },
	cost = 6,
	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.final_scoring_step and not context.blueprint then
			local bad = SMODS.pseudorandom_probability(
				card,
				'prl_result',
				1,
				card.ability.extra.odds
			)

			local factor = bad
				and card.ability.extra.bad_factor
				or card.ability.extra.good_factor

			hand_chips = mod_chips(math.floor((tonumber(hand_chips) or 0) * factor))

			update_hand_text(
				{ delay = 0 },
				{ chips = hand_chips }
			)

			return {
				message = bad and '-60%' or '+25%',
				colour = bad and G.C.RED or G.C.CHIPS
			}
		end
	end
}

-- РОЗОВЫЙ РЕБОРН ДЖОКЕР
SMODS.Atlas {
	key = "pinkreborn",
	path = "PinkReborn.png",
	px = 71,
	py = 95
}

local function trgu_count_hearts_in_cards(cards)
	local count = 0

	if not cards then return 0 end

	for _, c in ipairs(cards) do
		if c then
			if c.is_suit and c:is_suit('Hearts') then
				count = count + 1
			elseif c.base and c.base.suit == 'Hearts' then
				count = count + 1
			end
		end
	end

	return count
end

SMODS.Joker {
	key = 'pinkreborn',
	loc_txt = {
		['en-us'] = {
			name = 'Pink Reborn',
			text = {
				"{C:mult}+#1#{} Mult if",
				"played hand contains",
				"at least {C:attention}3{} {C:hearts}Hearts{} cards"
			}
		},
		ru = {
			name = 'Розовый Реборн',
			text = {
				"{C:mult}+#1#{} множ., если",
				"в сыгранной руке есть",
				"хотя бы {C:attention}3{} {C:hearts}червовые{} карты"
			}
		}
	},
	config = {
		extra = {
			mult = 13,
			hearts_needed = 3
		}
	},
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				card.ability.extra.hearts_needed
			}
		}
	end,
	rarity = 1,
	atlas = 'pinkreborn',
	pos = { x = 0, y = 0 },
	cost = 5,

	calculate = function(self, card, context)
		if context.joker_main then
			local cards = context.full_hand or context.scoring_hand

			if trgu_count_hearts_in_cards(cards) >= card.ability.extra.hearts_needed then
				return {
					mult = card.ability.extra.mult
				}
			end
		end
	end
}

-- ЭЛИАС ДЖОКЕР
SMODS.Atlas {
	key = "elias",
	path = "Elias.png",
	px = 71,
	py = 95
}

TRGU = TRGU or {}
TRGU.elias = TRGU.elias or {}

local function trgu_elias_now()
	if G and G.TIMERS and G.TIMERS.REAL then
		return G.TIMERS.REAL
	end

	if love and love.timer then
		return love.timer.getTime()
	end

	return 0
end

local function trgu_elias_is_card(card)
	local center = card and card.config and card.config.center
	local key = center and tostring(center.key or "") or ""
	local original_key = center and tostring(center.original_key or "") or ""

	return key:sub(-5) == 'elias' or original_key == 'elias'
end

local function trgu_elias_cards()
	local result = {}

	if not G or not G.jokers or not G.jokers.cards then
		return result
	end

	for _, joker in ipairs(G.jokers.cards) do
		if trgu_elias_is_card(joker) then
			result[#result + 1] = joker
		end
	end

	return result
end

local function trgu_elias_can_tick()
	if not (G and G.STATE and G.STATES and G.STATE == G.STATES.SELECTING_HAND) then
		return false
	end

	if not G.GAME or not G.GAME.blind then
		return false
	end

	return true
end

local function trgu_elias_remove_timer_ui()
	if TRGU.elias.timer_ui then
		TRGU.elias.timer_ui:remove()
		TRGU.elias.timer_ui = nil
	end
end

G.UIDEF.trgu_elias_timer = function()
	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 0,
			colour = G.C.CLEAR
		},
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					padding = 0.08,
					r = 0.08,
					colour = G.C.DYN_UI.DARK,
					minw = 1.75
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							ref_table = TRGU.elias,
							ref_value = 'timer_text',
							scale = 0.42,
							colour = G.C.FILTER,
							shadow = true
						}
					}
				}
			}
		}
	}
end

local function trgu_elias_create_timer_ui()
	if TRGU.elias.timer_ui then return end
	if not G or not G.ROOM_ATTACH then return end

	TRGU.elias.timer_ui = UIBox {
		definition = G.UIDEF.trgu_elias_timer(),
		config = {
			align = "cri",
			major = G.ROOM_ATTACH,
			offset = { x = -3.2, y = -6.1 }
		}
	}
end


local function trgu_elias_blind_won()
	if not G or not G.GAME or not G.GAME.blind then
		return false
	end

	local chips = tonumber(G.GAME.chips or 0) or 0
	local target = tonumber(G.GAME.blind.chips or math.huge) or math.huge

	return chips >= target
end

local function trgu_elias_has_room(card)
	if not G or not G.consumeables then return false end

	local buffer = G.GAME and (G.GAME.consumeable_buffer or 0) or 0
	local limit = G.consumeables.config.card_limit or 0
	local current = #G.consumeables.cards + buffer

	if card and card.area == G.consumeables then
		current = current - 1
	end

	return current < limit
end

local function trgu_elias_roll_consumable_set(card)
	local id = card and card.ID or 0
	local roll = pseudorandom('elias_drop_' .. tostring(G.GAME.round or 0) .. '_' .. tostring(id))

	if roll < 0.40 then
		return 'Planet'
	elseif roll < 0.80 then
		return 'Tarot'
	elseif roll < 0.92 then
		return 'Spectral'
	else
		return 'Admin'
	end
end

local function trgu_elias_add_reward(card)
	if not trgu_elias_has_room() then
		SMODS.calculate_effect({
			message = localize('trgu_no_room') or 'No room!',
			colour = G.C.RED
		}, card)

		return false
	end

	local set = trgu_elias_roll_consumable_set(card)

	if set == 'Admin' and not (G.P_CENTER_POOLS and G.P_CENTER_POOLS.Admin) then
		set = 'Tarot'
	end

	G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.2,
		func = function()
			SMODS.add_card({
				set = set,
				area = G.consumeables,
				allow_duplicates = true,
				soulable = set == 'Spectral',
				key_append = 'elias'
			})

			G.GAME.consumeable_buffer = math.max((G.GAME.consumeable_buffer or 1) - 1, 0)

			SMODS.calculate_effect({
				message = localize('trgu_reward') or 'Reward!',
				colour = G.C.SECONDARY_SET[set] or G.C.FILTER
			}, card)

			return true
		end
	}))

	return true
end

local function trgu_elias_update_timer()
	local cards = trgu_elias_cards()
	local now = trgu_elias_now()
	local display_card = nil
	local display_remaining = nil

	for _, card in ipairs(cards) do
		local extra = card.ability and card.ability.extra

		if extra and extra.elias_active then
			if trgu_elias_can_tick() then
				local dt = 0

				if extra.last_update_time then
					dt = math.max(0, now - extra.last_update_time)
				end

				extra.last_update_time = now
				extra.remaining = math.max(0, (extra.remaining or 0) - dt)

				if extra.remaining <= 0 and not extra.expired then
					extra.expired = true
					extra.elias_active = false

					SMODS.calculate_effect({
						message = localize('trgu_time_up') or 'Time up!',
						colour = G.C.RED
					}, card)
				end
			else
				extra.last_update_time = now
			end

			if not extra.expired and (extra.remaining or 0) > 0 then
				if not display_remaining or extra.remaining < display_remaining then
					display_remaining = extra.remaining
					display_card = card
				end
			end
		end
	end

	if display_card and display_remaining then
		TRGU.elias.timer_text = string.format('%.1fs', display_remaining)
		trgu_elias_create_timer_ui()
	else
		trgu_elias_remove_timer_ui()
	end
end

if not TRGU.elias_update_hooked then
	TRGU.elias_update_hooked = true
	TRGU.elias_game_update_ref = Game.update

	function Game:update(dt)
		TRGU.elias_game_update_ref(self, dt)
		trgu_elias_update_timer()
	end
end

SMODS.Joker {
	key = 'elias',
	loc_txt = {
		['en-us'] = {
			name = 'Elias',
			text = {
				"At start of Blind,",
				"starts a {C:attention}#1#s{} timer",
				"Beat the Blind in time",
				"to create a random",
				"{C:attention}Consumable{} card",
				"{C:inactive}(Requires room)"
			}
		},
		ru = {
			name = 'Элиас',
			text = {
				"В начале блайнда",
				"запускает таймер на {C:attention}#1# сек.{}",
				"Пройдите блайнд вовремя,",
				"чтобы создать случайную",
				"{C:attention}расходуемую{} карту",
				"{C:inactive}(Нужно место)"
			}
		}
	},
	config = {
		extra = {
			time_limit = 20,
			remaining = 20,
			elias_active = false,
			expired = false,
			last_update_time = 0
		}
	},
	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.time_limit
			}
		}
	end,
	rarity = 3,
	atlas = 'elias',
	pos = { x = 0, y = 0 },
	cost = 7,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			card.ability.extra.remaining = card.ability.extra.time_limit
			card.ability.extra.elias_active = true
			card.ability.extra.expired = false
			card.ability.extra.last_update_time = trgu_elias_now()

			return {
				message = tostring(card.ability.extra.time_limit) .. 's',
				colour = G.C.FILTER
			}
		end

		if context.end_of_round and context.main_eval and not context.blueprint then
			if trgu_elias_blind_won()
				and card.ability.extra.elias_active
				and not card.ability.extra.expired
				and (card.ability.extra.remaining or 0) > 0
			then
				card.ability.extra.elias_active = false
				trgu_elias_add_reward(card)
			else
				card.ability.extra.elias_active = false
			end
		end
	end,

	remove_from_deck = function(self, card, from_debuff)
		card.ability.extra.elias_active = false
		trgu_elias_remove_timer_ui()
	end
}

-- QUIXORT ДЖОКЕР
SMODS.Atlas {
	key = "quixort",
	path = "Quixort.png",
	px = 71,
	py = 95
}

local TRGU_QUIXORT_SETS = {
	Tarot = true,
	Planet = true,
	Spectral = true,
	Admin = true
}

local function trgu_quixort_get_set(card)
	local center = card and card.config and card.config.center
	local set = center and center.set

	if TRGU_QUIXORT_SETS[set] then
		return set
	end

	return nil
end

local function trgu_quixort_random_center(set, old_key, seed)
	if not G or not G.P_CENTER_POOLS then return nil end

	local pool = G.P_CENTER_POOLS[set]
	if not pool then return nil end

	local candidates = {}

	for _, center in ipairs(pool) do
		if center
			and center.key
			and center.key ~= old_key
			and center.set == set
			and not center.no_collection
		then
			candidates[#candidates + 1] = center
		end
	end

	if #candidates <= 0 then return nil end

	local index = math.floor(pseudorandom(seed) * #candidates) + 1
	return candidates[index]
end

local function trgu_quixort_transform_card(consumable, seed)
	local set = trgu_quixort_get_set(consumable)
	if not set then return false end

	local old_center = consumable.config and consumable.config.center
	local old_key = old_center and old_center.key
	local new_center = trgu_quixort_random_center(set, old_key, seed)

	if not new_center then return false end

	consumable:set_ability(new_center, nil, true)

	if consumable.children and consumable.children.front then
		consumable.children.front:remove()
		consumable.children.front = nil
	end

	consumable:set_sprites(consumable.config.center)
	consumable:juice_up()

	return true
end

local function trgu_quixort_transform_all(source_card)
	if not G or not G.consumeables or not G.consumeables.cards then
		return 0
	end

	local changed = 0
	local base_seed = 'quixort_' .. tostring(G.GAME.round or 0) .. '_' .. tostring(source_card and source_card.ID or 0)

	for i, consumable in ipairs(G.consumeables.cards) do
		if trgu_quixort_transform_card(consumable, base_seed .. '_' .. tostring(i)) then
			changed = changed + 1
		end
	end

	if changed > 0 then
		SMODS.calculate_effect({
			message = localize('trgu_quixorted') or 'Quixorted!',
			colour = G.C.FILTER
		}, source_card)
	end

	return changed
end

SMODS.Joker {
	key = 'quixort',
	loc_txt = {
		['en-us'] = {
			name = 'Quixort',
			text = {
				"At start of Blind,",
				"turns all held",
				"{C:attention}Consumables{} into",
				"different {C:attention}Consumables{} of",
				"the {C:attention}same type{}"
			}
		},
		ru = {
			name = 'Скортировка',
			text = {
				"В начале блайнда",
				"превращает все",
				"{C:attention}расходники{} в другие",
				"{C:attention}расходники{} того же",
				"{C:attention}типа{}"
			}
		}
	},

	rarity = 3,
	atlas = 'quixort',
	pos = { x = 0, y = 0 },
	cost = 7,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			local changed = trgu_quixort_transform_all(card)
		end
	end,

	add_to_deck = function(self, card, from_debuff)
		if from_debuff then return end

		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 0.2,
			func = function()
				trgu_quixort_transform_all(card)
				return true
			end
		}))
	end
}

-- ИГНАТ КОРОЛЁВ ДЖОКЕР
SMODS.Atlas {
	key = "ignat_korolev",
	path = "IgnatKorolev.png",
	px = 71,
	py = 95
}

TRGU = TRGU or {}
TRGU.ignat_korolev = TRGU.ignat_korolev or {}

local function trgu_ignat_key_ends_with(key, tail)
	key = tostring(key or ""):lower()
	tail = tostring(tail or ""):lower()

	return key == tail
		or key == "m_" .. tail
		or key:sub(-#tail) == tail
end

local function trgu_ignat_get_enhancement(card)
	if not card or not card.config or not card.config.center then
		return nil
	end

	local center = card.config.center
	local key = tostring(center.key or ""):lower()
	local original_key = tostring(center.original_key or ""):lower()
	local name = tostring(center.name or ""):lower()

	local values = {
		"mult",
		"bonus",
		"glass",
		"stone",
		"lucky",
		"gold",
		"steel",
		"wild",
		"convert",
		"corrupted"
	}

	for _, value in ipairs(values) do
		if trgu_ignat_key_ends_with(key, value)
			or trgu_ignat_key_ends_with(original_key, value)
			or name == value
		then
			return value
		end
	end

	return nil
end

local function trgu_ignat_base_chips(card)
	if not card then return 0 end

	if card.base and card.base.nominal then
		return card.base.nominal
	end

	if card.get_id then
		local ok, id = pcall(function()
			return card:get_id()
		end)

		if ok and id then
			if id == 14 then return 11 end
			if id > 10 then return 10 end
			return id
		end
	end

	return 0
end

local function trgu_ignat_roll_int(seed, min, max)
	return math.floor(pseudorandom(seed) * (max - min + 1)) + min
end

local function trgu_ignat_money_text(amount)
	if amount > 0 then
		return "+$" .. tostring(amount)
	end

	if amount < 0 then
		return "-$" .. tostring(math.abs(amount))
	end

	return "$0"
end

local function trgu_ignat_ease_dollars(amount)
	if amount == 0 then return end

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.15,
		func = function()
			if ease_dollars then
				ease_dollars(amount)
			elseif G and G.GAME then
				G.GAME.dollars = (G.GAME.dollars or 0) + amount
			end

			return true
		end
	}))
end

local function trgu_ignat_destroy_cards_later(cards)
	if not cards or #cards <= 0 then return end

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.35,
		func = function()
			SMODS.destroy_cards(cards, false, false, false)
			return true
		end
	}))
end

local function trgu_ignat_create_negative_tarot(source_card, seed)
	if not G or not G.consumeables then return false end

	G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.2,
		func = function()
			local tarot = SMODS.add_card({
				set = 'Tarot',
				area = G.consumeables,
				edition = 'e_negative',
				allow_duplicates = true,
				key_append = seed or 'ignat_corrupted_negative_tarot'
			})

			G.GAME.consumeable_buffer = math.max((G.GAME.consumeable_buffer or 1) - 1, 0)

			if tarot then
				if not tarot.edition then
					tarot:set_edition('e_negative', true)
				end

				tarot:juice_up()
			end

			return true
		end
	}))

	return true
end

local function trgu_ignat_show_card_message(card, message, colour)
	if not card then return end

	if card.juice_up then
		card:juice_up()
	end

	if SMODS and SMODS.calculate_effect then
		SMODS.calculate_effect({
			message = message,
			colour = colour or G.C.FILTER
		}, card)
	end
end

local function trgu_ignat_card_seed(prefix, hand_card, index)
	return table.concat({
		prefix,
		tostring(G and G.GAME and G.GAME.hands_played or 0),
		tostring(hand_card and hand_card.ID or index or 0),
		tostring(index or 0)
	}, '_')
end

local function trgu_ignat_count_hand_enhancements()
	if not G or not G.hand or not G.hand.cards then return 0 end

	local count = 0

	for _, hand_card in ipairs(G.hand.cards) do
		local enhancement = trgu_ignat_get_enhancement(hand_card)

		if enhancement then
			count = count + 1
		end
	end

	return count
end

SMODS.Joker {
	key = 'ignat_korolev',
	loc_txt = {
		['en-us'] = {
			name = 'IgnatKorolev',
			text = {
				"During scoring, {C:attention}enhanced cards{}",
				"left in hand send their",
				"enhancement effects to server,",
				"than {C:attention}Ignat{} does cumulative effect",
				"{C:inactive}(except for Gold/Steel cards){}"
			}
		},
		ru = {
			name = 'ИгнатКоролёв',
			text = {
				"После подсчёта разыгранных карт",
				"оставшиеся в руке",
				"{C:attention}карты с улучшениями{} отправляют свои",
				"эффекты на сервер, после чего",
				"{C:attention}Игнат{} исполняет сумму эффектов",
				"{C:inactive}(кроме золотых/стальных карт){}"
			}
		}
	},

	rarity = 3,
	atlas = 'ignat_korolev',
	pos = { x = 0, y = 0 },
	cost = 9,

	blueprint_compat = false,

	calculate = function(self, card, context)
		if not context.joker_main then return end
		if not G or not G.hand or not G.hand.cards then return end

		local total_chips = 0
		local total_mult = 0
		local total_xmult = 1
		local triggered = 0
		local glass_to_destroy = {}

		for index, hand_card in ipairs(G.hand.cards) do
			local enhancement = trgu_ignat_get_enhancement(hand_card)

			if enhancement == 'mult' then
				triggered = triggered + 1
				total_mult = total_mult + 4
				trgu_ignat_show_card_message(hand_card, '+4', G.C.MULT)

			elseif enhancement == 'bonus' then
				triggered = triggered + 1
				total_chips = total_chips + 30
				trgu_ignat_show_card_message(hand_card, '+30', G.C.CHIPS)

			elseif enhancement == 'glass' then
				triggered = triggered + 1
				total_xmult = total_xmult * 2
				trgu_ignat_show_card_message(hand_card, 'X2', G.C.MULT)

				local destroy_seed = trgu_ignat_card_seed('ignat_glass_break', hand_card, index)
				local breaks = false

				if SMODS.pseudorandom_probability then
					breaks = SMODS.pseudorandom_probability(
						card,
						destroy_seed,
						1,
						4
					)
				else
					breaks = pseudorandom(destroy_seed) < 0.25
				end

				if breaks then
					glass_to_destroy[#glass_to_destroy + 1] = hand_card
				end

			elseif enhancement == 'stone' then
				triggered = triggered + 1
				total_chips = total_chips + 50
				trgu_ignat_show_card_message(hand_card, '+50', G.C.CHIPS)

			elseif enhancement == 'lucky' then
				triggered = triggered + 1
				local mult_seed = trgu_ignat_card_seed('ignat_lucky_mult', hand_card, index)
				local money_seed = trgu_ignat_card_seed('ignat_lucky_money', hand_card, index)

				local hit_mult
				local hit_money

				if SMODS.pseudorandom_probability then
					hit_mult = SMODS.pseudorandom_probability(card, mult_seed, 1, 5)
					hit_money = SMODS.pseudorandom_probability(card, money_seed, 1, 15)
				else
					hit_mult = pseudorandom(mult_seed) < 0.2
					hit_money = pseudorandom(money_seed) < (1 / 15)
				end

				if hit_mult then
					total_mult = total_mult + 20
					trgu_ignat_show_card_message(hand_card, '+20', G.C.MULT)
				else
					trgu_ignat_show_card_message(hand_card, 'Nope!', G.C.FILTER)
				end

				if hit_money then
					trgu_ignat_ease_dollars(20)
					trgu_ignat_show_card_message(hand_card, '+$20', G.C.MONEY)
				end

			elseif enhancement == 'convert' then
				local base_chips = trgu_ignat_base_chips(hand_card)

				if base_chips > 0 then
					triggered = triggered + 1
					total_mult = total_mult + base_chips
					trgu_ignat_show_card_message(hand_card, '+' .. tostring(base_chips), G.C.MULT)
				end

			elseif enhancement == 'corrupted' then
				triggered = triggered + 1

				local type_seed = trgu_ignat_card_seed('ignat_corrupted_type', hand_card, index)
				local roll = pseudorandom(type_seed)

				local roll_type

				if roll < 0.32 then
					roll_type = 1
				elseif roll < 0.64 then
					roll_type = 2
				elseif roll < 0.96 then
					roll_type = 3
				elseif roll < 0.99 then
					roll_type = 4
				else
					roll_type = 5
				end

				if roll_type == 1 then
					local dollars = trgu_ignat_roll_int(
						trgu_ignat_card_seed('ignat_corrupted_money', hand_card, index),
						-5,
						5
					)

					trgu_ignat_ease_dollars(dollars)
					trgu_ignat_show_card_message(
						hand_card,
						trgu_ignat_money_text(dollars),
						dollars >= 0 and G.C.MONEY or G.C.RED
					)

				elseif roll_type == 2 then
					local chips = trgu_ignat_roll_int(
						trgu_ignat_card_seed('ignat_corrupted_chips', hand_card, index),
						-20,
						20
					)

					total_chips = total_chips + chips
					trgu_ignat_show_card_message(
						hand_card,
						(chips >= 0 and '+' or '') .. tostring(chips),
						chips >= 0 and G.C.CHIPS or G.C.RED
					)

				elseif roll_type == 3 then
					local mult = trgu_ignat_roll_int(
						trgu_ignat_card_seed('ignat_corrupted_mult', hand_card, index),
						-10,
						10
					)

					total_mult = total_mult + mult
					trgu_ignat_show_card_message(
						hand_card,
						(mult >= 0 and '+' or '') .. tostring(mult),
						mult >= 0 and G.C.MULT or G.C.RED
					)

				elseif roll_type == 4 then
					total_mult = total_mult + 50
					trgu_ignat_show_card_message(hand_card, '+50', G.C.MULT)

				elseif roll_type == 5 then
					local created = trgu_ignat_create_negative_tarot(
						hand_card,
						trgu_ignat_card_seed('ignat_negative_tarot', hand_card, index)
					)

					trgu_ignat_show_card_message(
						hand_card,
						created and 'Tarot?' or 'Error',
						created and G.C.SECONDARY_SET.Tarot or G.C.RED
					)
				end

			elseif enhancement == 'gold'
				or enhancement == 'steel'
				or enhancement == 'wild'
			then
			end
		end

		if #glass_to_destroy > 0 then
			trgu_ignat_destroy_cards_later(glass_to_destroy)
		end

		if triggered <= 0 then
			return
		end

		local ret = {
			message = localize('trgu_ignat_work_done'),
			colour = G.C.FILTER
		}

		if total_chips ~= 0 then
			ret.chips = total_chips
		end

		if total_mult ~= 0 then
			ret.mult = total_mult
		end

		if total_xmult ~= 1 then
			ret.xmult = total_xmult
		end

		return ret
	end
}