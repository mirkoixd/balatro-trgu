SMODS.Atlas {
	key = "triviadeckatlas",
	path = "TriviaDeck.png",
	px = 71,
	py = 95
}

SMODS.Atlas {
	key = "trgu_tags",
	path = "TrGuTags.png",
	px = 34,
	py = 34
}

local function trgu_resolve_center_key(prefix, short_key)
	if not G or not G.P_CENTERS then return nil end

	local candidates = {
		prefix .. short_key,
		prefix .. 'trgu_' .. short_key,
		prefix .. 'TrGu_' .. short_key
	}

	for _, key in ipairs(candidates) do
		if G.P_CENTERS[key] then
			return key
		end
	end

	for key, center in pairs(G.P_CENTERS) do
		if type(key) == 'string'
			and key:sub(1, #prefix) == prefix
			and key:sub(-#short_key) == short_key
		then
			return key
		end
	end

	return nil
end

local function trgu_resolve_joker_key(short_key)
	return trgu_resolve_center_key('j_', short_key)
end

local function trgu_resolve_pack_key(short_key)
	return trgu_resolve_center_key('p_', short_key)
end

TRGU = TRGU or {}
TRGU.tag_pack_queue = TRGU.tag_pack_queue or {}
TRGU.tag_pack_opening = TRGU.tag_pack_opening or false
TRGU.tag_pack_seen_open = TRGU.tag_pack_seen_open or false
TRGU.tag_pack_started_at = TRGU.tag_pack_started_at or 0

local function trgu_tag_pack_now()
	if G and G.TIMERS and G.TIMERS.REAL then
		return G.TIMERS.REAL
	end

	if love and love.timer then
		return love.timer.getTime()
	end

	return 0
end

local function trgu_is_pack_open_state()
	if G and G.pack_cards and G.pack_cards.cards and #G.pack_cards.cards > 0 then
		return true
	end

	if not (G and G.STATE and G.STATES) then return false end

	local pack_states = {
		'STANDARD_PACK',
		'TAROT_PACK',
		'PLANET_PACK',
		'SPECTRAL_PACK',
		'BUFFOON_PACK',
		'SMODS_BOOSTER_OPENED'
	}

	for _, state_name in ipairs(pack_states) do
		if G.STATES[state_name] and G.STATE == G.STATES[state_name] then
			return true
		end
	end

	return false
end

local trgu_try_open_next_tag_pack

local function trgu_open_free_pack_now(short_key)
	local pack_key = trgu_resolve_pack_key(short_key)

	if not pack_key or not G.P_CENTERS[pack_key] then
		print("TRGU Tag: pack not found: " .. tostring(short_key))
		return false
	end

	TRGU.tag_pack_opening = true
	TRGU.tag_pack_seen_open = false
	TRGU.tag_pack_started_at = trgu_tag_pack_now()

	local ok, err = pcall(function()
		local pack_card = Card(
			G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2,
			G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2,
			G.CARD_W * 1.27,
			G.CARD_H * 1.27,
			G.P_CARDS.empty,
			G.P_CENTERS[pack_key],
			{
				bypass_discovery_center = true,
				bypass_discovery_ui = true
			}
		)

		pack_card.cost = 0
		pack_card.from_tag = true
		pack_card.shop_voucher = false
		pack_card.ability.couponed = true

		G.FUNCS.use_card({
			config = {
				ref_table = pack_card
			}
		})

		pack_card:start_materialize()
	end)

	if not ok then
		print("TRGU Tag: failed to open pack " .. tostring(short_key))
		print(tostring(err))

		TRGU.tag_pack_opening = false
		TRGU.tag_pack_seen_open = false
		TRGU.tag_pack_started_at = 0

		return false
	end

	return true
end

local function trgu_queue_free_pack(short_key)
	TRGU.tag_pack_queue[#TRGU.tag_pack_queue + 1] = short_key

	if trgu_try_open_next_tag_pack then
		trgu_try_open_next_tag_pack()
	end

	return true
end

trgu_try_open_next_tag_pack = function()
	if TRGU.tag_pack_opening then return end
	if trgu_is_pack_open_state() then return end
	if not TRGU.tag_pack_queue or #TRGU.tag_pack_queue <= 0 then return end

	local next_pack = table.remove(TRGU.tag_pack_queue, 1)

	if next_pack then
		trgu_open_free_pack_now(next_pack)
	end
end

if not TRGU.tag_pack_queue_update_hooked then
	TRGU.tag_pack_queue_update_hooked = true
	TRGU.tag_pack_queue_game_update_ref = Game.update

	function Game:update(dt)
		TRGU.tag_pack_queue_game_update_ref(self, dt)

		if TRGU.tag_pack_opening then
			if trgu_is_pack_open_state() then
				TRGU.tag_pack_seen_open = true
			end

			if TRGU.tag_pack_seen_open and not trgu_is_pack_open_state() then
				TRGU.tag_pack_opening = false
				TRGU.tag_pack_seen_open = false
				TRGU.tag_pack_started_at = 0

				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.25,
					func = function()
						trgu_try_open_next_tag_pack()
						return true
					end
				}))
			end

			if not TRGU.tag_pack_seen_open
				and trgu_tag_pack_now() - (TRGU.tag_pack_started_at or 0) > 2
			then
				TRGU.tag_pack_opening = false
				TRGU.tag_pack_seen_open = false
				TRGU.tag_pack_started_at = 0

				trgu_try_open_next_tag_pack()
			end
		else
			trgu_try_open_next_tag_pack()
		end
	end
end

SMODS.Back {
	key = 'trivia_deck',

	loc_txt = {
		['en-us'] = {
			name = 'Trivia Deck',
			text = {
			"Start run with",
			"an {C:attention}Eternal{}",
			"{C:attention}Fibbage Joker{}"
			}
		},
		ru = {
			name = 'Колода-викторина',
			text = {
			"Начните забег",
			"с {C:attention}Вечной{}",
			"{C:attention}Бредовухой 4{}"
			}
		}
	},

	atlas = 'triviadeckatlas',
	pos = { x = 0, y = 0 },
	unlocked = true,
	discovered = true,

	apply = function(self, back)
		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 0.1,
			func = function()
				local fibbage_key = trgu_resolve_joker_key('fibbagejoker')

				if fibbage_key then
					local joker = SMODS.add_card({
						set = 'Joker',
						area = G.jokers,
						key = fibbage_key,
						no_edition = true,
						allow_duplicates = true,
						key_append = 'trivia_deck'
					})

					if joker then
						if joker.set_eternal then
							joker:set_eternal(true)
						else
							joker.ability = joker.ability or {}
							joker.ability.eternal = true
						end

						joker:juice_up()
					end
				else
					print("Trivia Deck: fibbagejoker was not found")
				end

				return true
			end
		}))
	end
}

SMODS.Tag {
	key = 'admin_help',

	loc_txt = {
		['en-us'] = {
			name = 'Admin\'s Help',
			text = {
				"Immediately open",
				"a free {C:purple}Mega Admin Pack{}"
			}
		},
		ru = {
			name = 'Помощь админов',
			text = {
				"Даёт бесплатный",
				"{C:purple}Мега Админ Набор{}"
			}
		}
	},

	atlas = 'trgu_tags',
	pos = { x = 0, y = 0 },

	config = {
		type = 'immediate'
	},

	apply = function(self, tag, context)
		if context.type == self.config.type then
			tag:yep('+', G.C.PURPLE, function()
				trgu_queue_free_pack('admin_pack_mega')
				return true
			end)

			tag.triggered = true
			return true
		end
	end
}

SMODS.Tag {
	key = 'trgu_effect',

	loc_txt = {
		['en-us'] = {
			name = 'TrGu Effect',
			text = {
				"Immediately open",
				"a free {C:red}Mega TrGu Pack{}"
			}
		},
		ru = {
			name = 'Эффект TrGu',
			text = {
				"Даёт бесплатный",
				"{C:purple}Мега TrGu Набор{}"
			}
		}
	},

	atlas = 'trgu_tags',
	pos = { x = 1, y = 0 },

	config = {
		type = 'immediate'
	},

	apply = function(self, tag, context)
		if context.type == self.config.type then
			tag:yep('+', G.C.RED, function()
				trgu_queue_free_pack('trgu_joker_pack_mega')
				return true
			end)

			tag.triggered = true
			return true
		end
	end
}

SMODS.Atlas {
	key = "corrupteddeckatlas",
	path = "CorruptedDeck.png",
	px = 71,
	py = 95
}

local function trgu_find_corrupted_enhancement_for_deck()
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
			return G.P_CENTERS[key]
		end
	end

	return nil
end

SMODS.Back {
	key = 'corrupted_deck',

	loc_txt = {
		['en-us'] = {
		name = 'Corrupted Deck',
		text = {
			"Each card in your",
			"starting deck has a",
			"{C:green}1 in 2{} chance",
			"to become {C:red}Corrupted{}"
		}
		},
		ru = {
		name = 'Повреждённая колода',
		text = {
			"Каждая карта в",
			"начальной колоде имеет",
			"шанс {C:green}1 из 2{}",
			"стать {C:red}повреждённой{}"
		}
		}
	},

	atlas = 'corrupteddeckatlas',
	pos = { x = 0, y = 0 },
	unlocked = true,
	discovered = true,

	apply = function(self, back)
		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 0.1,
			func = function()
				local corrupted_center = trgu_find_corrupted_enhancement_for_deck()

				if not corrupted_center then
					print("Corrupted Deck: Corrupted enhancement not found")
					return true
				end

				if G.playing_cards then
					for _, playing_card in ipairs(G.playing_cards) do
						if pseudorandom('corrupted_deck_' .. tostring(playing_card.ID or '')) < 0.5 then
							playing_card:set_ability(corrupted_center, nil, false)

							if playing_card.children and playing_card.children.front then
								playing_card.children.front:remove()
								playing_card.children.front = nil
							end

							playing_card:set_sprites(playing_card.config.center)
						end
					end
				end

				return true
			end
		}))
	end
}