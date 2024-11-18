class_name Define
extends RefCounted

# カードの絵柄
enum Suit {
    HEART,
    DIAMOND,
    CLUB,
    SPADE,
    NUM,
}

# カードの数字
enum Number {
    A,
    _2,
    _3,
    _4,
    _5,
    _6,
    _7,
    _8,
    _9,
    _10,
    J,
    Q,
    K,
    NUM,
}

# 札の種類
enum CardType {
    STOCK,      # 山札
    WASTE,      # 山札からめくった札
    PILE,       # 場札
    FOUNDATION  # 組札
}

# 難易度
enum Difficulty {
    EASY,
    HARD,
}

# 操作の種類
enum CardMoveStep {
    STOCK_TO_WASTE,         # カード移動（山札 -> 山札からめくった札）
    WASTE_TO_STOCK,         # カード移動（山札からめくった札 -> 山札）
    WASTE_TO_PILE,          # カード移動（山札からめくった札 -> 場札）
    WASTE_TO_FOUNDATION,    # カード移動（山札からめくった札 -> 組札）
    PILE_TO_PILE,           # カード移動（場札 -> 場札）
    PILE_TO_FOUNDATION,     # カード移動（場札 -> 組札）
    FOUNDATION_TO_PILE,     # カード移動（組札 -> 場札）
    FACEUP_PILE             # 場札をめくる
}

# カードのテクスチャ領域
const CARD_TEXTURE_REGION: Dictionary = {
    Define.Suit.HEART: {
        Define.Number.A: Rect2(76, 156, 38, 52),
        Define.Number._2: Rect2(114, 156, 38, 52),
        Define.Number._3: Rect2(152, 156, 38, 52),
        Define.Number._4: Rect2(190, 156, 38, 52),
        Define.Number._5: Rect2(228, 156, 38, 52),
        Define.Number._6: Rect2(266, 156, 38, 52),
        Define.Number._7: Rect2(0, 208, 38, 52),
        Define.Number._8: Rect2(38, 208, 38, 52),
        Define.Number._9: Rect2(76, 208, 38, 52),
        Define.Number._10: Rect2(114, 208, 38, 52),
        Define.Number.J: Rect2(152, 208, 38, 52),
        Define.Number.Q: Rect2(190, 208, 38, 52),
        Define.Number.K: Rect2(228, 208, 38, 52),
    },
    Define.Suit.DIAMOND: {
        Define.Number.A: Rect2(266, 208, 38, 52),
        Define.Number._2: Rect2(0, 260, 38, 52),
        Define.Number._3: Rect2(38, 260, 38, 52),
        Define.Number._4: Rect2(76, 260, 38, 52),
        Define.Number._5: Rect2(114, 260, 38, 52),
        Define.Number._6: Rect2(152, 260, 38, 52),
        Define.Number._7: Rect2(190, 260, 38, 52),
        Define.Number._8: Rect2(228, 260, 38, 52),
        Define.Number._9: Rect2(266, 260, 38, 52),
        Define.Number._10: Rect2(0, 312, 38, 52),
        Define.Number.J: Rect2(38, 312, 38, 52),
        Define.Number.Q: Rect2(76, 312, 38, 52),
        Define.Number.K: Rect2(114, 312, 38, 52),
    },
    Define.Suit.CLUB: {
        Define.Number.A: Rect2(190, 52, 38, 52),
        Define.Number._2: Rect2(228, 52, 38, 52),
        Define.Number._3: Rect2(266, 52, 38, 52),
        Define.Number._4: Rect2(0, 104, 38, 52),
        Define.Number._5: Rect2(38, 104, 38, 52),
        Define.Number._6: Rect2(76, 104, 38, 52),
        Define.Number._7: Rect2(114, 104, 38, 52),
        Define.Number._8: Rect2(152, 104, 38, 52),
        Define.Number._9: Rect2(190, 104, 38, 52),
        Define.Number._10: Rect2(228, 104, 38, 52),
        Define.Number.J: Rect2(266, 104, 38, 52),
        Define.Number.Q: Rect2(0, 156, 38, 52),
        Define.Number.K: Rect2(38, 156, 38, 52),
    },
    Define.Suit.SPADE: {
        Define.Number.A: Rect2(0, 0, 38, 52),
        Define.Number._2: Rect2(38, 0, 38, 52),
        Define.Number._3: Rect2(76, 0, 38, 52),
        Define.Number._4: Rect2(114, 0, 38, 52),
        Define.Number._5: Rect2(152, 0, 38, 52),
        Define.Number._6: Rect2(190, 0, 38, 52),
        Define.Number._7: Rect2(228, 0, 38, 52),
        Define.Number._8: Rect2(266, 0, 38, 52),
        Define.Number._9: Rect2(0, 52, 38, 52),
        Define.Number._10: Rect2(38, 52, 38, 52),
        Define.Number.J: Rect2(76, 52, 38, 52),
        Define.Number.Q: Rect2(114, 52, 38, 52),
        Define.Number.K: Rect2(152, 52, 38, 52),
    },
}
const CARD_TEXTURE_REGION_FACEDOWN := Rect2(152, 312, 38, 52)
const CARD_TEXTURE_REGION_PLACEHOLDER: Dictionary = {
    Define.Suit.HEART: Rect2(266, 312, 38, 52),
    Define.Suit.DIAMOND: Rect2(0, 364, 38, 52),
    Define.Suit.CLUB: Rect2(228, 312, 38, 52),
    Define.Suit.SPADE: Rect2(190, 312, 38, 52),
}
const CARD_TEXTURE_REGION_PLACEHOLDER_STOCK := Rect2(38, 364, 38, 52)

# カードの座標
class CardCoordinates:
    var stock: Vector2
    var waste: Vector2
    var piles: Array[Vector2]
    var foundations: Array[Vector2]

# カードドラッグ時のドロップ可能領域
class CardDropRect:
    var piles: Array[Rect2]
    var foundations: Array[Rect2]
