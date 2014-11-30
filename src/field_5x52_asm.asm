	;; Added by Diederik Huys, March 2013
	;;
	;; Provided public procedures:
	;; 	secp256k1_fe_mul_inner
	;; 	secp256k1_fe_sqr_inner
	;;
	;; Needed tools: YASM (http://yasm.tortall.net)
	;;
	;; 

	BITS 64

%ifidn   __OUTPUT_FORMAT__,macho64
%define SYM(x) _ %+ x
%else
%define SYM(x) x
%endif

	;;  Procedure ExSetMult
	;;  Register Layout:
	;;  INPUT: 	rdi	= a->n
	;; 	   	rsi  	= b->n
	;; 	   	rdx  	= r->a
	;; 
	;;  INTERNAL:	rdx:rax  = multiplication accumulator
	;; 		r9:r8    = c
	;; 		r10-r13  = t0-t3
	;; 		r14	 = b.n[0] / t4
	;; 		r15	 = b.n[1] / t5
	;; 		rbx	 = b.n[2] / t6
	;; 		rcx	 = b.n[3] / t7
	;; 		rbp	 = Constant 0FFFFFFFFFFFFFh / t8
	;; 		rsi	 = b.n / b.n[4] / t9

	GLOBAL SYM(secp256k1_fe_mul_inner)
	ALIGN 32
SYM(secp256k1_fe_mul_inner):
	push rbp
	push rbx
	push r12
	push r13
	push r14
	push r15
	push rdx
	mov r14,[rsi+8*0]	; preload b.n[0]. This will be the case until
				; b.n[0] is no longer needed, then we reassign
				; r14 to t4
	;; c=a.n[0] * b.n[0]
   	mov rax,[rdi+0*8]	; load a.n[0]
	mov rbp,0FFFFFFFFFFFFFh
	mul r14			; rdx:rax=a.n[0]*b.n[0]
	mov r15,[rsi+1*8]
	mov r10,rbp		; load modulus into target register for t0
	mov r8,rax
	and r10,rax		; only need lower qword of c
	shrd r8,rdx,52
	xor r9,r9		; c < 2^64, so we ditch the HO part 

	;; c+=a.n[0] * b.n[1] + a.n[1] * b.n[0]
	mov rax,[rdi+0*8]
	mul r15			
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul r14			
	mov r11,rbp
	mov rbx,[rsi+2*8]
	add r8,rax
	adc r9,rdx
	and r11,r8
	shrd r8,r9,52
	xor r9,r9
	
	;; c+=a.n[0 1 2] * b.n[2 1 0]
	mov rax,[rdi+0*8]
	mul rbx			
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul r15			
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul r14
	mov r12,rbp		
	mov rcx,[rsi+3*8]
	add r8,rax
	adc r9,rdx
	and r12,r8		
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[0 1 2 3] * b.n[3 2 1 0]
	mov rax,[rdi+0*8]
	mul rcx			
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul rbx			
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul r15			
	add r8,rax
	adc r9,rdx
	
	mov rax,[rdi+3*8]
	mul r14			
	mov r13,rbp             
	mov rsi,[rsi+4*8]	; load b.n[4] and destroy pointer
	add r8,rax
	adc r9,rdx
	and r13,r8

	shrd r8,r9,52
	xor r9,r9		


	;; c+=a.n[0 1 2 3 4] * b.n[4 3 2 1 0]
	mov rax,[rdi+0*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+1*8]
	mul rcx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul rbx			
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+3*8]
	mul r15			
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul r14			
	mov r14,rbp             ; load modulus into t4 and destroy a.n[0]
	add r8,rax
	adc r9,rdx
	and r14,r8
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[1 2 3 4] * b.n[4 3 2 1]
	mov rax,[rdi+1*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+2*8]
	mul rcx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+3*8]
	mul rbx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul r15
	mov r15,rbp		
	add r8,rax
	adc r9,rdx

	and r15,r8
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[2 3 4] * b.n[4 3 2]
	mov rax,[rdi+2*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+3*8]
	mul rcx
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul rbx
	mov rbx,rbp		
	add r8,rax
	adc r9,rdx

	and rbx,r8		
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[3 4] * b.n[4 3]
	mov rax,[rdi+3*8]
	mul rsi
	add r8,rax
	adc r9,rdx

	mov rax,[rdi+4*8]
	mul rcx
	mov rcx,rbp		
	add r8,rax
	adc r9,rdx
	and rcx,r8		
	shrd r8,r9,52
	xor r9,r9		

	;; c+=a.n[4] * b.n[4]
	mov rax,[rdi+4*8]
	mul rsi
	;; mov rbp,rbp		; modulus already there!
	add r8,rax
	adc r9,rdx
	and rbp,r8 
	shrd r8,r9,52
	xor r9,r9		

	mov rsi,r8		; load c into t9 and destroy b.n[4]

	mov rdi,01000003D10h	; load constant

	mov rax,r15		; get t5
	mul rdi
	add rax,r10    		; +t0
	adc rdx,0
	mov r10,0FFFFFFFFFFFFFh ; modulus. Sadly, we ran out of registers!
	mov r8,rax		; +c
	and r10,rax
	shrd r8,rdx,52
	xor r9,r9

	mov rax,rbx		; get t6
	mul rdi
	add rax,r11		; +t1
	adc rdx,0
	mov r11,0FFFFFFFFFFFFFh ; modulus
	add r8,rax		; +c
	adc r9,rdx
	and r11,r8
	shrd r8,r9,52
	xor r9,r9

	mov rax,rcx    		; get t7
	mul rdi
	add rax,r12		; +t2
	adc rdx,0
	pop rbx			; retrieve pointer to this.n	
	mov r12,0FFFFFFFFFFFFFh ; modulus
	add r8,rax		; +c
	adc r9,rdx
	and r12,r8
	mov [rbx+2*8],r12	; mov into this.n[2]
	shrd r8,r9,52
	xor r9,r9
	
	mov rax,rbp    		; get t8
	mul rdi
	add rax,r13    		; +t3
	adc rdx,0
	mov r13,0FFFFFFFFFFFFFh ; modulus
	add r8,rax		; +c
	adc r9,rdx
	and r13,r8
	mov [rbx+3*8],r13	; -> this.n[3]
	shrd r8,r9,52
	xor r9,r9
	
	mov rax,rsi    		; get t9
	mul rdi
	add rax,r14    		; +t4
	adc rdx,0
	mov r14,0FFFFFFFFFFFFh	; !!!
	add r8,rax		; +c
	adc r9,rdx
	and r14,r8
	mov [rbx+4*8],r14	; -> this.n[4]
	shrd r8,r9,48		; !!!
	xor r9,r9
	
	mov rax,01000003D1h
	mul r8		
	add rax,r10
	adc rdx,0
	mov r10,0FFFFFFFFFFFFFh ; modulus
	mov r8,rax
	and rax,r10
	shrd r8,rdx,52
	mov [rbx+0*8],rax	; -> this.n[0]
	add r8,r11
	mov [rbx+1*8],r8	; -> this.n[1]

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret

	
	;;  PROC ExSetSquare
	;;  Register Layout:
	;;  INPUT: 	rdi	 = a.n
	;; 	   	rsi  	 = r.n
	;;  INTERNAL:	rdx:rax  = multiplication accumulator
	;; 		r9:r8    = c
	;;		r10:r14  = a0-a4
	;;		rcx:rbx  = d
	;; 		rbp	 = R
	;; 		rdi	 = t?
	;;		r15	 = M
	GLOBAL SYM(secp256k1_fe_sqr_inner)
	ALIGN 32
