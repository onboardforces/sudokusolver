# Program written by: William Stawicki
# Project 3 (v10) Sudoku
#
# This program solves a 9 by 9 Sudoku puzzle using a recursive algorithm. 
# The program allows taking an input board from the user, displaying a 2-D board, 
# solving a 9 by 9 board with any amount of empty cells, and finding multiple solutions if possible.
#
# History:
# v01: got the menu to work, added function to input board, added checking for input board 1-9 and e, added a row check algorithm and tested
# v02: added print function
# v03: added and checked column checking
# v04: added and checked box checking
# v05: cleaned up error reporting
# v06: working on solving technique
# v07: fixing error with solver (fixed by incrementing loopSolve to 10 and not 9)
# v08: wrap up
# v09: clean up for turning in
# v10: moved to git

.data 

choice: .byte 0 		# input integer, for storing the user's selection
selectionPrompt: .asciiz "\n\nChoices: \n    1: Set Sudoku board \n    2: Print Board \n    3: Check validity \n    4: Solve\n    5: Load Default \n    0: Quit \nPlease input your choice: "	# selection prompt text
inputPromptBoard: .asciiz "\nPlease input your Sudoku board (e is for empty): " 	# prompt for input sudoku board
inputBoard: .asciiz "\nHere is the input string: \n"
defaultSet: .asciiz "\nBoard set to the following default string: \n"
setErrorText: .asciiz "\nYour input board was not a valid string."
boardValidNot: "\nThe Sudoku board is not valid."
boardValid: "\nThe Sudoku board is valid."
boardSolutionNo: "\nNo solution was found."
boardSolution: "\nA solution was found: "
boardNewAttempt: "\nWould you like to attempt another solution? (y or n):"
boardSolutionNoE: "\nThere are no empty, 'e', spaces to solve for. The board is valid and solved already. Try inputing a new board."

checkNoErrorR: "\n No duplicates in rows."
checkNoErrorC: "\n No duplicates in columns."
checkNoErrorB: "\n No duplicates in boxes."
checkError: "\n Duplicate of " 
checkErrorR: " found in row: "
checkErrorC: " found in column: "
checkErrorB: " found in box: "

board: .space 82

defaultBoard: .asciiz "3e7e6428146812357991258746363179584272431869589524613717645932858367291424983175e"

#Temporary storage for data:

columns: .space 82
boxes: .space 82
tempNine: .word 0,0,0,0,0,0,0,0,0 # temp array of 9 numbers

newLine: .asciiz "\n" # store a new line character
errorOverflow: .asciiz "\nError: " # error overflow detected


.text

Start:
#Display the option menu
	
#Prompt user for selection
	la $a0, selectionPrompt 	# load selection Prompt into $a0
	li $v0, 4			# print the string to the screen, using system call #4
	syscall

#Get integer, store, and branch
	li $v0, 12			# using system call #12: read character
	syscall
	sb $v0, choice 			# store user's choice from $v0 to choice
	lb $t0, choice			# load the choice into a register
	
	ble $t0, 0x29, Start		# branch to the start if choice is 0 or less than
	beq $t0, 0x30, Exit		# branch to the exit if choice is 0
	bgt $t0, 0x35, Start		# branch to the start if choice is greater than 5
	
	beq $t0, 0x31, Set		# branch to Stored if choice is 1
	beq $t0, 0x32, callPrint	# branch to Seed if choice is 2
	beq $t0, 0x33, Check		# branch to Seed if choice is 3
	beq $t0, 0x34, Solve		# branch to Seed if choice is 4
	beq $t0, 0x35, LoadDefault	# branch to Seed if choice is 5
	
	j Start
	
	callPrint:
	jal Print
	j Start
Set:
#Set the board using input from the user. Check the user's input and repeat until a valid board is input.

