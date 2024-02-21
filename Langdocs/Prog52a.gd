extends Control

func _on_btn_calc_pressed():
	var length = int($txtLen.text)
	var width = int($txtWid.text)
	var area = length * width
	var perim = 2 * length + 2 * width
	$lblArea.text = "Area: " + str(area)
	$lblPerim.text = "Perimeter: " + str(perim)
	# + - * /       ** pow
	# str: string (text)
	# int: integer (whole number)
	# float: floating-point (num w/ decimal)

func _on_btn_clear_pressed():
	$txtLen.text = ""
	$txtWid.text = ""
	$lblArea.text = ""
	$lblPerim.text = ""

func _on_btn_exit_pressed():
	get_tree().quit()
