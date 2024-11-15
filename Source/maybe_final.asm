	.data
image:			.word 0 : 300
kernel:			.word 0 : 300
padded_image:	.word 0 : 300
out:			.word 0 : 300

N:				.word 1
M:				.word 1
P:				.word 1
S:				.word 1
O:				.word 1

input_buffer:	.space 1000	# idk how many bytes we will reead from the file so... for safe guard, i guess
output_buffer:	.space 1000

epsilon:		.float  0.00001
input_dir:		.asciiz "D:\\Code\\MIPS\\Major Assignment\\Test_8\\input_matrix.txt"
output_dir:		.asciiz "D:\\Code\\MIPS\\Major Assignment\\Test_8\\output_matrix.txt"
msg1:			.asciiz "Image\n"
msg2: 			.asciiz "Added padding\n"
msg3:			.asciiz "Kernel\n"
msg4:			.asciiz "Result\n"
space:			.asciiz " "
tab:			.asciiz "\t"
newline:		.asciiz "\n"

###################################################
## Register rule for special variables (sort of) ##
## ############################################# ##
## image: s0									 ##
## kernel: s1									 ##
## padded_image: s2								 ##
## out: s3										 ##
## input_buffer: s4								 ##
###################################################

	.text
#################################################################################################
# Set pointers to matrices
la $s0, image
la $s1, kernel
la $s3, out
la $s4, input_buffer
#################################################################################################
# Open (for reading) a file
li $v0, 13 				# System call for open file
la $a0, input_dir 		# Input file name
li $a1, 0 				# Open for reading (0: read, 1: write)
li $a2, 0				# Mode is ignored
syscall 				# Open a file (file descriptor returned in $v0)
move $s6, $v0			# Save file descriptor
# Read from file
li $v0, 14 				# System call for read
move $a0, $s6 			# File descriptor
la $a1, input_buffer 	# Address of buffer read
li $a2,  1000 			# Hardcoded buffer length
syscall 				# Read file
#################################################################################################
#################################################################################################
# Read N, M, P and S
# Read N
la $t0, N				# Load address of N
lbu $t1, 0($s4)			# Since a character in the file buffer is only 1 byte, 
						# doing an unsigned load will avoid sign extension 
						# leading to wrong value
addi $t1, $t1, -48		# Convert char type to integer type
sw $t1, 0($t0)			# Store the converted value in N
addi $s4, $s4, 2		# Move to the next character, skipping white space 
						# on the way
# Read M
la $t0, M
lbu $t1, 0($s4)
addi $t1, $t1, -48
sw $t1, 0($t0)
addi $s4, $s4, 2
# Read P
la $t0, P
lbu $t1, 0($s4)
addi $t1, $t1, -48
sw $t1, 0($t0)
addi $s4, $s4, 2
# Read S
la $t0, S
lbu $t1, 0($s4)
addi $t1, $t1, -48
sw $t1, 0($t0)
addi $s4, $s4, 3	# On the last character of the first line, move the  
					# string pointer 3 characters ahead because of the  
					# CARRIAGE_RETURN and LINE_FEED 
#################################################################################################
#################################################################################################
# Store inputs to Image matrix and Kernel matrix

# Two loops, one for reading string and store them to image as floats, 
# one to store them in kernel
# If ' ' then go to next charecter
# If '\n' then end loop
# If anything else, go to process float

# Build Image matrix
# t3: Building mode indicator (0: Image mode, 1: Kernel mode)
li $t3, 0								# Image mode
buid_image_loop:
	lbu $t0, 0($s4)						# Load current character
	beq $t0, 10, pre_buid_kernel_loop	# If LINE_FEED, switch to buidling Kernel matrix 						
	beq $t0, 13, pre_buid_kernel_loop	# Same as the above case, but with CARRIAGE_RETURN
	beq $t0, 32, next_image_char		# For white spaces, skip them
	j string_to_float					# The string pointer now will be at the start of a float,
										# we need to convert them to actual floats and build the matrix
next_image_char:
	addi $s4, $s4, 1
	j buid_image_loop
#################################################################################################
pre_buid_kernel_loop:			# Processes before building the Kernel matrix
	addi $s4, $s4, 2			# Move forward 2 characters because of CARRIAGE_RETURN and LINE FEED
	lbu $t0, 0($s4)	
li $t3, 1									# Kernel mode
buid_kernel_loop:
	lbu $t0, 0($s4)							# Load current character
	beq $t0, 0, validate_output_size		# End of the file buffer, NULL, finish building and go to next tasks  
	beq $t0, 32, next_kernel_char			# For white spaces, skip them
	j string_to_float						# The string pointer now will be at the start of a float,
											# we need to convert them to actual floats and build the matrix
