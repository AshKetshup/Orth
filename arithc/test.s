	.text
	.globl	main
main:
	pushq $0
#If: 1
	popq %rbx
	cmpq $0, %rbx
	je else_1
	pushq $10
	pushq $30
	popq %rbx
	popq %rax
	addq %rbx, %rax
	pushq %rax
	jmp continua_1
else_1:
	pushq $1
#If: 2
	popq %rbx
	cmpq $0, %rbx
	je else_2
	pushq $100
	jmp continua_2
else_2:
	pushq $200
	jmp continua_2
continua_2:
	jmp continua_1
continua_1:
	popq %rdi
	call print_int
	movq $0, %rax
	ret
print_int:
	movq %rdi, %rsi
	leaq .Sprint_int, %rdi
	movq $0, %rax
	call printf
	ret
print_bool:
	cmpq $0, %rdi
	je .Lfalse
	movq $true, %rdi
	jmp .Lprint
.Lfalse:
	movq $false, %rdi
.Lprint:
	movq $0, %rax
	call printf
	ret
print_str:
	movq %rdi, %rsi
	leaq .Sprint_str, %rdi
	movq $0, %rax
	call printf
	ret
	.data
.Sprint_int:
	.string "%d\n"
.Sprint_str:
	.string "%s"
true:
	.string "true\n"
false:
	.string "false\n"
