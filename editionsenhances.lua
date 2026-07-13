SMODS.Atlas {
	key = "convertcard",
	path = "ConvertCard.png",
	px = 71,
	py = 95
}

local function trgu_get_base_card_chips(card)
	if not card then return 0 end

	if card.base and card.base.nominal then
		return card.base.nominal
	end

	if card:get_id() == 14 then return 11 end
	if card:get_id() and card:get_id() > 10 then return 10 end
	return card:get_id() or 0
end

SMODS.Enhancement {
	key = 'convert',
	loc_txt = {
		['en-us'] = {
		name = 'Convert Card',
		text = {
			"converted into",
			"{C:mult}+#1#{} Mult"
		}
		},
		ru = {
		name = 'Валютная карта',
		text = {
			"конвертирует в",
			"{C:mult}+#1#{} множ."
		}
		}
	},

	atlas = 'convertcard',
	pos = { x = 0, y = 0 },

	loc_vars = function(self, info_queue, card)
		local base_chips = trgu_get_base_card_chips(card)

		return {
			vars = {
				base_chips
			}
		}
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.play and context.main_scoring then
			local base_chips = trgu_get_base_card_chips(card)

			if base_chips > 0 then
				return {
					chips = -base_chips,
					mult = base_chips,
					remove_default_message = true,
					message = localize{
					type = 'variable',
					key = 'trgu_converting',
					vars = { base_chips }
					},
					colour = G.C.MULT
				}
			end
		end
	end
}

SMODS.Atlas {
	key = "corruptedcard",
	path = "CorruptedCard.png",
	px = 71,
	py = 95
}

local function trgu_corrupted_roll_int(seed, min, max)
	return math.floor(pseudorandom(seed) * (max - min + 1)) + min
end

local TRGU_CORRUPTED_DESCRIPTIONS = {
	{ "When scored, gives", "a4z$E3%o" },
	{ "When scored, runs", "CORRUPT.EXE" },
	{ "When scored, returns", "??? VALUE ???" },
	{ "When scored, gives", "[-ERROR-]" },
	{ "When scored, calculates", "NULL" },
	{ "Wnan skorrd, geevz", "plntsiqjzsavrs" },
	{ "When scored, gives", "MISSINGNO" }
}

local function trgu_corrupted_create_negative_tarot(card)
	if not G.consumeables then return false end

	G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.2,
		func = function()
			local tarot = SMODS.add_card({
				set = 'Tarot',
				area = G.consumeables,
				allow_duplicates = true,
				key_append = 'corrupted_negative_tarot'
			})

			G.GAME.consumeable_buffer = math.max((G.GAME.consumeable_buffer or 1) - 1, 0)

			if tarot then
				tarot:set_edition('e_negative', true)
				tarot:juice_up()
			end

			return true
		end
	}))

	return true
end

local function trgu_corrupted_destroy_self(card)
	if not card then return false end

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.25,
		func = function()
			SMODS.destroy_cards(card, false, false, false)
			return true
		end
	}))

	return true
end

local function trgu_corrupted_description()
	local timer = 0

	if G and G.TIMERS then
		timer = G.TIMERS.REAL or G.TIMERS.TOTAL or 0
	elseif love and love.timer then
		timer = love.timer.getTime()
	end

	local index = (math.floor(timer) % #TRGU_CORRUPTED_DESCRIPTIONS) + 1
	return TRGU_CORRUPTED_DESCRIPTIONS[index]
end

local function trgu_corrupted_random_visible_hand()
	if not G.GAME or not G.GAME.hands then return nil end

	local hands = {}

	for hand_name, hand_data in pairs(G.GAME.hands) do
		if hand_data and hand_data.visible then
			hands[#hands + 1] = hand_name
		end
	end

	if #hands <= 0 then return nil end

	local index = math.floor(pseudorandom('corrupted_random_hand') * #hands) + 1
	return hands[index]
end

local function trgu_corrupted_level_random_hand(card)
	local hand_name = trgu_corrupted_random_visible_hand()

	if hand_name and level_up_hand then
		level_up_hand(card, hand_name, nil, 1)
		return true
	end

	return false
end

local function trgu_corrupted_is_cerac_joker(joker)
	if not joker or not joker.config or not joker.config.center then return false end

	local center = joker.config.center
	local key = tostring(center.key or "")
	local original_key = tostring(center.original_key or "")

	return original_key == 'cerac'
		or key == 'cerac'
		or key:sub(-5) == 'cerac'
end

local function trgu_corrupted_find_cerac_joker()
	if not G.jokers or not G.jokers.cards then return nil end

	for _, joker in ipairs(G.jokers.cards) do
		if trgu_corrupted_is_cerac_joker(joker) then
			return joker
		end
	end

	return nil
end

local function trgu_corrupted_destroy_cerac_if_exists()
	local cerac = trgu_corrupted_find_cerac_joker()

	if not cerac then return false end

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.15,
		func = function()
			SMODS.destroy_cards(cerac, false, false, false)
			return true
		end
	}))

	return true
