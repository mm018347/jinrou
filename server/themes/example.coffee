module.exports=
    name:"some example"
    opening:""
    vote:""
    sunrise:""
    sunset:""
    icon:""
    background_color:"black"
    color:"rgb(255,0,166)"
    skins:
        some_character: # 罗马字名 ，只允许半角英数字和下划线，数字和下划线不允许是首位
            avatar:"http://img.example.com/some_character.jpg" # 头像链接，头像链接 和 称号 可以是字符串数组，也可以是字符串
            name:"Name" # 名称
            prize:["A Fighter","Cage Killer"] # 称号
        some_other_character:
            avatar:["http://img.example.com/some_other_character_1.jpg","http://img.example.com/some_other_character_2.jpg"]
            name:"Name"
            prize:"" # 称号是允许留空的
    # ↓ important！！ how many skins above
    skin_length:2
    # to let players know woh they are
    skin_tip:"Identity"
    lockable:false
    isAvailable:->
        # if want to be a time limited theme
        # return false
        return true