next_kernel_char:
	addi $s4, $s4, 1
	j buid_kernel_loop
#################################################################################################
# Convert string of floats to actual floats and store in the correct matrix
string_to_float:
	seq $t1, $t0, 45			# Sign flag, t1 = 1 : negative; t1 = 0 : positive

	lui $t2, 0x0000				# We can't directly set a register to float so we need to store 
								# its IEEE-754 format to the stack and use lwc1 instead 
	addi $sp, $sp, -4			# Create space in the stack
	sw $t2, 0($sp)				# Store the IEEE-754 in the stack
	lwc1 $f0, 0($sp)			# Initialize the reuslting float f0 with 0.0
	addi $sp, $sp 4				# Pop the stack
	
	lui $t2, 0x4120
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	lwc1 $f1, 0($sp)			# Initialize f1 with 10.0, this is for later use in calculating
								# a float's whole number
	addi $sp, $sp 4
	
	lui $t2, 0x4120
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	lwc1 $f2, 0($sp)			# Initialize f2 with 10.0, this is for later use in calculating 
								# a float's decimal part
	addi $sp, $sp 4
		
	beqz $t1, before_decimal_point		# If it is positive skip the next line
	addi $s4, $s4, 1

	before_decimal_point:
		lbu $t0, 0($s4)				# Load current character
		beq $t0, 0, store_float		# If we get to NULL, store the current f0 to the correct matrix
		beq $t0, 10, store_float	# If we get to LINE_FEED, store the current f0 to the correct matrix
		beq $t0, 13, store_float	# If we get to CARRIAGE_RETURN, store the current f0 to the correct matrix
		beq $t0, 32, store_float	# If we get to SPACE, store the current f0 to the correct matrix
		
		beq $t0, 46, skip_decimal	# If we get to '.', skip it and go processing the decimal part of a float
		
		addi $t0, $t0, -48			# Convert current character to its integer form
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		lwc1 $f3, 0($sp)			# f3: current character in float form. This is because the matrix has float type
		addi $sp, $sp, 4
		cvt.s.w $f3, $f3			# To actually get a character float form from its word form, we have to use this 
		
		mul.s $f0, $f0, $f1			# Shift left the resulting float (x10)
		add.s  $f0, $f0, $f3		# Add the current character in float form to the resulting float's whole number
		
		addi $s4, $s4, 1
		j before_decimal_point
	
	skip_decimal:
		addi $s4, $s4, 1			# Skip the decimal symbol

	after_decimal_point:
		lbu $t0, 0($s4)				# Load current character
		beq $t0, 0, store_float		# If we get to NULL, store the current f0 to the correct matrix
		beq $t0, 10, store_float	# If we get to LINE_FEED, store the current f0 to the correct matrix
		beq $t0, 13, store_float	# If we get to CARRIAGE_RETURN, store the current f0 to the correct matrix
		beq $t0, 32, store_float	# If we get to SPACE, store the current f0 to the correct matrix
	
		addi $t0, $t0, -48		
		addi $sp, $sp, -4	
		sw $t0, 0($sp)
		lwc1 $f3, 0($sp)	
		addi $sp, $sp, 4
		cvt.s.w $f3, $f3
		
		div.s $f3, $f3, $f1		# Since we are calculating the decimal part, we need to divide the current character
								# in float form by 10^n everytime before adding it to the resulting float
		mul.s $f1, $f1, $f2		# Operation as 10^n
		add.s $f0, $f0, $f3		# Add the current character in float form to the resulting float's decimal part
		
		addi $s4, $s4, 1
		j after_decimal_point
#################################################################################################
# Store the resulting float into correct matrix
store_float:
	beq $t1, 1, negate			# Negate the resulting float if needed
	beq $t3, 0, store_img		
	beq $t3, 1, store_kernel	
		
	store_img:
		swc1 $f0, 0($s0)
		addi $s0, $s0, 4
		j store_next_char

	store_kernel:
		swc1 $f0, 0($s1)
		addi $s1, $s1, 4
		j store_next_char

negate:
	sub.s $f1, $f0, $f0
	sub.s $f0, $f1, $f0
	li $t1, 0
	j store_float

store_next_char:	
	beq $t3, 0, buid_image_loop
	beq $t3, 1, buid_kernel_loop		
