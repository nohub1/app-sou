-- param: this, url=(movie://param?query=[电影|电视剧|综艺|动画片大全]&type=[0|1|2]&cat=[|爱情|喜剧...|犯罪]&area=[|美国|...|英国])
local this, url = ...
local urlParam = this:urlParser(url)
local REQ_MOVIE_QUERY = urlParam:getString("query", "")
local REQ_MOVIE_TYPE = urlParam:getInt("type", 0)
local REQ_MOVIE_CAT = urlParam:getString("cat", "")
local REQ_MOVIE_AREA = urlParam:getString("area", "")
local IOS_UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1" 

local function generalURL(query, _type, cat, area, pn)
	local System = luajava.bindClass('java.lang.System')
	local currentTimeMillis = System:currentTimeMillis()

	local resourceId = {}
	resourceId["电影"] = 28286
	resourceId["综艺"] = 28263
	resourceId["电视剧"] = 28287
	resourceId["动画片大全"] = 28286
	
	return "https://sp0.baidu.com/8aQDcjqpAAV3otqbppnN2DJv/api.php"
	            .. "?sort_key=" .. _type
				.. "&stat0=" .. this:urlEncode(cat) 
				.. "&stat1=" .. this:urlEncode(area)
				.. "&pn=" .. pn
                .. "&rn=24" 
                .. "&resource_id=" .. resourceId[query]
                .. "&tn=wisexmlnew&dsp=iphone&from_mid=1&format=json&ie=utf-8&oe=utf-8"
                .. "&need_di=1&ks_from=ks_sf&pd=movie_general"
                .. "&query=" .. this:urlEncode(query)
                .. "&_=" .. currentTimeMillis
                .. "&cb="
end

local categoryState = {
	loader = nil,
	cursor = 0,
	name = "",
	image = "",
	desc = "",
	getURL = function(pn)
		return generalURL(REQ_MOVIE_QUERY, REQ_MOVIE_TYPE, REQ_MOVIE_CAT, REQ_MOVIE_AREA, pn)
	end
}

local function getQueryData(data)
	if REQ_MOVIE_QUERY == "电影" 
		or REQ_MOVIE_QUERY == "动画片大全"
		or REQ_MOVIE_QUERY == "电视剧"
		or REQ_MOVIE_QUERY == "综艺" then
		return data:getArray("data", "[]")
				:getObject(0, "{}")
				:getObject("result", "{}")
				:getArray("result", "[]")
	end

	return data
end

--[ret: name, image, desc]
local function parseItem(item)
	local name = item:getString("ename", "")
	local image = item:getString("img", "")
	local desc = ""

	if REQ_MOVIE_QUERY == "电影" or REQ_MOVIE_QUERY == "动画片大全" then
		local score = item:getString("score", "")
		if score == "" then
			score = "N/N"
		end
		
		desc = "<font color='#929292'>豆瓣</font>"
			.. "<font color='#FE5B00'>" .. score .. "</font>"
			.. "<font color='#929292'>分</font>"
	end

	if REQ_MOVIE_QUERY == "电视剧" or REQ_MOVIE_QUERY == "综艺" then
		local additional = item:getString("additional", "");
		desc = "<font color='#929292'>" .. additional .. "</font>"
	end

	return name, image, desc
end

local function request(category)
	local header = {}
	header["User-Agent"] = IOS_UA
	
	local url = category.getURL(category.cursor)
	this:request(0, url, false, header, {}, function(ret, msg, responce)
		local data = this:toJson(responce)
		if data ~= nil then
			local result = getQueryData(data)
			for i = 0, result:getLength() do
				category.cursor = category.cursor + 1
			
				local item = result:getObject(i, "{}")
				local name, image, desc = parseItem(item)
				
				local action = "app-sou://search?keywords=" .. this:urlEncode(name) .. "&mimeType=mp4"
				local url = "http://m.baidu.com/s?word=" .. this:urlEncode(name)
				local longAction = "app-sou://webPreview?title=" .. this:urlEncode(name)
					.. "&url=" .. this:urlEncode(url)
					.. "&action=" .. this:urlEncode(action)
					.. "&actionText=" .. this:urlEncode("搜资源")
				local imageAction = ""

				if image ~= "" and name ~= "" then
					category.loader:addItem(url, image, name, desc, action, longAction, imageAction)
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
this:init("", "", IOS_UA, "")

--setItemViewTemplate[nameVisibleType, descVisibleType, imageVisibleType, nameRenderType, descRenderType, imageScaleType, imagePlaceholder]
this:setItemViewTemplate("", "", "", "", "html", "", "")

--addCategory[categoryId, image, name, desc]
this:addCategory("default", "", "", "")
