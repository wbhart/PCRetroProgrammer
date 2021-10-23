   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

_cga_line PROC
   ARG x0:WORD, y0:WORD, x1:WORD, y1:WORD, colour:BYTE
   ; assumes x1 >= x0, y1 >= y0, dx >= dy
   
   ; ax = accum, dx = 2dx, bp = 2dy, si = D, cx = iters
   ; di = offset, bl = mask, bh = colour

   push bp
   mov bp, sp
   push si
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; compute dx
   mov dx, x1
   mov di, x0
   sub dx, di

   ; compute x0 mod 4 and x0 / 4
   mov cx, di
   and cl, 3
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

   ; compute iterations
   mov cx, dx
   inc cx

   ; compute 2dy
   mov ax, y0
   mov bp, y1
   sub bp, ax
   shl bp, 1

   ; offset += 8192 if y0 odd
   shr ax, 1
   jnc line_even
   add di, 8192
line_even:

   ; add 80*(y0/2) to offset
   shl ax, 1
   shl ax, 1
   shl ax, 1
   shl ax, 1
   add di, ax
   shl ax, 1
   shl ax, 1
   add di, ax

   ; compute initial D
   mov si, dx
   neg si

   ; compute 2*dx
   shl dx, 1

line_loop:
   mov al, es:[di] ; get pixel
   and al, bl      ; and with mask
   or al, bh       ; or with colour
   stosb           ; write pixel

   add si, bp      ; D += 2dy
   jle line_skipy  ; if D > 0

   sub di, 8112    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   sub si, dx      ; D -= 2dx

line_skipy:
   ror bh, 1
   ror bh, 1
   ror bl, 1
   ror bl, 1
   sbb di, 0

   loop line_loop

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

   mov al, 2   ; colour = 2
   push ax
   xor ah, ah
   mov al, 100 ; y1 = 100
   push ax
   mov al, 200 ; x1 = 200
   push ax
   xor al, al
   push ax     ; y0 = 0
   push ax     ; x0 = 0
   call _cga_line
   add sp, 10

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
