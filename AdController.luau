local frame = script.Parent
local speed, waitTime = 1.5, 5
local newsFrame, weatherFrame = frame.News, frame.Weather
local imageAssetIds, elements = {}, {}

local ServerStorage = game:GetService("ServerStorage")
local Events = ServerStorage:WaitForChild("VYLIX | Advertising Events")
local FetchAdvertEvent_Large, NewsEvent, WeatherEvent = Events:WaitForChild("FetchAdvertEvent_Large"), Events:WaitForChild("NewsEvent"), Events:WaitForChild("WeatherEvent")

local lastUpdateTime = os.time()
local isAdvertsReady, isNewsReady, isWeatherReady, isSpecialAdvertDisplayed = false, false, false, false

local function isAllDataReady()
	return isAdvertsReady and isNewsReady and isWeatherReady
end

local function updateLastUpdatedText()
	local minutesDifference = math.floor(os.difftime(os.time(), lastUpdateTime) / 60)
	newsFrame.Footer.LastUpdate.Text = "Last updated: " .. (minutesDifference == 0 and "a few seconds ago" or minutesDifference .. " minute" .. (minutesDifference == 1 and "" or "s") .. " ago")
end

local function setDescendantsVisibility(parent, isVisible)
	for _, descendant in ipairs(parent:GetChildren()) do
		if descendant:IsA("GuiObject") then descendant.Visible = isVisible end
	end
	parent.Visible = isVisible
end

local function shuffleArray(array)
	for i = #array, 2, -1 do
		local j = math.random(i)
		array[i], array[j] = array[j], array[i]
	end
end

local function showContent()
	setDescendantsVisibility(frame, true)
	while true do
		if #elements > 0 then
			if isSpecialAdvertDisplayed then
				newsFrame.Visible, weatherFrame.Visible = false, false
				for _, element in ipairs(elements) do element.Visible = false end
				elements[1].Visible = true
				while isSpecialAdvertDisplayed do wait(waitTime) end
				newsFrame.Visible, weatherFrame.Visible = true, true
				for _, element in ipairs(elements) do element.Visible = true end
			else
				for i = 1, #elements + 1 do
					if isSpecialAdvertDisplayed then break end
					frame:TweenPosition(UDim2.new(-i, 0, 0, 0), "Out", "Quad", speed)
					wait(waitTime)
				end
				frame.Position = UDim2.new(0, 0, 0, 0)
			end
		else
			wait(1)
		end
		updateLastUpdatedText()
	end
end

local function updateAdverts(decalIds, specialAdvertFound)
	isSpecialAdvertDisplayed = specialAdvertFound
	for _, element in ipairs(elements) do element:Destroy() end
	elements = {}
	imageAssetIds = decalIds
	if not isAdvertsReady then shuffleArray(imageAssetIds) end

	for i, assetId in ipairs(imageAssetIds) do
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Parent, imageLabel.Size, imageLabel.Image = frame, UDim2.new(1, 0, 1, 0), assetId
		imageLabel.Position, imageLabel.BackgroundTransparency, imageLabel.ZIndex, imageLabel.Visible = UDim2.new(i - 1, 0, 0, 0), 1, 3, false
		table.insert(elements, imageLabel)
	end

	newsFrame.Position = UDim2.new(#imageAssetIds + 0.5, 0, 0.5, 0)
	weatherFrame.Position = UDim2.new(#imageAssetIds + 1.5, 0, 0.5, 0)

	if #imageAssetIds > 0 then
		local firstImageDuplicate = elements[1]:Clone()
		firstImageDuplicate.Position, firstImageDuplicate.Parent = UDim2.new(#imageAssetIds + 2, 0, 0, 0), frame
		table.insert(elements, firstImageDuplicate)
	end

	isAdvertsReady = true
	if isAllDataReady() then showContent() end
end

local function updateNews(newsDetails)
	newsFrame.Content.Headline.Text, newsFrame.Content.Story.Text = newsDetails.title, newsDetails.excerpt
	newsFrame.Content.BREAKING.Visible = newsDetails.breaking_news
	lastUpdateTime = os.time()
	updateLastUpdatedText()
	isNewsReady = true
	if isAllDataReady() then showContent() end
end

local function getWeatherIcon(conditionCode)
	local iconMap = {
		[1000] = 15198242753, [1003] = 15082315340, [1006] = 15082315340, [1009] = 15082315340,
		[1030] = 15083528350, [1135] = 15083528350, [1147] = 15083528350,
		[1087] = 15198589131, [1273] = 15198589131, [1276] = 15198589131, [1279] = 15198589131, [1282] = 15198589131,
		[1066] = 15199165023, [1114] = 15199165023, [1117] = 15199165023, [1219] = 15199165023,
		[1222] = 15199165023, [1225] = 15199165023,
		[1069] = 15082323427, [1072] = 15082323427, [1168] = 15082323427, [1171] = 15082323427,
		[1204] = 15082323427, [1207] = 15082323427, [1210] = 15082323427, [1213] = 15082323427,
		[1216] = 15082323427, [1237] = 15082323427, [1249] = 15082323427, [1252] = 15082323427,
		[1255] = 15082323427, [1258] = 15082323427, [1261] = 15082323427, [1264] = 15082323427,
	}
	return iconMap[conditionCode] or 15082315340
end

local function updateWeather(weatherDetails)
	weatherFrame.Location.Text = weatherDetails.location
	local iconImageId = getWeatherIcon(weatherDetails.condition)
	weatherFrame.WeatherIcon.Image, weatherFrame.WeatherIcon2.Image = "rbxassetid://" .. iconImageId, "rbxassetid://" .. iconImageId
	local tempValue, tempUnit = weatherDetails.temperature_celsius or "N/A", weatherDetails.temperature_celsius and "C" or ""
	weatherFrame.Temperature.Text = tempValue .. "<font size='20' color='#AAAAAA'>°" .. tempUnit .. "</font>"
	isWeatherReady = true
	if isAllDataReady() then showContent() end
end

setDescendantsVisibility(frame, false)
FetchAdvertEvent_Large.Event:Connect(updateAdverts)
NewsEvent.Event:Connect(updateNews)
WeatherEvent.Event:Connect(updateWeather)
