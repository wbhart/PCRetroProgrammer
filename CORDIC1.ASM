   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA
   
   lo  DW 0
   xhi DW 0
   yhi DW 0

   .CODE

_cordic_mul PROC
   ; multiply ax.bh by K = cos(atan(1/8))
   ; top three bytes returned in ax.bh

   ; cos(atan(1/8)) ~= 16647660/256^3
   ;   16647660 = 256^3 - 2*256^2 + (4 + 2)*256 - (16 + 4)

   ; copy input into dl.cx and sign extend to dx.cx
   cwd
   mov dl, ah
   mov ch, al
   mov cl, bh

   ; multiply by 2 and subtract carry from ah (*)
   shl cx, 1
   rcl dx, 1
   sbb ah, 0

   ; subtract 2*256^2*val from input
   sub bh, ch
   sbb ax, dx

   ; add 2*256*val to input, sign extended at (*)
   add bh, dl
   adc al, dh
   adc ah, 0
   
   ; multiply by 2 and sub borrow from al (**)
   shl cx, 1
   rcl dx, 1
   jnc skip_adjust1
   sub ax, 0ffh
skip_adjust1:
   
   ; add 4*256*val to input
   add bh, dl
   adc al, dh
   adc ah, 0

   ; sub 4*val from input, sign extended at (**)
   sub bh, dh
   sbb ax, 0

   ; multiply by 4 and add carry to ax (***)
   shl dx, 1
   shl dx, 1
   adc ax, 0

   ; sub 16*val to input, sign extended at (***)
   sub bh, dh
   sbb ax, 0

   ret
_cordic_mul ENDP

_cordic PROC
   ; x_i = dx.bh, y_i = si.bl
   push si
   push di

   mov bx, [lo]
   mov dx, [xhi]
   mov si, [yhi]

   ; di.cl = y_i/8
   mov cx, bx
   mov di, si
   sar di, 1
   rcr cl, 1
   sar di, 1
   rcr cl, 1
   sar di, 1
   rcr cl, 1
   
   ; ax.bh = x_i - yi/8
   mov ax, dx
   sub bh, cl
   sbb ax, di

   ; dx.ch  = x_i/8
   sar dx, 1
   rcr ch, 1
   sar dx, 1
   rcr ch, 1
   sar dx, 1
   rcr ch, 1

   ; si.bl = x_i/8 + y_i
   add bl, ch
   adc si, dx

   ; multiply ax.bh by K
   call _cordic_mul

   ; write out result
   mov [xhi], ax
   xchg bl, bh

   ; multiply si.bl by K
   mov ax, si
   call _cordic_mul

   ; write result out
   xchg bh, bl
   mov [lo], bx
   mov [yhi], ax

   pop di
   pop si
   ret
_cordic ENDP

_cga_line PROC
   ARG x0:WORD, y0:WORD, x1:WORD, y1:WORD, colour:BYTE
   ; ax = accum, dx = 2dx, si = 2dy, bp = D, cx = iters
   ; di = offset, bl = mask, bh = colour

   push bp
   mov bp, sp
   push si
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; get x0 and x1
   mov dx, x1
   mov bx, x0

   ; compute dy
   mov ax, y0
   mov si, y1
   sub si, ax

   ; ensure y1 >= y0
   jge line_dy_nonneg
   xchg dx, bx
   add ax, si
   neg si
line_dy_nonneg:

   ; offset += 4*8192 if y0 odd
   xor di, di
   shr ax, 1
   rcr di, 1

   ; add 4*80*(y0/2) to offset
   xchg ah, al
   add di, ax
   shr ax, 1
   shr ax, 1
   add di, ax

   ; compute dx
   sub dx, bx

   jge line_right
   jmp line_left

line_right:

   ; compute x0 mod 4 and x0 / 4 and divide di by 4
   mov cx, bx
   and cl, 3
   add di, bx
   shr di, 1
   shr di, 1

   ; compute colour and mask
   mov bh, colour
   mov bl, 03fh
   shl cl, 1
   ror bl, cl
   inc cl
   inc cl
   ror bh, cl

   cmp dx, si
   jae line_hr

line_vr:

   ; compute iterations
   mov cx, si
   inc cx

   ; compute initial D
   mov bp, si
   neg bp

   ; compute 2dx and 2dy
   shl si, 1
   shl dx, 1

line_vr_loop:
   mov al, es:[di] ; get pixel
   and al, bl      ; and with mask
   or al, bh       ; or with colour
   stosb           ; write pixel

   add bp, dx      ; D += 2dx
   jle line_vr_skipx ; if D > 0

   ror bh, 1
   ror bh, 1
   ror bl, 1
   ror bl, 1
   cmc
   adc di, 0
   
   sub bp, si      ; D -= 2dy

