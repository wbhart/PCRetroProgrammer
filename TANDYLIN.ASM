   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

_tga_line PROC
   ARG x0:WORD, y0:WORD, x1:WORD, y1:WORD, colour:BYTE
   ; ax = accum, dx = 2dx, si = 2dy, bp = D, cx = iters
   ; di = offset, bl = mask, bh = colour

   push bp
   mov bp, sp
   push si
   push di

   ; set up TGA segment
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

   ; offset += 2*8192*bank
   ror ax, 1
   ror ax, 1
   mov di, ax
   xor ah, ah
   sub di, ax

   ; add 2*160*(y0/4) to offset
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

   ; compute x0 mod 2 and x0 / 2 and divide di by 2
   add di, bx
   shr di, 1
   
   ; compute colour and mask
   sbb bl, bl
   xor bl, 0fh
   mov bh, colour
   mov al, bh
   shl al, 1
   shl al, 1
   shl al, 1
   shl al, 1
   add bh, al

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
   mov ax, bx
   and al, es:[di] ; get pixel
   not bl          ; complement mask
   and ah, bl      ; and colour with mask complement
   or al, ah       ; or with colour
   stosb           ; write pixel
   not bl          ; restore mask

   add bp, dx      ; D += 2dx
   jle line_vr_skipx ; if D > 0

   not bl          ; complement mask
   mov ah, bl
   sahf
   adc di, 0
   
   sub bp, si      ; D -= 2dy

line_vr_skipx:

   sub di, 3*8192-160+1    ; increment y
   sbb ax, ax
   and ax, 4*8192-160
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
   mov ax, bx
   and al, es:[di] ; get pixel
   not bl          ; complement mask
   and ah, bl      ; and colour with mask complement
   or al, ah       ; or with colour
   stosb           ; write pixel
   not bl          ; restore mask

   add bp, si      ; D += 2dy
   jle line_hr_skipy  ; if D > 0

   sub di, 3*8192-160    ; increment y
   sbb ax, ax
   and ax, 4*8192-160
   add di, ax

   sub bp, dx      ; D -= 2dx

line_hr_skipy:
   mov ah, bl
   not bl          ; complement mask
   sahf
   sbb di, 0

   loop line_hr_loop

   pop di
   pop si
   pop bp
   ret

line_left:
   neg dx

   std

   ; compute x0 mod 2 and x0 / 2 and divide di by 2
   add di, bx
   shr di, 1
   
   ; compute colour and mask
   sbb bl, bl
   xor bl, 0fh
   mov bh, colour
   mov al, bh
   shl al, 1
   shl al, 1
   shl al, 1
   shl al, 1
   add bh, al

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
   mov ax, bx
   and al, es:[di] ; get pixel
   not bl          ; complement mask
   and ah, bl      ; and colour with mask complement
   or al, ah       ; or with colour
   stosb           ; write pixel
   not bl          ; restore mask

   add bp, dx      ; D += 2dx
   jle line_vl_skipx ; if D > 0

   mov ah, bl
   not bl          ; complement mask
   sahf
   sbb di, 0
   
   sub bp, si      ; D -= 2dy

line_vl_skipx:

   sub di, 3*8192-160-1    ; increment y
   sbb ax, ax
   and ax, 4*8192-160
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
   mov ax, bx
   and al, es:[di] ; get pixel
   not bl          ; complement mask
   and ah, bl      ; and colour with mask complement
   or al, ah       ; or with colour
   stosb           ; write pixel
   not bl          ; restore mask

   add bp, si      ; D += 2dy
   jle line_hl_skipy  ; if D > 0

   sub di, 3*8192-160    ; increment y
   sbb ax, ax
   and ax, 4*8192-160
   add di, ax

   sub bp, dx      ; D -= 2dx

line_hl_skipy:
   not bl          ; complement mask
   mov ah, bl
   sahf
   adc di, 0

   loop line_hl_loop

   cld

   pop di
   pop si
   pop bp
   ret
_tga_line ENDP
   
start:
   ; set video mode = 9 (TGA 320x200 16 colours)
   mov ax, 9
   int 10h

   mov si, 199

vline_right_loop:
   xor ah, ah
   mov al, 1   ; colour = 1
   push ax
   mov al, 199 ; y1 = 199
   push ax
   push si     ; x1 = 199..0
   xor al, al
   push ax     ; y0 = 0
   push ax     ; x0 = 0
   call _tga_line
   add sp, 10

   dec si
   jge vline_right_loop

   ; wait for keypress
   xor ah, ah
   int 16h
   
   mov si, 199

vline_left_loop:
   xor ah, ah
   mov al, 2   ; colour = 2
   push ax
   mov al, 199 ; y1 = 199
   push ax
   push si     ; x1 = 199..0
   xor al, al
   push ax     ; y0 = 0
   mov al, 199
   push ax     ; x0 = 199
   call _tga_line
   add sp, 10

   dec si
   jge vline_left_loop

   ; wait for keypress
   xor ah, ah
   int 16h
   
   mov si, 199

hline_right_loop:
   xor ah, ah
   mov al, 12   ; colour = 12
   push ax
   push si     ; y1 = 199..0
   mov al, 199 ; x1 = 199
   push ax
   xor al, al
   push ax     ; y0 = 0
   push ax     ; x0 = 0
   call _tga_line
   add sp, 10

   dec si
   jge hline_right_loop

   ; wait for keypress
   xor ah, ah
   int 16h
   
  mov si, 199

hline_left_loop:
   xor ah, ah
   mov al, 14   ; colour = 14
   push ax
   push si     ; y1 = 199..0
   mov al, 0   ; x1 = 0
   push ax
   xor al, al
   push ax     ; y0 = 0
   mov al, 199
   push ax     ; x0 = 199
   call _tga_line
   add sp, 10

   dec si
   jge hline_left_loop

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