# $a0	board
# $v0	syscalls
# $t1	character, counter
# $t2	temp variable for comparing
	
	#set string space to blank
	#loop
	li $t1, 0	# count variable
	li $t2, 0x23	# temp character variable
	loopBlank:
		# set character to 00 
		sb $t2, board($t1)		#set current byte of character string
		addi $t1, $t1, 1		#increment counter
		blt $t1, 81, loopBlank		# escape if loop reaches 81
	
	la $a0, newLine 		# print newLine
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
		
	#la $a0, board 			# test
	#li $v0, 4			# print the string to the screen, using system call #4
	#syscall
		
	#input prompt:
	la $a0, inputPromptBoard 	# load selection Prompt into $a0
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	#read in a string:
	la $a0, board			# set the address of the input buffer
	li $a1, 82			# set the maximum amount of characters to input to 81 
	li $v0, 8			# read in a string using system call 8
	syscall				# return value is stored into $a0		
	
	la $a0, newLine 		# print newLine
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	la $a0, inputBoard 		# print newLine
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	la $a0, board 			# print board
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	#check the string for consistancy:

	#loop
	li $t1, 0
	lb $t2, board
	loopSet:
		# check if the character is e or 0-9 character 
		
		beq  $t2, 0x65, incSet 	  	# continue loop if equal to 'e'
		blt  $t2, 0x31, setError  	# escape if less than 1
		bgt  $t2, 0x39, setError  	# escape if greather than 9
		
		
		incSet:
		addi $t1, $t1, 1
		beq $t1, 81, Start	# escape if loop reaches 81
		lb $t2, board($t1)	# load next byte if continuing
		j loopSet		# repeat loop
		
	#repeat until a good string is found
	j Start
	
	setError:
	#print error message
	la $a0, setErrorText	 	# load selection Prompt into $a0
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	j Set

Print:
#Print out the board in 2-D

# $t1	outer loop counter
# $t2	inner loop counter
# $t3	combined number storage/

	#print out the sudoku board
	la $a0, newLine 		# print newLine
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	la $a0, newLine 		# print newLine
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	li $t1, 0	# outer loop counter (Rows)
	li $t2, 0	# inner loop counter (Columns)
	li $t3, 0	# combined number of r an c storage
	li $t4, 0	# character storage
	
	loopPout:
		
		loopPin:
		# convert current row and column into combined number (R*9) + C = #
		mul $t3, $t1, 9			# R*9
		add $t3, $t3, $t2		# (R*9) + C = #
		
		li $a0, ' ' 			# print character
		li $v0, 11			# print the character to the screen, using system call #11
		syscall
										
		lb $a0, board($t3)		# get the current character byte from the board
		li $v0, 11			#  print the character to the screen, using system call #11
		syscall
		
		li $a0, ' ' 			# print character
		li $v0, 11			# print the character to the screen, using system call #11
		syscall
		
		beq $t2, 2 printDash		# jump if the current column count indicates a '|' needs to be printed
		beq $t2, 5 printDash		# jump if the current column count indicates a '|' needs to be printed
		j incPin
		
		printDash:
		
		li $a0, '|' 			# print character
		li $v0, 11			# print the character to the screen, using system call #11
		syscall
		
		incPin:				# increment the inner loop counter (columns)
		addi $t2, $t2, 1
		blt $t2, 9, loopPin
		
		li $a0, '\n' 			# print newLine
		li $v0, 11			# print the character to the screen, using system call #11
		syscall
		
		li $t2, 0
		
	incPout:
		
	beq $t1, 2 printLine
	beq $t1, 5 printLine
	j incPcontinue
	
	printLine:	
	
	li $t4, 0
	li $a0, '-' 			# print '-'
	loopPL: 
		li $v0, 11		# print the character to the screen, using system call #11
		syscall
		
		addi $t4, $t4, 1
		ble $t4, 27, loopPL
		
	li $a0, '\n' 			# print newLine
	li $v0, 11			# print the character to the screen, using system call #11
	syscall
			
	incPcontinue:
	addi $t1, $t1, 1
	blt $t1, 9, loopPout
	jr $ra


Check:
#Check the board for validity.