#################################################################################################
#################################################################################################
# Validate output size
validate_output_size:	
	la $t0, N		# Load N
	lw $t0, 0($t0)
		
	la $t1, M		# Load M
	lw $t1, 0($t1)

	la $t2, P		# Load P
	lw $t2, 0($t2)
	
	la $t3, S		# Load S
	lw $t3, 0($t3)
	
	mul $t2, $t2, 2		# P *= 2
	add $t0, $t0, $t2	# N += 2*P
	sub $t0, $t0, $t1	# N -= M
	
	blt $t0, 0, end_program
	
	div $t0, $t3		# N / S
	mflo $t0			# N = floor(N)
	addi $t0, $t0, 1

	la $t4, O 
	sw $t0, 0($t4)
#################################################################################################
#################################################################################################	
# Build Padded image
build_padded_image:
	la $s0, image
	la $s2, padded_image	# Load Padded image address
		
	la $t0, N		# Load N
	lw $t0, 0($t0)

	la $t2, P		# Load P
	lw $t2, 0($t2)
	
	mul $t3, $t2, 2		# D = 2*P
	add $t3, $t0, $t3	# D = N + 2*P
	mul $t3, $t3, $t2	# D = (N + 2*P)*P
	add $t3, $t3, $t2	# D = (N + 2*P)*P + P
	
	mul $t3, $t3, 4		# D = D * 4
	add $s2, $s2, $t3	# Move Padded image pointer to the correct position 
						# and begin filling it with content of Image
				
	li $t4, 0		# Outer loop counter
	outer_loop:
		beq $t4, $t0, end_outer_loop
		li $t5, 0	# Inner loop counter
		inner_loop:
			beq $t5, $t0, end_inner_loop
			lwc1 $f6, 0($s0)
			swc1 $f6, 0($s2)
			
			addi $s0, $s0, 4
			addi $s2, $s2, 4
			addi $t5, $t5, 1
			j inner_loop
		end_inner_loop:
			# Move the Padded image pointer to the next row that needs filling
			move $t6, $t2
			mul $t6, $t6, 8
			add $s2, $s2, $t6
		addi $t4, $t4, 1
		j outer_loop
	end_outer_loop:	
#################################################################################################
#################################################################################################	
# MOST IMPORTANT PART
convolve:
	
	la $s3, out

	la $t0, N 
	lw $t0, 0($t0)

	la $t1, M
	lw $t1, 0($t1)

	la $t2, P 
	lw $t2, 0($t2)

	la $t3, S
	lw $t3, 0($t3)

	la $t4, O
	lw $t4, 0($t4) 

	mul $t9, $t2, 2		# P *= 2
	add $t9, $t0, $t9	# N += 2*P

	li $t5, 0	# loop_1 counter
	loop_1:
		beq $t5, $t4, end_loop_1
		# YOUR CODE HERE

		li $t6, 0	# loop_2 counter
		loop_2:
			beq $t6, $t4, end_loop_2
			# YOUR CODE HERE
			lui $t7, 0x0000
			addi $sp, $sp, -4
			sw $t7, 0($sp)
			lwc1 $f0, 0($sp)		# Sum to store in output
			addi $sp, $sp, 4

			li $t7, 0	# loop_3 counter
			loop_3:
				beq $t7, $t1, end_loop_3
				# YOUR CODE HERE

				li $t8, 0	# loop_4 counter
				loop_4:
					beq $t8, $t1, end_loop_4
					# YOUR CODE HERE
					mul $s5, $t5, $t3		# Row to go to
					add $s5, $s5, $t7
					mul $s5, $s5, $t9		# Needs to multiply by the matrix size to get correct row 
											# because they are stored in a line 
					mul $s5, $s5, 4

					mul $s6, $t6, $t3		# Column to go to
					add $s6, $s6, $t8
					#mul $s5, $s5, $s7
					mul $s6, $s6, 4

					la $s1, kernel
					la $s2, padded_image
					
					# Get value at padded_image[s5][s6]
					add $s2, $s2, $s5		# Go to row s5
					add $s2, $s2, $s6		# Go to column s6
					lwc1 $f1, 0($s2)		# Get value at destination

					# Get value at kernel[t7][t8]
					mul $s7, $t7, $t1	# Needs to multiply by the matrix size to get correct row
										# because they are stored in a line 
					mul $s7, $s7, 4
					add $s1, $s1, $s7	# Go to row t7

					mul $s7, $t8, 4
					add $s1, $s1, $s7	# Go to column t8

					lwc1 $f2, 0($s1)	# Get value at destination

					mul.s $f3, $f1, $f2		# f1 = padded_image[s5][s6] * kernel[t7][t8]
					add.s $f0, $f0, $f3		# sum += padded_image[s5][s6] * kernel[t7][t8]

					addi $t8, $t8, 1
					j loop_4
				end_loop_4:
					# YOUR CODE HERE

				addi $t7, $t7, 1
				j loop_3
			end_loop_3:
				# YOUR CODE HERE

			swc1 $f0, 0($s3)
			addi $s3, $s3, 4

			addi $t6, $t6, 1
			j loop_2
		end_loop_2:
			# YOUR CODE HERE

		addi $t5, $t5, 1
		j loop_1
	end_loop_1:
