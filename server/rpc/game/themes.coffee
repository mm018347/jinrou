# example at server/themes/example.coffee
fs=require 'fs'

module.exports = 
    getTheme:(name)->
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