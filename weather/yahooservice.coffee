#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

class YahooService

    APPID = "dj0yJmk9QU10MlFDcUlsWEIxJmQ9WVdrOVdXbFlVbGxOTnpRbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1lZA--"
    DEG = 'c'
    lc = 'zh-Hans'
    lang = 'zh-cn'
    Dbus_citypinyin = null
    Dbus_citypinyin_connect = false
    constructor: ->
        lang = window.navigator.language
        #echo "lang:#{lang}"
        #@get_cityinfo_by_input("wuha")
        try
            Dbus_citypinyin = DCore.DBus.session("com.deepin.dde.api.CityPinyin")
            Dbus_citypinyin_connect = true
        catch error
            echo "Dbus_citypinyin failed:#{error}"
            Dbus_citypinyin_connect = false


    get_woeid_by_place_name:(place_name,callback)->
        lc = @lang_to_lc(lang)
        echo "lc:---#{lc}---"
        woeid_url = "http://sugg.hk.search.yahoo.net/gossip-gl-location/?appid=weather&output=sd1&p2=cn,t,pt,z&lc=" + lc + "&command=" + place_name
        woeid_data = new Array()
        array_clear(woeid_data)
        ajax(woeid_url,true,(xhr)=>
            # try
                xml_str = xhr.responseText
                localStorage.setItem("yahoo_woeid_xml_str",xml_str)
                woeid_xml = localStorage.getObject("yahoo_woeid_xml_str")
                try
                    if woeid_xml.q isnt place_name
                        echo "get_woeid_by_place_name xml_str  wrong!"
                        return
                catch e
                    echo "get_woeid_by_place_name xml_str  wrong!"
                    return

                r = woeid_xml.r
                for dk,index in r
                    value = new Array()
                    array_clear(value)
                    d = dk.d
                    k = dk.k
                    t = d.substring(d.indexOf(":") + 1)
                    t_arr = t.split("&")
                    for pt,i in t_arr
                        value.push(pt.slice(pt.indexOf("=") + 1))

                    arr = {index:index,k:k,iso:value[0],id:value[1],lon:value[2],lat:value[3],s:value[4],c:value[5],pn:value[6]}
                    woeid_data.push(arr)

                localStorage.setObject("woeid_data",woeid_data)
                callback?()
            # catch e
                # echo "get_woeid_by_place_name xhr.responseText error!"
        )

    get_woeid_by_whole_name:(place_name,callback)->
        woeid_url = "http://where.yahooapis.com/v1/places.q('#{place_name}')?appid=#{APPID}&lang=#{lang}&format=json"
        woeid_data = new Array()
        array_clear(woeid_data)
        woeid_data_whole = new Array()
        array_clear(woeid_data_whole)
        ajax(woeid_url,true,(xhr)=>
            # try
                xml_str = xhr.responseText
                localStorage.setItem("yahoo_woeid_xml_str",xml_str)
                woeid_xml = localStorage.getObject("yahoo_woeid_xml_str")
                try
                    if woeid_xml.places.count == 0
                        echo "get_woeid_by_place_name xml_str  count == 0!"
                        return
                catch e
                    echo "get_woeid_by_place_name xml_str  wrong!"
                    return

                woeid_data_whole = woeid_xml.places.place
                for data,j in woeid_data_whole
                    arr = {index:j,k:data.name,iso:lang,id:data.woeid,lon:"32.1605",lat:"-95.6692",s:data.admin1,c:data.country,pn:data.admin2}
                    woeid_data.push(arr)
                localStorage.setObject("woeid_data_whole_name",woeid_data)
                callback?()
            # catch e
                # echo "get_woeid_by_place_name xhr.responseText error!"
        )




    get_weather_data_by_woeid:(woeid,callback)->
        #echo "woeid:" + woeid
        if !woeid
            echo "woeid :" + woeid + ",return!"
            return
        DEG = localStorage.getItem("temp_danwei")
        if not DEG?
            DEG = "c"
            localStorage.setItem("temp_danwei",DEG)
        xml_str = "http://weather.yahooapis.com/forecastrss?w=" + woeid + "&u=" + DEG
        yahoo_weather_data_more = new Array()
        array_clear(yahoo_weather_data_more)
        ajax(xml_str,true,(xhr)=>
            # try
                xmlDoc =  xhr.responseXML
                title = xmlDoc.getElementsByTagName("item")[0].getElementsByTagName("title")[0].childNodes[0].nodeValue
                if title is "City not found"
                    echo "title:" + title + ",the return data is error ,return!"
                    return
                location = xmlDoc.getElementsByTagNameNS("*","location")
                city = location[0].getAttribute("city")
                region = location[0].getAttribute("region")
                country = location[0].getAttribute("country")
                item  = xmlDoc.getElementsByTagName("title")

                units = xmlDoc.getElementsByTagNameNS("*","units")
                temperature = units[0].getAttribute("temperature")

                condition = xmlDoc.getElementsByTagNameNS("*","condition")
                text_now = condition[0].getAttribute("text")
                code_now = condition[0].getAttribute("code")
                temp_now = condition[0].getAttribute("temp")
                date_now = condition[0].getAttribute("date")
                common_dists = localStorage.getObject("common_dists")
                #city_name = _("choose city")
                city_name = null
                if not common_dists? then return
                for tmp in common_dists
                    if woeid is tmp.id.toString()
                        echo "#{tmp.name}:#{woeid}"
                        city_name = tmp.name

                yahoo_weather_data_now = {city:city,city_name:city_name,id:woeid,region:region,country:country,temp_danwei:temperature,text:text_now,code:code_now,temp:temp_now,date:date_now}
                localStorage.setObject("yahoo_weather_data_now",yahoo_weather_data_now)

                forecast = xmlDoc.getElementsByTagNameNS("*","forecast")
                for i in [0..forecast.length-1]
                    day = forecast[i].getAttribute("day")
                    date = forecast[i].getAttribute("date")
                    low = forecast[i].getAttribute("low")
                    high = forecast[i].getAttribute("high")
                    text = forecast[i].getAttribute("text")
                    code = forecast[i].getAttribute("code")
                    yahoo_weather_data_more.push({index:i,id:woeid,day:day,date:date,low:low,high:high,text:text,code:code})

                localStorage.setObject("yahoo_weather_data_more",yahoo_weather_data_more)
                callback?()
            # catch e
                # echo "get_weather_data_by_woeid xhr.responseText error!"
        )

    get_cityinfo_by_input:(input,callback)->
        if input.length <= 2 then return
        if Dbus_citypinyin_connect
            cityinfo_array = Dbus_citypinyin.GetValues_sync(input)
            for info,i in cityinfo_array
                cityname = info.substring(0,info.indexOf(","))
                @get_woeid_by_whole_name(cityname,callback)
        else
            echo "Dbus_citypinyin connect failed"
            @get_woeid_by_whole_name(input,callback)


    lang_to_lc:(lang) ->
        switch(lang)
            when "zh-hk" then return "zh-Hant"
            when "zh-tw" then return "zh-Hant"
            when "zh-cn" then return "zh-Hans"
            when "en-us" then return "en"
            when "cs" then return "cs"
            when "cs-cz" then return "cs"
            when "es" then return "es"
            when "es_CL" then return "es"
            when "pt-pt" then return "pt"
            when "pt-br" then return "pt"
            else return lang

    temperature_c_to_f:(c)->
       f = c * 9 / 5 + 32
       return f

    temperature_f_to_c:(f)->
       c = (f - 32) * 5 / 9
       return c

    day_en_zh:(day) ->
        switch(day)
            when "Sun" then return _("Sun")
            when "Mon" then return _("Mon")
            when "Tue" then return _("Tue")
            when "Wed" then return _("Wed")
            when "Thu" then return _("Thu")
            when "Fri" then return _("Fri")
            when "Sat" then return _("Sat")
            else echo "no this day:" + day

    month_en_num:(month) ->
        switch(month)
            when "Jan" then return "1"
            when "Feb" then return "2"
            when "Mar" then return "3"
            when "Apr" then return "4"
            when "May" then return "5"
            when "Jun" then return "6"
            when "Jul" then return "7"
            when "Aug" then return "8"
            when "Sep" then return "9"
            when "Oct" then return "10"
            when "Nov" then return "11"
            when "Dec" then return "12"
            else echo "no this month:" + month

    yahoo_img_code_to_en:(code) ->
        switch(code)
            when "0" then  return _("tornado")
            when "1" then  return _("tropical storm")
            when "2" then  return _("hurricane")
            when "3" then  return _("severe thunderstorms")
            when "4" then  return _("thunderstorms")
            when "5" then  return _("mixed rain and snow")
            when "6" then  return _("mixed rain and sleet")
            when "7" then  return _("mixed snow and sleet")
            when "8" then  return _("freezing drizzle")
            when "9" then  return _("drizzle")
            when "10" then return _("freezing rain")
            when "11" then return _("showers")
            when "12" then return _("showers")
            when "13" then return _("snow flurries")
            when "14" then return _("light snow showers")
            when "15" then return _("blowing snow")
            when "16" then return _("snow")
            when "17" then return _("hail")
            when "18" then return _("sleet")
            when "19" then return _("dust")
            when "20" then return _("foggy")
            when "21" then return _("haze")
            when "22" then return _("smoky")
            when "23" then return _("blustery")
            when "24" then return _("windy")
            when "25" then return _("cold")
            when "26" then return _("cloudy")
            when "27" then return _("mostly cloudy (night)")
            when "28" then return _("mostly cloudy (day)")
            when "29" then return _("partly cloudy (night)")
            when "30" then return _("partly cloudy (day)")
            when "31" then return _("clear (night)")
            when "32" then return _("sunny")
            when "33" then return _("fair (night)")
            when "34" then return _("fair (day)")
            when "35" then return _("mixed rain and hail")
            when "36" then return _("hot")
            when "37" then return _("isolated thunderstorms")
            when "38" then return _("scattered thunderstorms")
            when "39" then return _("scattered thunderstorm")
            when "40" then return _("scattered showers")
            when "41" then return _("heavy snow")
            when "42" then return _("scattered snow showers")
            when "43" then return _("heavy snow")
            when "44" then return _("partly cloudy")
            when "45" then return _("thundershowers")
            when "46" then return _("snow showers")
            when "47" then return _("isolated thundershowers")
            else return _("3200 not available")


    yahoo_img_code_to_zh:(code) ->
        #small_img_url = "http://l.yimg.com/a/i/us/we/52/11.gif"
        #big_img_url = "http://l.yimg.com/a/i/us/nws/weather/gr/11n.png"
        switch(code)
            when "0" then  return "龙卷风"
            when "1" then  return "热带风暴"
            when "2" then  return "飓风"
            when "3" then  return "严重的雷暴"
            when "4" then  return "雷暴"
            when "5" then  return "混合雨雪"
            when "6" then  return "混合降雨和冰雹"
            when "7" then  return "混合雪和雨夹雪"
            when "8" then  return "冻结小雨"
            when "9" then  return "小雨"
            when "10" then return "冻雨"
            when "11" then return  "阵雨"
            when "12" then return "阵雨"
            when "13" then return "雪飘雪"
            when "14" then return "小雪阵雨"
            when "15" then return "吹雪"
            when "16" then return "雪"
            when "17" then return "冰雹"
            when "18" then return "雨夹雪"
            when "19" then return "尘埃"
            when "20" then return "雾"
            when "21" then return "霾"
            when "22" then return "黑烟"
            when "23" then return "大风"
            when "24" then return "风"
            when "25" then return "低温"
            when "26" then return "多云"
            when "27" then return "多云（晚上）"
            when "28" then return "多云（白天）"
            when "29" then return "局部多云（晚上）"
            when "30" then return "局部多云（白天）"
            when "31" then return "清爽（晚）"
            when "32" then return "晴天"
            when "33" then return "晴朗（晚）"
            when "34" then return "晴朗（白天）"
            when "35" then return "混合雨和冰雹"
            when "36" then return "热"
            when "37" then return "局部地区性雷暴"
            when "38" then return "零星雷暴"
            when "39" then return "零星雷暴"
            when "40" then return "零星阵雨"
            when "41" then return "大雪"
            when "42" then return "零星阵雪"
            when "43" then return "大雪"
            when "44" then return "多云"
            when "45" then return "雷阵雨"
            when "46" then return "阵雪"
            when "47" then return "局部雷阵雨"
            else return "3200无法使用"
