nodemailer = require("nodemailer")
crypto = require('crypto')
user=require './rpc/user.coffee'

# create reusable transporter object using the default SMTP transport
transporter = nodemailer.createTransport(Config.smtpConfig)

# setup e-mail data with unicode symbols
mailOptions =
    from: "\"月下人狼\" <#{Config.smtpConfig.auth.user}>" # sender address


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
            res {error:"两次获取认证邮件请至少间隔五分钟"}
            return
        # defaults
        mail=
            token:crypto.randomBytes(64).toString('hex')
            timestamp:Date.now()

        # to avoid TypeError: Cannot read property 'address' of undefined
        if !record.mail?
            record.mail = 
                address = ""
                verified = false

        # mail address
        if record.mail.address == query.mail
            res {error:"邮箱地址没有变化。"}
            return
        # new
        # when the last mail was not confirmed, take it as new
        else if (!record.mail.address || !record.mail.verified) && query.mail
            mail.address = query.mail
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
            
        # 限制邮箱绑定数
        M.users.find({"mail.address":mail.address}).toArray (err,count)->
            if err?
                res {error:"配置变更失败"}
                return
            console.log count.length
            if count.length>=3 && mail.for in ["confirm","change"]
                res {error:"一个邮箱最多允许绑定三个账号"}
                return
            # write a mail
            mailOptions.to = mail.address
            mailOptions.text = "您正在「月下人狼」为您的账号「#{req.session.userId}」#{if mail.for=='remove' then '解除绑定' else '绑定邮箱'}「#{if mail.new? then mail.new else mail.address}」，用于在找回密码时证实您的身份。\n请访问以下链接以完成绑定，此链接有效时间为1小时：\n#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\n\n如果这不是您的操作，请无视本条邮件。\n本条邮件由系统自动发出，请勿回复。"
            mailOptions.html = "<h1>月下人狼：确认您的邮箱</h1><p>您正在「月下人狼」为您的账号「#{req.session.userId}」#{if mail.for=='remove' then '解除绑定' else '绑定邮箱'}「#{if mail.new? then mail.new else mail.address}」，用于在找回密码时证实您的身份。</p><p>请访问以下链接以完成绑定，此链接有效时间为1小时：</p><p><a href=\"#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p><p></p><p>如果这不是您的操作，请无视本条邮件。</p><p>本条邮件由系统自动发出，请勿回复。</p>"
            
            transporter.sendMail mailOptions, (error, info) ->
                return console.error(error) if error
                console.log "Message sent: " + info.response

            # save to database
            M.users.update {"userid":req.session.userId}, {$set:{mail:mail}},{safe:true},(err,count)=>
                if err?
                    res {error:"配置变更失败"}
                    return
                delete record.password
                record.info="认证邮件已经发送至您的邮箱「#{mail.address}」，该邮件将在一小时内有效，请尽快查看。"
                record.mail=
                    address:mail.address
                    verified:mail.verified
                res record
            return
        return
    return

sendResetMail=(query,req,res,ss)->
    console.log "找回密码"
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
            res {error:"两次获取认证邮件请至少间隔五分钟"}
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
        mailOptions.text = "您正在「月下人狼」为您的账号「#{query.userid}」（#{query.mail}）重设密码。\n请访问以下链接以完成重设，此链接有效时间为1小时：\n#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\n\n如果这不是您的操作，请无视本条邮件。\n本条邮件由系统自动发出，请勿回复。"
        mailOptions.html = "<h1>月下人狼：重设密码</h1><p>您正在「月下人狼」为您的账号「#{query.userid}」（#{query.mail}）重设密码。</p><p>请访问以下链接以完成重设，此链接有效时间为1小时：</p><p><a href=\"#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}\">#{Config.application.url}my?token=#{mail.token}&timestamp=#{mail.timestamp}</a></p><p></p><p>如果这不是您的操作，请无视本条邮件。</p><p>本条邮件由系统自动发出，请勿回复。</p>"
            
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