module.exports=
    name:"東方Project"
    opening:""
    vote:""
    sunrise:""
    sunset:""
    icon:""
    background_color:"black"
    color:"rgb(255,0,166)"
    skins:
        # 羅馬字名 ，只允許半形英數字和下劃線，數字和下劃線不允許是首位
        # 不可以重複
        some_character: 
            # 頭像URL 和 稱號 可以是字符串數組，也可以是字符串
            # 頭像在顯示的時候 會壓縮為48*48，所以最好縱橫比是1:1
            avatar:"http://img.example.com/some_character.jpg" # 頭像URL
            name:"博麗靈夢" # 名字，必填
            prize:["八百萬神的代言人","博麗神社的巫女小姐","飛翔於天空的不可思議的巫女","快晴的巫女","樂園的可愛巫女","樂園的巫女","神秘！結界的巫女","五欲的巫女","永遠之巫女","追逐怪奇！終結異變的巫女"] # 稱號
        some_other_character:
            avatar:["http://img.example.com/some_other_character_1.jpg","http://img.example.com/some_other_character_2.jpg"]
            name:"大鯰魚"
            prize:"" # 稱號是允許留空的
    # to let players know woh they are
    skin_tip:"你的身份"
    lockable:false
    isAvailable:->
        # if want to be a time limited theme
        # return false
        return true
