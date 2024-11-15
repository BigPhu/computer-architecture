	.data
image:			.word 0 : 49
kernel:			.word 0 : 16
padded_image:	.word 0 : 225
out:			.word 0 : 196
config:			.word 0 : 4

N:				.word 1
M:				.word 1
P:				.word 1
S:				.word 1
p_N:			.word 1
O:				.word 1

input_buffer:	.space 1024	# idk how many bytes we will reead from the file so... for safe guard, i guess
output_buffer:	.space 1024

f_0:			.float 0
f_005:			.float 0.05
f_10:			.float 10
f_48:			.float 48
f_100:			.float 100
epsilon:		.float 0.0001

input_dir:		.asciiz "D:\\Code\\MIPS\\Major Assignment\\Tests\\Test_10\\input_matrix.txt"
output_dir:		.asciiz "D:\\Code\\MIPS\\Major Assignment\\Tests\\Test_10\\output_matrix.txt"
msg1:			.asciiz "Image\n"
msg2: 			.asciiz "Kernel\n"
msg3:			.asciiz "Added padding\n"
msg4:			.asciiz "Result\n"
error:			.asciiz "Error: size not match"
space:			.asciiz " "
tab:			.asciiz "\t"
newline:		.asciiz "\n"

	.text
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
li $a2,  1024			# Hardcoded buffer length
syscall 				# Read file

la $s0 input_buffer

li $v0, 4
move $a0, $s0
syscall

li $v0, 4
la $a0, newline
syscall

# move $a0, $s0
# # int load_config(addr file_buffer)
# jal load_config
# add $s0, $s0, $v0

la $a0, config
move $a1, $s0
li $a2, 4
jal build_matrix
add $s0, $s0, $v0

la $a0, config
jal load_config

la $t0, N 
lw $t0, 0($t0)
# Build image
la $a0, image
move $a1, $s0 
mul $a2, $t0, $t0
# int build_matrix(addr matrix_to_build, addr start_of_string, int num_of_elements)
jal build_matrix
add $s0, $s0 , $v0

la $t0, M
lw $t0, 0($t0)
# Build kernel
la $a0, kernel
move $a1, $s0
mul $a2, $t0, $t0
# int build_matrix(addr matrix_to_build, addr start_of_string, int num_of_elements)
jal build_matrix

# void build_padded_image(addr image, addr output)
la $a0, image
la $a1, padded_image
jal build_padded_image

# void convolve(addr padded_image, addr kernel, addr output)
la $a0, padded_image
la $a1, kernel
la $a2, out
jal convolve

# Open (for writing) a file that does not exist 
li $v0, 13				# System call for open file
la $a0, output_dir		# Output file name
li $a1, 1				# Open for writing (0: read, 1: write)
li $a2, 0				# Mode is ignored
syscall
move $s6, $v0

# void wrtie_to_file(addr data, addr file_buffer)
la $a0, out
la $a1, output_buffer
jal write_to_buffer

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

la $a0, image
la $a1, N 
lw $a1, 0($a1)
la $a2, msg1
jal print

la $a0, kernel
la $a1, M
lw $a1, 0($a1)
la $a2, msg2
jal print

la $a0, padded_image
la $a1, p_N 
lw $a1, 0($a1)
la $a2, msg3
jal print

la $a0, out
la $a1, O 
lw $a1, 0($a1)
la $a2, msg4
jal print

end_program:
	li $v0, 10
	syscall

#################################################################################################
#################################################################################################

