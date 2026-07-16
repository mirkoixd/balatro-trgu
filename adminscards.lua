SMODS.Atlas {
	key = "admincards",
	path = "AdminCards.png",
	px = 71,
	py = 95
}

local TRGU_ADMIN_PACK_BG = HEX('4B1D75')
local TRGU_ADMIN_PACK_BG_DARK = HEX('1B0B2B')

local TRGU_ADMIN_TEXTURE_OPTIONS = {
	"Indexed",
	"Colorful"
}

local TRGU_ADMIN_CARDS = {
	{ key = 'admin_mirkoi',    x = 2, y = 0 },
	{ key = 'admin_starly',    x = 1, y = 0 },
	{ key = 'admin_luter',     x = 0, y = 0 },
	{ key = 'admin_mrfrozen',  x = 2, y = 1 },
	{ key = 'admin_draserg',   x = 0, y = 1 },
	{ key = 'admin_ocitivka',  x = 1, y = 1 },
	{ key = 'admin_valerich',  x = 3, y = 0 },
	{ key = 'admin_kcats',     x = 4, y = 0 },
	{ key = 'admin_scarsosat', x = 3, y = 1 },
	{ key = 'admin_batstop',   x = 5, y = 0 },
	{ key = 'admin_gorplay',   x = 4, y = 1 },
	{ key = 'admin_misharey',  x = 5, y = 1 }
}

local function trgu_admin_texture_mode()
	TRGU = TRGU or {}
	TRGU.config = TRGU.config or {}

	if not TRGU.config.admin_textures then
		TRGU.config.admin_textures = 1
	end

	return TRGU.config.admin_textures
end

local function trgu_admin_y(base_y)
	return base_y + ((trgu_admin_texture_mode() or 1) - 1) * 2
end

local function trgu_admin_pos(x, y)
	return {
		x = x,
		y = trgu_admin_y(y)
	}
end

