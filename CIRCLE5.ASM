   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA

   circle_diff DW 0 ; diff of upper and lower offsets

   .CODE

_cga_circle PROC
   ARG x0:WORD, y0:WORD, r:WORD, colour:BYTE
   ; draws circle with centre x0, y0 and semiradii
   ; r, 5*r/6 in the horizontal/vertical direction
   ; assumes r > 0

   ; ax = accum, si = D, dx = dx, bp = dy
   ; di = right offset, bx = left offset
   ; ch = right mask, cl = left mask

   push bp
   mov bp, sp
   push si
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   mov WORD PTR [circle_diff], 0

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

   mov BYTE PTR cs:[circle_colour1+1], al
   mov BYTE PTR cs:[circle_colour2+1], al
   mov BYTE PTR cs:[circle2_colour1+1], al
   mov BYTE PTR cs:[circle2_colour2+1], al

   ; compute x0 + r and x0 - r
   mov di, x0
   mov bx, di
   mov si, r            ; save r
   add di, si
   sub bx, si 

   ; compute x0 - r mod 4 and x0 - r
   mov cx, bx
   inc cx
   and cl, 3

   ; compute left mask
   mov ch, 03h
   shl cl, 1
   ror ch, cl

   mov al, ch   ; save left mask

   ; compute x0 + r mod 4 and x0 + r
   mov cx, di
   inc cx
   and cl, 3

   ; compute right mask
   mov ch, 03h
   shl cl, 1
   ror ch, cl

   mov cl, al   ; restore left mask

   ; compute y0 offset
   mov ax, y0

   ; offsets += 4*8192 if y0 odd
   shr ax, 1
   jnc scanline_even
   add di, 32768
   add bx, 32768
scanline_even:

   ; add 4*80*(y0/2) to offsets
   xchg ah, al
   add di, ax
   add bx, ax
   shr ax, 1
   shr ax, 1
   add di, ax
   add bx, ax

   ; divide offsets by 4
   shr di, 1
   shr di, 1

   shr bx, 1
   shr bx, 1

   mov dx, si           ; dx = 50*r
   shl dx, 1
   add dx, si
   shl dx, 1
   shl dx, 1
   shl dx, 1
   add dx, si
   shl dx, 1

   mov bp, 36          ; dy = 36

   xor si, si          ; D = 0

   jmp circle_skip_recover

circle_loop1:
   
circle_colour1:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel
   dec di

   sub di, [circle_diff]

   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel

circle2_colour1:
   mov ah, 012h
   and ah, cl           ; and with mask
   
   mov al, cl           ; get inverse mask
   not al
   and al, es:[bx]      ; get pixel

   or al, ah            ; or with colour
   mov es:[bx], al      ; write pixel

   sub bx, [circle_diff]

   mov al, cl           ; get inverse mask
   not al
   and al, es:[bx]      ; get pixel

   or al, ah            ; or with colour
   mov es:[bx], al      ; write pixel

   add si, bp           ; D += dy

   add bp, 72           ; dy += 2a

   sub bx, 8112         ; no need to adjust for stosb
   sub di, 8113         ; y += 1, adjust for stosb
   jnc circle_odd1
   add bx, 16304
   add di, 16304
circle_odd1:

   mov ax, [circle_diff]
   add di, ax
   add bx, ax
   add ax, 80
   mov [circle_diff], ax 

   shr dx, 1            ; dx >> 1

   cmp si, dx           ; if D >= dx >> 1
   jl circle_skip_x1

   shl dx, 1

   sub dx, 25           ; dx -= c

   sub si, dx           ; D -= dx
 
   sub dx, 25           ; dx -= c

   rol ch, 1            ; x -= 1
   rol ch, 1
   sbb di, 0

   ror cl, 1            ; x += 1
   ror cl, 1
   adc bx, 0

   cmp dx, bp          ; if dx >= dy
   jb circle_done1

circle_jmp1:
   jmp circle_loop1

circle_skip_x1:
   shl dx, 1

circle_skip_recover:
   cmp dx, bp
   jae circle_jmp1

circle_done1:

   shr bp, 1            ; dy >> 1

   cmp si, bp           ; if D > dy >> 1
   jle circle_skip_diag1

circle_diag1:
   shl bp, 1

   sub WORD PTR [circle_diff], 80

   sub bp, 72           ; dy -= 2a

   sub si, bp           ; D -= dy

   sub bx, 8192
   sub di, 8192         ; y -= 1
   jnc circle_odd2
   add bx, 16304
   add di, 16304
