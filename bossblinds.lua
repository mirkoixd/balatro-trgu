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