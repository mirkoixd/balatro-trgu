-- СОВИНЫЙ УРОК БОСС-БЛАЙНД
SMODS.Atlas {
	key = "duolingo_blind",
	path = "DuolingoBlind.png",
	px = 34,
	py = 34
}

SMODS.Atlas {
	key = "duolingo_owl",
	path = "DuolingoOwl.png",
	px = 71,
	py = 71
}

SMODS.Font {
	key = 'cyrillic',
	path = 'NotoSans-Bold.ttf'
}

local function trgu_duolingo_font()
	return SMODS.Fonts
		and (
			SMODS.Fonts['trgumod_cyrillic']
			or SMODS.Fonts['trgu_cyrillic']
			or SMODS.Fonts['cyrillic']
		)
end

TRGU = TRGU or {}
TRGU.duolingo = TRGU.duolingo or {}
TRGU.config = TRGU.config or {}

if TRGU.config.easier_owl_blind == nil then
	TRGU.config.easier_owl_blind = false
end

local TRGU_DUOLINGO_INTERVAL_NORMAL = 2
local TRGU_DUOLINGO_ANSWER_TIME_NORMAL = 3

local TRGU_DUOLINGO_INTERVAL_EASY = 5
local TRGU_DUOLINGO_ANSWER_TIME_EASY = 5

local function trgu_duolingo_interval()
	return TRGU
		and TRGU.config
		and TRGU.config.easier_owl_blind
		and TRGU_DUOLINGO_INTERVAL_EASY
		or TRGU_DUOLINGO_INTERVAL_NORMAL
end

local function trgu_duolingo_answer_time()
	return TRGU
		and TRGU.config
		and TRGU.config.easier_owl_blind
		and TRGU_DUOLINGO_ANSWER_TIME_EASY
		or TRGU_DUOLINGO_ANSWER_TIME_NORMAL
end

local function trgu_duolingo_get_questions()
	return TRGU.load_lang_content('content/duolingo_words')
end

local function trgu_duolingo_now()
	if G and G.TIMERS and G.TIMERS.REAL then
		return G.TIMERS.REAL
	end

	if love and love.timer then
		return love.timer.getTime()
	end

	return 0
end

local function trgu_duolingo_get_owl_atlas()
	if not G or not G.ASSET_ATLAS then return nil end

	return G.ASSET_ATLAS['duolingo_owl']
		or G.ASSET_ATLAS['trgu_duolingo_owl']
		or G.ASSET_ATLAS['trgumod_duolingo_owl']
end

local function trgu_duolingo_is_active_blind()
	local blind = G and G.GAME and G.GAME.blind
	local key = blind
		and blind.config
		and blind.config.blind
		and blind.config.blind.key

	return type(key) == 'string' and key:sub(-8) == 'duolingo'
end

local function trgu_duolingo_remove_ui()
	local state = TRGU.duolingo

	if state.question_ui then
		state.question_ui:remove()
		state.question_ui = nil
	end

	if state.timer_ui then
		state.timer_ui:remove()
		state.timer_ui = nil
	end
end

local function trgu_duolingo_penalty()
	local blind = G and G.GAME and G.GAME.blind
	if not blind or not blind.chips then return end

	blind.chips = math.ceil(blind.chips * 1.2)

	if number_format then
		blind.chip_text = number_format(blind.chips)
	else
		blind.chip_text = tostring(blind.chips)
	end

	if blind.juice_up then
		blind:juice_up()
	end
end

local function trgu_duolingo_pick_question()
	local state = TRGU.duolingo
	state.question_count = (state.question_count or 0) + 1

	local questions = trgu_duolingo_get_questions()

	if not questions or #questions <= 0 then
		return {
			word = "missing",
			option_a = "missing",
			option_b = "error",
			a_correct = true,
			b_correct = false
		}
	end

	local q_index = math.floor(
		pseudorandom('duolingo_question_' .. tostring(state.question_count)) * #questions
	) + 1

	local base = questions[q_index]
	local flip = pseudorandom('duolingo_flip_' .. tostring(state.question_count)) < 0.5

	local option_a = flip and base.correct or base.wrong
	local option_b = flip and base.wrong or base.correct

	return {
		word = base.word,
		option_a = option_a,
		option_b = option_b,
		a_correct = option_a == base.correct,
		b_correct = option_b == base.correct
	}
end

local function trgu_duolingo_schedule_next_question()
	local state = TRGU.duolingo

	state.question = nil
	state.question_active = false
	state.answer_remaining = nil
	state.remaining_text = nil
	state.last_timer_tick = nil
	state.buttons_enabled = true
	state.next_question_remaining = trgu_duolingo_interval()

	trgu_duolingo_remove_ui()
end

local function trgu_duolingo_finish_question(correct)
	local state = TRGU.duolingo

	if not state.active or not state.question_active then return end

	if not correct then
		trgu_duolingo_penalty()
	end

	trgu_duolingo_schedule_next_question()
end

local function trgu_duolingo_can_tick()
	if not TRGU.duolingo.active then return false end
	if not trgu_duolingo_is_active_blind() then return false end
	if not (G and G.STATE and G.STATES and G.STATES.SELECTING_HAND) then
		return false
	end

	if G.STATE ~= G.STATES.SELECTING_HAND then
		return false
	end

	return true
end

G.FUNCS.trgu_duolingo_answer_a = function(e)
	local state = TRGU.duolingo

	if not state.buttons_enabled then return end
	if not trgu_duolingo_can_tick() then return end
	if not state.question then return end

	trgu_duolingo_finish_question(state.question.a_correct)
end

G.FUNCS.trgu_duolingo_answer_b = function(e)
	local state = TRGU.duolingo

	if not state.buttons_enabled then return end
	if not trgu_duolingo_can_tick() then return end
	if not state.question then return end

	trgu_duolingo_finish_question(state.question.b_correct)
end

G.UIDEF.trgu_duolingo_question = function(question)
	local owl_atlas = trgu_duolingo_get_owl_atlas()
	local ui_font = trgu_duolingo_font()
	local owl_node

	if owl_atlas then
		local owl_sprite = Sprite(
			0,
			0,
			1.05,
			1.05,
			owl_atlas,
			{ x = 0, y = 0 }
		)

		owl_node = {
			n = G.UIT.O,
			config = {
				object = owl_sprite
			}
		}
	else
		owl_node = {
			n = G.UIT.T,
			config = {
				text = "OWL",
				scale = 0.7,
				colour = G.C.GREEN,
				shadow = true,
				font = ui_font
			}
		}
	end

	local function answer_button(text, button_name, colour)
		return {
			n = G.UIT.C,
			config = {
                align = "cm",
                padding = 0.08,
                r = 0.08,
                minw = 1.75,
                minh = 0.55,
                colour = TRGU.duolingo.buttons_enabled and colour or G.C.UI.BACKGROUND_INACTIVE,
                hover = TRGU.duolingo.buttons_enabled,
                shadow = true,
                button = TRGU.duolingo.buttons_enabled and button_name or nil
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						text = text,
						scale = 0.35,
						colour = G.C.UI.TEXT_LIGHT,
						shadow = true,
						font = ui_font
					}
				}
			}
		}
	end

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
					padding = 0.16,
					r = 0.12,
					colour = G.C.DYN_UI.MAIN,
					emboss = 0.05,
					minw = 4.2
				},
				nodes = {
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.04
						},
						nodes = { owl_node }
					},
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.08
						},
						nodes = {
							{
								n = G.UIT.T,
								config = {
									text = '"' .. question.word .. '"',
									scale = 0.5,
									colour = G.C.UI.TEXT_LIGHT,
									shadow = true,
									font = ui_font
								}
							}
						}
					},
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							padding = 0.06
						},
						nodes = {
							answer_button(question.option_a, "trgu_duolingo_answer_a", G.C.GREEN),
							{ n = G.UIT.B, config = { w = 0.12, h = 0.1 } },
							answer_button(question.option_b, "trgu_duolingo_answer_b", G.C.RED)
						}
					}
				}
			}
		}
	}
end

G.UIDEF.trgu_duolingo_timer = function()
	local state = TRGU.duolingo
	local ui_font = trgu_duolingo_font()

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
					minw = 1.4
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							ref_table = state,
							ref_value = "remaining_text",
							scale = 0.42,
							colour = G.C.FILTER,
							shadow = true,
							font = ui_font
						}
					}
				}
			}
		}
	}
end

local function trgu_duolingo_create_question_ui()
	local state = TRGU.duolingo
	if state.question_ui or not state.question then return end

	state.question_ui = UIBox {
		definition = G.UIDEF.trgu_duolingo_question(state.question),
		config = {
			align = "cri",
			major = G.ROOM_ATTACH,
			offset = { x = -0.25, y = -0.15 }
		}
	}
end