# t1	temp value for storing errors (backup for procedure calls)
        
        li $a0, '\n' 			# print newLine
	li $v0, 11			# print the character to the screen, using system call #11
	syscall
        
        li $t1, 0	#set error counter to zero
        
         sub $sp, $sp, 4
         sw $t1, 0($sp)   
	jal checkBoardR # call the checkBoard function to check rows
         lw $t1, 0($sp)
         add $sp, $sp, 4
        
        add $t1, $t1, $s0	#add returned error to running total
        
	#Did an error occur?
	beq $s0, 0, errorR
	
	# Yes, print error. No, then state no error.
	la $a0, checkError 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	move $a0, $s1
	li $v0, 11	# print the integer to the screen, using system call #1
	syscall
	
	la $a0, checkErrorR 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	move $a0, $s3
	li $v0, 11	# print the character to the screen, using system call #11
	syscall
	
	j checkC
	
	errorR:
	la $a0, checkNoErrorR 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	checkC:

	 sub $sp, $sp, 4
         sw $t1, 0($sp) 
	jal checkBoardC # call the checkBoard function to check columns
	 lw $t1, 0($sp)
         add $sp, $sp, 4
         
        add $t1, $t1, $s0	#add returned error to running total

	#Did an error occur?
	beq $s0, 0, noErrorC
	# Yes, print error. No, then state no error.
	la $a0, checkError 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	move $a0, $s1
	li $v0, 11	# print the integer to the screen, using system call #1
	syscall
	
	la $a0, checkErrorC 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	move $a0, $s3
	li $v0, 11	# print the character to the screen, using system call #11
	syscall
	
	j checkB
	
	noErrorC:
	la $a0, checkNoErrorC 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	checkB:
	 sub $sp, $sp, 4
         sw $t1, 0($sp) 
	jal checkBoardB # call the checkBoard function to check boxes
         lw $t1, 0($sp)
         add $sp, $sp, 4
         
        add $t1, $t1, $s0	#add returned error to running total
         
	#Did an error occur?
	beq $s0, 0, noErrorB
	# Yes, print error. No, then state no error.
	la $a0, checkError 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	move $a0, $s1
	li $v0, 11	# print the integer to the screen, using system call #1
	syscall
	
	la $a0, checkErrorB 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	move $a0, $s3
	li $v0, 11	# print the character to the screen, using system call #11
	syscall
	
	j checkOut
	
	noErrorB:
	la $a0, checkNoErrorB 		# print checkNoErrorR
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	checkOut:
	
	li $a0, '\n' 			# print newLine
	li $v0, 11			# print the character to the screen, using system call #11
	syscall
	
	beq $t1, 0, stackValid
	#stack not valid
	la $a0, boardValidNot 		# print boardValidNot
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	j Start
	
	stackValid:
	la $a0, boardValid 		# print boardValid
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
j Start

checkBoardR:
#check the validity of the board rows

