extends Control


func _on_btn_calc_pressed():
	$ItemList.add_item("Number     Square     Square Root")
	for num in range(1, 51):
		var numsquared = num**2  # pow(num, 2)
		var numsqrt = sqrt(num)
		# var line = str(num) + "     " + str(numsquared) + "     " + str(numsqrt)
		var line = "%d     %d     %.4f" % [num, numsquared, numsqrt]
		$ItemList.add_item(line)


func _on_btn_clear_pressed():
	$ItemList.clear()


func _on_btn_exit_pressed():
	pass # Replace with function body.
