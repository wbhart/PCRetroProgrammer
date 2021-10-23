   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

_cga_line PROC
   ARG x0:WORD, y0:WORD, x1:WORD, y1:WORD, colour:BYTE
   ; assumes down-right or up-left
   
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
_cga_line ENDP
   
start:
   ; set video mode = 4 (CGA 320x200x4)
   xor ah, ah
   mov al, 4
   int 10h

   mov si, 199

vline_loop:
   xor ah, ah
   mov al, 2   ; colour = 2
   push ax
   mov al, 199 ; y1 = 199
   push ax
   push si     ; x1 = 199..0
   xor al, al
   push ax     ; y0 = 0
   push ax     ; x0 = 0
   call _cga_line
   add sp, 10

   dec si
   jge vline_loop

   mov si, 199

hline_loop:
   xor ah, ah
   mov al, 2   ; colour = 2
   push ax
   push si     ; y1 = 199..0
   mov al, 199 ; x1 = 199
   push ax
   xor al, al
   push ax     ; y0 = 0
   push ax     ; x0 = 0
   call _cga_line
   add sp, 10

   dec si
   jge hline_loop

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
