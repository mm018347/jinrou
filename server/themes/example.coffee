module.exports=
    name:"东方Project"
    opening:"异变发生！"
    vote:""
    sunrise:""
    sunset:""
    icon:""
    background_color:"black"
    color:"rgb(255,0,166)"
    skins:
        # 罗马字名 ，只允许半角英数字和下划线，数字和下划线不允许是首位
        # 不可以重复
        some_character: 
            # 头像链接 和 称号 可以是字符串数组，也可以是字符串
            # 头像在显示的时候 会压缩为48*48，所以最好纵横比是1:1
            avatar:"http://img.example.com/some_character.jpg" # 头像链接
            name:"博丽灵梦" # 名字，必填
            prize:["八百万神的代言人","博丽神社的巫女小姐","飞翔于天空的不可思议的巫女","快晴的巫女","乐园的可爱巫女","乐园的巫女","神秘！结界的巫女","五欲的巫女","永远之巫女","追逐怪奇！终结异变的巫女"] # 称号
        some_other_character:
            avatar:["http://img.example.com/some_other_character_1.jpg","http://img.example.com/some_other_character_2.jpg"]
            name:"大鲶鱼"
            prize:"" # 称号是允许留空的
    # to let players know woh they are
    skin_tip:"你的身份"
    lockable:false
    isAvailable:->
        # if want to be a time limited theme
        # return false
        return true