local function trgu_find_admin_center(short_key)
	if not G or not G.P_CENTERS then return nil end

	for key, center in pairs(G.P_CENTERS) do
		if type(key) == 'string'
			and key:sub(1, 2) == 'c_'
			and key:sub(-#short_key) == short_key
		then
			return center
		end
	end

	return nil
end

local function trgu_refresh_cards_in_area(area)
	if not area or not area.cards then return end

	for _, card in ipairs(area.cards) do
		if card
			and card.config
			and card.config.center
			and card.config.center.set == 'Admin'
		then
			if card.children and card.children.front then
				card.children.front:remove()
				card.children.front = nil
			end
			card:set_sprites(card.config.center)
		end
	end
end

local function trgu_admin_atlas_key()
	if G
		and G.ASSET_ATLAS
		and G.ASSET_ATLAS['trgu_admincards']
	then
		return 'trgu_admincards'
	end

	if G
		and G.ASSET_ATLAS
		and G.ASSET_ATLAS['admincards']
	then
		return 'admincards'
	end

	return 'trgu_admincards'
end

function TRGU.apply_admin_texture_mode()
	local atlas_key = trgu_admin_atlas_key()

	for _, data in ipairs(TRGU_ADMIN_CARDS) do
		local center = trgu_find_admin_center(data.key)

		if center then
			center.atlas = atlas_key
			center.pos = trgu_admin_pos(data.x, data.y)
		end
	end

	trgu_refresh_cards_in_area(G.consumeables)
	trgu_refresh_cards_in_area(G.pack_cards)
	trgu_refresh_cards_in_area(G.shop_jokers)
	trgu_refresh_cards_in_area(G.shop_booster)
end

SMODS.Atlas {
	key = "adminpack",
	path = "BoosterPacks.png",
	px = 71,
	py = 95
}

SMODS.Atlas {
	key = "admincards_undiscovered",
	path = "AdminUndiscovered.png",
	px = 71,
	py = 95
}

SMODS.UndiscoveredSprite {
	key = 'Admin',
	atlas = 'admincards_undiscovered',
	pos = { x = 0, y = 0 }
}


local TRGU_PACK_JOKERS = {
	'googlesheetjoker',
	'tdotjoker',
	'mp3joker',
	'cryjoker',
	'fallendices',
	'fibbagejoker',
	'bunnywitch',
	'tmwreborn',
	'kank',
	'volumejoker',
	'passvital',
	'mirkoiplush',
	'wifhat',
	'jobjob',
	'ziper',
	'mirkoshkabot',
	'innocent',
	'genshin',
	'sosisnik',
	'cerac',
	'omonduck',
	'fffjoker',
	'markoi',
	'bingo',
	'juniperbot',
	'googletranslate',
	'leninbust',
	'algerianpatience',
	'mirkoilawyer',
	'diamondore',
	'burlannaburov',
	'votefor2',
	'teftelya',
	'trguaward',
	'frozenrescue',
	'smekhlyst3',
	'cyberbox2077',
	'anitavitek',
	'capybaradance',
	'ieytd',
	'hundredpercentjoker',
	'plotgoose',
	'ydkm',
	'boosty',
	'censuramoment',
	'pnh',
	'postcardhost',
	'quarantine',
	'mirkotik',
	'girlfriendforhour',
	'mysterybox',
	'mishburger',
	'twochairs',
	'yellowroulette',
	'friday',
	'prl',
	'pinkreborn',
	'elias',
	'quixort',
	'ignat_korolev',
	'notmiku',
	'mother'
}

local TRGU_JACKBOX_JOKERS = {
	'mp3joker',
	'fibbagejoker',
	'volumejoker',
	'innocent',
	'jobjob',
	'frozenrescue',
	'smekhlyst3',
	'hundredpercentjoker',
	'ydkm',
	'pnh',
	'mysterybox',
	'yellowroulette',
	'friday',
	'quixort'
}

local function trgu_resolve_joker_key(short_key)
	if not G or not G.P_CENTERS then return nil end

	local candidates = {
		short_key,
		'j_' .. short_key,
		'j_trgu_' .. short_key,
		'j_TrGu_' .. short_key
	}

	for _, key in ipairs(candidates) do
		if G.P_CENTERS[key] then
			return key
		end
	end

	for key, center in pairs(G.P_CENTERS) do
		if type(key) == 'string'
			and key:sub(1, 2) == 'j_'
			and key:sub(-#short_key) == short_key
		then
			return key
		end
	end

	return nil
end

local function trgu_has_showman()
	if not G or not G.jokers or not G.jokers.cards then return false end

	for _, joker in ipairs(G.jokers.cards) do
		local center = joker and joker.config and joker.config.center
		local key = center and tostring(center.key or '') or ''
		local original_key = center and tostring(center.original_key or '') or ''

		if key == 'j_showman'
			or original_key == 'showman'
			or key:sub(-7) == 'showman'
		then
			return true
		end
	end

	return false
end

local function trgu_joker_key_is_owned(full_key)
	if not full_key or not G or not G.jokers or not G.jokers.cards then
		return false
	end

	for _, joker in ipairs(G.jokers.cards) do
		local center = joker and joker.config and joker.config.center
		local key = center and center.key

		if key == full_key then
			return true
		end
	end

	return false
end

local function trgu_get_existing_joker_keys(list)
	local result = {}
	local showman = trgu_has_showman()

	for _, short_key in ipairs(list) do
		local full_key = trgu_resolve_joker_key(short_key)

		if full_key and (showman or not trgu_joker_key_is_owned(full_key)) then
			result[#result + 1] = full_key
		end
	end

	return result
end

local function trgu_pick_joker_for_pack(pack_card, i)
	if not pack_card.ability.trgu_pack_joker_keys then
		local available = trgu_get_existing_joker_keys(TRGU_PACK_JOKERS)
		local pool = {}
		local chosen = {}

		for _, key in ipairs(available) do
			pool[#pool + 1] = key
		end

		local amount = pack_card.ability.extra or 2

		for pick_i = 1, amount do
			if #pool == 0 then
				for _, key in ipairs(available) do
					pool[#pool + 1] = key
				end
			end

			if #pool > 0 then
				local seed = 'trgu_joker_pack_' .. tostring(pack_card.ID or '') .. '_' .. tostring(pick_i)
				local index = math.floor(pseudorandom(seed) * #pool) + 1
				chosen[pick_i] = table.remove(pool, index)
			end
		end

		pack_card.ability.trgu_pack_joker_keys = chosen
	end

	return pack_card.ability.trgu_pack_joker_keys[i]
end

local function trgu_card_has_any_edition(card)
	return card
		and type(card.edition) == 'table'
		and next(card.edition) ~= nil
end

SMODS.ConsumableType {
	key = 'Admin',
	primary_colour = HEX('7559FF'),
	secondary_colour = HEX('755997'),
	text_colour = G.C.WHITE,
	collection_rows = { 4, 4, 4 },
	shop_rate = 0,

	loc_txt = {
		['en-us'] = {
		name = 'Admin',
		collection = 'Admin Cards',
		undiscovered = {
			name = 'Unknown Admin',
			text = {
				"Find this card",
				"in an Admin Pack"
			}
		}
		},
		ru = {
		name = 'Админ',
		collection = 'Админские карты',
		undiscovered = {
			name = 'Неизвестный админ',
			text = {
				"Найдите эту карту",
				"в Наборе админов"
			}
		}
		}
	}
}

SMODS.Consumable {
	key = 'admin_mirkoi',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(2, 0),

loc_txt = {
    ['en-us'] = {
        name = 'Mirkoi',
        text = {
            "Gain {C:money}$#1#{}",
            "for each {C:attention}Joker{}",
            "{C:inactive}(Currently {C:money}$#2#{C:inactive})"
        }
    },
    ru = {
        name = 'Миркой',
        text = {
            "Получите {C:money}$#1#{}",
            "за каждого {C:attention}джокера{}",
            "{C:inactive}(Сейчас: {C:money}$#2#{C:inactive})"
        }
    }
},

	config = {
		extra = {
			money_per_joker = 5
		}
	},

	loc_vars = function(self, info_queue, card)
		local joker_count = G.jokers and #G.jokers.cards or 0
		return {
			vars = {
				card.ability.extra.money_per_joker,
				joker_count * card.ability.extra.money_per_joker
			}
		}
	end,

	can_use = function(self, card)
		return G.jokers and #G.jokers.cards > 0
	end,

	use = function(self, card, area, copier)
		local joker_count = G.jokers and #G.jokers.cards or 0
		local dollars = joker_count * card.ability.extra.money_per_joker

		if dollars > 0 then
			ease_dollars(dollars)

			SMODS.calculate_effect({
				message = "+$" .. dollars,
				colour = G.C.MONEY
			}, card)
		end
	end
}

SMODS.Consumable {
	key = 'admin_starly',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(1, 0),

loc_txt = {
    ['en-us'] = {
        name = 'Starly',
        text = {
            "Apply {C:attention}Foil{} or",
            "{C:attention}Holographic{} to",
            "selected {C:attention}Joker{}",
            "{C:green}#1# in #2#{} chance",
            "to {C:red}destroy{} it"
        }
    },
    ru = {
        name = 'Старли',
        text = {
            "Накладывает {C:attention}Foil{} или",
            "{C:attention}Holographic{} на",
            "выбранного {C:attention}джокера{}",
            "{C:green}#1# из #2#{} шанс",
            "{C:red}уничтожить{} его"
        }
    }
},

	config = {
		extra = {
			odds = 4
		}
	},

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'admin_starly_destroy'
		)

		return {
			vars = {
				numerator,
				denominator
			}
		}
	end,

	can_use = function(self, card)
	if not (G.jokers and G.jokers.highlighted and #G.jokers.highlighted == 1) then
		return false
	end

	local joker = G.jokers.highlighted[1]
	if trgu_card_has_any_edition(joker) then
		return false
	end

	return true
	end,

	use = function(self, card, area, copier)
		local joker = G.jokers.highlighted[1]
		if not joker then return end

		local edition

		if pseudorandom('admin_starly_edition') < 0.5 then
			edition = { foil = true }
		else
			edition = { holo = true }
		end

		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 0.2,
			func = function()
				joker:set_edition(edition, true)
				joker:juice_up()

				SMODS.calculate_effect({
					message = localize('trgu_starly'),
					colour = G.C.FILTER
				}, joker)

				return true
			end
		}))

		if SMODS.pseudorandom_probability(
			card,
			'admin_starly_destroy',
			1,
			card.ability.extra.odds
		) then
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.7,
				func = function()
					SMODS.destroy_cards(joker, false, false, false)
					return true
				end
			}))
		end
	end
}

