###
    danganronpa:
        name:String
        opening:String
        vote:String
        sunrise:String
        sunset:String
        icon:String(URL)
        background_color:"black"
        color:"rgb(255,0,166)"
        skins:
            some_id:
                avatar:String(URL)
                name:String
                prize:String
        skin_length:55
        skin_tip:String
        lockable:false
        isAvailable:->
            date=new Date
            month=date.getMonth()
            d=date.getDate()
            if month==8 && 1<=d<=15 #9月1日~15日
                true
            else
                false
###
fs=require 'fs'
themeFiles = fs.readdirSync "server/themes/"
# not the example
themeFiles=themeFiles.filter (n)->n!="example.coffee"
themes={}
for themeFile in themeFiles
    unless themeFile.match(/\.coffee$/) == null
        name = themeFile.replace /\.coffee$/, ""
        try
            themes[name] = require "../../themes/#{name}.coffee"
        catch e
            console.log e

module.exports = themes