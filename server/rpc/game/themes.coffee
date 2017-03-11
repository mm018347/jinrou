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

module.exports = themes