local function trgu_duolingo_create_timer_ui()
	local state = TRGU.duolingo
	if state.timer_ui then return end

	state.timer_ui = UIBox {
		definition = G.UIDEF.trgu_duolingo_timer(),
		config = {
			align = "cri",
			major = G.ROOM_ATTACH,
			offset = { x = -1.65, y = 1.65 }
		}
	}
end

local function trgu_duolingo_update_timer_text()
	local state = TRGU.duolingo
	if not state.question_active or not state.answer_remaining then return end

	local tenths = math.ceil(state.answer_remaining * 10)

	if state.last_timer_tick == tenths then return end
	state.last_timer_tick = tenths

	state.remaining_text = string.format("%.1fs", tenths / 10)
end

local function trgu_duolingo_render_question()
	local state = TRGU.duolingo
	if not state.question_active or not state.question then return end

	trgu_duolingo_update_timer_text()
	trgu_duolingo_create_question_ui()
	trgu_duolingo_create_timer_ui()
end

local function trgu_duolingo_start_question()
	local state = TRGU.duolingo

	state.question = trgu_duolingo_pick_question()
	state.question_active = true
	state.answer_remaining = trgu_duolingo_answer_time()
	state.last_timer_tick = nil
	state.remaining_text = string.format("%.1fs", state.answer_remaining)
	state.buttons_enabled = true

	if state.question_ui then
		state.question_ui:remove()
		state.question_ui = nil
	end

	if state.timer_ui then
		state.timer_ui:remove()
		state.timer_ui = nil
	end

	trgu_duolingo_render_question()
end

local function trgu_duolingo_restore_if_loaded_run()
	local state = TRGU.duolingo

	if not trgu_duolingo_is_active_blind() then
		return false
	end

	if state.active then
		return true
	end

	print("Duolingo restored after loading run")

	state.active = true
	state.question_active = false
	state.question = nil
	state.question_count = state.question_count or 0

	state.question_ui = nil
	state.timer_ui = nil

	state.next_question_remaining = 0.5
	state.answer_remaining = nil
	state.remaining_text = nil
	state.last_timer_tick = nil

	state.buttons_enabled = true
	state.last_update_time = trgu_duolingo_now()

	return true
end

local function trgu_duolingo_update()
	local state = TRGU.duolingo

	if not state.active then
		if not trgu_duolingo_restore_if_loaded_run() then
			return
		end
	end

	if not trgu_duolingo_is_active_blind() then
		state.active = false
		state.question_active = false
		state.question = nil
		state.answer_remaining = nil
		state.next_question_remaining = nil
		state.remaining_text = nil
		trgu_duolingo_remove_ui()
		return
	end

	local now = trgu_duolingo_now()
	local dt = 0

	if state.last_update_time then
		dt = math.max(0, now - state.last_update_time)
	end

	state.last_update_time = now

	local can_tick = trgu_duolingo_can_tick()

	if state.buttons_enabled ~= can_tick then
		state.buttons_enabled = can_tick

		if state.question_active and state.question then
			if state.question_ui then
				state.question_ui:remove()
				state.question_ui = nil
			end

			trgu_duolingo_create_question_ui()
		end
	end

	if not can_tick then
		if state.question_active then
			trgu_duolingo_render_question()
		end

		return
	end

	if state.question_active then
		state.answer_remaining = math.max(0, (state.answer_remaining or 0) - dt)

		if state.answer_remaining <= 0 then
			trgu_duolingo_finish_question(false)
			return
		end

		trgu_duolingo_render_question()
		return
	end

	state.next_question_remaining = math.max(0, (state.next_question_remaining or trgu_duolingo_interval()) - dt)

	if state.next_question_remaining <= 0 then
		trgu_duolingo_start_question()
	end
end

if not TRGU.duolingo_update_hooked then
	TRGU.duolingo_update_hooked = true
	TRGU.duolingo_game_update_ref = Game.update

	function Game:update(dt)
		TRGU.duolingo_game_update_ref(self, dt)
		trgu_duolingo_update()
	end
end

