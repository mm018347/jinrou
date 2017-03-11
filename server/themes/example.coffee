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
        some_character:
            avatar:"http://img.example.com/some_character.jpg"
            name:"Name"
            prize:["A Fighter","Cage Killer"]
        some_other_character:
            avatar:"http://img.example.com/some_other_character.jpg"
            name:"Name"
            prize:[""]
    # ↓ important！！ how many skins above
    skin_length:2
    # to let players know woh they are
    skin_tip:"Identity"
    lockable:false
    isAvailable:->
        # if want to be a time limited theme
        # return false
        return true