#################################################################################################
#################################################################################################
# Open (for writing) a file that does not exist 
li $v0, 13				# System call for open file
la $a0, output_dir		# Output file name
li $a1, 1				# Open for writing (0: read, 1: write)
li $a2, 0				# Mode is ignored
syscall
move $s6, $v0
#################################################################################################
# Write to the file just opened
la $s3, out
la $s5, output_buffer

la $t4, O
lw $t4, 0($t4)
mul $t4, $t4, $t4

lui $t2, 0x42c8
addi $sp, $sp, -4
sw $t2, 0($sp)
lwc1 $f3, 0($sp)			# f1 = 100.0
addi $sp, $sp 4

li $t9, 0	# Buffer length
li $t5, 0
write_to_buffer:
	beq $t5, $t4, write_to_file

	# Check if the float is negative
	lwc1 $f1, 0($s3)
	abs.s $f2, $f1

	# Process if float is negative. Store '-' before hand in the buffer
	c.lt.s $f1, $f2
	bc1f positive
	li $t1, 45
	sb $t1, 0($s5)

	addi $s5, $s5, 1
	addi $t9, $t9, 1

    positive:
    	# Extract and store whole number of float
    	trunc.w.s $f0, $f2
    	mfc1 $t0, $f0

    	move $a0, $s5
    	jal int_to_string
    	add $s5, $s5, $v0
    	add $t9, $t9, $v0

    	# Store decimal point
    	li $t1, 46
    	sb $t1, 0($s5)
    	addi $s5, $s5, 1
    	addi $t9, $t9, 1

    	# Extract and store decimal part of float
    	cvt.s.w $f0, $f0
    	sub.s $f2, $f2, $f0	# f2 is now the decimal part, we only need the first two digits

    	la $t8, epsilon
    	lwc1 $f4, 0($t8)
    	add.s $f2, $f2, $f4

    	mul.s $f2, $f2, $f3	# Shift right the decimal point twice
    	# Convert decimal part to integer
    	trunc.w.s $f0, $f2
    	mfc1 $t0, $f0

    	move $a0, $s5
    	jal int_to_string_decimal
    	add $s5, $s5, $v0
    	add $t9, $t9, $v0

    	li $t1, 32
    	sb $t1, 0($s5)
    	addi $s5, $s5, 1
    	addi $t9, $t9, 1

    	addi $t5, $t5, 1
    	addi $s3, $s3, 4
    	j write_to_buffer

# INT_TO_STRING function
int_to_string:
	li $v0, 0
	move $t1, $t0
	addi $a1, $a0, 11
	li $t2, 10		# Decimal, so divide by 10

	int_to_string_loop:
		div $t1, $t2
		mfhi $t7		# Remainder
		mflo $t1		# Quotient

		addi $t7, $t7, 48	# Convert remainder to ASCII
		subi $a1, $a1, 1
		sb $t7, 0($a1)
		addi $v0, $v0, 1

		bne $t1, 0, int_to_string_loop

	# Move to start of buffer
	#move $t1, $a0
	li $t8, 0
	move_loop:
		lb $t3, 0($a1)
		sb $t3, 0($a0)

		addi $a0, $a0, 1
		addi $a1, $a1, 1

		addi $t8, $t8, 1
		bne $t8, $v0, move_loop 

		jr $ra
	
# INT_TO_STRING for decimal part of float (maximum 2 numbers)
int_to_string_decimal:
	li $v0, 0
	move $t1, $t0
	addi $a1, $a0, 11
	li $t2, 10		# Decimal, so divide by 10

	li $t6, 0
	int_to_string_decimal_loop:
		div $t1, $t2
		mfhi $t7		# Remainder
		mflo $t1		# Quotient

		addi $t7, $t7, 48	# Convert remainder to ASCII
		subi $a1, $a1, 1
		sb $t7, 0($a1)
		addi $v0, $v0, 1

		addi $t6, $t6, 1
		bne $t6, 2, int_to_string_decimal_loop

	# Move to start of buffer
	#move $t1, $a0
	li $t8, 0
	move_loop_decimal:
		lb $t3, 0($a1)
		sb $t3, 0($a0)

		addi $a0, $a0, 1
		addi $a1, $a1, 1

		addi $t8, $t8, 1
		bne $t8, $v0, move_loop_decimal

		jr $ra