end

SMODS.Enhancement {
	key = 'corrupted',
	loc_txt = {
		['en-us'] = {
		name = 'Corrupted Card',
		text = {
			"No rank or suit",
			"#1#",
			"{C:red}#2#{}"
		}
		},
		ru = {
		name = 'Повреждённая карта',
		text = {
			"Без достоинства или масти",
			"#1#",
			"{C:red}#2#{}"
		}
		}
	},

	atlas = 'corruptedcard',
	pos = { x = 0, y = 0 },

	replace_base_card = true,
	no_rank = true,
	no_suit = true,
	always_scores = true,

	loc_vars = function(self, info_queue, card)
		local desc = trgu_corrupted_description()

		return {
			vars = {
				desc[1],
				desc[2]
			}
		}
	end,

	calculate = function(self, card, context)
		if context.cardarea == G.play and context.main_scoring then
			local id = tostring(card.ID or '')
			
			if pseudorandom('corrupted_destroy_self_' .. id) < 0.01 then
				trgu_corrupted_destroy_self(card)
				return {
					message = localize('trgu_deleted'),
					colour = G.C.RED
				}
			end

			if pseudorandom('corrupted_negative_tarot_' .. id) < 0.02 then
				local created = trgu_corrupted_create_negative_tarot(card)

				return {
					message = created and localize('trgu_tarot_q') or localize('trgu_error'),
					colour = created and G.C.SECONDARY_SET.Tarot or G.C.RED
				}
			end

			if trgu_corrupted_find_cerac_joker()
				and pseudorandom('corrupted_destroy_cerac_' .. id) < 0.01
			then
				trgu_corrupted_destroy_cerac_if_exists()

				return {
					message = localize('trgu_cerac_q'),
					colour = G.C.RED
				}
			end

			if pseudorandom('corrupted_big_mult_' .. id) < 0.01 then
				return {
					mult = 50
				}
			end

			if pseudorandom('corrupted_level_hand_' .. id) < 0.05 then
				local upgraded = trgu_corrupted_level_random_hand(card)

				return {
					message = upgraded and localize('trgu_upgrade') or localize('trgu_error'),
					colour = upgraded and G.C.FILTER or G.C.RED
				}
			end

			local roll_type = math.floor(pseudorandom('corrupted_type_' .. id) * 3) + 1

			if roll_type == 1 then
				local mult = trgu_corrupted_roll_int(
					'corrupted_mult_' .. id,
					-10,
					10
				)

				return {
					mult = mult
				}
			elseif roll_type == 2 then
				local chips = trgu_corrupted_roll_int(
					'corrupted_chips_' .. id,
					-20,
					20
				)

				return {
					chips = chips
				}
			else
				local dollars = trgu_corrupted_roll_int(
					'corrupted_money_' .. id,
					-5,
					5
				)

				if dollars ~= 0 then
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.1,
						func = function()
							if ease_dollars then
								ease_dollars(dollars)
							elseif G and G.GAME then
								G.GAME.dollars = (G.GAME.dollars or 0) + dollars
							end

							return true
						end
					}))
				end

				local money_text

				if dollars > 0 then
					money_text = '+$' .. tostring(dollars)
				elseif dollars < 0 then
					money_text = '-$' .. tostring(math.abs(dollars))
				else
					money_text = '$0'
				end

				return {
					message = money_text,
					colour = dollars >= 0 and G.C.MONEY or G.C.RED
				}
			end
		end
	end
}