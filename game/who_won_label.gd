extends Label

func make_winner_text():
	if Global.p1_won:
		text = "[Player_1] won by " + str(Global.p1_score - Global.p2_score) + " points."
	else:
		text = "[Player_2] won by " + str(Global.p2_score - Global.p1_score) + " points."
