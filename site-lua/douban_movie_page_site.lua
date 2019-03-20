-- param: this, url=(movie://param?key=value)
local this, url = ...
local urlParam = this:urlParser(url)
local TAG = urlParam:getString("tag", "热门")
local REFERER = "https://movie.douban.com/explore"
local ANDROID_UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36"

local function generalURL(pn)
	local System = luajava.bindClass('java.lang.System')
	local currentTimeMillis = System:currentTimeMillis()

	return "https://movie.douban.com/j/search_subjects"
	            .. "?type=movie"
				.. "&tag=" .. this:urlEncode(TAG) 
				.. "&sort=recommend&page_limit=20"
				.. "&page_start=" .. pn
end

local categoryState = {
	loader = nil,
	cursor = 0,
	name = "",
	image = "",
	desc = "",
	getURL = function(pn)
		return generalURL(pn)
	end
}

local function getQueryData(data)
	return data:getArray("subjects", "[]")
end

--[ret: url, name, image, desc]
local function parseItem(item)
    local url = item:getString("url", "")
	local name = item:getString("title", "")
	local image = item:getString("cover", "")
	local score = item:getString("rate", "")
	local desc = "<font color='#929292'>豆瓣</font>"
		       .. "<font color='#FE5B00'>" .. score .. "</font>"
		       .. "<font color='#929292'>分</font>"

	return url, name, image, desc
end

local function request(category)
	local header = {}
	header["Referer"] = REFERER
	header["Referrer"] = REFERER
	header["User-Agent"] = ANDROID_UA

	local url = category.getURL(category.cursor)
	this:request(0, url, false, header, {}, function(ret, msg, responce)
		local data = this:toJson(responce)
		if data ~= nil then
			local result = getQueryData(data)
			for i = 0, result:getLength() do
				category.cursor = category.cursor + 1
			
				local item = result:getObject(i, "{}")
				local url, name, image, desc = parseItem(item)
				
				local action = "app-sou://search?keywords=" .. this:urlEncode(name) .. "&mimeType=mp4"
				--local url = "http://m.baidu.com/s?word=" .. this:urlEncode(name)
				local longAction = "app-sou://webPreview?title=" .. this:urlEncode(name)
					.. "&url=" .. this:urlEncode(url)
					.. "&action=" .. this:urlEncode(action)
					.. "&actionText=" .. this:urlEncode("搜资源")
				
				if image ~= "" and name ~= "" then
					category.loader:addItem(url, image, name, desc, action, longAction)
				end
			end
		end
		
		category.loader:completed(ret, msg)
	end)
end

--[[ 
	loader = {
		addItem(String pageUrl, String image, String name, String desc, String action, String longAction),
		completed(int ret, String msg)
	}
]]
function load(categoryId, loader)
	categoryState.cursor = 0
	categoryState.loader = loader
	request(categoryState)
end

function next(categoryId, loader)
	categoryState.loader = loader
	request(categoryState)
end

--init[title, pageUrl, userAgent, referrer]
this:init("", "", ANDROID_UA, "")

--setItemViewTemplate[nameVisibleType, descVisibleType, imageVisibleType, nameRenderType, descRenderType, imageScaleType, imagePlaceholder]
this:setItemViewTemplate("", "", "", "", "html", "", "")

--addCategory[categoryId, image, name, desc]
this:addCategory("default", "", "", "")
