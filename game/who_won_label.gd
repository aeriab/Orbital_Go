extends Label

func make_winner_text():
	if Global.draw_occurred:
		text = "Draw"
	else:
		if Global.p1_won:
			if (Global.p1_total_score - Global.p2_total_score) == 1:
				text = "Black won by " + str(Global.p1_total_score - Global.p2_total_score) + " point."
			else:
				text = "Black won by " + str(Global.p1_total_score - Global.p2_total_score) + " points."
		else:
			if (Global.p2_total_score - Global.p1_total_score) == 1:
				text = "White won by " + str(Global.p2_total_score - Global.p1_total_score) + " point."
			else:
				text = "White won by " + str(Global.p2_total_score - Global.p1_total_score) + " points."
