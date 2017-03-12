# example at server/themes/example.coffee
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

module.exports = 
    getTheme:(name)->
        if themes[name] != null
            return themes[name]
        themeFiles = fs.readdirSync "server/themes/"
        # not the example
        themeFiles=themeFiles.filter (n)->n!="example.coffee"

        if "#{name}.coffee" in themeFiles
            try
                theme = require "../../themes/#{name}.coffee"
            catch e
                console.log e
                theme = null
            return theme
        return null