SMODS.Consumable {
	key = 'admin_luter',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(0, 0),

loc_txt = {
    ['en-us'] = {
        name = 'Luter',
        text = {
            "Add four {C:attention}4s{}",
            "of different suits",
            "to your deck",
            "Each has a different {C:attention}Seal{}"
        }
    },
    ru = {
        name = 'Лютер',
        text = {
            "Добавляет четыре {C:attention}4{}",
            "разных мастей",
            "в вашу колоду",
            "Каждая имеет разную {C:attention}печать{}"
        }
    }
},

	can_use = function(self, card)
		return G.deck ~= nil
	end,

	use = function(self, card, area, copier)
		local cards_to_add = {
			{ suit = 'Hearts',   seal = 'Red' },
			{ suit = 'Diamonds', seal = 'Gold' },
			{ suit = 'Clubs',    seal = 'Blue' },
			{ suit = 'Spades',   seal = 'Purple' }
		}

		local added_cards = {}

		for _, data in ipairs(cards_to_add) do
			local new_card = SMODS.add_card({
				set = 'Playing Card',
				area = G.deck,
				rank = '4',
				suit = data.suit,
				seal = data.seal,
				enhanced_poll = 1,
				key_append = 'admin_luter'
			})

			added_cards[#added_cards + 1] = new_card
		end

		if playing_card_joker_effects then
			playing_card_joker_effects(added_cards)
		end

		SMODS.calculate_effect({
			message = localize('trgu_4_cards_added'),
			colour = G.C.CHIPS
		}, card)
	end
}

SMODS.Booster {
	key = 'admin_pack_small',

loc_txt = {
    ['en-us'] = {
        name = 'Admin Pack',
        text = {
            "Choose {C:attention}#1#{} of up to",
            "{C:attention}#2#{} {C:purple}Admin{} cards"
        },
        group_name = 'Admin Pack'
    },
    ru = {
        name = 'Набор Админов',
        text = {
            "Выберите {C:attention}#1#{} из",
            "{C:attention}#2#{} {C:purple}админских{} карт"
        },
        group_name = 'Набор Админов'
    }
},

	config = {
		extra = 3,
		choose = 1
	},

	atlas = 'adminpack',
	pos = { x = 0, y = 0 },

	cost = 4,
	weight = 1,
	kind = 'Admin',
	draw_hand = true,

	ease_background_colour = function(self)
	ease_colour(G.C.DYN_UI.MAIN, TRGU_ADMIN_PACK_BG)
	ease_colour(G.C.DYN_UI.DARK, TRGU_ADMIN_PACK_BG_DARK)

	ease_background_colour({
		new_colour = TRGU_ADMIN_PACK_BG,
		special_colour = TRGU_ADMIN_PACK_BG_DARK,
		contrast = 2
	})
	end,

	create_card = function(self, card, i)
		return {
			set = 'Admin',
			area = G.pack_cards,
			skip_materialize = true,
			soulable = false,
			key_append = 'admin_pack'
		}
	end
}

SMODS.Booster {
	key = 'admin_pack_mega',

loc_txt = {
    ['en-us'] = {
        name = 'Mega Admin Pack',
        text = {
            "Choose {C:attention}#1#{} of up to",
            "{C:attention}#2#{} {C:purple}Admin{} cards"
        },
        group_name = 'Admin Pack'
    },
    ru = {
        name = 'Мега набор Админов',
        text = {
            "Выберите {C:attention}#1#{} из",
            "{C:attention}#2#{} {C:purple}админских{} карт"
        },
        group_name = 'Набор Админов'
    }
},

	config = {
		extra = 5,
		choose = 2
	},

	atlas = 'adminpack',
	pos = { x = 1, y = 0 },

	cost = 8,
	weight = 1,
	kind = 'Admin',
	draw_hand = true,

	ease_background_colour = function(self)
	ease_colour(G.C.DYN_UI.MAIN, TRGU_ADMIN_PACK_BG)
	ease_colour(G.C.DYN_UI.DARK, TRGU_ADMIN_PACK_BG_DARK)

	ease_background_colour({
		new_colour = TRGU_ADMIN_PACK_BG,
		special_colour = TRGU_ADMIN_PACK_BG_DARK,
		contrast = 2
	})
	end,

	create_card = function(self, card, i)
		return {
			set = 'Admin',
			area = G.pack_cards,
			skip_materialize = true,
			soulable = false,
			key_append = 'admin_pack'
		}
	end
}

SMODS.Booster {
	key = 'trgu_joker_pack_small',

	loc_txt = {
		['en-us'] = {
			name = 'TrGu Pack',
			text = {
				"Choose {C:attention}#1#{} of up to",
				"{C:attention}#2#{} {C:red}TrGu{} Jokers"
			},
			group_name = 'TrGu Pack'
		},
		ru = {
			name = 'TrGu Набор',
			text = {
				"Выберите {C:attention}#1#{} из",
				"{C:attention}#2#{} {C:red}TrGu{} джокеров"
			},
			group_name = 'TrGu Набор'
		}
	},

	config = {
		extra = 2,
		choose = 1
	},

	atlas = 'adminpack',
	pos = { x = 2, y = 0 },

	cost = 4,
	weight = 1,
	kind = 'TrGuJoker',
	draw_hand = false,

	create_card = function(self, card, i)
		local key = trgu_pick_joker_for_pack(card, i)

		if key then
			return {
				set = 'Joker',
				area = G.pack_cards,
				key = key,
				skip_materialize = true,
				soulable = false,
				allow_duplicates = trgu_has_showman(),
				key_append = 'trgu_joker_pack'
			}
		end

		return {
			set = 'Joker',
			area = G.pack_cards,
			skip_materialize = true,
			soulable = false,
			key_append = 'trgu_joker_pack_fallback'
		}
	end
}

SMODS.Booster {
	key = 'trgu_joker_pack_mega',

	loc_txt = {
		['en-us'] = {
			name = 'Mega TrGu Pack',
			text = {
				"Choose {C:attention}#1#{} of up to",
				"{C:attention}#2#{} {C:red}TrGu{} Jokers"
			},
			group_name = 'TrGu Pack'
		},
		ru = {
			name = 'Мега TrGu Набор',
			text = {
				"Выберите {C:attention}#1#{} из",
				"{C:attention}#2#{} {C:red}TrGu{} джокеров"
			},
			group_name = 'TrGu Набор'
		}
	},

	config = {
		extra = 4,
		choose = 2
	},

	atlas = 'adminpack',
	pos = { x = 3, y = 0 },

	cost = 8,
	weight = 1,
	kind = 'TrGuJoker',
	draw_hand = false,

	create_card = function(self, card, i)
		local key = trgu_pick_joker_for_pack(card, i)

		if key then
			return {
				set = 'Joker',
				area = G.pack_cards,
				key = key,
				skip_materialize = true,
				soulable = false,
				allow_duplicates = trgu_has_showman(),
				key_append = 'trgu_joker_pack'
			}
		end

		return {
			set = 'Joker',
			area = G.pack_cards,
			skip_materialize = true,
			soulable = false,
			key_append = 'trgu_joker_pack_fallback'
		}
	end
}

SMODS.Consumable {
	key = 'admin_draserg',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(0, 1),

	loc_txt = {
    ['en-us'] = {
        name = 'Draserg',
        text = {
            "Create a random",
            "{C:attention}Jackbox{} Joker"
        }
    },
    ru = {
        name = 'Драсерг',
        text = {
            "Создаёт случайного",
            "{C:attention}Jackbox{} джокера"
        }
    }
},

	can_use = function(self, card)
		return G.jokers
			and #G.jokers.cards < G.jokers.config.card_limit
	end,

	use = function(self, card, area, copier)
		local pool = trgu_get_existing_joker_keys(TRGU_JACKBOX_JOKERS)

		if #pool <= 0 then
			SMODS.calculate_effect({
				message = localize('trgu_no_more_jackbox'),
				colour = G.C.RED
			}, card)

			return
		end

		local index = math.floor(pseudorandom('admin_draserg_joker') * #pool) + 1
		local key = pool[index]

		local joker = SMODS.add_card({
			set = 'Joker',
			area = G.jokers,
			key = key,
			allow_duplicates = trgu_has_showman(),
			key_append = 'admin_draserg'
		})

		if joker then
			SMODS.calculate_effect({
				message = localize('trgu_jackbox'),
				colour = G.C.FILTER
			}, joker)
		end
	end
}

SMODS.Consumable {
	key = 'admin_mrfrozen',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(2, 1),

	loc_txt = {
    ['en-us'] = {
        name = 'MrFrozen',
        text = {
            "Select up to {C:attention}3{} cards",
            "and turn them into",
            "{C:attention}Kings{}"
        }
    },
    ru = {
        name = 'Мр. Фрозен',
        text = {
            "Выберите до {C:attention}3{} карт",
            "и превратите их",
            "в {C:attention}королей{}"
        }
    }
},

	can_use = function(self, card)
		return G.hand
			and G.hand.highlighted
			and #G.hand.highlighted >= 1
			and #G.hand.highlighted <= 3
	end,

	use = function(self, card, area, copier)
		local selected_cards = {}

		for _, playing_card in ipairs(G.hand.highlighted) do
			selected_cards[#selected_cards + 1] = playing_card
		end

		for _, playing_card in ipairs(selected_cards) do
			if playing_card and not playing_card.removed then
				local changed, err = SMODS.change_base(playing_card, nil, 'King', true)

				if changed then
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.1,
						func = function()
							playing_card:set_sprites(nil, playing_card.config.card)
							playing_card:juice_up()
							return true
						end
					}))
				else
					print("MrFrozen failed to change card: " .. tostring(err))
				end
			end
		end

		if G.hand and G.hand.unhighlight_all then
			G.hand:unhighlight_all()
		end

		SMODS.calculate_effect({
			message = localize('trgu_kings'),
			colour = G.C.FILTER
		}, card)
	end
}

