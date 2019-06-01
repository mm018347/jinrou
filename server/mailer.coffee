nodemailer = require("nodemailer")
crypto = require('crypto')
user=require './rpc/user.coffee'
auth=require './auth.coffee'

# create reusable transporter object using the default SMTP transport
transporter = nodemailer.createTransport(Config.smtpConfig)

# setup e-mail data with unicode symbols
mailOptions =
    from: "\"月下人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>" # sender address

# ユーザーにメールを送る
sendMail=(userquery, makemailobj, callback)->
    M.users.findOne userquery, (err, record)->
        if err?
            callback "DB err:#{err}", null
            return
        if !record?
            callback "用户信息错误", null
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            callback "获取认证邮件失败，请于5分钟后再试。", null
            return

        # tokenを生成
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
            mailOptions.subject = "月下人狼：Bug report"
            mailOptions.to = Config.smtpConfig.from ? Config.smtpConfig.auth.user
            # mailOptions.text = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            mailOptions.text = String(mail.error)
            mailOptions.html = mailOptions.text
            transporter.sendMail mailOptions, (error, info) ->
                return console.error("nodemailer:",error) if error
                console.log "Message sent: " + info.response
            callback "请求处理失败。"
            return

        dochange = (err, count)->
            if err?
                callback "请求处理失败。", null
                return
            if count.length>=3 && mail.for in ["confirm", "change"]
                callback "一个邮箱最多允许绑定三个账号。", null
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
                    callback "请求处理失败。", null
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
        from: "\"月下人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>"
        subject: subject
        to: to
        text: body
    transporter.sendMail options, callback

sendConfirmMail=(query, req, res, ss)->
    unless /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
        res {error:"请输入有效的邮箱地址"}
        return

    userquery =
        userid: req.session.userId
    makemailobj = (record, mail)->
        options = {}
        if record.mailconfirmsecurity
            return {
                error: "邮箱地址被锁定，变更失败。"
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
            options.subject = "月下人狼：确认您的邮箱"
        else if !query.mail
            mail.address = record.mail.address
            mail.verified = record.mail.verified
            mail.for = "remove"

            options.to = mail.address
            options.subject = "月下人狼：解除邮箱绑定"
        else if record.mail.address != query.mail && record.mail.verified
            mail.address = record.mail.address
            mail.new = query.mail
            mail.verified = record.mail.verified
            mail.for="change"

            options.to = mail.address
            options.subject = "月下人狼：修改绑定邮箱"
        else
            # ?????
            mail.error = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            return {
                mail: mail
                options: {}
            }

        options.text = """您好 #{req.session.userId}，
您正在「月下人狼」为您的账号#{if mail.for=='remove' then '解除认证' else '认证邮箱'}「#{if mail.for in ['confirm','change'] then mail.new else mail.address}」，用于在重置密码时证实您的身份。
请访问以下链接以完成#{if mail.for=='remove' then '解除认证' else '认证邮箱'}操作，此链接有效时间为1小时：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。
本条邮件由系统自动发出，请勿回复。
"""
        options.html = """<p>您好 #{req.session.userId}，</p>
<p>您正在「月下人狼」为您的账号#{if mail.for=='remove' then '解除认证' else '认证邮箱'}「#{if mail.for in ['confirm','change'] then mail.new else mail.address}」，用于在重置密码时证实您的身份。</p>
<p>请访问以下链接以完成#{if mail.for=='remove' then '解除认证' else '认证邮箱'}操作，此链接有效时间为1小时：</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。</p>
<hr>
<p>本条邮件由系统自动发出，请勿回复。</p>
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
            record.info="认证邮件已经发送至您的邮箱「#{if record.mail.for in ['remove','change'] then record.mail.address else record.mail.new}」，该邮件将在一小时内有效，请尽快查看。"
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
            subject: "月下人狼：重设密码"

        options.text = """您好 #{query.userid}，

您正在「月下人狼」为您的账号重设密码。
请访问以下链接以完成密码重置操作，此链接有效时间为1小时：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。
不访问此链接，您的密码就不会被重置。

本条邮件由系统自动发出，请勿回复。
"""
        options.html = """<p>您好 #{query.userid}，</p>

<p>您正在「月下人狼」为您的账号重设密码。</p>
<p>请访问以下链接以完成密码重置操作，此链接有效时间为1小时：</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。</p>
<p>不访问此链接，您的密码就不会被重置。</p>
<hr>
<p>本条邮件由系统自动发出，请勿回复。</p>
"""
        return {
            mail: mail
            options: options
        }



    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        record.info="重置密码邮件已经发送至「#{query.mail}」，有效时间1小时，请注意查收。"

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
            subject: "月下人狼: 变更安全性设置"

        options.text = """您好 #{query.userid}，

您正在「月下人狼」申请解除「锁定密码·邮箱地址」。
请访问以下链接以完成解锁，此链接有效时间为1小时：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。
不访问此链接，您的设置就不会被变更。

本条邮件由系统自动发出，请勿回复。
"""
        options.html = """<p>您好 #{query.userid}，</p>

<p>您正在「月下人狼」申请解除「锁定密码·邮箱地址」。</p>
<p>请访问以下链接以完成解锁，此链接有效时间为1小时：</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。</p>
<p>不访问此链接，您的设置就不会被变更。</p>
<hr>
<p>本条邮件由系统自动发出，请勿回复。</p>
"""
        return {
            mail: mail
            options: options
        }

    sendMail userquery, makemailobj, (err, record)->
        if err?
            res {error: String(err)}
            return
        record.info="解锁认证邮件已经发送至「#{record.mail.address}」。请按照邮件指示内容操作。"

        res record


exports.sendConfirmMail=sendConfirmMail
exports.sendResetMail=sendResetMail
exports.sendMailconfirmsecurityMail=sendMailconfirmsecurityMail