line_vr_skipx:

   sub di, 8113    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   loop line_vr_loop

   pop di
   pop si
   pop bp
   ret

line_hr:

   ; compute iterations
   mov cx, dx
   inc cx

   ; compute initial D
   mov bp, dx
   neg bp

   ; compute 2dx and 2dy
   shl si, 1
   shl dx, 1

line_hr_loop:
   mov al, es:[di] ; get pixel
   and al, bl      ; and with mask
   or al, bh       ; or with colour
   stosb           ; write pixel

   add bp, si      ; D += 2dy
   jle line_hr_skipy  ; if D > 0

   sub di, 8112    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   sub bp, dx      ; D -= 2dx

line_hr_skipy:
   ror bh, 1
   ror bh, 1
   ror bl, 1
   ror bl, 1
   sbb di, 0

   loop line_hr_loop

   pop di
   pop si
   pop bp
   ret

line_left:
   neg dx

   std

   ; compute x0 mod 4 and x0 / 4 and divide di by 4
   mov cx, bx
   and cl, 3
   add di, bx
   shr di, 1
   shr di, 1

   ; compute colour and mask
   mov bh, colour
   mov bl, 03fh
   shl cl, 1
   ror bl, cl
   inc cl
   inc cl
   ror bh, cl

   cmp dx, si
   jae line_hl

line_vl:

   ; compute iterations
   mov cx, si
   inc cx

   ; compute initial D
   mov bp, si
   neg bp

   ; compute 2dx and 2dy
   shl si, 1
   shl dx, 1

line_vl_loop:
   mov al, es:[di] ; get pixel
   and al, bl      ; and with mask
   or al, bh       ; or with colour
   stosb           ; write pixel

   add bp, dx      ; D += 2dx
   jle line_vl_skipx ; if D > 0

   rol bh, 1
   rol bh, 1
   rol bl, 1
   rol bl, 1
   cmc
   sbb di, 0
   
   sub bp, si      ; D -= 2dy

line_vl_skipx:

   sub di, 8111    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   loop line_vl_loop

   cld

   pop di
   pop si
   pop bp
   ret

line_hl:

   ; compute iterations
   mov cx, dx
   inc cx

   ; compute initial D
   mov bp, dx
   neg bp

   ; compute 2dx and 2dy
   shl si, 1
   shl dx, 1

line_hl_loop:
   mov al, es:[di] ; get pixel
   and al, bl      ; and with mask
   or al, bh       ; or with colour
   stosb           ; write pixel

   add bp, si      ; D += 2dy
   jle line_hl_skipy  ; if D > 0

   sub di, 8112    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   sub bp, dx      ; D -= 2dx

line_hl_skipy:
   rol bh, 1
   rol bh, 1
   rol bl, 1
   rol bl, 1
   adc di, 0

   loop line_hl_loop

   cld

   pop di
   pop si
   pop bp
   ret
_cga_line ENDP
   
start:
   ; set video mode = 4 (CGA 320x200x4)
   xor ah, ah
   mov al, 4
   int 10h

   ; initial coordinates
   mov WORD PTR [lo], 0
   mov WORD PTR [xhi], 100*256
   mov WORD PTR [yhi], 0

   mov si, 10000

rotate_loop:
   ; round up coordinates
   mov ax, [xhi]
   add ax, 080h
   mov bx, [yhi]
   add bx, 080h

   mov al, ah
   cbw
   xchg ax, bx
   mov al, ah
   cbw

   ; shift center to 150, 100
   add bx, 150
   add ax, 100

   ; save coordinates
   mov dh, bl
   mov dl, al
   mov di, dx

   mov cx, 2   ; colour = 2
   push cx
   push ax                       ; y
   push bx                       ; x
   xor al, al
   mov ax, 100
   push ax
   mov ax, 150
   push ax
   call _cga_line
   add sp, 10

   call _cordic

   ; restore coordinates
   mov dx, di
   xor bx, bx
   mov bl, dh
   xor ax, ax
   mov al, dl

   mov di, 10000
delay:
   dec di
   jnz delay

   mov cx, 0   ; colour = 0
   push cx
   push ax                          ; y
   push bx                          ; x
   mov ax, 100
   push ax
   mov ax, 150
   push ax
   call _cga_line
   add sp, 10

   dec si
   jnz rotate_loop

   ; wait for keypress
   xor ah, ah
   int 16h
   
   ; restore video mode
   xor ah, ah
   mov al, 3
   int 10h

   mov  ah, 4ch ; terminate program
   int  21h
   END start
         
