nodemailer = require("nodemailer")
crypto = require('crypto')
user=require './rpc/user.coffee'

# create reusable transporter object using the default SMTP transport
transporter = nodemailer.createTransport(Config.smtpConfig)

# setup e-mail data with unicode symbols
mailOptions =
    from: "\"月下人狼\" <#{Config.smtpConfig.from ? Config.smtpConfig.auth.user}>" # sender address


sendConfirmMail=(query,req,res,ss)->
    console.log "绑定邮箱"
    M.users.findOne {"userid":req.session.userId,"password":user.crpassword(query.password)},(err,record)=>
        if err?
            res {error:"DB err:#{err}"}
            return
        if !record?
            res {error:"用户认证失败"}
            return
        query.mail = query.mail.trim()
        if /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
            mailOptions.to = query.mail
        else
            res {error:"请输入有效的邮箱地址"}
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            res {error:"获取认证邮件失败，请于5分钟后再试。"}
            return
        # defaults
        mail=
            token:crypto.randomBytes(64).toString('hex')
            timestamp:Date.now()

        # to avoid TypeError: Cannot read property 'address' of undefined
        if !record.mail?
            record.mail =
                address : ""
                verified : false

        # mail address
        if record.mail.address == query.mail
            res {nochange: true}
            return
        # new
        # when the last mail was not confirmed, take it as new
        else if (!record.mail.address || !record.mail.verified) && query.mail
            mail.new = query.mail
            mail.verified = false
            mail.for="confirm"
            mailOptions.subject = "月下人狼：确认您的邮箱"
        # remove
        else if !query.mail
            # mail address
            mail.address = record.mail.address
            mail.verified = record.mail.verified
            mail.for="remove"
            mailOptions.subject = "月下人狼：解除邮箱绑定"
        # change
        else if record.mail.address != query.mail && record.mail.verified
            # mail address
            mail.address = record.mail.address
            mail.new = query.mail
            mail.verified = record.mail.verified
            mail.for="change"
            mailOptions.subject = "月下人狼：修改绑定邮箱"
        # why didn't stop? what happened?
        # report bug automatically
        else
            mailOptions.subject = "月下人狼：Bug report"
            mailOptions.to = Config.smtpConfig.auth.user
            mailOptions.text = "query:\n#{JSON.stringify(query)}\n\nrecord.mail:\n#{JSON.stringify(record.mail)}\n"
            mailOptions.html = mailOptions.text
            transporter.sendMail mailOptions, (error, info) ->
                return console.error("nodemailer:",error) if error
                console.log "Message sent: " + info.response
            res {error:"邮箱变更失败。"}
            return
            
        dochange = (err,count)->
            if err?
                res {error:"配置变更失败"}
                return
            if count.length>=3 && mail.for in ["confirm","change"]
                res {error:"一个邮箱最多允许绑定三个账号"}
                return
            # write a mail
            if mail.for in ['remove','change']
                mailOptions.to = mail.address
            else
                mailOptions.to = mail.new
            console.log mail
            mailOptions.text = """您好 #{req.session.userId}，
您正在「月下人狼」为您的账号#{if mail.for=='remove' then '解除认证' else '认证邮箱'}「#{if mail.for=='change' then mail.new else mail.address}」，用于在重置密码时证实您的身份。
请访问以下链接以完成#{if mail.for=='remove' then '解除认证' else '认证邮箱'}操作，此链接有效时间为1小时：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。
本条邮件由系统自动发出，请勿回复。
"""
            mailOptions.html = """<p>您好 #{req.session.userId}，</p>
<p>您正在「月下人狼」为您的账号#{if mail.for=='remove' then '解除认证' else '认证邮箱'}「#{if mail.for=='change' then mail.new else mail.address}」，用于在重置密码时证实您的身份。</p>
<p>请访问以下链接以完成#{if mail.for=='remove' then '解除认证' else '认证邮箱'}操作，此链接有效时间为1小时：</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。</p>
<hr>
<p>本条邮件由系统自动发出，请勿回复。</p>
"""
            
            console.log mailOptions
            transporter.sendMail mailOptions, (error, info) ->
                return console.error("nodemailer:",error) if error
                console.log "Message sent: " + info.response

            # save to database
            M.users.update {"userid":req.session.userId}, {$set:{mail:mail}},{safe:true},(err,count)=>
                if err?
                    res {error:"配置变更失败"}
                    return
                delete record.password
                record.mail=
                    address:mail.address
                    new:mail.new
                    verified:mail.verified
                req.session.user = record
                req.session.save ->
                    record.info="认证邮件已经发送至您的邮箱「#{if mail.for in ['remove','change'] then mail.address else mail.new}」，该邮件将在一小时内有效，请尽快查看。"
                    res record
            return

        if mail.new?
            # 限制邮箱绑定数
            M.users.find({"mail.address": mail.new}).toArray dochange
        else
            dochange null, []
        return
    return

sendResetMail=(query,req,res,ss)->
    console.log "重置密码"
    M.users.findOne {"userid":query.userid,"mail.address":query.mail,"mail.verified":true},(err,record)=>
        if err?
            res {error:"DB err:#{err}"}
            return
        if !record?
            res {error:"账号或邮箱不正确，或邮箱没有绑定"}
            return
        if /\w[-\w.+]*@([A-Za-z0-9][-A-Za-z0-9]+\.)+[A-Za-z]{2,14}/.test(query.mail) || query.mail == ""
            mailOptions.to = query.mail
        else
            res {error:"请输入有效的邮箱地址"}
            return
        if record.mail?.timestamp? && Date.now() < record.mail.timestamp + 5*60*1000
            res {error:"现在不能为您重设密码。请于5分钟后再试。"}
            return
        # defaults
        mail=
            token:crypto.randomBytes(64).toString('hex')
            timestamp:Date.now()
        # mail address
        # reset
        mail.address = record.mail.address
        mail.verified = record.mail.verified
        mail.for="reset"
        mail.newpass=user.crpassword(query.newpass)
        mailOptions.subject = "月下人狼：重设密码"
        # write a mail
        mailOptions.to = mail.address
        mailOptions.text = """您好 #{req.session.userId}，

您正在「月下人狼」为您的账号重设密码。
请访问以下链接以完成密码重置操作，此链接有效时间为1小时：
#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}

如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。
不访问此链接，您的密码就不会被重置。

本条邮件由系统自动发出，请勿回复。
"""

        mailOptions.html = """<p>您好 #{req.session.userId}，</p>

<p>「月下人狼」のアカウントのパスワード再設定がリクエストされました。</p>
<p>您正在「月下人狼」为您的账号重设密码。</p>
<p><a href='#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}'>#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p>

<p>如果这不是您的操作，请无视本条邮件，并务必不要访问此链接。</p>
<p>不访问此链接，您的密码就不会被重置。</p>
<hr>
<p>本条邮件由系统自动发出，请勿回复。</p>
"""
            
        console.log mailOptions
        transporter.sendMail mailOptions, (error, info) ->
            return console.error(error) if error
            console.log "Message sent: " + info.response

        # save to database
        M.users.update {"userid":query.userid}, {$set:{mail:mail}},{safe:true},(err,count)=>
            if err?
                res {error:"配置变更失败"}
                return
            delete record.password
            record.info="重置密码邮件已经发送至「#{query.mail}」，有效时间1小时，请注意查收。"
            record.mail=
                address:mail.address
                verified:mail.verified
            res record
        return

    
exports.sendConfirmMail=sendConfirmMail
exports.sendResetMail=sendResetMail
