/*
 * Bencode implementation in x64 assembly (AT&T flavour)
 * Simple dynamically-allocated vector implementation
 *
 * Copyright (c) 2015 Ahmed Samy  <f.fallen45@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
#define INITIAL_VEC_SPACE	5
	.text
/*
	#00	data
	#08	current
	#16	size

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

