/*
 * Bencode implementation in x64 assembly (AT&T flavour)
 *
 * Copyright (c) 2015 Ahmed Samy  <f.fallen45@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

/*
	To understand this, mov yourself to the end of the file
	then read it backwards

	To use this, define the function hash_str(const char *str)
	and see bencode_decode()
*/

	.text
/*
	uint64_t bencode_readintuntil(const void *data, size_t size,
		size_t *current_pos, const uint8_t until);
*/
.type bencode_readintuntil, @function
bencode_readintuntil:
	/* Find first occurence of that byte  */
	movq	(%rdx), %rax
	movzbl	%cl, %ecx
	cmpq	%rsi, %rax
	jb	search
	jmp	toomuch

cntsearch:
	addq	$1, %rax
	cmpq	%rax, %rsi
	jbe	toomuch

search:
	movsbl	(%rdi, %rax, 4), %r8d
	cmpl	%ecx, %r8d
	jne	cntsearch

foundmatch:
	addq	$1, %rax
	movq	%rax, (%rdx)
	addq	%rax, %rdi
	xorq	%rax, %rax
	jmp	atoi

toomuch:
	movsbl	(%rdi, %rax), %esi
	cmpl	%ecx, %esi
	je	foundmatch
	movl	$-1, %eax
	ret

/*
	char *bencode_readstr(const void *data, size_t size, size_t *current_pos)
*/
.type bencode_readstr, @function
bencode_readstr:
	pushq	%rbx
	pushq	%r8

	/* Read length  */
	movq	$0x3A, %rcx		/* ':'  */
	xorq	%rax, %rax
	call	bencode_readintuntil
	testq	%rax, %rax
	jz	gooutside

	/* Check if length + current_pos would exceed size  */
	movq	(%rdx), %rbx
	movq	%rbx, %r8
	addq	%rax, %r8
	cmpq	%r8, %rsi
	jg	gooutside

	movq	(%rdi, %rbx, 8), %rax
	movq	%r8, (%rdx)

gooutside:
	popq	%r8
	popq	%rbx

	ret

/*
	uint8_t bencode_unpack_byte(const void *data, size_t size, size_t *cpos)
*/
.type bencode_unpack_byte, @function
bencode_unpack_byte:
	movq	(%rdx), %r8
	cmpq	%rsi, %r8
	ja	outofdata

	movzbl	(%rdi, %rcx, 4), %eax
	ret

outofdata:
	xorl	%eax, %eax
	ret

/*
	void *bencode_readvec(const void *data, size_t size, size_t *cpos, void *htable)
*/
.type bencode_readvec, @function
bencode_readvec:
	ret

/*
	void *bencode_readict(const void *data, size_t size, size_t *cpos, void *htable)
*/
.type bencode_readict, @function
bencode_readict:
	pushq	%rcx
	pushq	%r8

forever:
	/* Read key  */
	call	bencode_readstr
	testq	%rax, %rax
	jz 	failure
	movq	%rax, %r8

	/* Hashed string in %r8  */
	pushq	%rdi
	movq	%rax, %rdi
	call	hash_str
	popq	%rdi
	movq	%rax, %r8

	call	bencode_unpack_byte
	testl	%eax, %eax
	jz	failure

	cmpb	$0x69, %al		/* int?  */
	je	case_int

	cmpb	$0x6C, %al		/* list?  */
	je	case_list

	cmpb	$0x64, %al		/* another dictionary?  */
	je	case_dict

case_int:
	movq	$0x65, %rcx
	xorq	%rax, %rax
	call	bencode_readintuntil
	testq	%rax, %rax
	jz	failure
	jmp	actuallyaddit

case_list:
	call 	bencode_readvec

case_dict:
	pushq	%rsi
	call	htable_init
	pushq	%rdi
	movq	%rax, %rdi
	call	bencode_readict
	popq	%rdi

actuallyaddit:
	/* Give htable_add the arguments it needs in the appropriate
	 * registers.  */
	pushq	%rdi
	movq	%rcx, %rdi
	pushq	%rsi
	movq	%r8, %rsi
	pushq	%rdx
	movq	%rax, %rdx
	call	htable_add

	popq	%rdx
	popq	%rsi
	popq	%rdi
	jmp	forever

failure:
	xorq	%rax, %rax
	popq	%r8
	popq	%rcx
	movq	%rcx, %rdi
	call	free
	xorq	%rcx, %rcx
	ret

/*
	void *bencode_decode(const void *data, size_t size)
	Returns a hashtable with all the data decoded.
	Use htable_free() to free the data.
 */
.globl bencode_decode
	.type bencode_decode, @function
bencode_decode:
	movzbl	(%rdi), %eax
	cmpb	$0x64, %al	/* Lowercase d  */
	jne	failure

	call	htable_init
	testq	%rax, %rax
	je 	htable_failed

	/* We have to use the stack for this,
	 * or a global variable but this is not our intention,
	 * or yet anther data structure, which is not worth it.  */
	subq	$24, %rsp		/* Pad all day long  */
	movq	$1, 12(%rsp)		/* Start at 1, we already tested that there's a dictionary.  */
	leaq	12(%rsp), %rdx		/* Le current position.  */
	movq	%rax, %rcx		/* Le hashtable  */
	call	bencode_readict
	addq	$24, %rsp
	ret

htable_failed:
	xorq	%rax, %rax
	ret

/* vim: set ft=gas:  */

