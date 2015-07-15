/*
 * Bencode implementation in x64 assembly (AT&T flavour)
 * Simple dynamically-allocated vector implementation
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

#define INITIAL_VEC_SPACE	5
	.text
/*
	#00	data
	#08	size
	#16	capacity

	Note: Code written with a potatoe.  Proceed with caution.
*/
.globl vec_init
	.type vec_init, @function
vec_init:
	pushq	%rbx

	movl	$24, %edi
	call	malloc
	testq	%rax, %rax
	je	failure
	movq	%rax, %rbx

	movl	$8, %esi
	movl	$INITIAL_VEC_SPACE, %edi
	call	calloc
	testq	%rax, %rax
	je	vec_failure

	movq	%rax, (%rbx)
	movq	$0, 8(%rbx)
	movq	$INITIAL_VEC_SPACE, 16(%rbx)

	movq	%rbx, %rax
	popq	%rbx
	ret

vec_failure:
	movq	%rbx, %rdi
	call	free

failure:
	popq	%rbx
	ret

.globl vec_free
	.type vec_free, @function
vec_free:
	pushq	%rsi

	movq	%rdi, %rsi
	movq	(%rdi), %rdi
	call	free

	movq	%rsi, %rdi
	call	free

	popq	%rsi
	ret

/*
	void vec_push(void *vec, const void *p)
*/
.globl vec_push
	.type vec_push, @function
vec_push:
	movq	8(%rdi), %rax
	incq	%rax
	cmpq	16(%rdi), %rax
	jz	do_expand_vec

doaddit:
	movq	(%rdi), %rdx
	movq	8(%rdi), %rax
	movq	%rsi, (%rdx, %rax, 8)
	incq	8(%rdi)
	ret

do_expand_vec:
	addq	$INITIAL_VEC_SPACE, %rax
	pushq	%rsi
	movq	$8, %rsi
	mulq	%rsi
	movq	%rax, %rsi

	pushq	%rdi
	movq	(%rdi), %rdi
	call	realloc
	testq	%rax, %rax
	jz	restinpeace

	popq	%rdi
	popq	%rsi
	movq	%rax, (%rdi)
	jmp	doaddit

restinpeace:
	popq	%rdi
	popq	%rsi
	xorq	%rax, %rax
	ret

.globl vec_at
	.type vec_at, @function
vec_at:
	movq	(%rdi), %rax
	movq	(%rax, %rsi, 8), %rax
	ret