SMODS.Consumable {
	key = 'admin_ocitivka',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(1, 1),

loc_txt = {
    ['en-us'] = {
        name = 'Ocitivka',
        text = {
            "Create a random",
            "{C:spectral}Spectral{} card",
            "{C:inactive}(Must have room)"
        }
    },
    ru = {
        name = 'Оситивка',
        text = {
            "Создаёт случайную",
            "{C:spectral}спектральную{} карту",
            "{C:inactive}(Нужно место)"
        }
    }
},

	can_use = function(self, card)
		if not G.consumeables then return false end

		local buffer = G.GAME and (G.GAME.consumeable_buffer or 0) or 0
		local limit = G.consumeables.config.card_limit or 0
		local current = #G.consumeables.cards + buffer

		if card.area == G.consumeables then
			current = current - 1
		end

		return current < limit
	end,

	use = function(self, card, area, copier)
		G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1

		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 0.2,
			func = function()
				SMODS.calculate_effect({
					message = localize('trgu_spectral'),
					colour = G.C.SECONDARY_SET.Spectral
				}, card)

				SMODS.add_card({
					set = 'Spectral',
					area = G.consumeables,
					soulable = true,
					allow_duplicates = true,
					key_append = 'admin_ocitivka'
				})

				G.GAME.consumeable_buffer = math.max((G.GAME.consumeable_buffer or 1) - 1, 0)

				return true
			end
		}))
	end
}







-- НОВОЕ

local function trgu_admin_joker_space()
	if not G.jokers then return false end

	local buffer = G.GAME and (G.GAME.joker_buffer or 0) or 0
	local current = #G.jokers.cards + buffer
	local limit = G.jokers.config.card_limit or 0

	return current < limit
end

local function trgu_admin_consumable_space(card)
	if not G.consumeables then return 0 end

	local buffer = G.GAME and (G.GAME.consumeable_buffer or 0) or 0
	local current = #G.consumeables.cards + buffer
	local limit = G.consumeables.config.card_limit or 0

	if card and card.area == G.consumeables then
		current = current - 1
	end

	return math.max(limit - current, 0)
end

local function trgu_find_convert_enhancement()
	if not G or not G.P_CENTERS then return nil end

	local candidates = {
		'm_trgu_convert',
		'm_trgumod_convert',
		'm_convert'
	}

	for _, key in ipairs(candidates) do
		if G.P_CENTERS[key] then
			return G.P_CENTERS[key]
		end
	end

	for key, center in pairs(G.P_CENTERS) do
		if type(key) == 'string'
			and key:sub(1, 2) == 'm_'
			and key:sub(-7) == 'convert'
		then
			return center
		end
	end

	return nil
end

local function trgu_get_most_played_hand()
	if not G.GAME or not G.GAME.hands then return nil end

	local best_hand = nil
	local best_played = -1

	for hand_name, hand_data in pairs(G.GAME.hands) do
		if hand_data
			and hand_data.visible
			and hand_data.played
			and hand_data.played > best_played
		then
			best_hand = hand_name
			best_played = hand_data.played
		end
	end

	return best_hand