SMODS.Blind {
	key = 'duolingo',

	loc_txt = {
		['en-us'] = {
			name = 'Owl Lingo',
			text = {
				"Translate words in time",
				"Wrong or missed answers",
				"increase required score",
				"by {X:mult,C:white} X1.2 {}"
			}
		},
		ru = {
			name = 'Совиный урок',
			text = {
				"Переводите слова вовремя",
				"Ошибки и пропуски",
				"увеличивают требуемый счёт",
				"на {X:mult,C:white} X1.2 {}"
			}
		}
	},

	atlas = 'duolingo_blind',
	pos = { x = 0, y = 0 },

	mult = 2,
	dollars = 7,

	boss = {
		min = 1
	},

	boss_colour = HEX('58CC02'),

set_blind = function(self)
	local state = TRGU.duolingo

	state.active = true
	state.question_active = false
	state.question = nil
	state.question_count = 0

	state.next_question_remaining = trgu_duolingo_interval()
	state.answer_remaining = nil
	state.remaining_text = nil
	state.last_timer_tick = nil

	state.buttons_enabled = true
	state.last_update_time = trgu_duolingo_now()

	trgu_duolingo_remove_ui()
end,

disable = function(self)
	local state = TRGU.duolingo

	state.active = false
	state.question_active = false
	state.question = nil
	state.answer_remaining = nil
	state.next_question_remaining = nil
	state.remaining_text = nil

	trgu_duolingo_remove_ui()
end,

defeat = function(self)
	local state = TRGU.duolingo

	state.active = false
	state.question_active = false
	state.question = nil
	state.answer_remaining = nil
	state.next_question_remaining = nil
	state.remaining_text = nil

	trgu_duolingo_remove_ui()
end
}

-- КАФЕ МИШИ БОСС-БЛАЙНД
SMODS.Atlas {
	key = "misha_cafe_blind",
	path = "MishaCafeBlind.png",
	px = 34,
	py = 34
}

TRGU = TRGU or {}
TRGU.misha_cafe = TRGU.misha_cafe or {}

local function trgu_misha_cafe_resolve_mishburger_key()
	if not G or not G.P_CENTERS then return nil end

	local candidates = {
		'j_mishburger',
		'j_trgu_mishburger',
		'j_trgumod_mishburger'
	}

	for _, key in ipairs(candidates) do
		if G.P_CENTERS[key] then
			return key
		end
	end

	for key, center in pairs(G.P_CENTERS) do
		if type(key) == 'string'
			and key:sub(1, 2) == 'j_'
			and key:sub(-10) == 'mishburger'
		then
			return key
		end
	end

	return nil
end

local function trgu_misha_cafe_is_mishburger(card)
	local center = card and card.config and card.config.center
	if not center then return false end

	local key = tostring(center.key or ''):lower()
	local original_key = tostring(center.original_key or ''):lower()
	local resolved_key = trgu_misha_cafe_resolve_mishburger_key()

	return key == tostring(resolved_key or ''):lower()
		or key:sub(-10) == 'mishburger'
		or original_key == 'mishburger'
end

local function trgu_misha_cafe_has_mishburger()
	if not G or not G.jokers or not G.jokers.cards then
		return false
	end

	for _, joker in ipairs(G.jokers.cards) do
		if trgu_misha_cafe_is_mishburger(joker) then
			return true
		end
	end

	return false
end