# $t1	outer loop counter
# $t2	inner loop counter
# $t3	combined number storage/
# $t4	character storage/
# $t5	character address storage for tempNine array/
# $t6   byte counter for accessing tempNine
# $s0 	return error found 0 no 1 yes
# $s1   return (row box or column) number (1-9)
# $s2   return r row, c column, b box
# $s3   return error generating number ascii character

	li $t1, 0	# outer loop counter (Rows)
	li $t2, 0	# inner loop counter (Columns)
	li $t3, 0	# combined number of r an c storage
	li $t4, 0	# character storage

	loopRout:
	
		#initialize tempNine counts all to zero
		li $t6, 0
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
	
	
		loopRin:
			# convert current row and column into combined number (R*9) + C = #
			mul $t3, $t1, 9			# R*9
			add $t3, $t3, $t2		# (R*9) + C = #
						
			lb $t4, board($t3)		# get the current character byte from the board
			beq $t4, 0x65, incRin 	  	# continue loop if equal to 'e'			
			#if the current cell is equal to a given character, increment that character's cell in temp array
			subi $t4, $t4, 0x31		# basically convert the ascii to int and offset by -1
			mul $t6, $t4, 4			# multiply the int by 4 bytes to find location in tempNine array
			lw $t5, tempNine($t6)		# get number from tempNine array and increment by 1
			addi $t5, $t5, 1		# increment the temp value from tempNine
			#check to see if each cell in temp array is one or less
			bgt $t5, 1, checkErrorFoundRow
			#if there is an error, break and issue an error
			sw $t5, tempNine($t6)		# store the updated number back into tempNine
		 
			incRin:
			addi $t2, $t2, 1
			blt $t2, 9, loopRin
			li $t2, 0
		
		incRout:
		addi $t1, $t1, 1
		blt $t1, 9, loopRout
		# No error must have been found 
		# set any return variables
		li $s0, 0	# set return value of no error found
		li $s1, 'n'	# set return value of no error found
		li $s2, 'r'	# set return value of no error found
		jr $ra
		
	checkErrorFoundRow:
	li $s0, 1
	addi $t1, $t1, 0x31  	# convert row to ascii number
	move $s1, $t1		# store the return ascii character (0-9) in return value
	li $s2, 'r' 		# set return error type (row, coulum, box)
	addi $t6, $t6, 0x31  	# convert error generating character to ascii number
	move $s3, $t6		# store the return ascii character (0-9) in return value
	jr $ra

checkBoardC:
#check the validity of the board columns

# $t1	outer loop counter
# $t2	inner loop counter
# $t3	combined number storage/
# $t4	character storage/
# $t5	character address storage for tempNine array/
# $t6   byte counter for accessing tempNine
# $s0 	return error found 0 no 1 yes
# $s1   return (row box or column) number (1-9)
# $s2   return 0 row, 1 column, 2 box
# $s3   return error generating number ascii character

	li $t1, 0	# outer loop counter (Columns)
	li $t2, 0	# inner loop counter (Rows)
	li $t3, 0	# combined number of r an c storage
	li $t4, 0	# character storage
	
	loopCout:
		#initialize tempNine counts all to zero
		li $t6, 0
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
	
	
		loopCin:
			# convert current row and column into combined number (R*9) + C = #
			mul $t3, $t2, 9			# R*9
			add $t3, $t3, $t1		# (R*9) + C = #
						
			lb $t4, board($t3)		# get the current character byte from the board
			beq $t4, 0x65, incCin 	  	# continue loop if equal to 'e'			
			#if the current cell is equal to a given character, increment that character's cell in temp array
			subi $t4, $t4, 0x31		# basically convert the ascii to int and offset by -1
			mul $t6, $t4, 4			# multiply the int by 4 bytes to find location in tempNine array
			lw $t5, tempNine($t6)		# get number from tempNine array and increment by 1
			addi $t5, $t5, 1		# increment the temp value from tempNine
			#check to see if each cell in temp array is one or less
			bgt $t5, 1, checkErrorFoundColumn
			#if there is an error, break and issue an error
			sw $t5, tempNine($t6)		# store the updated number back into tempNine
		 
			incCin:
			addi $t2, $t2, 1
			blt $t2, 9, loopCin
			li $t2, 0
		
		incCout:
		addi $t1, $t1, 1
		blt $t1, 9, loopCout
		# No error must have been found 
		# set any return variables
		li $s0, 0	# set return value of no error found
		li $s1, 'n'	# set return value of no error found
		li $s2, 'c'	# set return value of no error found
		jr $ra
		
	checkErrorFoundColumn:
	li $s0, 1		# note that an error was found
	addi $t1, $t1, 0x31  	# convert column to ascii number
	move $s1, $t1		# store the return ascii character (0-9) in return value
	li $s2, 'c' 		# set return error type (row, coulum, box)
	addi $t6, $t6, 0x31  	# convert error generating character to ascii number
	move $s3, $t6		# store the return ascii character (0-9) in return value
	jr $ra

checkBoardB:
#check the validity of the board boxes

