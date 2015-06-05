/*
 * Bencode implementation in x64 assembly (AT&T flavour)
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

	.text
/*
	uint64_t bencode_readintuntil(const void *data, size_t size,
		size_t *current_pos, const uint8_t until);
*/
.type bencode_readintuntil, @function
bencode_readintuntil:
	/* Find first occurence of that byte  */
	pushq	%rbx
	movq	(%rdx), %rbx	/* *current_pos  */

loopdata:
	cmpq	%rbx, %rsi
	jge	rip		/* Already exceeded length and found nothing  */

	movzbl	(%rdi, %rbx, 4), %eax
	cmpb	%al, %cl
	je	foundmatch

	incq	%rcx
	jmp	loopdata

foundmatch:
	movq	(%rdi, %rbx, 8), %rax

rip:
	popq	%rbx
	ret

/*
	char *bencode_readstr(const void *data, size_t size, size_t *current_pos)
*/
.type bencode_readstr, @function
bencode_readstr:
	pushq	%rcx
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
	popq	%rcx

	ret

/*
	__bencode_decode(void *htable, const void *data)
*/
.type __bencode_decode, @function
__bencode_decode:

/*
	void *bencode_decode(const void *data, size_t size)
	Returns a hashtable with all the data decoded.
	Use htable_free() to free the data.
 */
.globl bencode_decode
	.type bencode_decode, @function
bencode_decode:
	movzbl	(%rdi), %eax
	cmpb	$100, %al	/* Lowercase d  */
	jne	failure

	call	htable_init
	testq	%rax, %rax
	je 	failure

	movq	%rdi, %rsi
	movq	%rax, %rdi
	call	__bencode_decode
	ret

failure:
	xorq	%rax, %rax
	ret