end

local function trgu_get_planet_for_hand(hand_name)
	if not hand_name or not G.P_CENTER_POOLS or not G.P_CENTER_POOLS.Planet then
		return nil
	end

	for _, center in ipairs(G.P_CENTER_POOLS.Planet) do
		if center
			and center.config
			and center.config.hand_type == hand_name
		then
			return center.key
		end
	end

	return nil
end

SMODS.Consumable {
	key = 'admin_valerich',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(3, 0),

loc_txt = {
    ['en-us'] = {
        name = 'Valerich',
        text = {
            "Select up to {C:attention}5{} cards",
            "and change their suit",
            "to {C:clubs}Clubs{}"
        }
    },
    ru = {
        name = 'Валерыч',
        text = {
            "Выберите до {C:attention}5{} карт",
            "и измените их масть",
            "на {C:clubs}трефы{}"
        }
    }
},

	can_use = function(self, card)
		return G.hand
			and G.hand.highlighted
			and #G.hand.highlighted >= 1
			and #G.hand.highlighted <= 5
	end,

	use = function(self, card, area, copier)
		local selected_cards = {}

		for _, playing_card in ipairs(G.hand.highlighted) do
			selected_cards[#selected_cards + 1] = playing_card
		end

		for _, playing_card in ipairs(selected_cards) do
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.1,
				func = function()
					local changed, err = SMODS.change_base(playing_card, 'Clubs', nil, true)

					if changed then
						playing_card:set_sprites(nil, playing_card.config.card)
						playing_card:juice_up()
					else
						print("Valerich failed: " .. tostring(err))
					end

					return true
				end
			}))
		end

		if G.hand and G.hand.unhighlight_all then
			G.hand:unhighlight_all()
		end

		SMODS.calculate_effect({
			message = localize('trgu_clubs'),
			colour = G.C.SUITS.Clubs
		}, card)
	end
}

local function trgu_force_perishable(card)
	if not card then return false end

	card.ability = card.ability or {}

	if card.set_perishable then
		card:set_perishable(true)
	end

	card.ability.perishable = true
	card.ability.perish_tally = G.GAME and G.GAME.perishable_rounds or 5

	if card.set_cost then
		card:set_cost()
	end

	if card.juice_up then
		card:juice_up()
	end

	return true
end

SMODS.Consumable {
	key = 'admin_kcats',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(4, 0),

loc_txt = {
    ['en-us'] = {
        name = 'KCats',
        text = {
            "Create a random",
            "{C:red}Rare{} Joker",
            "with {C:attention}Perishable{} sticker",
            "{C:inactive}(Must have room)"
        }
    },
    ru = {
        name = 'Кикец',
        text = {
            "Создаёт случайного",
            "{C:red}редкого{} джокера",
            "с наклейкой {C:attention}Портящийся{}",
            "{C:inactive}(Нужно место)"
        }
    }
},

	can_use = function(self, card)
		return trgu_admin_joker_space()
	end,

	use = function(self, card, area, copier)
	G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + 1

	G.E_MANAGER:add_event(Event({
		trigger = 'after',
		delay = 0.2,
		func = function()
			local joker = SMODS.add_card({
				set = 'Joker',
				area = G.jokers,
				rarity = 3,
				allow_duplicates = trgu_has_showman(),
				key_append = 'admin_kcats'
			})

			G.GAME.joker_buffer = math.max((G.GAME.joker_buffer or 1) - 1, 0)

			if joker then
				trgu_force_perishable(joker)

				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.1,
					func = function()
						trgu_force_perishable(joker)
						return true
					end
				}))

				SMODS.calculate_effect({
					message = localize('trgu_perishable'),
					colour = G.C.RED
				}, joker)
			end

			return true
		end
	}))