# $t0	most outer loop counter
# $t1	outer loop counter
# $t2	inner loop counter
# $t3	combined number storage/
# $t4	character storage/
# $t5	character address storage for tempNine array/
# $t6   byte counter for accessing tempNine
# $t7   box counter
# $s0 	return error found 0 no 1 yes
# $s1   return (row box or column) number (1-9)
# $s2   return 0 row, 1 column, 2 box
# $s3   return error generating number ascii character
	
	li $t0, 0 	# most outer loop counter (Boxes)
	li $t1, 0	# outer loop counter (Rows)
	li $t2, 0	# inner loop counter (Columns)
	li $t3, 0	# combined number of r an c storage
	li $t4, 0	# character storage
	li $t7, 1	# set the box counter
	loopBmost:
		
		#initialize tempNine counts all to zero
		li $t6, 0
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		addi $t6, $t6, 4
		sw $zero, tempNine($t6)
		
		loopBout:
	
			loopBin:
				# convert current row and column into combined number (R*9) + C = #
				
				mul $t3, $t1, 9			# R*9
				add $t3, $t3, $t2		# (R*9) + C = #
				add $t3, $t3, $t0		# add calculated offset from start cell (0,0)
								
				lb $t4, board($t3)		# get the current character byte from the board
				beq $t4, 0x65, incBin 	  	# continue loop if equal to 'e'		
				#if the current cell is equal to a given character, increment that character's cell in temp array
				subi $t4, $t4, 0x31		# basically convert the ascii to int and offset by -1
				mul $t6, $t4, 4			# multiply the int by 4 bytes to find location in tempNine array
				lw $t5, tempNine($t6)		# get number from tempNine array and increment by 1
				addi $t5, $t5, 1		# increment the temp value from tempNine
				#check to see if each cell in temp array is one or less
				bgt $t5, 1, checkErrorFoundBox
				#if there is an error, break and issue an error
				sw $t5, tempNine($t6)		# store the updated number back into tempNine
		 
				incBin:
				addi $t2, $t2, 1
				blt $t2, 3, loopBin
				li $t2, 0
		
			incBout:
			addi $t1, $t1, 1
			blt $t1, 3, loopBout
			li $t1, 0
			addi $t7, $t7, 1	#increment the box counter 
		
		incBmost:
		# increment the placeholder to next upperleft corner of the next box.
		addi $t0, $t0, 3
		beq $t0, 3 loopBmost
		beq $t0, 6 loopBmost
		beq $t0, 27 loopBmost
		beq $t0, 30 loopBmost
		beq $t0, 33 loopBmost
		beq $t0, 54 loopBmost
		beq $t0, 57 loopBmost
		beq $t0, 60 loopBmost
		blt $t0, 61 incBmost
		
		# No error must have been found 
		# set any return variables
		li $s0, 0	# set return value of no error found
		li $s1, 'n'	# set return value of no error found
		li $s2, 'b'	# set return value of no error found
		jr $ra
		

	checkErrorFoundBox:
	li $s0, 1
	addi $s1, $t7, 0x30  	# convert row to ascii number
	li $s2, 'b' 		# set return error type (row, coulum, box)
	addi $t6, $t6, 0x31  	# convert error generating character to ascii number
	move $s3, $t6		# store the return ascii character (0-9) in return value
	jr $ra

Solve:
# initiate the solve routine

# t1 cell number to be passed


	jal checkBoardR 		# call the checkBoard function to check rows
	bgt $s0, 0, boardValidNotJ	# check to see if the board is valid
	jal checkBoardC 		# call the checkBoard function to check columns
	bgt $s0, 0, boardValidNotJ	# check to see if the board is valid
	jal checkBoardB 		# call the checkBoard function to check boxes
	bgt $s0, 0, boardValidNotJ	# check to see if the board is valid
	
	# board must be valid at this point and can start to solve:
	
	li $t1, 0				# initialize count
	li $t3, 'e'				# store ascii for 'e'
	loopE:
		lb $t2, board($t1)		# get the current byte to check from the board
		beq $t2, $t3, continueSolve 	# check to see if there are an 'e's to solve for:
		addi $t1, $t1, 1		# increment counter
		blt $t1, 81, loopE		# keep looping until the end of the string
		
		la $a0, boardSolutionNoE
		li $v0, 4			# print the string to the screen, using system call #4
		syscall
		
		j Start
	continueSolve:
	# prime and start solving
	li $t1, 0	# set the first cell number
	jal SolveNext	# start solving
	
	la $a0, boardSolutionNo		# print boardSolutionNo
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	j Start
	
	boardValidNotJ:
		la $a0, boardValidNot 		# print boardValidNot
		li $v0, 4			# print the string to the screen, using system call #4
		syscall
		j Start