load_config:
	# $a0: config matrix's address
    # $v0: returns number of characters read
	#la $t4, config
	la $t0, N 
	lwc1 $f0, 0($a0)
	cvt.w.s $f0, $f0 
	mfc1 $t9, $f0  
	#addi $t9, $t9, -48
	sw $t9 0($t0)
	lw $t0, 0($t0)

	la $t1, M
	#lbu $t9, 4($t4)
	lwc1 $f0, 4($a0)
	cvt.w.s $f0, $f0 
	mfc1 $t9, $f0  
	#addi $t9, $t9, -48
	sw $t9 0($t1)
	lw $t1, 0($t1)

	la $t2, P 
	#lbu $t9, 4($a0)
	lwc1 $f0, 8($a0)
	cvt.w.s $f0, $f0 
	mfc1 $t9, $f0  
	#addi $t9, $t9, -48
	sw $t9 0($t2)
	lw $t2, 0($t2)

	la $t3, S 
	#lbu $t9, 6($a0)
	lwc1 $f0, 12($a0)
	cvt.w.s $f0, $f0 
	mfc1 $t9, $f0  
	#addi $t9, $t9, -48
	sw $t9 0($t3)
	lw $t3, 0($t3)

	# Calculate size of output
	mul $t2, $t2, 2		# P *= 2
	add $t8, $t0, $t2	# N += 2*P
	sub $t9, $t8, $t1	# N -= M

	blt $t9, 0, invalid_congfig

	div $t9, $t3		# N / S
	mflo $t9			# N = floor(N)
	addi $t9, $t9, 1

	la $t4, p_N 
	sw $t8, 0($t4)

	la $t5, O 
	sw $t9, 0($t5)

	j end_load_config
	invalid_congfig:
		# Open (for writing) a file that does not exist 
		li $v0, 13				# System call for open file
		la $a0, output_dir		# Output file name
		li $a1, 1				# Open for writing (0: read, 1: write)
		li $a2, 0				# Mode is ignored
		syscall
		move $s6, $v0

		li $v0, 15				# System call to write to file
		move $a0, $s6			# File descriptor
		la $a1, error			# Address of buffer from which to write
		li $a2, 21				# Hardcoded buffer length
		syscall

		j end_program
end_load_config:
	#li $v0, 9
	jr $ra

#################################################################################################
#################################################################################################

build_matrix:
    # $a0: storage's address
    # $a1: pointer to index of a string that reading should start from
    # $a2: how many word should we read from the string
    # $v0: returns number of characters read
    li $v0, 0   # Set return number to 0
    li $t0, 0   # Loop counter
    build_matrix_loop:
        beq $t0, $a2, end_build_matrix

        lbu $t1, 0($a1)
        beq $t1, '\0', skip_char
        beq $t1, '\n', skip_char
        beq $t1, '\r', skip_char

        addi $sp, $sp, -12
        sw $a0, 8($sp)
        sw $v0, 4($sp)
        sw $ra, 0($sp)

        move $a0, $a1
        jal string_to_float
        move $t2, $v0
        addi $t2, $t2, 1

		addi $sp, $sp, 12
        lw $a0, -4($sp)
        lw $v0, -8($sp)
        lw $ra, -12($sp)

		swc1 $f0, 0($a0)
        addi $t0, $t0, 1
        addi $a0, $a0, 4
        add $a1, $a1, $t2
        add $v0, $v0, $t2
        j build_matrix_loop

		skip_char:
			addi $a1, $a1, 1
			j build_matrix_loop

end_build_matrix:
	addi $v0, $v0, 1
	jr $ra