end
}

SMODS.Consumable {
	key = 'admin_scarsosat',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(3, 1),

loc_txt = {
    ['en-us'] = {
        name = 'ScarSosat',
        text = {
            "Select {C:attention}3{} cards",
            "Convert the two left cards",
            "into the right card"
        }
    },
    ru = {
        name = 'Скар',
        text = {
            "Выберите {C:attention}3{} карты",
            "Две левые карты",
            "станут правой"
        }
    }
},

	can_use = function(self, card)
		return G.hand
			and G.hand.highlighted
			and #G.hand.highlighted == 3
	end,

	use = function(self, card, area, copier)
		local right_card = G.hand.highlighted[1]

		for _, playing_card in ipairs(G.hand.highlighted) do
			if playing_card.T.x > right_card.T.x then
				right_card = playing_card
			end
		end

		for _, playing_card in ipairs(G.hand.highlighted) do
			if playing_card ~= right_card then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.15,
					func = function()
						copy_card(right_card, playing_card)
						playing_card:juice_up()
						return true
					end
				}))
			end
		end

		if G.hand and G.hand.unhighlight_all then
			G.hand:unhighlight_all()
		end

		SMODS.calculate_effect({
			message = localize('trgu_copied'),
			colour = G.C.FILTER
		}, card)
	end
}

SMODS.Consumable {
	key = 'admin_batstop',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(5, 0),

loc_txt = {
    ['en-us'] = {
        name = 'Batstop',
        text = {
            "Create up to {C:attention}2{}",
            "{C:planet}Planet{} cards",
            "for your most played",
            "poker hand",
            "{C:inactive}(Must have room)"
        }
    },
    ru = {
        name = 'Батстоп',
        text = {
            "Создаёт до {C:attention}2{}",
            "карт {C:planet}планет{}",
            "для вашей самой",
            "разыгрываемой комбинации",
            "{C:inactive}(Нужно место)"
        }
    }
},

	can_use = function(self, card)
		local space = trgu_admin_consumable_space(card)
		local hand_name = trgu_get_most_played_hand()
		local planet_key = trgu_get_planet_for_hand(hand_name)

		return space > 0 and planet_key ~= nil
	end,

	use = function(self, card, area, copier)
		local space = trgu_admin_consumable_space(card)
		local amount = math.min(2, space)

		local hand_name = trgu_get_most_played_hand()
		local planet_key = trgu_get_planet_for_hand(hand_name)

		if not planet_key or amount <= 0 then return end

		G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + amount

		for i = 1, amount do
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.15 * i,
				func = function()
					SMODS.add_card({
						set = 'Planet',
						area = G.consumeables,
						key = planet_key,
						allow_duplicates = true,
						key_append = 'admin_batstop'
					})

					G.GAME.consumeable_buffer = math.max((G.GAME.consumeable_buffer or 1) - 1, 0)

					return true
				end
			}))
		end

		SMODS.calculate_effect({
			message = hand_name or localize('trgu_planet'),
			colour = G.C.SECONDARY_SET.Planet
		}, card)
	end
}

SMODS.Consumable {
	key = 'admin_gorplay',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(4, 1),

	no_pool_flag = 'admin_gorplay_success',

	in_pool = function(self, args)
		return not (
			G
			and G.GAME
			and G.GAME.pool_flags
			and G.GAME.pool_flags.admin_gorplay_success
		)
	end,

loc_txt = {
    ['en-us'] = {
        name = 'Gorplay',
        text = {
            "{C:green}#1# in #2#{} chance to make",
            "selected {C:attention}Joker{} {C:dark_edition}Negative{}",
            "{C:inactive}(If success, does not appear",
            "{C:inactive}in packs or shop anymore)"
        }
    },
    ru = {
        name = 'Горплей',
        text = {
            "{C:green}#1# из #2#{} шанс сделать",
            "выбранного {C:attention}джокера{}",
            "{C:dark_edition}Negative{}",
            "{C:inactive}(После успеха больше",
            "{C:inactive}не появляется в паках и магазине)"
        }
    }
},

	config = {
		extra = {
			odds = 3
		}
	},

	loc_vars = function(self, info_queue, card)
		local numerator, denominator = SMODS.get_probability_vars(
			card,
			1,
			card.ability.extra.odds,
			'admin_gorplay_negative'
		)

		return {
			vars = {
				numerator,
				denominator
			}
		}
	end,

	can_use = function(self, card)
		if not (G.jokers and G.jokers.highlighted and #G.jokers.highlighted == 1) then
			return false
		end

		local joker = G.jokers.highlighted[1]
		if trgu_card_has_any_edition(joker) then
			return false
		end

		return true
	end,

	use = function(self, card, area, copier)
		local joker = G.jokers.highlighted[1]
		if not joker then return end

		if SMODS.pseudorandom_probability(
			card,
			'admin_gorplay_negative',
			1,
			card.ability.extra.odds
		) then
			G.GAME.pool_flags = G.GAME.pool_flags or {}
			G.GAME.pool_flags.admin_gorplay_success = true

			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = 0.2,
				func = function()
					joker:set_edition('e_negative', true)
					joker:juice_up()

					SMODS.calculate_effect({
						message = localize('trgu_negative'),
						colour = G.C.DARK_EDITION
					}, joker)

					return true
				end
			}))
		else
			SMODS.calculate_effect({
				message = localize('trgu_nope'),
				colour = G.C.RED
			}, card)
		end
	end
}

