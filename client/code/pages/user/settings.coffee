app = require '/app'
unmount = null

exports.start = ->
    Promise.all([
        JinrouFront.loadI18n().then((i18n)-> i18n.getI18nFor())
        JinrouFront.loadUserSettings()
    ])
        .then ([i18n, userSettings])->
            node = $("#settingsapp").get 0
            userSettings.place({
                i18n: i18n
                node: node
            }).then (u)-> unmount = u

exports.end = ->
    if unmount?
        unmount()
