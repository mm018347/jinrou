exports.start=(userid)->
    ss.rpc "user.userData", userid,null,(obj)->
        unless obj?
            Index.util.message "錯誤","找不到該玩家"
            return
        user = obj.user
        $("#uname").text user.name
        $("#userid").text userid
        $("#usercomment").text user.comment
        # 戰績
        usersummary = obj.usersummary
        if usersummary?
            if usersummary.open

                $("#usersummary").append """
                <p>最近 #{usersummary.days} 天內的戰績：</p>
                <p>對戰數 <b>#{usersummary.game_total}</b>，勝利數 <b>#{usersummary.win}</b>，敗北數 <b>#{usersummary.lose}</b></p>
                <p>GM 數： <b>#{usersummary.gm}</b>，助手數 <b>#{usersummary.helper}</b></p>
                <p>暴斃數 <b>#{usersummary.gone}</b> #{if usersummary.game_total > 0 then "(#{(usersummary.gone / usersummary.game_total * 100).toFixed(1)}%)" else ""}</p>
                """
            else
                $("#usersummary").append """
                <p>該玩家最近 #{usersummary.days} 天內的戰績設為不公開。（最近 #{usersummary.days} 天內的暴斃率：#{(if usersummary.game_total > 0 then usersummary.gone / usersummary.game_total * 100 else 0).toFixed(1)}%）</p>
                    """
        userlog = obj.userlog
        if userlog?
            $("#usersummary").append """
                <p>全部戰績：</p>
                <p>對戰數 <b>#{userlog.game}</b>，勝利數 <b>#{userlog.win}</b>，敗北數 <b>#{userlog.lose}</b></p>
                """
        else
            $("#usersummary").append """
                <p>該玩家全部戰績設為不公開。</p>
                """


exports.end=->