write_to_file:
	li $v0, 15				# System call to write to file
	move $a0, $s6			# File descriptor
	la $a1, output_buffer	# Address of buffer from which to write
	move $a2, $t9			# Hardcoded buffer length
	syscall 
#################################################################################################
# Close the file
li $v0, 16				# System call for close file
move $a0, $s6			# File descriptor to close
syscall					# Close file
#################################################################################################
#################################################################################################

# UNCOMMENT THE FOLLOWING LINE IF YOU NEED TO PRINT OUT THE MATRICES
# j end_program

#################################################################################################
#################################################################################################
print:
	la $s0, image
	la $s1, kernel
	la $s2, padded_image
	la $s3, out

	la $t0, N
	lw $t0, 0($t0)

	la $t1, M
	lw $t1, 0($t1)

	la $t2, P
	lw $t2, 0($t2)

	la $t4, O
	lw $t4, 0($t4) 

	move $t8, $t2
	mul $t8, $t8, 2
	move $t9, $t0
	add $t9, $t9, $t8
	
	li $v0, 4
	la $a0, msg1
	syscall

	li $t5, 0
	print_image_loop_1:
		beq $t5, $t0, end_print_image_loop_1
		
		li $t6, 0
		print_image_loop_2:
			beq $t6, $t0, end_print_image_loop_2

			li $v0, 2
			lwc1 $f12, 0($s0)
			syscall

			li $v0, 4
			la $a0, tab
			syscall

			addi $s0, $s0, 4
			addi $t6, $t6, 1
			j print_image_loop_2
		end_print_image_loop_2:
			li $v0, 4
			la $a0, newline
			syscall
		
		addi $t5, $t5, 1
		j print_image_loop_1
	end_print_image_loop_1:
		li $v0, 4
		la $a0, newline
		syscall

		li $v0, 4
		la $a0, newline
		syscall
#################################################################################################

	li $v0, 4
	la $a0, msg2
	syscall

	li $t5, 0
	print_padded_loop_1:
		beq $t5, $t9, end_print_padded_loop_1
		
		li $t6, 0
		print_padded_loop_2:
			beq $t6, $t9, end_print_padded_loop_2

			li $v0, 2
			lwc1 $f12, 0($s2)
			syscall

			li $v0, 4
			la $a0, tab
			syscall

			addi $s2, $s2, 4
			addi $t6, $t6, 1
			j print_padded_loop_2
		end_print_padded_loop_2:
			li $v0, 4
			la $a0, newline
			syscall
		
		addi $t5, $t5, 1
		j print_padded_loop_1
	end_print_padded_loop_1:
		li $v0, 4
		la $a0, newline
		syscall
		
		li $v0, 4
		la $a0, newline
		syscall

#################################################################################################

	li $v0, 4
	la $a0, msg3
	syscall

	li $t5, 0
	print_kernel_loop_1:
		beq $t5, $t1, end_print_kernel_loop_1
		
		li $t6, 0
		print_kernel_loop_2:
			beq $t6, $t1, end_print_kernel_loop_2

			li $v0, 2
			lwc1 $f12, 0($s1)
			syscall

			li $v0, 4
			la $a0, tab
			syscall

			addi $s1, $s1, 4
			addi $t6, $t6, 1
			j print_kernel_loop_2
		end_print_kernel_loop_2:
			li $v0, 4
			la $a0, newline
			syscall
		
		addi $t5, $t5, 1
		j print_kernel_loop_1
	end_print_kernel_loop_1:
		li $v0, 4
		la $a0, newline
		syscall

		li $v0, 4
		la $a0, newline
		syscall

#################################################################################################

	li $v0, 4
	la $a0, msg4
	syscall

	li $t5, 0
	print_output_loop_1:
		beq $t5, $t4, end_print_output_loop_1
		
		li $t6, 0
		print_output_loop_2:
			beq $t6, $t4, end_print_output_loop_2

			li $v0, 2
			lwc1 $f12, 0($s3)
			syscall

			li $v0, 4
			la $a0, tab
			syscall

			addi $s3, $s3, 4
			addi $t6, $t6, 1
			j print_output_loop_2
		end_print_output_loop_2:
			li $v0, 4
			la $a0, newline
			syscall
		
		addi $t5, $t5, 1
		j print_output_loop_1
	end_print_output_loop_1:
		li $v0, 4
		la $a0, newline
		syscall

		li $v0, 4
		la $a0, newline
		syscall
#################################################################################################
#################################################################################################
end_program:
	li $v0, 10
	syscall
