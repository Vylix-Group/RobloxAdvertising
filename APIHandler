local module = {}

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Settings = require(game.ServerScriptService:WaitForChild("VYLIX AD | SETTINGS"))
local experienceId = game.GameId

-- Function to fetch the whitelist
local function fetchWhitelist()
	local success, response
	repeat
		success, response = pcall(function()
			return HttpService:GetAsync("https://api.vylix.net/admin/whitelist", false)
		end)
		if not success then
			warn("[VYLIX] Failed to fetch whitelist. Handler will NOT run:", response)
			wait(5)
		end
	until success
	return HttpService:JSONDecode(response)
end

-- Function to check if the game is whitelisted
local function isWhitelisted()
	local whitelistData = fetchWhitelist()
	for _, entry in ipairs(whitelistData) do
		if entry.experience_id == tostring(experienceId) then
			return true
		end
	end
	return false
end

-- Only run if the game is whitelisted
if not isWhitelisted() then
	warn("[VYLIX] Experience not whitelisted. Your workspace has been deleted.")
	game.Workspace:ClearAllChildren()
	return
end

Settings.WeatherLocation = (Settings.WeatherLocation == "" or not Settings.WeatherLocation) and "uk" or Settings.WeatherLocation:lower()
Settings.NewsType = (Settings.NewsType == "" or not Settings.NewsType) and "home" or Settings.NewsType:lower()

local advertisingEventsFolder = ServerStorage:FindFirstChild("VYLIX | Advertising Events") or Instance.new("Folder", ServerStorage)
advertisingEventsFolder.Name = "VYLIX | Advertising Events"

local function createEvent(name)
	local event = advertisingEventsFolder:FindFirstChild(name) or Instance.new("BindableEvent", advertisingEventsFolder)
	event.Name = name
	return event
end

local Events = {
	FetchAdvert_Large = createEvent("FetchAdvertEvent_Large"),
	FetchAdvert_AList = createEvent("FetchAdvertEvent_AList"),
	FetchAdvert_Street = createEvent("FetchAdvertEvent_Street"),
	News = createEvent("NewsEvent"),
	Weather = createEvent("WeatherEvent")
}

local lastData = { Adverts = {}, News = {}, Weather = {} }
local headers = { ["Authorization"] = Settings.APIKey }

local function fetchData(url)
	local success, response
	repeat
		success, response = pcall(function()
			return HttpService:GetAsync(url, false, headers)
		end)
		if not success then
			warn("[VYLIX] Failed to fetch data:", response)
			wait(5)
		end
	until success
	return HttpService:JSONDecode(response)
end

local function fetchAdverts(url, eventKey)
	local data = fetchData(url)
	local adverts = {}
	local primaryFound = false

	for _, advert in ipairs(data) do
		local assetId = tonumber(advert.decal_id)
		if assetId then
			local decalId = "rbxassetid://" .. assetId
			if advert.location == 0 or advert.location == Settings.OverrideAdLocation then
				table.insert(adverts, decalId)
				primaryFound = true
			end
		end
	end

	if not primaryFound then
		for _, advert in ipairs(data) do
			local assetId = tonumber(advert.decal_id)
			if assetId and (advert.location == 1 or advert.location == Settings.PrimaryAdLocation) then
				table.insert(adverts, "rbxassetid://" .. assetId)
			end
		end
	end

	if #adverts > 0 and HttpService:JSONEncode(lastData.Adverts[eventKey] or {}) ~= HttpService:JSONEncode(adverts) then
		lastData.Adverts[eventKey] = adverts
		Events[eventKey]:Fire(adverts, primaryFound)
	end
end

local function fetchNews()
	local newsData = fetchData("https://api.vylix.net/news/sky/" .. Settings.NewsType)
	local newsItem = newsData.items[1]
	local newsDetails = {
		title = newsItem.title,
		excerpt = newsItem.excerpt,
		breaking_news = newsItem.breaking_news
	}

	if HttpService:JSONEncode(lastData.News) ~= HttpService:JSONEncode(newsDetails) then
		lastData.News = newsDetails
		Events.News:Fire(newsDetails)
	end
end

local function fetchWeather()
	local weatherDetails = fetchData("https://api.vylix.net/weather/" .. Settings.WeatherLocation)
	local weatherData = {
		location = weatherDetails.location,
		condition = weatherDetails.current.condition_code,
	}

	if Settings.UseCelsius then
		weatherData.temperature_celsius = weatherDetails.current.temperature_celsius
	else
		weatherData.temperature_fahrenheit = weatherDetails.current.temperature_fahrenheit
	end

	if HttpService:JSONEncode(lastData.Weather) ~= HttpService:JSONEncode(weatherData) then
		lastData.Weather = weatherData
		Events.Weather:Fire(weatherData)
	end
end

local function fetchAllAdverts()
	fetchAdverts("https://api.vylix.net/advert/main", "FetchAdvert_Large")
	fetchAdverts("https://api.vylix.net/advert/a-list", "FetchAdvert_AList")
	fetchAdverts("https://api.vylix.net/advert/street", "FetchAdvert_Street")
end

function module.start()
	fetchNews()
	fetchWeather()
	fetchAllAdverts()

	while true do
		wait(10)
		fetchNews()
		fetchWeather()
		fetchAllAdverts()
	end
end

return module