local function trgu_misha_cafe_get_non_mishburger_jokers()
	local result = {}

	if not G or not G.jokers or not G.jokers.cards then
		return result
	end

	for _, joker in ipairs(G.jokers.cards) do
		if joker
			and not joker.removed
			and not trgu_misha_cafe_is_mishburger(joker)
		then
			result[#result + 1] = joker
		end
	end

	return result
end

local function trgu_misha_cafe_has_joker_space()
	if not G or not G.jokers then return false end

	local buffer = G.GAME and (G.GAME.joker_buffer or 0) or 0
	local current = #G.jokers.cards + buffer
	local limit = G.jokers.config.card_limit or 0

	return current < limit
end

local function trgu_misha_cafe_blind_won()
	if not G or not G.GAME or not G.GAME.blind then
		return false
	end

	local chips = tonumber(G.GAME.chips or 0) or 0
	local target = tonumber(G.GAME.blind.chips or math.huge) or math.huge

	return chips >= target
end

local function trgu_misha_cafe_safe_remove_old_joker_effects(joker)
	local old_center = joker and joker.config and joker.config.center

	if old_center and type(old_center.remove_from_deck) == 'function' then
		local ok, err = pcall(function()
			old_center:remove_from_deck(joker, false)
		end)

		if not ok then
			print("Misha Cafe: old remove_from_deck failed")
			print(tostring(err))
		end
	end
end

local function trgu_misha_cafe_safe_add_new_joker_effects(joker)
	local new_center = joker and joker.config and joker.config.center

	if new_center and type(new_center.add_to_deck) == 'function' then
		local ok, err = pcall(function()
			new_center:add_to_deck(joker, false)
		end)

		if not ok then
			print("Misha Cafe: new add_to_deck failed")
			print(tostring(err))
		end
	end
end

local function trgu_misha_cafe_transform_joker(joker)
	local mishburger_key = trgu_misha_cafe_resolve_mishburger_key()

	if not mishburger_key or not G.P_CENTERS[mishburger_key] then
		print("Misha Cafe: Mishburger joker not found")
		return false
	end

	if not joker or joker.removed then
		return false
	end

	trgu_misha_cafe_safe_remove_old_joker_effects(joker)

	joker:set_ability(G.P_CENTERS[mishburger_key], nil, true)

	if joker.set_sprites then
		joker:set_sprites(joker.config.center)
	end

	if joker.set_cost then
		joker:set_cost()
	end

	trgu_misha_cafe_safe_add_new_joker_effects(joker)

	if joker.juice_up then
		joker:juice_up()
	end

	SMODS.calculate_effect({
		message = localize('trgu_mishburger') or 'Mishburger!',
		colour = G.C.FILTER
	}, joker)

	return true
end

local function trgu_misha_cafe_add_mishburger()
	local mishburger_key = trgu_misha_cafe_resolve_mishburger_key()

	if not mishburger_key or not G.P_CENTERS[mishburger_key] then
		print("Misha Cafe: Mishburger joker not found")
		return false
	end

	if not trgu_misha_cafe_has_joker_space() then
		return false
	end

	G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + 1

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.2,
		func = function()
			local joker = SMODS.add_card({
				set = 'Joker',
				area = G.jokers,
				key = mishburger_key,
				allow_duplicates = true,
				key_append = 'misha_cafe'
			})

			G.GAME.joker_buffer = math.max((G.GAME.joker_buffer or 1) - 1, 0)

			if joker then
				SMODS.calculate_effect({
					message = localize('trgu_mishburger') or 'Mishburger!',
					colour = G.C.FILTER
				}, joker)
			end

			return true
		end
	}))

	return true
end

local function trgu_misha_cafe_do_effect()
	if TRGU.misha_cafe.disabled_this_blind then
		return false
	end

	local candidates = trgu_misha_cafe_get_non_mishburger_jokers()

	if #candidates > 0 then
		local seed =
			'misha_cafe_'
			.. tostring(G.GAME.hands_played or 0)
			.. '_'
			.. tostring(G.GAME.round or 0)

		local index = math.floor(pseudorandom(seed) * #candidates) + 1
		local chosen = candidates[index]

		return trgu_misha_cafe_transform_joker(chosen)
	end

	return trgu_misha_cafe_add_mishburger()
end

SMODS.Blind {
	key = 'misha_cafe',

	loc_txt = {
		['en-us'] = {
			name = "Misha's Cafe",
			text = {
				"If you enter with",
				"{C:attention}Mishburger{},",
				"this Blind is disabled",
				"Otherwise, after each hand,",
				"turns a random Joker",
				"into {C:attention}Mishburger{}"
			}
		},
		ru = {
			name = 'Кафе Миши',
			text = {
				"Если при входе есть",
				"{C:attention}Мишбургер{},",
				"блайнд отключается",
				"Иначе после каждой руки",
				"случайный джокер становится",
				"{C:attention}Мишбургером{}"
			}
		}
	},

	atlas = 'misha_cafe_blind',
	pos = { x = 0, y = 0 },

	mult = 2,
	dollars = 5,

	boss = {
		min = 2
	},

	boss_colour = HEX('D89A45'),

	set_blind = function(self)
		TRGU.misha_cafe.disabled_this_blind = false

		if trgu_misha_cafe_has_mishburger() then
			TRGU.misha_cafe.disabled_this_blind = true

			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.2,
				func = function()
					if G.GAME
						and G.GAME.blind
						and G.GAME.blind.disable
					then
						G.GAME.blind:disable()
					end

					return true
				end
			}))
		end
	end,

	calculate = function(self, blind, context)
		if context.after and not TRGU.misha_cafe.disabled_this_blind then
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.35,
				func = function()
					if not trgu_misha_cafe_blind_won() then
						trgu_misha_cafe_do_effect()
					end

					return true
				end
			}))
		end
	end,

	disable = function(self)
		TRGU.misha_cafe.disabled_this_blind = true
	end,

	defeat = function(self)
		TRGU.misha_cafe.disabled_this_blind = false
	end
}

