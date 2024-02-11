   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

_cga_ellipse PROC
   ARG x0:WORD, y0:WORD, r:WORD, s:WORD, colour:BYTE
   
   ; ax = accum, dh:si = D, dl:bx = dx, cl:bp = dy
   ; di = offset, ch = mask

   push bp
   mov bp, sp
   push si
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   mov al, colour
   mov ah, al
   shl al, 1
   shl al, 1
   add al, ah
   shl al, 1
   shl al, 1
   add al, ah
   shl al, 1
   shl al, 1
   add al, ah

   mov BYTE PTR cs:[ellipse_colour1+1], al
   mov BYTE PTR cs:[ellipse_colour2+1], al

   ; compute x0 + r
   mov di, x0
   mov bx, r            ; save r
   add di, bx 

   ; compute x0 + r mod 4 and x0 + r
   mov cx, di
   and cl, 3

   ; compute mask
   mov ch, 03h
   shl cl, 1
   inc cl
   inc cl
   ror ch, cl

   ; compute y0 offset
   mov ax, y0

   ; offset += 4*8192 if y0 odd
   shr ax, 1
   jnc scanline_even
   add di, 32768
scanline_even:

   ; add 4*80*(y0/2) to offset
   xchg ah, al
   add di, ax
   shr ax, 1
   shr ax, 1
   add di, ax

   ; divide offset by 4
   shr di, 1
   shr di, 1

   mov ax, s            ; compute c = s*s
   mul al
   mov WORD PTR cs:[const_c1+2], ax
   mov WORD PTR cs:[const_c2+2], ax
   mov WORD PTR cs:[const_c3+2], ax
   mov WORD PTR cs:[const_c4+2], ax
   mov bp, ax

   mov ax, bx           ; compute a = r*r
   mul al
   shl ax, 1
   mov WORD PTR cs:[const_2a1+2], ax
   mov WORD PTR cs:[const_2a2+2], ax
   mov WORD PTR cs:[const_2a3+2], ax
   shr ax, 1

   xor dx, dx
   xchg ax, bp          ; compute dx = 2*s*s*r
   mul bx
   shl ax, 1
   rcl dx, 1
   mov bx, ax

   xor cl, cl
   xor si, si
   xor dh, dh

ellipse_loop1:
   
ellipse_colour1:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel

   add si, bp           ; D += dy
   adc dh, cl

const_2a1:
   add bp, 01234h       ; dy += 2a
   adc cl, 0

   sub di, 8113         ; y += 1, adjust for stosb
   jnc ellipse_odd1
   add di, 16304
ellipse_odd1:

   shr dl, 1            ; dx >> 1
   rcr bx, 1

   cmp dh, dl           ; if D >= dx >> 1
   jl ellipse_skip_x1
   jne ellipse_inc_x1
   cmp si, bx
   jb ellipse_skip_x1
ellipse_inc_x1:

   shl bx, 1
   rcl dl, 1

const_c1:
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   sub si, bx           ; D -= dx
   sbb dh, dl

const_c2:   
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   rol ch, 1            ; x -= 1
   rol ch, 1
   sbb di, 0

   cmp dl, cl
   jg ellipse_loop1
   jne ellipse_done1
   cmp bx, bp
   ja ellipse_loop1
   jmp ellipse_done1

ellipse_skip_x1:
   shl bx, 1
   rcl dl, 1

   cmp dl, cl
   jg ellipse_loop1
   jne ellipse_done1
   cmp bx, bp
   ja ellipse_loop1

ellipse_done1:

   shr cl, 1            ; dy >> 1
   rcr bp, 1
   lahf

   cmp dh, cl           ; if D > dy >> 1
   jl ellipse_skip_diag1
   jne ellipse_diag1
   cmp si, bp
   jbe ellipse_skip_diag1

ellipse_diag1:
   sahf
   rcl bp, 1
   rcl cl, 1

const_2a2:
   sub bp, 01234        ; dy -= 2a
   sbb cl, 0

   sub si, bp           ; D -= dy
   sbb dh, cl

   sub di, 8192         ; y -= 1
   jnc ellipse_odd2
   add di, 16304
ellipse_odd2:
   
   jmp ellipse_done_diag1

ellipse_skip_diag1:
   sahf
   rcl bp, 1
   rcl cl, 1

ellipse_done_diag1:

   neg si               ; D = -D
   not dh
   adc dh, 0

ellipse_loop2:

ellipse_colour2:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel

const_c3:
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   add si, bx           ; D += dx
   adc dh, dl

const_c4:   
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   rol ch, 1            ; x -= 1
   rol ch, 1
   sbb di, 1

   shr cl, 1            ; dy >> 1
   rcr bp, 1
   lahf

   cmp dh, cl           ; if D > dy >> 1
   jl ellipse_skip_y1
   jne ellipse_inc_y1
   cmp si, bp
   jbe ellipse_skip_y1
ellipse_inc_y1:

   sahf
   rcl bp, 1
   rcl cl, 1

   sub si, bp           ; D -= dy
   sbb dh, cl

const_2a3:
   add bp, 01234h       ; dy += 2a
   adc cl, 0

   sub di, 8112         ; y += 1
   jnc ellipse_odd3
   add di, 16304
ellipse_odd3:

   cmp dl, 0
   jge ellipse_loop2
   jmp ellipse_done2

ellipse_skip_y1:
   sahf
   rcl bp, 1
   rcl cl, 1

   cmp dl, 0
   jge ellipse_loop2

ellipse_done2:

   pop di
   pop si
   pop bp
   ret
_cga_ellipse ENDP
   
start:
   ; set video mode = 4 (CGA 320x200x4)
   mov ax, 4
   int 10h

   mov ax, 2   ; colour = 2
   push ax
   mov al, 30  ; s = 30 
   push ax
   mov al, 100 ; r = 100
   push ax
   push ax     ; y0 = 100
   mov al, 160
   push ax     ; x0 = 160
   call _cga_ellipse
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