circle_odd2:
   
   jmp circle_done_diag1

circle_skip_diag1:
   shl bp, 1

circle_done_diag1:

   neg si               ; D = -D

   jmp circle_check_dx

circle_loop2:

circle_colour2:
   mov ah, 012h
   and ah, ch           ; and with mask
   
   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel
   dec di

   sub di, [circle_diff]

   mov al, ch           ; get inverse mask
   not al
   and al, es:[di]      ; get pixel

   or al, ah            ; or with colour
   stosb                ; write pixel

circle2_colour2:
   mov ah, 012h
   and ah, cl           ; and with mask

   mov al, cl           ; get inverse mask
   not al
   and al, es:[bx]      ; get pixel

   or al, ah            ; or with colour
   mov es:[bx], al      ; write pixel

   sub bx, [circle_diff]

   mov al, cl           ; get inverse mask
   not al
   and al, es:[bx]      ; get pixel

   or al, ah            ; or with colour
   mov es:[bx], al      ; write pixel

   sub dx, 25           ; dx -= c

   add si, dx           ; D += dx
 
   sub dx, 25           ; dx -= c

   rol ch, 1            ; x -= 1
   rol ch, 1
   sbb di, 1

   ror cl, 1            ; x += 1
   ror cl, 1
   adc bx, 0

   shr bp, 1            ; dy >> 1

   mov ax, [circle_diff]
   add di, ax
   add bx, ax

   cmp si, bp           ; if D > dy >> 1
   jle circle_skip_y1

   shl bp, 1

   sub si, bp           ; D -= dy

   add bp, 72           ; dy += 2a

   sub bx, 8112
   sub di, 8112         ; y += 1
   jnc circle_odd3
   add bx, 16304
   add di, 16304
circle_odd3:

   add ax, 80
   mov [circle_diff], ax

   cmp dx, 0
   jl circle_done2

circle_jmp2:
   jmp circle_loop2

circle_skip_y1:
   shl bp, 1

circle_check_dx:
   cmp dx, 0
   jge circle_jmp2

circle_done2:

   pop di
   pop si
   pop bp
   ret
_cga_circle ENDP
   
start:
   ; set video mode = 4 (CGA 320x200x4)
   mov ax, 4
   int 10h

   mov ax, 2   ; colour = 2
   push ax
   mov al, 60  ; r = 60
   push ax
   mov al, 100
   push ax     ; y0 = 100
   mov al, 160
   push ax     ; x0 = 160
   call _cga_circle
   add sp, 8

   ; wait for keypress
   xor ah, ah
   int 16h
   
   mov ax, 0   ; colour = 0
   push ax
   mov al, 60  ; r = 60
   push ax
   mov al, 100
   push ax     ; y0 = 100
   mov al, 160
   push ax     ; x0 = 160
   call _cga_circle
   add sp, 8

   mov cx, 40
animation_loop:
   push cx     ; save iteration

   mov ax, 2   ; colour = 2
   push ax
   mov al, 60  ; r = 60
   push ax
   mov ax, 40
   sub ax, cx
   shl ax, 1
   add ax, 60
   push ax     ; y0 = 2*i + 60
   shl ax, 1
   sub ax, 60  ; x0 = 4*i + 60
   push ax     ; x0 = 160
   call _cga_circle
   add sp, 8

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
   mov al, 60  ; r = 60
   push ax
   mov ax, 40
   sub ax, cx
   shl ax, 1
   add ax, 60
   push ax     ; y0 = 2*i + 60
   shl ax, 1
   sub ax, 60  ; x0 = 4*i + 60
   push ax     ; x0 = 160
   call _cga_circle
   add sp, 8

   pop cx
   loop animation_loop2

   ; wait for keypress
   xor ah, ah
   int 16h

   mov bx, 10
colour_loop:

   mov cx, 200
animation_loop3:
   push cx     ; save iteration
   push bx     ; save colour

   mov ax, bx   ; colour = 1
   and ax, 1
   inc ax
   push ax
   mov al, 59  ; r = 59
   push ax
   mov ax, 100
   push ax     ; y0 = 100
   mov ax, cx
   add ax, 60  ; x0 = i + 60
   push ax     ; x0 = 160
   call _cga_circle
   add sp, 8

   pop bx
   pop cx
   loop animation_loop3

   dec bx
   jnz colour_loop

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
