extends Control

func _on_btn_calc_pressed():
	var num1 = int($LineEdit.text)
	var num2 = int($LineEdit2.text)
	var Sum = num1 + num2
	var Diff = num1 - num2
	# TODO: product and average by yourself
	var Abs = abs(Diff)
	var Max = 0
	var Min = 0
	if num1 > num2:
		Max = num1
		# Min = num2
	else:  # Otherwise...
		Max = num2
		
	if Max == num1:  # == checks if same value
		Min = num2
	else:
		Min = num1
		
	$Label.text = "Sum: " + str(Sum) + \
				  "\nDifference: " + str(Diff) + \
				  
				  "\nAbs. Distance: " + str(Abs) + \
				  "\nMax: " + str(Max) + \
				  "\nMin: " + str(Min)

func _on_btn_clear_pressed():
	pass # Replace with function body.


func _on_btn_exit_pressed():
	pass # Replace with function body.
