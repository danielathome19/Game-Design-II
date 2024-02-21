extends Control

func _on_btn_calc_pressed():
	var speedLimit = int($txtLimit.text)
	var carSpeed = int($txtSpeed.text)
	var milesOver = carSpeed - speedLimit
	var fine = 20.0 + (milesOver * 5.0)
	$lblOut.text = "Fine: $ %.2f" % fine

func _on_btn_clear_pressed():
	$txtLimit.text = ""
	$txtSpeed.text = ""
	$lblOut.text = ""

func _on_btn_exit_pressed():
	get_tree().quit()
