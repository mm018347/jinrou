# 肩書きで、称号をつなげる接続語

exports.conjunctions=["1","2","3","4","5","6","7","8","9","0","１","２","３","４","５","６","７","８","９","０","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","ぁ","あ","ぃ","い","ぅ","う","ぇ","え","ぉ","お","か","が","き","ぎ","く","ぐ","け","げ","こ","ご","さ","ざ","し","じ","す","ず","せ","ぜ","そ","ぞ","た","だ","ち","ぢ","っ","つ","づ","て","で","と","ど","な","に","ぬ","ね","の","は","ば","ぱ","ひ","び","ぴ","ふ","ぶ","ぷ","へ","べ","ぺ","ほ","ぼ","ぽ","ま","み","む","め","も","ゃ","や","ゅ","ゆ","ょ","よ","ら","り","る","れ","ろ","ゎ","わ","ゐ","ゑ","を","ん","゜","゛","ゝ","ゞ","ァ","ア","ィ","イ","ゥ","ウ","ェ","エ","ォ","オ","カ","ガ","キ","ギ","ク","グ","ケ","ゲ","コ","ゴ","サ","ザ","シ","ジ","ス","ズ","セ","ゼ","ソ","ゾ","タ","ダ","チ","ヂ","ッ","ツ","ヅ","テ","デ","ト","ド","ナ","ニ","ヌ","ネ","ノ","ハ","バ","パ","ヒ","ビ","ピ","フ","ブ","プ","ヘ","ベ","ペ","ホ","ボ","ポ","マ","ミ","ム","メ","モ","ャ","ヤ","ュ","ユ","ョ","ヨ","ラ","リ","ル","レ","ロ","ヮ","ワ","ヰ","ヱ","ヲ","ン","ヴ","ヵ","ヶ","・","ー","ヽ","ヾ","､","･","ｦ","ｧ","ｨ","ｩ","ｪ","ｫ","ｬ","ｭ","ｮ","ｯ","ｰ","ｱ","ｲ","ｳ","ｴ","ｵ","ｶ","ｷ","ｸ","ｹ","ｺ","ｻ","ｼ","ｽ","ｾ","ｿ","ﾀ","ﾁ","ﾂ","ﾃ","ﾄ","ﾅ","ﾆ","ﾇ","ﾈ","ﾉ","ﾊ","ﾋ","ﾌ","ﾍ","ﾎ","ﾏ","ﾐ","ﾑ","ﾒ","ﾓ","ﾔ","ﾕ","ﾖ","ﾗ","ﾘ","ﾙ","ﾚ","ﾛ","ﾜ","ﾝ","ﾞ","ﾟ","風","超","呢","般","都","哇","變","桶","而","至","從","和","但","使","該","這","乳","與","願","能","長","今","朝","久","最","下","貧","狼","絕","對","了","不","想","來","用","回","出","初","較","叫","世","代","有","沒","阿","吧","在","大","之","中","們","小","到","巨","向","王","嗎","者","被","男","女","唷","曾","你","我","他","她","就","那","呀","的","得","是","如","把","又","要","可","將","啊","逼","長","短","寬","高","矮","攻","受","象","像","向","心","連","常","捲","直","尖","現","噁","上","方","打","好","做","坐","騎","當","☆","★","♡","♥","・","×","✝","─","…","！","？","喜歡","討厭","迴避","防禦","逃跑","絕對","衝擊","挫折","難道","都不","不過","接著","就被","因為","這是","其實","所以","但是","好有","可是","竟然","然而","沒有","成為","不要","專精","路過","撒嬌","原來","THE","OF","AND","NOT","ANY","NEVER"]
exports.prizes_composition=["prize","conjunction","prize"]

# 称号の数で
exports.getPrizesComposition=(number)->
    result=[]
    if number<15
        return ["prize","conjunction","prize"]
    else if number<25
        return ["prize","conjunction","prize","conjunction"]
    else if number<35
        return ["prize","conjunction","prize","conjunction","prize","conjunction"]
    else if number<80
        return ["conjunction","prize","conjunction","prize","conjunction","prize","conjunction"]
    else if number<110
        return ["prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction"]
    else if number<150
        return ["conjunction","prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction"]
    else if number<190
        return ["prize","conjunction","prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction"]
    else if number<260
        return ["prize","conjunction","prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction","conjunction","prize"]
    else if number<350
        return ["prize","prize","conjunction","prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction","conjunction","prize","prize"]
    else
        return ["prize","prize","conjunction","conjunction","prize","prize","conjunction","conjunction","prize","conjunction","conjunction","prize","prize","conjunction","conjunction","prize","prize","conjunction","conjunction","prize","prize"]
    
    result