LoadDefault:
#load the default array into board
# t1	counter
# t2	temp variable

	li $t1, 0				#initialize counter
	li $t2, 0
	loopDefault:
		lb $t2, defaultBoard($t1)	# get the byte from the default board
		sb $t2, board($t1)		# store the byte fromt the default board into board
		addi $t1, $t1, 1		# increment counter	
		blt $t1, 81, loopDefault	# check to make sure the counter is less than 81
	
	li $a0, '\n'	 			# print newLine
	li $v0, 11				# print the string to the screen, using system call #4
	syscall
	
	la $a0, defaultSet 		# print defaultSet
	li $v0, 4			# print the string to the screen, using system call #4
	syscall
	
	la $a0, board 			# print board
	li $v0, 4			# print the string to the screen, using system call #4
	syscall

	j Start			
	
Error:
		la $a0, errorOverflow		# load input into $a0
		li $v0, 4			# print the string to the screen, using system call #4
		syscall

SolveNext:
# $t1	input:number of array
# $t2	number to check (for solving)  

	#check if character in array is e ?
	lb $t2, board($t1)			# get character from board array
	beq $t2, 0x65, solveCell		# check to see if the character is equal to 'e'
	
	#character is not equal to 'e', thus it must be  1-9 and not need to solve, jump to next position 
	addi $t1, $t1,1				# increment board array position by 1
	bgt $t1, 81, solveSolutionFound		# check to see if the end was reached, if so then a solution was found
									
	 sub $sp, $sp, 4			# backup pointer
         sw $ra, 0($sp) 
	jal SolveNext				# jump to next cell
	 lw $ra, 0($sp)				# restore pointer
         add $sp, $sp, 4
      	# no solution was found, thus
      	subi $t1, $t1, 1			# decrement position counter
	jr $ra					# no solution was found, so return					
	
	solveSolutionFound:
		la $a0, boardSolution	 		# 
		li $v0, 4				# print the string to the screen, using system call #4
		syscall
	
	 	 sub $sp, $sp, 4			# backup pointer
        	 sw $ra, 0($sp) 
		jal Print				# jump to next cell
	 	 lw $ra, 0($sp)				# restore pointer
         	 add $sp, $sp, 4
	
		# Ask user for another solution attempt
		boardNewAttemptSelect:
			#Prompt user for selection
			la $a0, boardNewAttempt 	# load selection Prompt into $a0
			li $v0, 4			# print the string to the screen, using system call #4
			syscall

			#Get integer, store, and branch
			li $v0, 12			# using system call #12: read character
			syscall
			beq $v0, 'y', falsePositive				
			beq $v0, 'n', Start		# return to start if no other solution attempt is desired
			j boardNewAttemptSelect
	
		falsePositive:
			subi $t1, $t1, 1		# decrement position counter
			jr $ra				# Give false positive and return if to try for another attempt
	
	solveCell: # it is known that the current cell is 'e', need to try 1-9 one at a time for validity
	li $t2, 1 #initialize number to check
		
	loopSolveC:
		#update cell
		addi $t2, $t2, 0x30			# convert to ascii
		sb $t2, board($t1)			# update board cell
		subi $t2, $t2, 0x30			# convert back to non-ascii
		
		#check validity
		 sub $sp, $sp, 12			
        	 sw $ra, 0($sp)				# backup pointer
        	 sw $t1, 4($sp)				# backup place holder
        	 sw $t2, 8($sp)				# backup solveCounter
		jal checkBoardR 			# call the checkBoard function to check rows
		 lw $ra, 0($sp)				# restore pointer
		 lw $t1, 4($sp)				# restore place holder
		 lw $t2, 8($sp)				# restore solveCounter
         	 add $sp, $sp, 12
		bgt $s0, 0, incSolveC			# check to see if the board is valid
		 
		 sub $sp, $sp, 12			
        	 sw $ra, 0($sp)				# backup pointer
        	 sw $t1, 4($sp)				# backup place holder
        	 sw $t2, 8($sp)				# backup solveCounter
		jal checkBoardC
		 lw $ra, 0($sp)				# restore pointer
		 lw $t1, 4($sp)				# restore place holder
		 lw $t2, 8($sp)				# restore solveCounter
         	 add $sp, $sp, 12 			# call the checkBoard function to check columns
		bgt $s0, 0, incSolveC			# check to see if the board is valid
		
		 sub $sp, $sp, 12			
        	 sw $ra, 0($sp)				# backup pointer
        	 sw $t1, 4($sp)				# backup place holder
        	 sw $t2, 8($sp)				# backup solveCounter
		jal checkBoardB 			# call the checkBoard function to check boxes
		 lw $ra, 0($sp)				# restore pointer
		 lw $t1, 4($sp)				# restore place holder
		 lw $t2, 8($sp)				# restore solveCounter
         	 add $sp, $sp, 12
         	bgt $s0, 0, incSolveC			# check to see if the board is valid
         	
         	#found a valid solution to cell
         	
         	#check if 
		addi $t1,$t1, 1				# increment board array position by 1
		bgt $t1, 81, solveSolutionFoundL	# check to see if the end was reached, if so then a solution was found
									
	 	 sub $sp, $sp, 12			
        	 sw $ra, 0($sp) 			# backup pointer
        	 sw $t1, 4($sp)				# backup placeholder
        	 sw $t2, 8($sp)				# backup solveCounter
		jal SolveNext				# jump to next cell
		 lw $ra, 0($sp)				# restore pointer
		 lw $t1, 4($sp)				# restore placeholder
		 lw $t2, 8($sp)				# restore solveCounter
        	 add $sp, $sp, 12
        	 
      		# no solution was found, thus
      		subi $t1, $t1, 1			# decrement position counter
							# no solution was found, so continue to solve cell
												
		incSolveC: # was not a valid solution to cell  
		addi $t2, $t2, 1			# increment $t2 num check
		blt $t2, 10, loopSolveC			# check if less than or equal to 9, then jump to repeat loop
		
		#if greater than 9, then can't solve, set back to 'e' and jr
		li $t2, 0x65				# set $t2 to 'e'
		sb $t2, board($t1)			# update board cell to 'e'
		jr $ra					# jump return to last call because could not solve
		
	solveSolutionFoundL:
		la $a0, boardSolution	 		# 
		li $v0, 4				# print the string to the screen, using system call #4
		syscall
	
	 	 sub $sp, $sp, 4			# backup pointer
        	 sw $ra, 0($sp) 
		jal Print				# jump to next cell
	 	 lw $ra, 0($sp)				# restore pointer
         	 add $sp, $sp, 4
	
		# Ask user for another solution attempt
		boardNewAttemptSelectL:
			#Prompt user for selection
			la $a0, boardNewAttempt 	# load selection Prompt into $a0
			li $v0, 4			# print the string to the screen, using system call #4
			syscall

			#Get integer, store, and branch
			li $v0, 12			# using system call #12: read character
			syscall
			beq $v0, 'y', falsePositiveL				
			beq $v0, 'n', Start		# return to start if no other solution attempt is desired
			j boardNewAttemptSelectL
	
		falsePositiveL:
			subi $t1, $t1, 1		# decrement position counter
			j incSolveC			# Give false positive and return if to try for another attempt
		
Exit:

li $v0, 10 			# exit program
syscall


