exports.start=(userid)->
    ss.rpc "user.userData", userid,null,(obj)->
        unless obj?
            Index.util.message "错误","这个玩家不存在"
            return
        user = obj.user
        $("#uname").text user.name
        $("#userid").text userid
        $("#usercomment").text user.comment
        # 战绩
        usersummary = obj.usersummary
        if usersummary?
            if usersummary.open

                $("#usersummary").append """
                <p>最近 #{usersummary.days} 天内的战绩：</p>
                <p>对战数 <b>#{usersummary.game_total}</b>，胜利数 <b>#{usersummary.win}</b>，败北数 <b>#{usersummary.lose}</b></p>
                <p>GM数： <b>#{usersummary.gm}</b>，帮手数 <b>#{usersummary.helper}</b></p>
                <p>猝死数 <b>#{usersummary.gone}</b> #{if usersummary.game_total > 0 then "(#{(usersummary.gone / usersummary.game_total * 100).toFixed(1)}%)" else ""}</p>
                """
            else
                $("#usersummary").append """
                <p>此用户最近 #{usersummary.days} 天内的战绩设为不公开。（最近 #{usersummary.days} 天内的猝死率：#{(if usersummary.game_total > 0 then usersummary.gone / usersummary.game_total * 100 else 0).toFixed(1)}%）</p>
                    """
        userlog = obj.userlog
        if userlog?
            $("#usersummary").append """
                <p>全部战绩：</p>
                <p>对战数 <b>#{userlog.game}</b>，胜利数 <b>#{userlog.win}</b>，败北数 <b>#{userlog.lose}</b></p>
                """
        else
            $("#usersummary").append """
                <p>此用户全部战绩设为不公开。</p>
                """


exports.end=->
