   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

_cga_circle PROC
   ARG x0:WORD, y0:WORD, r:WORD, colour:BYTE
   
   ; ax = accum, si = dx, bp = dy, cx = D, bx = offset diff
   ; di = offset, dl = mask, dh = colour

   push bp
   mov bp, sp
   push si
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   push bp

   ; right arc of circle

   ; compute y offset
   mov ax, y0
   
   ; offset += 4*8192 if y0 odd
   xor di, di
   shr ax, 1
   rcr di, 1

   ; get r
   mov si, r
   mov di, x0

   ; compute (x0 + r) mod 4 and 4*(x0 + r) / 4
   add di, si
   mov cx, di
   and cl, 3

   ; compute colour and mask
   mov dh, colour
   mov dl, 03fh
   shl cl, 1
   ror dl, cl
   inc cl
   inc cl
   ror dh, cl

   ; add 4*80*(y0/2) to offset
   xchg ah, al
   add di, ax
   shr ax, 1
   shr ax, 1
   add di, ax
   shr di, 1
   shr di, 1

   ; compute initial D and dx
   mov cx, 1
   sub cx, si
   shl si, 1

   ; compute dy
   xor bp, bp

   xor bx, bx      ; offset diff = 0

circle_loop1:
   mov al, es:[di+bx] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   mov es:[di+bx], al ; write pixel

   mov al, es:[di] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   stosb           ; write pixel

   cmp cx, 0       ; if D >= 0
   jl circle_skipy1

   rol dh, 1       ; dec x
   rol dh, 1
   rol dl, 1
   rol dl, 1
   cmc
   sbb di, 0

   dec si          ; dx -= 2
   dec si
   
   sub cx, si      ; D -= dx

circle_skipy1:
   sub di, 8113    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   sub bx, 80      ; increase offset diff

   inc bp          ; dy += 2
   inc bp
   
   add cx, bp      ; D += dy + 1
   inc cx

   cmp si, bp
   jge circle_loop1

   pop bp
   push bp

   ; left arc of circle

   ; compute y offset
   mov ax, y0
   
   ; offset += 4*8192 if y0 odd
   xor di, di
   shr ax, 1
   rcr di, 1

   ; get r
   mov si, r
   mov di, x0

   ; compute (x0 - r) mod 4 and 4*(x0 - r) / 4
   sub di, si
   mov cx, di
   and cl, 3

   ; compute colour and mask
   mov dh, colour
   mov dl, 03fh
   shl cl, 1
   ror dl, cl
   inc cl
   inc cl
   ror dh, cl

   ; add 4*80*(y0/2) to offset
   xchg ah, al
   add di, ax
   shr ax, 1
   shr ax, 1
   add di, ax
   shr di, 1
   shr di, 1

   ; compute initial D and dx
   mov cx, 1
   sub cx, si
   shl si, 1

   ; compute dy
   xor bp, bp

   xor bx, bx      ; offset diff = 0

circle_loop2:
   mov al, es:[di+bx] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   mov es:[di+bx], al ; write pixel

   mov al, es:[di] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   stosb           ; write pixel

   cmp cx, 0       ; if D >= 0
   jl circle_skipy2

   ror dh, 1       ; inc x
   ror dh, 1
   ror dl, 1
   ror dl, 1
   cmc
   adc di, 0

   dec si          ; dx -= 2
   dec si
   
   sub cx, si      ; D -= dx

circle_skipy2:
   sub di, 8113    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   sub bx, 80      ; increase offset diff

   inc bp          ; dy += 2
   inc bp
   
   add cx, bp      ; D += dy + 1
   inc cx

   cmp si, bp
   jge circle_loop2

   ; left top and bottom arcs of circle

   pop bp
   push bp

   ; get r
   mov si, r

   ; compute y offset
   mov ax, y0
   sub ax, si

   ; offset += 4*8192 if y0 odd
   xor di, di
   shr ax, 1
   rcr di, 1

   ; compute x0 mod 4 and 4*x0 / 4
   mov cx, x0
   add di, cx
   and cl, 3

   ; compute colour and mask
   mov dh, colour
   mov dl, 03fh
   shl cl, 1
   ror dl, cl
   inc cl
   inc cl
   ror dh, cl

   ; add 4*80*((y0 - r)/2) to offset
   xchg ah, al
   add di, ax
   shr ax, 1
   shr ax, 1
   add di, ax
   shr di, 1
   shr di, 1

   ; save offset, colour and mask bytes
   push di
   push dx

   ; compute initial D
   mov cx, 1
   sub cx, si

   ; compute offset diff = 80*r
   mov bx, si
   shl bx, 1
   shl bx, 1
   shl bx, 1
   shl bx, 1
   mov ax, bx
   shl bx, 1
   shl bx, 1
   add bx, ax

   ; compute dy
   xor bp, bp

   ; compute dx
   shl si, 1

   std

circle_loop3:
   mov al, es:[di+bx] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   mov es:[di+bx], al ; write pixel

   mov al, es:[di] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   stosb           ; write pixel

   cmp cx, 0       ; if D >= 0
   jl circle_skipy3

   sub di, 8112    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   sub bx, 80      ; decrease offset diff

   dec si          ; dx -= 2
   dec si
   
   sub cx, si      ; D -= dx

circle_skipy3:
   rol dh, 1       ; dec x
   rol dh, 1
   rol dl, 1
   rol dl, 1
   adc di, 0
   
   inc bp          ; dy += 2
   inc bp
   
   add cx, bp      ; D += dy + 1
   inc cx

   cmp si, bp
   jge circle_loop3

   cld

   ; restore offset, colour and mask bytes
   pop dx
   pop di

   pop bp

   ; get r
   mov si, r

   ; compute initial D
   mov cx, 1
   sub cx, si

   ; compute offset diff = 80*r
   mov bx, si
   shl bx, 1
   shl bx, 1
   shl bx, 1
   shl bx, 1
   mov ax, bx
   shl bx, 1
   shl bx, 1
   add bx, ax

   ; compute dy
   xor bp, bp

   ; compute dx
   shl si, 1

circle_loop4:
   mov al, es:[di+bx] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   mov es:[di+bx], al ; write pixel

   mov al, es:[di] ; get pixel
   and al, dl      ; and with mask
   or al, dh       ; or with colour
   stosb           ; write pixel

   cmp cx, 0       ; if D >= 0
   jl circle_skipy4

   sub di, 8112    ; increment y
   sbb ax, ax
   and ax, 16304
   add di, ax

   sub bx, 80      ; decrease offset diff

   dec si          ; dx -= 2
   dec si
   
   sub cx, si      ; D -= dx

circle_skipy4:
   ror dh, 1       ; inc x
   ror dh, 1
   ror dl, 1
   ror dl, 1
   sbb di, 0
   
   inc bp          ; dy += 2
   inc bp
   
   add cx, bp      ; D += dy + 1
   inc cx

   cmp si, bp
   jge circle_loop4

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