string_to_float:
    # a0: pointer to index of a string that reading should start from
    # v0: number of character read 
    li $v0, 0
    lbu $t2, 0($a0)

    seq $t3, $t2, '-'
    beq $t3, 1, skip_sign
    j end_skip_sign
    
    skip_sign:
        addi $a0, $a0, 1
        addi $v0, $v0, 1
    end_skip_sign:

	l.s $f0, f_0
	l.s $f1, f_10
	l.s $f2, f_10 

    before_decimal_point:
        # If we reach decimal point, raise the flag t2
        lbu $t2, 0($a0)

        beq $t2, '\0', return_string_to_float
        beq $t2, '\n', return_string_to_float
        beq $t2, '\r', return_string_to_float
        beq $t2, ' ', return_string_to_float

        beq $t2, '.', end_before_decimal_point

        addi $t2, $t2, -48			# Convert current character to its integer form
	    addi $sp, $sp, -4
	    sw $t2, 0($sp)
	    lwc1 $f3, 0($sp)			# f3: current character in float form. This is because the matrix has float type
	    addi $sp, $sp, 4
	    cvt.s.w $f3, $f3

        mul.s $f0, $f0, $f1			# Shift left the resulting float (x10)
	    add.s  $f0, $f0, $f3		# Add the current character in float form to the resulting float's whole number

        addi $a0, $a0, 1
        addi $v0, $v0, 1
        j before_decimal_point
    end_before_decimal_point:

    addi $a0, $a0, 1
    addi $v0, $v0, 1

    after_decimal_point:
        lbu $t2, 0($a0)

        beq $t2, '\0', return_string_to_float
        beq $t2, '\n', return_string_to_float
        beq $t2, '\r', return_string_to_float
        beq $t2, ' ', return_string_to_float

        addi $t2, $t2, -48		
	    addi $sp, $sp, -4	
	    sw $t2, 0($sp)
	    lwc1 $f3, 0($sp)	
	    addi $sp, $sp, 4
	    cvt.s.w $f3, $f3

	    div.s $f3, $f3, $f1		# Since we are calculating the decimal part, we need to divide the current character
	    						# in float form by 10^n everytime before adding it to the resulting float
	    mul.s $f1, $f1, $f2		# Operation as 10^n
	    add.s $f0, $f0, $f3		# Add the current character in float form to the resulting float's decimal part

        addi $a0, $a0, 1
        addi $v0, $v0, 1
	    j after_decimal_point
    end_after_decimal_point:

return_string_to_float:
    beq $t3, 1, negate
    jr $ra

    negate:
        neg.s $f0, $f0
        jr $ra

#################################################################################################
#################################################################################################	
# Build Padded image
build_padded_image:		
	la $t0, N		# Load N
	lw $t0, 0($t0)

	la $t1, P		# Load P
	lw $t1, 0($t1)
	
	mul $t2, $t1, 2		# D = 2*P
	add $t2, $t0, $t2	# D = N + 2*P
	mul $t2, $t2, $t1	# D = (N + 2*P)*P
	add $t2, $t2, $t1	# D = (N + 2*P)*P + P
	
	mul $t2, $t2, 4		# D = D * 4
	add $a1, $a1, $t2	# Move Padded image pointer to the correct position 
						# and begin filling it with content of Image
				
	li $t3, 0		# Outer loop counter
	outer_loop:
		beq $t3, $t0, end_outer_loop
		li $t4, 0	# Inner loop counter
		inner_loop:
			beq $t4, $t0, end_inner_loop
			lwc1 $f0, 0($a0)
			swc1 $f0, 0($a1)
			
			addi $a0, $a0, 4
			addi $a1, $a1, 4
			addi $t4, $t4, 1
			j inner_loop
		end_inner_loop:
			# Move the Padded image pointer to the next row that needs filling
			move $t5, $t1
			mul $t5, $t5, 8
			add $a1, $a1, $t5
		addi $t3, $t3, 1
		j outer_loop
	end_outer_loop:	
end_build_padded_image:
	jr $ra
#################################################################################################
#################################################################################################	
# MOST IMPORTANT PART
convolve:
	la $t0, N 
	lw $t0, 0($t0)

	la $t1, M
	lw $t1, 0($t1)

	la $t2, P 
	lw $t2, 0($t2)

	la $t3, S
	lw $t3, 0($t3)

	la $t4, p_N
	lw $t4, 0($t4)

	la $t5, O
	lw $t5, 0($t5) 

	# l.s $f4, f_0
	# l.s $f5, f_005

	li $t6, 0	# loop_1 counter
	loop_1:
		beq $t6, $t5, end_loop_1
		# YOUR CODE HERE

		li $t7, 0	# loop_2 counter
		loop_2:
			beq $t7, $t5, end_loop_2
			# YOUR CODE HERE
			l.s $f0, f_0

			li $t8, 0	# loop_3 counter
			loop_3:
				beq $t8, $t1, end_loop_3
				# YOUR CODE HERE

				li $t9, 0	# loop_4 counter
				loop_4:
					beq $t9, $t1, end_loop_4
					# YOUR CODE HERE
					mul $s1, $t6, $t3		# Row to go to
					add $s1, $s1, $t8
					mul $s1, $s1, $t4		# Needs to multiply by the matrix size to get correct row 
											# because they are stored in a line 
					mul $s1, $s1, 4

					mul $s2, $t7, $t3		# Column to go to
					add $s2, $s2, $t9
					mul $s2, $s2, 4

					move $s3, $a0
					move $s4, $a1
					
					# Get value at padded_image[s1][s2]
					#move $s3, $a0
					add $s3, $s3, $s1		# Go to row s1
					add $s3, $s3, $s2		# Go to column s2
					lwc1 $f1, 0($s3)		# Get value at destination

					# Get value at kernel[t8][t9]
					#move $s3, $a1
					mul $s5, $t8, $t1	# Needs to multiply by the matrix size to get correct row
										# because they are stored in a line 
					mul $s5, $s5, 4
					add $s4, $s4, $s5	# Go to row t8

					mul $s6, $t9, 4
					add $s4, $s4, $s6	# Go to column t7

					lwc1 $f2, 0($s4)	# Get value at destination

					mul.s $f3, $f1, $f2		# f1 = padded_image[s1][s2] * kernel[t7][t8]
					add.s $f0, $f0, $f3		# sum += padded_image[s1][s2] * kernel[t7][t8]

					addi $t9, $t9, 1
					j loop_4
				end_loop_4:
					# YOUR CODE HERE

				addi $t8, $t8, 1
				j loop_3
			end_loop_3:
				# YOUR CODE HERE
			# c.lt.s $f0, $f4
			# bc1f round_up

			# sub.s $f0, $f0, $f5
			# j store

			# round_up:
			# 	add.s $f0, $f0, $f5 

			store:
				swc1 $f0, 0($a2)
				addi $a2, $a2, 4

			addi $t7, $t7, 1
			j loop_2
		end_loop_2:
			# YOUR CODE HERE

		addi $t6, $t6, 1
		j loop_1
	end_loop_1:
end_convolve:
	jr $ra

#################################################################################################
#################################################################################################

write_to_buffer:
	# Write to the file just opened
	# la $s3, out
	# la $s5, output_buffer

	la $t4, O
	lw $t4, 0($t4)
	mul $t4, $t4, $t4

	l.s $f3, f_10
	l.s $f4, f_005
	l.s $f5, epsilon

	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $t9, 0	# Buffer length
	li $t5, 0
	write_to_buffer_loop:
		beq $t5, $t4, end_write_to_buffer_loop

		# Check if the float is negative
		lwc1 $f1, 0($a0)
		# Round the float
		abs.s $f2, $f1

		# Process if float is negative. Store '-' before hand in the buffer
		c.lt.s $f1, $f2
		bc1f positive
		# Round the float
		li $t1, 45
		sb $t1, 0($a1)

		addi $a1, $a1, 1
		addi $t9, $t9, 1

	    positive:
			# Round the float
			add.s $f2, $f2, $f4
	    	# Extract and store whole number of float
	    	trunc.w.s $f0, $f2
	    	mfc1 $t0, $f0
			# int int_to_string(addr int, addr string)
	    	jal int_to_string
	    	#add $a1, $a1, $v0
	    	add $t9, $t9, $v0

	    	# Store decimal point
	    	li $t1, '.'
	    	sb $t1, 0($a1)
	    	addi $a1, $a1, 1
	    	addi $t9, $t9, 1

	    	# Extract and store decimal part of float
	    	cvt.s.w $f0, $f0
	    	sub.s $f2, $f2, $f0	# f2 is now the decimal part, we only need the first two digits

	    	add.s $f2, $f2, $f5 # Correct the number because computers have accuracy issues when it comes to dealing with floats

	    	mul.s $f2, $f2, $f3	# Shift right the decimal point once
	    	# Convert decimal part to integer
	    	trunc.w.s $f0, $f2
	    	mfc1 $t0, $f0

			#li $t8, 1
	    	jal int_to_string
	    	#add $a1, $a1, $v0
	    	add $t9, $t9, $v0

	    	li $t1, ' '
	    	sb $t1, 0($a1)
	    	addi $a1, $a1, 1
	    	addi $t9, $t9, 1

	    	addi $a0, $a0, 4
	    	addi $t5, $t5, 1
	    	j write_to_buffer_loop
		end_write_to_buffer_loop:

end_write_to_buffer:
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	jr $ra

# INT_TO_STRING function
int_to_string:
	li $v0, 0
	move $t1, $t0
	addi $t2, $a1, 11
	li $t3, 10		# Decimal, so divide by 10

	int_to_string_loop:
		div $t1, $t3
		mfhi $t7		# Remainder
		mflo $t1		# Quotient

		addi $t7, $t7, 48	# Convert remainder to ASCII
		subi $t2, $t2, 1
		sb $t7, 0($t2)
		addi $v0, $v0, 1

		bne $t1, 0, int_to_string_loop

	# int_to_string_decimal:
	# 	div $t1, $t3
	# 	mfhi $t7		# Remainder
	# 	mflo $t1		# Quotient

	# 	bge $t7, 5, increment_quotient
	# 	j done_convert
	# 	increment_quotient:
	# 		addi $t1, $t1, 1
	# 		bge $t1, 10, int_to_string_decimal

	# save_decimal:
	# 	addi $t1, $t1, 48	# Convert remainder to ASCII
	# 	subi $a1, $a1, 1
	# 	sb $t1, 0($a1)
	# 	addi $v0, $v0, 1

	# Move to start of buffer
	#move $t1, $a0
	li $t8, 0
	move_loop:
		lb $t3, 0($t2)
		sb $t3, 0($a1)

		addi $t2, $t2, 1
		addi $a1, $a1, 1

		addi $t8, $t8, 1
		bne $t8, $v0, move_loop 

		jr $ra

#################################################################################################
#################################################################################################

# UNCOMMENT THE FOLLOWING LINE IF YOU NEED TO PRINT OUT THE MATRICES
# j end_program

#################################################################################################
#################################################################################################
print:	
	addi $sp, $sp, -4
	sw $a0, 0($sp)

	li $v0, 4
	move $a0, $a2
	syscall

	li $v0, 4
	la $a0, newline
	syscall

	lw $a0, 0($sp)

	li $t5, 0
	print_image_loop_1:
		beq $t5, $a1, end_print_image_loop_1
		
		li $t6, 0
		print_image_loop_2:
			beq $t6, $a1, end_print_image_loop_2

			li $v0, 2
			lwc1 $f12, 0($a0)
			syscall

			li $v0, 4
			la $a0, tab
			syscall
			lw $a0, 0($sp)

			addi $a0, $a0, 4
			sw $a0, 0($sp)
			addi $t6, $t6, 1
			j print_image_loop_2
		end_print_image_loop_2:
			li $v0, 4
			la $a0, newline
			syscall
			lw $a0, 0($sp)
		
		addi $t5, $t5, 1
		j print_image_loop_1
	end_print_image_loop_1:
		li $v0, 4
		la $a0, newline
		syscall

		li $v0, 4
		la $a0, newline
		syscall

	addi $sp, $sp, 4

end_print:
	jr $ra
