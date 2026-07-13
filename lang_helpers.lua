TRGU = TRGU or {}

TRGU.mod_id = TRGU.mod_id or 'trgumod'
TRGU.lang_content_cache = TRGU.lang_content_cache or {}

function TRGU.current_language()
	local lang = G
		and G.SETTINGS
		and G.SETTINGS.language
		or 'en-us'

	lang = tostring(lang):lower()
	lang = lang:gsub("_", "-")

	if lang == 'ru' or lang == 'ru-ru' or lang == 'russian' then
		return 'ru'
	end

	if lang == 'en' or lang == 'en-us' or lang == 'english' then
		return 'en-us'
	end

	return lang
end

function TRGU.try_load_content(path)
	if TRGU.lang_content_cache[path] then
		return TRGU.lang_content_cache[path]
	end

	local ok, chunk = pcall(function()
		return SMODS.load_file(path, TRGU.mod_id)
	end)

	if not ok or not chunk then
		print("TRGU content not found: " .. tostring(path))
		return nil
	end

	local ok2, data = pcall(chunk)

	if not ok2 then
		print("TRGU content load failed: " .. tostring(path))
		print(tostring(data))
		return nil
	end

	print("TRGU content loaded: " .. tostring(path))

	TRGU.lang_content_cache[path] = data
	return data
end

function TRGU.load_lang_content(base_path)
	local lang = TRGU.current_language()

	print("TRGU language = " .. tostring(lang))
	print("TRGU trying content base = " .. tostring(base_path))

	return TRGU.try_load_content(base_path .. '_' .. lang .. '.lua')
		or TRGU.try_load_content(base_path .. '_en-us.lua')
		or TRGU.try_load_content(base_path .. '_ru.lua')
		or {}
end