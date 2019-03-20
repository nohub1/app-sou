-- param: this, url==(movie://param?query=[电影|电视剧|综艺|动画片大全]
local this, url = ...
local urlParam = this:urlParser(url)
local REQ_MOVIE_QUERY = urlParam:getString("query", "电影")
local IOS_UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1" 

local MOVIE_CATEGORY = {
	["电影"] = {
		TYPE = {["最热"] = 0, ["最新"] = 1, ["好评"] = 2},
		CAT = {"爱情", "喜剧", "动作", "剧情", "科幻", "恐怖", "惊悚", "犯罪"},
		AREA = {"美国", "大陆", "香港", "韩国", "日本", "泰国", "英国"},
		RESOURCEID = 28286
	},
	["电视剧"] = {
		TYPE = {["最热"] = 0, ["最新"] = 1},
		CAT = {"爱情", "悬疑", "古装", "犯罪", "战争", "动作", "科幻", "剧情"},
		AREA = {"大陆", "香港", "日本"},
		RESOURCEID = 28287
	},
	["动画片大全"] = {
		TYPE = {["最热"] = 0, ["最新"] = 1},
		CAT = {"冒险", "科幻", "搞笑", "剧情", "奇幻", "动作", "热血", "儿童", "情感", "其他"},
		AREA = {"中国", "欧美", "日本", "其他"},
		RESOURCEID = 28286
	},
	["综艺"] = {
		TYPE = {["最热"] = 0, ["最新"] = 1},
		CAT = {"真人秀", "生活", "脱口秀", "访谈", "音乐", "美食", "情感", "旅游", "其他"},
		AREA = {"中国", "日韩", "欧美"},
		RESOURCEID = 28263
	}
}

local QUERY_MOVIE_CATEGORY = MOVIE_CATEGORY[REQ_MOVIE_QUERY]

local function makeMovieURL(_type, cat, area, pn)
	local System = luajava.bindClass('java.lang.System')
	local currentTimeMillis = System:currentTimeMillis()

	local query = REQ_MOVIE_QUERY
	local resourceId = QUERY_MOVIE_CATEGORY.RESOURCEID
	
	return "https://sp0.baidu.com/8aQDcjqpAAV3otqbppnN2DJv/api.php"
	            .. "?sort_key=" .. _type
				.. "&stat0=" .. this:urlEncode(cat) 
				.. "&stat1=" .. this:urlEncode(area)
				.. "&pn=" .. pn
                .. "&rn=24" 
                .. "&resource_id=" .. resourceId
                .. "&tn=wisexmlnew&dsp=iphone&from_mid=1&format=json&ie=utf-8&oe=utf-8"
                .. "&need_di=1&ks_from=ks_sf&pd=movie_general"
                .. "&query=" .. this:urlEncode(query)
                .. "&_=" .. currentTimeMillis
                .. "&cb="
end

local function makeCategoryActionURL(title, _type, cat, area)
	local query = REQ_MOVIE_QUERY
	local rule = "https://nohub1.github.io/app-sou/site-lua/baidu_movie_page_site.lua"
	local url = "movie://param?query=" .. this:urlEncode(query)
	    .. "&type=" .. _type
	    .. "&cat=" .. this:urlEncode(cat)
	    .. "&area=" .. this:urlEncode(area)

	return "app-sou://site?siteType=lua-common&type=miniCard&title=" .. this:urlEncode(title)
		.. "&rule=" .. this:urlEncode(rule) .. "&url=" .. this:urlEncode(url)
end

--- load state
local loadState = {}
local function initLoadState(categoryId, __type, __cat, __area)
	loadState[categoryId] = {
		_type = __type,
		cat = __cat,
		area = __area,
		cursor = 0,
		loader = nil
	}
end

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

local function request(loadItem)
	local header = {}
	header["User-Agent"] = IOS_UA
	
	local url = makeMovieURL(loadItem._type, loadItem.cat, loadItem.area, loadItem.cursor)
	this:request(0, url, false, header, {}, function(ret, msg, responce)
		local data = this:toJson(responce)
		if data ~= nil then
			local result = getQueryData(data)
			local limit = 0
			for i = 0, result:getLength() do
				loadItem.cursor = loadItem.cursor + 1
			
				local item = result:getObject(i, "{}")
				local name, image, desc = parseItem(item)
				local action = "app-sou://search?keywords=" .. this:urlEncode(name) .. "&mimeType=mp4"
				
				local url = "http://m.baidu.com/s?word=" .. this:urlEncode(name)
				local longAction = "app-sou://webPreview?title=" .. this:urlEncode(name)
					.. "&url=" .. this:urlEncode(url)
					.. "&action=" .. this:urlEncode(action)
					.. "&actionText=" .. this:urlEncode("搜资源")
				local imageAction = ""

				if image ~= "" and name ~= "" and limit < 9 then
					loadItem.loader:addItem(url, image, name, desc, action, longAction, imageAction)
					limit = limit + 1
				end
			end
		end
		
		loadItem.loader:completed(ret, msg)
	end)
end

--[[ 
	loader = {
		addItem(String pageUrl, String image, String name, String desc, String action, String longAction),
		completed(int ret, String msg)
	}
]]
function load(categoryId, loader)
	local loadItem = loadState[categoryId]
	loadItem.cursor = 0
	loadItem.loader = loader
	request(loadItem)
end

function next(categoryId, loader)
	local loadItem = loadState[categoryId]
	loadItem.loader = loader
	request(loadItem)
end

--init[title, pageUrl, userAgent, referrer]
this:init(REQ_MOVIE_QUERY, "", IOS_UA, "")

--setItemViewTemplate[nameVisibleType, descVisibleType, imageVisibleType, nameRenderType, descRenderType, imageScaleType, imagePlaceholder]
this:setItemViewTemplate("", "", "", "", "html", "", "")

--addCategory[categoryId, image, name, desc, actionUrl]
for k, v in pairs(QUERY_MOVIE_CATEGORY.TYPE) do
	local categoryId = REQ_MOVIE_QUERY .. "_" .. k .. "_" .. v
	initLoadState(categoryId, v, "", "")
	this:addCategory(categoryId, "", k, "", makeCategoryActionURL(k .. REQ_MOVIE_QUERY, v, "", ""))
end

for i, v in ipairs(QUERY_MOVIE_CATEGORY.CAT) do
	local categoryId = REQ_MOVIE_QUERY .. "_" .. v .. "_" .. i
	initLoadState(categoryId, 0, v, "")
	this:addCategory(categoryId, "", v, "", makeCategoryActionURL(v .. REQ_MOVIE_QUERY, 0, v, ""))
end