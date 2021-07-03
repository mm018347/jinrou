nodemailer = require("nodemailer")
crypto = require('crypto')
user=require './rpc/user.coffee'
auth=require './auth.coffee'

# create reusable transporter object using the default SMTP transport
transporter = nodemailer.createTransport(Config.smtpConfig)

# setup e-mail data with unicode symbols
mailOptions =
    from: "\"紫月人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>" # sender address

# ユーザーにメールを送る
sendMail=(userquery, makemailobj, callback)->
    M.users.findOne userquery, (err, record)->
        if err?
            callback "DB err:#{err}", null
            return
        if !record?
            callback "玩家資訊錯誤", null
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            callback "讀取驗證信件失敗，請稍待 5 分鐘後再重新嘗試。", null
            return

        # tokenを產生
        token = crypto.randomBytes(64).toString('hex')
        timestamp = Date.now()

        # default mail object saved in user
        mail =
            token: token
            timestamp: timestamp

        # to avoid TypeError: Cannot read property 'address' of undefined
        if !record.mail?
            record.mail =
                address : ""
                verified : false


        obj = makemailobj record, mail
        if !obj?
            callback "?", null
            return
        if obj.error?
            callback obj.error, null
            return
        mail = obj.mail
        options = obj.options
        for key, value of mailOptions
            try
                options[key] = value
            catch e
                options={}
                options[key] = value

        if !mail?
            # 送る必要がない
            callback null, {nochange: true}
            return
        if mail.error?
            # why didn't stop? what happened?
            # report bug automatically
            mailOptions.subject = "紫月人狼：Bug 回報"
            mailOptions.to = Config.smtpConfig.from ? Config.smtpConfig.auth.user
            # mailOptions.text = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            mailOptions.text = String(mail.error)
            mailOptions.html = mailOptions.text
            transporter.sendMail mailOptions, (error, info) ->
                return console.error("nodemailer:",error) if error
                console.log "Message sent: " + info.response
            callback "請求處理失敗。"
            return

        dochange = (err, count)->
            if err?
                callback "請求處理失敗。", null
                return
            if count.length>=3 && mail.for in ["confirm", "change"]
                callback "一個電子信箱最多允許綁定三個帳號。", null
                return

            console.log options
            transporter.sendMail options, (err, info)->
                if err?
                    console.error "nodemailer:", err
                    return
                console.log "Message sent: " + info.response
            # save to database
            M.users.update userquery, {
                $set: {
                    mail: mail
                }
            }, {safe: true}, (err, count)->
                if err?
                    callback "請求處理失敗。", null
                    return
                delete record.password
                record.mail=
                    address: mail.address
                    new: mail.new
                    verified: mail.verified
                    for: mail.for

                callback null, record

        if mail.new?
            M.users.find({"mail.address": mail.new}).toArray dochange
        else
            dochange null, []

# raw API for other server systems
exports.sendRawMail = (to, subject, body, callback)->
    options =
        from: "\"紫月人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>"
        subject: subject
        to: to
        text: body
    transporter.sendMail options, callback

sendConfirmMail=(query, req, res, ss)->
    unless /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
        res {error:"請輸入有效的電子信箱。"}
        return

    userquery =
        userid: req.session.userId
    makemailobj = (record, mail)->
        options = {}
        if record.mailconfirmsecurity
            return {
                error: "已鎖定電子信箱，變更失敗。"
            }
        if record.mail.address == query.mail
            return {
                mail: null
                options: null
            }
        else if (!record.mail.address || !record.mail.verified) && query.mail
            mail.new = query.mail
            mail.verified = false
            mail.for = "confirm"

            options.to = mail.new
            options.subject = "紫月人狼：綁定電子信箱確認"
        else if !query.mail
            mail.address = record.mail.address
            mail.verified = record.mail.verified
            mail.for = "remove"

            options.to = mail.address
            options.subject = "紫月人狼：解除綁定電子信箱確認"
        else if record.mail.address != query.mail && record.mail.verified
            mail.address = record.mail.address
            mail.new = query.mail
            mail.verified = record.mail.verified
            mail.for="change"

            options.to = mail.address
            options.subject = "紫月人狼：變更綁定電子信箱確認"
        else
            # ?????
            mail.error = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            return {
                mail: mail
                options: {}
            }

        options.text = """#{req.session.userId} 玩家
        
這封信件是您於「紫月人狼」中#{if mail.for=='remove' then '解除綁定' else '申請綁定'}電子信箱「#{if mail.for in ['confirm','change'] then mail.new else mail.address}」而發送的驗證信件。
綁定電子信箱後，可於日後進行重置密碼時，證明您的身份。
為了完成#{if mail.for=='remove' then '解除綁定' else '申請綁定'}，請點擊下述網址，該網址的有效期間為 1 個小時之內：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

若您對這封信件毫無頭緒，還請勿理會這封信件，也請不要點擊該網址。
這封信件透過發信專用的電子信箱發送，請不要直接回覆該信件。
"""
        options.html = """<p>#{req.session.userId} 玩家</p>
<p>這封信件是您於「紫月人狼」中#{if mail.for=='remove' then '解除綁定' else '申請綁定'}電子信箱「#{if mail.for in ['confirm','change'] then mail.new else mail.address}」而發送的驗證信件。</p>
<p>綁定電子信箱後，可於日後進行重置密碼時，證明您的身份。</p>
<p>為了完成#{if mail.for=='remove' then '解除綁定' else '申請綁定'}，請點擊下述網址，該網址的有效期間為 1 個小時之內：</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>若您對這封信件毫無頭緒，還請勿理會這封信件，也請不要點擊該網址。</p>
<hr>
<p>這封信件透過發信專用的電子信箱發送，請不要直接回覆該信件。</p>
"""
        return {
            mail: mail
            options: options
        }


    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        if record.nochange
            res record
            return

        req.session.user = record
        req.session.save ->
            record.info="驗證信件已發送至電子信箱「#{if record.mail.for in ['remove','change'] then record.mail.address else record.mail.new}」。該信件的有效期間為 1 個小時之內，請儘速確認。"
            res record

