class_name Audio
extends AudioStreamPlayer

const AUDIO_NAME: Array[String] = [
    "move_card",
    "move_to_stock",
]

var _resources: Dictionary


func init() -> void:
    for i in AUDIO_NAME.size():
        _resources[AUDIO_NAME[i]] = (ResourceLoader.load("res://audio/%s.mp3" % AUDIO_NAME[i]) as AudioStream)


func move_one_step(card_move_step: Define.CardMoveStep) -> void:
    match card_move_step:
        Define.CardMoveStep.WASTE_TO_STOCK:
            stream = _resources["move_to_stock"]
            play()

        Define.CardMoveStep.STOCK_TO_WASTE,\
        Define.CardMoveStep.WASTE_TO_PILE,\
        Define.CardMoveStep.WASTE_TO_FOUNDATION,\
        Define.CardMoveStep.PILE_TO_PILE,\
        Define.CardMoveStep.PILE_TO_FOUNDATION,\
        Define.CardMoveStep.FOUNDATION_TO_PILE:
            stream = _resources["move_card"]
            play()

        Define.CardMoveStep.FACEUP_PILE:
            pass
    

func deal_cards() -> void:
    stream = _resources["move_to_stock"]
    play()