-- ДОПОЛНИТЕЛЬНЫЕ ХУКИ

TRGU = TRGU or {}

local function trgu_blind_current_key()
	local blind = G and G.GAME and G.GAME.blind
	local key = blind
		and blind.config
		and blind.config.blind
		and blind.config.blind.key

	return tostring(key or ''):lower()
end

local function trgu_blind_won()
	if not G or not G.GAME or not G.GAME.blind then
		return false
	end

	local chips = tonumber(G.GAME.chips or 0) or 0
	local target = tonumber(G.GAME.blind.chips or math.huge) or math.huge

	return chips >= target
end

local function trgu_update_blind_chips(blind, amount)
	if not blind then return end

	blind.chips = math.ceil(amount)

	if number_format then
		blind.chip_text = number_format(blind.chips)
	else
		blind.chip_text = tostring(blind.chips)
	end

	if blind.juice_up then
		blind:juice_up()
	end
end

local function trgu_find_enhancement_center(short_key)
	if not G or not G.P_CENTERS then return nil end

	local candidates = {
		'm_' .. short_key,
		'm_trgu_' .. short_key,
		'm_trgumod_' .. short_key
	}

	for _, key in ipairs(candidates) do
		if G.P_CENTERS[key] then
			return G.P_CENTERS[key]
		end
	end

	for key, center in pairs(G.P_CENTERS) do
		if type(key) == 'string'
			and key:sub(1, 2) == 'm_'
			and key:sub(-#short_key) == short_key
		then
			return center
		end
	end

	return nil
end

local function trgu_card_has_enhancement(card, short_key)
	local center = card and card.config and card.config.center
	local key = center and tostring(center.key or ''):lower() or ''
	local original_key = center and tostring(center.original_key or ''):lower() or ''

	short_key = tostring(short_key or ''):lower()

	return key == 'm_' .. short_key
		or key:sub(-#short_key) == short_key
		or original_key == short_key
end

-- КИРПИЧ БОСС-БЛАЙНД

SMODS.Atlas {
	key = "brick_blind",
	path = "BrickBlind.png",
	px = 34,
	py = 34
}

TRGU.brick_blind = TRGU.brick_blind or {}

local function trgu_brick_pick_card()
	if not G or not G.hand or not G.hand.cards then
		return nil
	end

	local candidates = {}

	for _, card in ipairs(G.hand.cards) do
		if card
			and not card.removed
			and not trgu_card_has_enhancement(card, 'stone')
		then
			candidates[#candidates + 1] = card
		end
	end

	if #candidates <= 0 then
		return nil
	end

	local seed =
		'brick_blind_'
		.. tostring(G.GAME.hands_played or 0)
		.. '_'
		.. tostring(G.GAME.round or 0)

	local index = math.floor(pseudorandom(seed) * #candidates) + 1
	return candidates[index]
end

local function trgu_brick_apply()
	if trgu_blind_won() then return false end

	local stone_center = trgu_find_enhancement_center('stone')
	if not stone_center then
		print("Brick Blind: Stone enhancement not found")
		return false
	end

	local chosen = trgu_brick_pick_card()
	if not chosen then return false end

	chosen:set_ability(stone_center, nil, true)
	chosen:juice_up()

	SMODS.calculate_effect({
		message = localize('trgu_stone') or 'Stone!',
		colour = G.C.CHIPS
	}, chosen)

	return true
end

SMODS.Blind {
	key = 'brick',

	loc_txt = {
		['en-us'] = {
			name = 'Brick',
			text = {
				"After each non-winning hand,",
				"one random card",
				"left in hand becomes",
				"a {C:attention}Stone Card{}"
			}
		},
		ru = {
			name = 'Кирпич',
			text = {
				"После каждой непобедной руки",
				"одна случайная карта,",
				"оставшаяся в руке,",
				"становится {C:attention}каменной{}"
			}
		}
	},

	atlas = 'brick_blind',
	pos = { x = 0, y = 0 },

	mult = 2,
	dollars = 5,

	boss = {
		min = 2
	},

	boss_colour = HEX('7C0A00'),

	calculate = function(self, blind, context)
		if context.after then
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.25,
				func = function()
					trgu_brick_apply()
					return true
				end
			}))
		end
	end
}

-- ЗЕ БОКС БОСС-БЛАЙНД

SMODS.Atlas {
	key = "the_box_blind",
	path = "TheBoxBlind.png",
	px = 34,
	py = 34
}

TRGU = TRGU or {}
TRGU.the_box = TRGU.the_box or {}

local function trgu_the_box_is_active()
	local key = trgu_blind_current_key()

	return TRGU.the_box.active
		and (
			key == 'bl_the_box'
			or key == 'bl_trgu_the_box'
			or key == 'bl_trgumod_the_box'
			or key:sub(-7) == 'the_box'
		)
end

local function trgu_the_box_should_trigger()
	if TRGU.the_box.triggered_this_blind then
		return false
	end

	if not trgu_the_box_is_active() then
		return false
	end

	if not G or not G.GAME or not G.GAME.blind then
		return false
	end

	local chips = tonumber(G.GAME.chips or 0) or 0
	local target = tonumber(G.GAME.blind.chips or math.huge) or math.huge

	return chips > target * 2
end

local function trgu_the_box_set_money_to_zero()
	if not trgu_the_box_should_trigger() then
		return false
	end

	TRGU.the_box.triggered_this_blind = true

	if G and G.GAME then
		G.GAME.dollars = 0
	end

	if G.HUD and G.HUD:get_UIE_by_ID('dollar_text') then
		G.HUD:get_UIE_by_ID('dollar_text').config.object:update()
	end

	if G.HUD and G.HUD:get_UIE_by_ID('dollars_text') then
		G.HUD:get_UIE_by_ID('dollars_text').config.object:update()
	end

	if G.GAME.blind and G.GAME.blind.juice_up then
		G.GAME.blind:juice_up()
	end

	if play_sound then
		play_sound('cancel')
	end

	return true
end

if not TRGU.the_box_update_hooked then
	TRGU.the_box_update_hooked = true
	TRGU.the_box_game_update_ref = Game.update

	function Game:update(dt)
		TRGU.the_box_game_update_ref(self, dt)

		if trgu_the_box_should_trigger() then
			trgu_the_box_set_money_to_zero()
		end
	end
end

SMODS.Blind {
	key = 'the_box',

	loc_txt = {
		['en-us'] = {
			name = 'The Box',
			text = {
				"If your score exceeds",
				"the required score by",
				"more than {C:attention}2X{},",
				"sets money to {C:money}$0{}"
			}
		},
		ru = {
			name = 'The Box',
			text = {
				"Если ваш счёт превышает",
				"требуемый больше чем",
				"в {C:attention}2 раза{},",
				"устанавливает деньги на {C:money}$0{}"
			}
		}
	},

	atlas = 'the_box_blind',
	pos = { x = 0, y = 0 },

	mult = 2,
	dollars = 5,

	boss = {
		min = 2
	},

	boss_colour = HEX('646464'),

	set_blind = function(self)
		TRGU.the_box.active = true
		TRGU.the_box.triggered_this_blind = false
	end,

	disable = function(self)
		TRGU.the_box.active = false
		TRGU.the_box.triggered_this_blind = false
	end,

	defeat = function(self)
		TRGU.the_box.active = false
		TRGU.the_box.triggered_this_blind = false
	end
}

-- ДАНЯ БОСС-БЛАЙНД

SMODS.Atlas {
	key = "d4n9_blind",
	path = "D4N9Blind.png",
	px = 34,
	py = 34
}

TRGU.d4n9 = TRGU.d4n9 or {}

local TRGU_D4N9_CONSUMABLE_SETS = {
	Tarot = true,
	Planet = true,
	Spectral = true,
	Admin = true
}

local function trgu_d4n9_is_active()
	local key = trgu_blind_current_key()

	return TRGU.d4n9.active
		and (
			key == 'bl_trgu_d4n9'
			or key == 'bl_trgumod_d4n9'
			or key == 'bl_d4n9'
			or key:sub(-4) == 'd4n9'
		)
end

local function trgu_d4n9_is_consumable_card(card)
	if not card then return false end

	if G and G.consumeables and card.area == G.consumeables then
		return true
	end

	local center = card.config and card.config.center
	local set = center and center.set

	return TRGU_D4N9_CONSUMABLE_SETS[set] == true
end

local function trgu_d4n9_block_message(card)
	if card then
		SMODS.calculate_effect({
			message = localize('trgu_no_consumables') or 'No consumables!',
			colour = G.C.RED
		}, card)

		if card.juice_up then
			card:juice_up()
		end
	end

	if play_sound then
		play_sound('cancel')
	end
end

local function trgu_d4n9_install_use_card_hook()
	if TRGU.d4n9.use_card_hooked then return end
	if not G or not G.FUNCS or not G.FUNCS.use_card then return end

	TRGU.d4n9.use_card_hooked = true
	TRGU.d4n9_use_card_ref = G.FUNCS.use_card

	G.FUNCS.use_card = function(e)
		local card = e and e.config and e.config.ref_table

		if trgu_d4n9_is_active()
			and trgu_d4n9_is_consumable_card(card)
		then
			trgu_d4n9_block_message(card)
			return true
		end

		return TRGU.d4n9_use_card_ref(e)
	end
end

trgu_d4n9_install_use_card_hook()

SMODS.Blind {
	key = 'd4n9',

	loc_txt = {
		['en-us'] = {
			name = 'D4N9',
			text = {
				"You cannot use",
				"{C:attention}Consumable{} cards",
				"during this Boss Blind"
			}
		},
		ru = {
			name = 'D4N9',
			text = {
				"Во время этого",
				"босс-блайнда нельзя",
				"использовать {C:attention}расходники{}"
			}
		}
	},

	atlas = 'd4n9_blind',
	pos = { x = 0, y = 0 },

	mult = 2,
	dollars = 5,

	boss = {
		min = 2
	},

	boss_colour = HEX('7C007C'),

	set_blind = function(self)
		TRGU.d4n9.active = true
		trgu_d4n9_install_use_card_hook()
	end,

	disable = function(self)
		TRGU.d4n9.active = false
	end,

	defeat = function(self)
		TRGU.d4n9.active = false
	end
}


-- ТЫКВА БОСС-БЛАЙНД
SMODS.Atlas {
	key = "pumpkin_blind",
	path = "PumpkinBlind.png",
	px = 34,
	py = 34
}

TRGU.pumpkin_blind = TRGU.pumpkin_blind or {}

local function trgu_pumpkin_current_hand_score()
	local chips = tonumber(hand_chips or 0) or 0
	local current_mult = tonumber(mult or 0) or 0

	return math.floor(chips * current_mult)
end

local function trgu_pumpkin_try_extend_blind(projected_score)
	if TRGU.pumpkin_blind.first_hand_checked then
		return false
	end

	if not G or not G.GAME or not G.GAME.blind then
		return false
	end

	local blind = G.GAME.blind
	local target = tonumber(blind.chips or math.huge) or math.huge
	local score = tonumber(projected_score or 0) or 0

	TRGU.pumpkin_blind.first_hand_checked = true

	if score < target then
		return false
	end

	local new_target = math.max(target + 1, math.ceil(score * 2))

	trgu_update_blind_chips(blind, new_target)

	if play_sound then
		play_sound('tarot1')
	end

	return true
end

SMODS.Blind {
	key = 'pumpkin',

	loc_txt = {
		['en-us'] = {
			name = 'Pumpkin',
			text = {
				"If the first hand",
				"would defeat this Blind,",
				"required score becomes",
				"{C:attention}2X{} that hand's score"
			}
		},
		ru = {
			name = 'Тыква',
			text = {
				"Если первая рука",
				"побеждает этот блайнд,",
				"требуемый счёт становится",
				"{C:attention}2X{} очков этой руки"
			}
		}
	},

	atlas = 'pumpkin_blind',
	pos = { x = 0, y = 0 },

	mult = 2,
	dollars = 5,

	boss = {
		min = 2
	},

	boss_colour = HEX('E06A22'),

	set_blind = function(self)
		TRGU.pumpkin_blind.first_hand_checked = false
	end,

	calculate = function(self, blind, context)
		if context.final_scoring_step
			and not TRGU.pumpkin_blind.first_hand_checked
		then
			local previous_score = tonumber(G.GAME.chips or 0) or 0
			local hand_score = trgu_pumpkin_current_hand_score()
			local projected_score = previous_score + hand_score

			if trgu_pumpkin_try_extend_blind(projected_score) then
				return {
					message = 'X2',
					colour = G.C.ORANGE
				}
			end
		end

		if context.after
			and not TRGU.pumpkin_blind.first_hand_checked
		then
			local score = tonumber(G.GAME.chips or 0) or 0

			if trgu_pumpkin_try_extend_blind(score) then
				return {
					message = 'X2',
					colour = G.C.ORANGE
				}
			end
		end
	end,

	disable = function(self)
		TRGU.pumpkin_blind.first_hand_checked = true
	end,

	defeat = function(self)
		TRGU.pumpkin_blind.first_hand_checked = true
	end
}