sendResetMail = (query, req, res, ss)->
    userquery =
        userid: query.userid
        "mail.address": query.mail
        "mail.verified": true
    makemailobj = (record, mail)->
        mail.address = record.mail.address
        mail.verified = record.mail.verified
        mail.for = "reset"
        mail.newsalt = auth.gensalt()
        mail.newpass = auth.crpassword query.newpass, mail.newsalt
        options =
            to: mail.address
            subject: "紫月人狼：重設密碼確認"

        options.text = """#{query.userid} 玩家

這封信件是您於「紫月人狼」中申請「重設密碼」而發送的驗證信件。
為了完成重設密碼，請點擊下述網址，該網址的有效期間為 1 個小時之內：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

若您對這封信件毫無頭緒，還請勿理會這封信件，也請不要點擊該網址。
若並未前往該網址，則密碼將不會重設。

這封信件透過發信專用的電子信箱發送，請不要直接回覆該信件。
"""
        options.html = """<p>#{query.userid} 玩家</p>

<p>這封信件是您於「紫月人狼」中申請「重設密碼」而發送的驗證信件。</p>
<p>為了完成重設密碼，請點擊下述網址，該網址的有效期間為 1 個小時之內：</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>若您對這封信件毫無頭緒，還請勿理會這封信件，也請不要點擊該網址。</p>
<p>若並未前往該網址，則密碼將不會重設。</p>
<hr>
<p>這封信件透過發信專用的電子信箱發送，請不要直接回覆該信件。</p>
"""
        return {
            mail: mail
            options: options
        }



    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        record.info="驗證信件已發送至電子信箱「#{query.mail}」。該信件的有效期間為 1 個小時之內，請儘速確認。"

        res record



sendMailconfirmsecurityMail=(query,req,res,ss)->
    userquery =
        userid: query.userid
    makemailobj = (record, mail)->
        mail.address = record.mail.address
        mail.verified = record.mail.verified
        mail.for = "mailconfirmsecurity-off"
        options =
            to: mail.address
            subject: "紫月人狼：變更安全性設定確認"

        options.text = """#{query.userid} 玩家

這封信件是您於「紫月人狼」中申請「解除鎖定密碼·電子信箱」而發送的驗證信件。
為了完成解除鎖定，請點擊下述網址，該網址的有效期間為 1 個小時之內：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

若您對這封信件毫無頭緒，還請勿理會這封信件，也請不要點擊該網址。
若並未前往該網址，則設定將不會變更。

這封信件透過發信專用的電子信箱發送，請不要直接回覆該信件。
"""
        options.html = """<p>#{query.userid} 玩家</p>

<p>這封信件是您於「紫月人狼」中申請「解除鎖定密碼·電子信箱」而發送的驗證信件。</p>
<p>為了完成解除鎖定，請點擊下述網址，該網址的有效期間為 1 個小時之內：</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>若您對這封信件毫無頭緒，還請勿理會這封信件，也請不要點擊該網址。</p>
<p>若並未前往該網址，則設定將不會變更。</p>
<hr>
<p>這封信件透過發信專用的電子信箱發送，請不要直接回覆該信件。</p>
"""
        return {
            mail: mail
            options: options
        }

    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        record.info="驗證信件已發送至電子信箱「#{query.mail}」。該信件的有效期間為 1 個小時之內，請儘速確認。"

        res record


exports.sendConfirmMail=sendConfirmMail
exports.sendResetMail=sendResetMail
exports.sendMailconfirmsecurityMail=sendMailconfirmsecurityMail
