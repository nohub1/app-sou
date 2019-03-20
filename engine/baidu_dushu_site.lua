-- param: this, url=(book://param?keyword=[keywords])
local this, url = ...
local urlParam = this:urlParser(url)
local KEYWORDS = urlParam:getString("keyword", "")
local REFERRER = "http://dushu.m.baidu.com/searchresult?query=%E6%90%9C%E7%B4%A2%E7%BB%93%E6%9E%9C&word=" .. this:urlEncode(KEYWORDS)
local IOS_UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1" 

local function generalURL(query, pn)
    if pn > 0 then
        return nil
    end

	return "http://dushu.m.baidu.com/api/getSearchResultData?query=" .. this:urlEncode(query)
end

local categoryState = {
	loader = nil,
	cursor = 0,
	name = "",
	image = "",
	desc = "",
	getURL = function(pn)
		return generalURL(KEYWORDS, pn)
	end
}

local function getQueryData(data)
	return data:getObject("data", "[]")
            :getArray("novelList", "[]")
end

--[ret: name, image, desc, url]
local function parseItem(item)
	local name = item:getString("title", "")
	local image = item:getString("cover", "")

	local description = item:getString("description", "")
    local author = item:getString("author", "")
    local status = item:getString("status", "")

    local desc = "作者：" .. author .. "\n"
            .. "状态：" .. status .. "\n"
            .. "简介：" .. description

    local bookId = item:getString("bookId", "")
    local url = "http://m.baidu.com/tcx?appui=alaxs&page=detail&gid=" .. bookId .. "&from=dushu"

	return name, image, desc, url
end

local function request(category)
	local header = {}
	header["User-Agent"] = IOS_UA
	header["Referer"] = REFERRER
	header["Referrer"] = REFERRER

	local url = category.getURL(category.cursor)
	if url == nil then
	    category.loader:completed(-1, "没有更多")
	    return
	end

	this:request(0, url, false, header, {}, function(ret, msg, response)
	    if response ~= nil then
            local data = this:toJson(response)
            if data ~= nil then
                local result = getQueryData(data)
                for i = 0, result:getLength() do
                    category.cursor = category.cursor + 1

                    local item = result:getObject(i, "{}")
                    local name, image, desc, url = parseItem(item)

                    local action = "app-sou://web?bar=0&url=" .. this:urlEncode(url)
                    local longAction = "app-sou://webPreview?title=" .. this:urlEncode(name)
                                    .. "&url=" .. this:urlEncode(url)

                    if image ~= "" and name ~= "" then
                        category.loader:addItem(url, image, name, desc, action, longAction)
                    end
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
this:setItemViewTemplate("", "", "", "", "", "", "")

--addCategory[categoryId, image, name, desc]
this:addCategory("default", "", "", "")