SYM(secp256k1_fe_sqr_inner):
	push rbp
	push rbx
	push r12
	push r13
	push r14
	push r15
	mov r10,[rdi+0*8]
	mov r11,[rdi+1*8]
	mov r12,[rdi+2*8]
	mov r13,[rdi+3*8]
	mov r14,[rdi+4*8]
	mov rbp,01000003D10h
	mov r15,0fffffffffffffh

	;; d = (a0*2) * a3
	lea rax,[r10*2]
	mul r13
	mov rbx,rax
	mov rcx,rdx
	;; d += (a1*2) * a2
	lea rax,[r11*2]
	mul r12
	add rbx,rax
	adc rcx,rdx
	;; c = [4]*[4]
	mov rax,r14
	mul r14
	mov r8,rax
	mov r9,rdx
	;; d += (c & M) * R
	and rax,r15
	mul rbp
	add rbx,rax
	adc rcx,rdx
	;; c >>= 52 (r8 only)
	shrd r8,r9,52
	;; t3 (stack) = d & M
	mov rdi,rbx
	and rdi,r15
	push rdi
	;; d >>= 52
	shrd rbx,rcx,52
	mov rcx,0
	;; a4 *= 2
	add r14,r14
	;; d += a0 * a4
	mov rax,r10
	mul r14
	add rbx,rax
	adc rcx,rdx
	;; d+= (a1*2) * a3
	lea rax,[r11*2]
	mul r13
	add rbx,rax
	adc rcx,rdx
	;; d += a2 * a2
	mov rax,r12
	mul r12
	add rbx,rax
	adc rcx,rdx
	;; d += c * R
	mov rax,r8
	mul rbp
	add rbx,rax
	adc rcx,rdx
	;; t4 = d & M (rdi)
	mov rdi,rbx
	and rdi,r15
	;; d >>= 52
	shrd rbx,rcx,52
	mov rcx,0
	;; tx = t4 >> 48 (rbp, overwrites constant)
	mov rbp,rdi
	shr rbp,48
	;; t4 &= (M >> 4) (stack)
	mov rax,0ffffffffffffh
	and rdi,rax
	push rdi
	;; c = a0 * a0
	mov rax,r10
	mul r10
	mov r8,rax
	mov r9,rdx
	;; d += a1 * a4
	mov rax,r11
	mul r14
	add rbx,rax
	adc rcx,rdx
	;; d += (a2*2) * a3
	lea rax,[r12*2]
	mul r13
	add rbx,rax
	adc rcx,rdx
	;; u0 = d & M (rdi)
	mov rdi,rbx
	and rdi,r15
	;; d >>= 52
	shrd rbx,rcx,52
	mov rcx,0
	;; u0 = (u0 << 4) | tx (rdi)
	shl rdi,4
	or rdi,rbp
	;; c += u0 * (R >> 4)
	mov rax,01000003D1h
	mul rdi
	add r8,rax
	adc r9,rdx
	;; r[0] = c & M
	mov rax,r8
	and rax,r15
	mov [rsi+0*8],rax
	;; c >>= 52
	shrd r8,r9,52
	mov r9,0
	;; a0 *= 2
	add r10,r10
	;; c += a0 * a1
	mov rax,r10
	mul r11
	add r8,rax
	adc r9,rdx
	;; d += a2 * a4
	mov rax,r12
	mul r14
	add rbx,rax
	adc rcx,rdx
	;; d += a3 * a3
	mov rax,r13
	mul r13
	add rbx,rax
	adc rcx,rdx
	;; load R in rbp
	mov rbp,01000003D10h
	;; c += (d & M) * R
	mov rax,rbx
	and rax,r15
	mul rbp
	add r8,rax
	adc r9,rdx
	;; d >>= 52
	shrd rbx,rcx,52
	mov rcx,0
	;; r[1] = c & M
	mov rax,r8
	and rax,r15
	mov [rsi+8*1],rax
	;; c >>= 52
	shrd r8,r9,52
	mov r9,0
	;; c += a0 * a2 (last use of r10)
	mov rax,r10
	mul r12
	add r8,rax
	adc r9,rdx
	;; fetch t3 (r10, overwrites a0),t4 (rdi)
	pop rdi
	pop r10
	;; c += a1 * a1
	mov rax,r11
	mul r11
	add r8,rax
	adc r9,rdx
	;; d += a3 * a4
	mov rax,r13
	mul r14
	add rbx,rax
	adc rcx,rdx
	;; c += (d & M) * R
	mov rax,rbx
	and rax,r15
	mul rbp
	add r8,rax
	adc r9,rdx
	;; d >>= 52 (rbx only)
	shrd rbx,rcx,52
	;; r[2] = c & M
	mov rax,r8
	and rax,r15
	mov [rsi+2*8],rax
	;; c >>= 52
	shrd r8,r9,52
	mov r9,0
	;; c += t3
	add r8,r10
	;; c += d * R
	mov rax,rbx
	mul rbp
	add r8,rax
	adc r9,rdx
	;; r[3] = c & M
	mov rax,r8
	and rax,r15
	mov [rsi+3*8],rax
	;; c >>= 52 (r8 only)
	shrd r8,r9,52
	;; c += t4 (r8 only)
	add r8,rdi
	;; r[4] = c
	mov [rsi+4*8],r8

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret
