   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA

   ellipse_diff DW 0

   .CODE

_cga_ellipse PROC
   ARG x0:WORD, y0:WORD, r:WORD, s:WORD, colour:BYTE
   ; draws ellipse with centre x0, y0 and semiradii
   ; r, s in the horizontal/vertical direction
   ; assumes r, s > 0

   ; ax = accum, dh:si = D, dl:bx = dx, cl:bp = dy
   ; di = offset, ch = mask

   push bp
   mov bp, sp
   push si
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   mov WORD PTR [ellipse_diff], 0

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
   mov BYTE PTR cs:[ellipse2_colour1+1], al
   mov BYTE PTR cs:[ellipse2_colour2+1], al

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

   push bp

   mov ax, s            ; compute c = s*s
   mul al
   mov WORD PTR cs:[const_c1+2], ax
   mov WORD PTR cs:[const_c2+2], ax
   mov WORD PTR cs:[const_c3+2], ax
   mov WORD PTR cs:[const_c4+2], ax
   mov WORD PTR cs:[const2_c1+2], ax
   mov WORD PTR cs:[const2_c2+2], ax
   mov WORD PTR cs:[const2_c3+2], ax
   mov WORD PTR cs:[const2_c4+2], ax
   mov bp, ax

   mov ax, bx           ; compute a = r*r
   mul al
   shl ax, 1
   mov WORD PTR cs:[const_2a1+2], ax
   mov WORD PTR cs:[const_2a2+2], ax
   mov WORD PTR cs:[const_2a3+2], ax
   mov WORD PTR cs:[const2_2a1+2], ax
   mov WORD PTR cs:[const2_2a2+2], ax
   mov WORD PTR cs:[const2_2a3+2], ax
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

   push dx
   push bx
   push bp

   jmp ellipse_skip_recover

ellipse_loop1:
   
ellipse_colour1:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel
   dec di

   sub di, [ellipse_diff]

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

   mov ax, [ellipse_diff]
   add di, ax
   add ax, 80
   mov [ellipse_diff], ax 

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

   jmp ellipse_skip_recover

ellipse_skip_x1:
   shl bx, 1
   rcl dl, 1

ellipse_skip_recover:
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

   sub WORD PTR [ellipse_diff], 80

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

   jmp ellipse_check_D

ellipse_loop2:

ellipse_colour2:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel
   dec di

   sub di, [ellipse_diff]

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

   mov ax, [ellipse_diff]
   add di, ax

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

   add ax, 80
   mov [ellipse_diff], ax

   cmp dl, 0
   jge ellipse_loop2
   jmp ellipse_done2

ellipse_skip_y1:
   sahf
   rcl bp, 1
   rcl cl, 1

   mov [ellipse_diff], ax

ellipse_check_D:
   cmp dl, 0
   jge ellipse_loop2

ellipse_done2:

   ; Left half of ellipse

   pop ax
   pop bx
   pop dx
   pop bp

   ; compute x0 - r
   mov di, x0
   sub di, r 

   ; compute x0 - r mod 4 and x0 - r
   mov cx, di
   and cl, 3

   ; compute mask
   mov ch, 03h
   shl cl, 1
   inc cl
   inc cl
   ror ch, cl

   ; compute y0 offset
   mov bp, y0
   xchg ax, bp

   ; offset += 4*8192 if y0 odd
   shr ax, 1
   jnc scanline2_even
   add di, 32768
scanline2_even:

   ; add 4*80*(y0/2) to offset
   xchg ah, al
   add di, ax
   shr ax, 1
   shr ax, 1
   add di, ax

   ; divide offset by 4
   shr di, 1
   shr di, 1

   xor cl, cl
   xor si, si
   xor dh, dh

   mov WORD PTR [ellipse_diff], 0

   jmp ellipse2_skip_recover

ellipse2_loop1:
   
ellipse2_colour1:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel
   dec di

   sub di, [ellipse_diff]

   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel

   add si, bp           ; D += dy
   adc dh, cl

const2_2a1:
   add bp, 01234h       ; dy += 2a
   adc cl, 0

   sub di, 8113         ; y += 1, adjust for stosb
   jnc ellipse2_odd1
   add di, 16304
ellipse2_odd1:

   mov ax, [ellipse_diff]
   add di, ax
   add ax, 80
   mov [ellipse_diff], ax 

   shr dl, 1            ; dx >> 1
   rcr bx, 1

   cmp dh, dl           ; if D >= dx >> 1
   jl ellipse2_skip_x1
   jne ellipse2_inc_x1
   cmp si, bx
   jb ellipse2_skip_x1
ellipse2_inc_x1:

   shl bx, 1
   rcl dl, 1

const2_c1:
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   sub si, bx           ; D -= dx
   sbb dh, dl

const2_c2:   
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   ror ch, 1            ; x += 1
   ror ch, 1
   adc di, 0

   jmp ellipse2_skip_recover

ellipse2_skip_x1:
   shl bx, 1
   rcl dl, 1

ellipse2_skip_recover:
   cmp dl, cl
   jg ellipse2_loop1
   jne ellipse2_done1
   cmp bx, bp
   ja ellipse2_loop1

ellipse2_done1:

   shr cl, 1            ; dy >> 1
   rcr bp, 1
   lahf

   cmp dh, cl           ; if D > dy >> 1
   jl ellipse2_skip_diag1
   jne ellipse2_diag1
   cmp si, bp
   jbe ellipse2_skip_diag1

ellipse2_diag1:
   sahf
   rcl bp, 1
   rcl cl, 1

   sub WORD PTR [ellipse_diff], 80

const2_2a2:
   sub bp, 01234        ; dy -= 2a
   sbb cl, 0

   sub si, bp           ; D -= dy
   sbb dh, cl

   sub di, 8192         ; y -= 1
   jnc ellipse2_odd2
   add di, 16304
ellipse2_odd2:
   
   jmp ellipse2_done_diag1

ellipse2_skip_diag1:
   sahf
   rcl bp, 1
   rcl cl, 1

ellipse2_done_diag1:

   neg si               ; D = -D
   not dh
   adc dh, 0

   jmp ellipse2_check_D

ellipse2_loop2:

ellipse2_colour2:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel
   dec di

   sub di, [ellipse_diff]

   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel

const2_c3:
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   add si, bx           ; D += dx
   adc dh, dl

const2_c4:   
   sub bx, 01234        ; dx -= c
   sbb dl, 0

   ror ch, 1            ; x += 1
   ror ch, 1
   cmc
   sbb di, 0

   shr cl, 1            ; dy >> 1
   rcr bp, 1
   lahf

   mov ax, [ellipse_diff]
   add di, ax

   cmp dh, cl           ; if D > dy >> 1
   jl ellipse2_skip_y1
   jne ellipse2_inc_y1
   cmp si, bp
   jbe ellipse2_skip_y1
ellipse2_inc_y1:

   sahf
   rcl bp, 1
   rcl cl, 1

   sub si, bp           ; D -= dy
   sbb dh, cl

const2_2a3:
   add bp, 01234h       ; dy += 2a
   adc cl, 0

   sub di, 8112         ; y += 1
   jnc ellipse2_odd3
   add di, 16304
ellipse2_odd3:

   add ax, 80
   mov [ellipse_diff], ax

   cmp dl, 0
   jge ellipse2_loop2
   jmp ellipse2_done2

ellipse2_skip_y1:
   sahf
   rcl bp, 1
   rcl cl, 1

   mov [ellipse_diff], ax

ellipse2_check_D:
   cmp dl, 0
   jge ellipse2_loop2

ellipse2_done2:

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
   mov al, 50  ; s = 30 
   push ax
   mov al, 60 ; r = 100
   push ax
   push ax     ; y0 = 100
   mov al, 160
   push ax     ; x0 = 160
   call _cga_ellipse
   add sp, 10

   ; wait for keypress
   xor ah, ah
   int 16h
   
   mov ax, 0   ; colour = 0
   push ax
   mov al, 50  ; s = 30 
   push ax
   mov al, 60 ; r = 100
   push ax
   push ax     ; y0 = 100
   mov al, 160
   push ax     ; x0 = 160
   call _cga_ellipse
   add sp, 10

   mov cx, 40
animation_loop:
   push cx     ; save iteration

   mov ax, 2   ; colour = 2
   push ax
   mov al, 50  ; s = 30 
   push ax
   mov al, 60 ; r = 100
   push ax
   mov ax, 40
   sub ax, cx
   shl ax, 1
   add ax, 60
   push ax     ; y0 = 2*i + 60
   shl ax, 1
   sub ax, 60  ; x0 = 4*i + 60
   push ax     ; x0 = 160
   call _cga_ellipse
   add sp, 10

   pop cx
   loop animation_loop

   ; wait for keypress
   xor ah, ah
   int 16h

   mov cx, 40
animation_loop2:
   push cx     ; save iteration

   mov ax, 0   ; colour = 0
   push ax
   mov al, 50  ; s = 30 
   push ax
   mov al, 60 ; r = 100
   push ax
   mov ax, 40
   sub ax, cx
   shl ax, 1
   add ax, 60
   push ax     ; y0 = 2*i + 60
   shl ax, 1
   sub ax, 60  ; x0 = 4*i + 60
   push ax     ; x0 = 160
   call _cga_ellipse
   add sp, 10

   pop cx
   loop animation_loop2

   ; wait for keypress
   xor ah, ah
   int 16h

   mov cx, 200
animation_loop3:
   push cx     ; save iteration

   mov ax, 1   ; colour = 1
   push ax
   mov al, 49  ; s = 30 
   push ax
   mov al, 59 ; r = 100
   push ax
   mov ax, 100
   push ax     ; y0 = 100
   mov ax, cx
   add ax, 60  ; x0 = i + 60
   push ax     ; x0 = 160
   call _cga_ellipse
   add sp, 10

   pop cx
   loop animation_loop3

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
