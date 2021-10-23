   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

_cga_circle PROC
   ARG x0:WORD, y0:WORD, r:WORD, colour:BYTE
   
   ; ax = accum, dx = dx, bp = dy, si = D
   ; di = offset, bl = mask, bh = colour

   push bp
   mov bp, sp
   push si
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; get r
   mov dx, r
   mov di, dx

   ; compute (x0 + r) mod 4 and (x0 + r) / 4
   add di, x0
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

   ; compute y offset
   mov ax, y0

   ; offset += 8192 if y0 odd
   shr ax, 1
   sbb si, si
   and si, 8192
   add di, si

   ; add 80*(y0/2) to offset
   shl ax, 1
   shl ax, 1
   shl ax, 1
   shl ax, 1
   add di, ax
   shl ax, 1
   shl ax, 1
   add di, ax

   ; compute initial D and dx
   mov si, dx
   neg si
   shl dx, 1

   ; compute dy
   xor bp, bp

circle_loop:
   mov al, es:[di] ; get pixel
   and al, bl      ; and with mask
   or al, bh       ; or with colour
   stosb           ; write pixel

   add si, bp      ; D += dy + 1
   inc si
   
   jl circle_skipy ; if D >= 0

   rol bh, 1       ; dec x
   rol bh, 1
   rol bl, 1
   rol bl, 1
   cmc
   sbb di, 0

   dec dx          ; dx -= 2
   dec dx
   
   sub si, dx      ; D -= dx

circle_skipy:
   sub di, 8113    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   inc bp          ; dy += 2
   inc bp
   
   cmp dx, bp
   jge circle_loop

   pop di
   pop si
   pop bp
   ret
_cga_circle ENDP
   
start:
   ; set video mode = 4 (CGA 320x200x4)
   xor ah, ah
   mov al, 4
   int 10h

   mov al, 2   ; colour = 2
   push ax
   xor ah, ah
   mov al, 50  ; r = 50
   push ax
   mov al, 100 ; y0 = 100
   push ax
   mov al, 100 ; x0 = 100
   push ax
   call _cga_circle
   add sp, 8

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