SMODS.Consumable {
	key = 'admin_misharey',
	set = 'Admin',
	atlas = 'admincards',
	pos = trgu_admin_pos(5, 1),

	loc_txt = {
		['en-us'] = {
			name = 'Misharey',
			text = {
				"Enhance up to",
				"{C:attention}3{} selected cards",
				"into {C:attention}Convert Cards{}"
			}
		},
		ru = {
			name = 'Мишарей',
			text = {
				"Улучшает до",
				"{C:attention}3{} выбранных карт",
				"в {C:attention}валютные карты{}"
			}
		}
	},

	can_use = function(self, card)
		return G.hand
			and G.hand.highlighted
			and #G.hand.highlighted >= 1
			and #G.hand.highlighted <= 3
			and trgu_find_convert_enhancement() ~= nil
	end,

	use = function(self, card, area, copier)
		local convert_center = trgu_find_convert_enhancement()

		if not convert_center then
			print("Misharey: Convert enhancement not found")
			return
		end

		local selected_cards = {}

		for _, playing_card in ipairs(G.hand.highlighted) do
			selected_cards[#selected_cards + 1] = playing_card
		end

		for i, playing_card in ipairs(selected_cards) do
			if playing_card and not playing_card.removed then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.12 * i,
					func = function()
						playing_card:set_ability(convert_center, nil, true)
						playing_card:juice_up()
						return true
					end
				}))
			end
		end

		if G.hand and G.hand.unhighlight_all then
			G.hand:unhighlight_all()
		end

		SMODS.calculate_effect({
			message = localize('trgu_converted'),
			colour = G.C.FILTER
		}, card)
	end
}



-- В КОНЕЦ!!!!!!!!!!!!!!!
G.FUNCS.trgu_admin_textures_changed = function(args)
	TRGU = TRGU or {}
	TRGU.config = TRGU.config or {}

	if args and args.to_key then
		TRGU.config.admin_textures = args.to_key
	else
		TRGU.config.admin_textures = TRGU.config.admin_textures or 1
	end

	if TRGU.mod then
		TRGU.mod.config = TRGU.config
	end

	if TRGU.apply_admin_texture_mode then
		TRGU.apply_admin_texture_mode()
	end

	if SMODS.save_mod_config and TRGU.mod then
		SMODS.save_mod_config(TRGU.mod)
	end
end

G.FUNCS.trgu_config_changed = function(args)
	TRGU = TRGU or {}
	TRGU.config = TRGU.config or {}

	if TRGU.mod then
		TRGU.mod.config = TRGU.config
	end

	if SMODS.save_mod_config and TRGU.mod then
		SMODS.save_mod_config(TRGU.mod)
	end
end

TRGU.mod.config_tab = function()
	TRGU.config = TRGU.config or {}
	TRGU.config.admin_textures = TRGU.config.admin_textures or 1

	if TRGU.config.easier_owl_blind == nil then
		TRGU.config.easier_owl_blind = false
	end

	return {
		n = G.UIT.ROOT,
		config = {
			align = "cm",
			padding = 0.2,
			colour = G.C.BLACK,
			r = 0.1,
			minw = 6,
			minh = 3.2
		},
		nodes = {
			{
				n = G.UIT.R,
				config = {
					align = "cm",
					padding = 0.1
				},
				nodes = {
					create_option_cycle({
						label = localize('trgu_config_admins'),
						options = TRGU_ADMIN_TEXTURE_OPTIONS,
						current_option = TRGU.config.admin_textures,
						ref_table = TRGU.config,
						ref_value = "admin_textures",
						opt_callback = "trgu_admin_textures_changed"
					})
				}
			},
			{
				n = G.UIT.R,
				config = {
					align = "cm",
					padding = 0.1
				},
				nodes = {
					create_toggle({
						label = localize('trgu_config_owl'),
						ref_table = TRGU.config,
						ref_value = "easier_owl_blind",
						callback = function()
							G.FUNCS.trgu_config_changed()
						end
					})
				}
			},
			{
				n = G.UIT.R,
				config = {
					align = "cm",
					padding = 0.02
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize('trgu_config_owl_desc'),
							scale = 0.32,
							shadow = true
						}
					}
				}
			}
		}
	}
end