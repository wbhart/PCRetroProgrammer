   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA
   
   graph_mode DB 1

   frequency DW 0

   attack_point DW 01eh
   decay_point DW 073ch
   sustain_point DW 075ah
   release_point DW 0f78h

   old_attack_point DW 01eh
   old_decay_point DW 073ch
   old_sustain_point DW 075ah
   old_release_point DW 0f78h

   last DB 0
   keystate DB 96 dup (0)
   extstate DB 96 dup (0)

   old_kb_off DW 0
   old_kb_seg DW 0

   old_irq0_off DW 0
   old_irq0_seg DW 0

   mode1 DB 0                      ; 0 = nothing, 1 = freq., 2 = atten.
   mode2 DB 0
   mode3 DB 0
   
   count1 DW 0
   count2 DW 0
   count3 DW 0

   sound1 DB 242 dup (?)
   sound2 DB 242 dup (?)
   sound3 DB 242 dup (?)

   .CODE

   mov ax, 20                       ; let floppy drive settle
delay_loop_outer:
   mov cx, 65535
delay_loop:
   loop delay_loop
   dec ax
   jnz delay_loop_outer

   cli
   xor ax, ax
   mov ds, ax

   mov si, ds:[8*4]                 ; save old handler
   mov di, ds:[8*4+2]

   mov cx, ds:[9*4]
   mov dx, ds:[9*4+2]

   mov WORD PTR ds:[8*4], offset irq0_handler ; set new handler
   mov WORD PTR ds:[8*4+2], cs

   mov WORD PTR ds:[9*4], offset kb_handler ; set new handler
   mov WORD PTR ds:[9*4+2], cs

   mov  ax, @data
   mov  ds, ax                      ; set DS to point to the data segment

   mov [old_irq0_off], si
   mov [old_irq0_seg], di

   mov [old_kb_off], cx
   mov [old_kb_seg], dx

   mov WORD PTR cs:[irq0_patch1+1], ax       ; set ds for handler
   mov WORD PTR cs:[kb_patch1+1], ax         ; set ds for handler

   mov al, 034h                     ; set timer for 1/120th sec, 9956 ticks
   out 043h, al
   mov al, 0e4h
   out 040h, al
   mov al, 026h
   out 040h, al
   
   sti

   mov ax, 1                        ; channel 1
   push ax
   mov ax, release_point
   mov bx, ax
   sub ax, sustain_point
   xor ah, ah
   push ax
   mov al, bh
   push ax
   mov ax, sustain_point
   mov bx, ax
   sub ax, decay_point
   xor ah, ah
   push ax
   mov al, bh
   push ax
   mov ax, decay_point
   mov bx, ax
   sub ax, attack_point
   xor ah, ah
   push ax
   mov al, bh
   push ax
   mov ax, attack_point
   mov bx, ax
   xor ah, ah
   push ax
   mov al, bh
   push ax
   mov frequency, ax
   push ax
   call ADSR
   add sp, 20

   mov ax, 9                           ; tandy graphics mode 9
   int 010h

   call adsr_graph

runloop:

   cmp BYTE PTR [keystate+01h], 0
   jz not_tandy_exit
   jmp tandy_exit
not_tandy_exit:

   cmp BYTE PTR [keystate+039h], 0
   jz not_space

   mov BYTE PTR [mode1], 1
   mov BYTE PTR [keystate+039h], 0

not_space:
   cmp BYTE PTR [keystate+01eh], 0
   jz not_a

   mov BYTE PTR [keystate+01eh], 0

   mov graph_mode, 1

not_a:
   cmp BYTE PTR [keystate+020h], 0
   jz not_d

   mov BYTE PTR [keystate+020h], 0

   mov graph_mode, 2

not_d:
   cmp BYTE PTR [keystate+01fh], 0
   jz not_s

   mov BYTE PTR [keystate+01fh], 0

   mov graph_mode, 3

not_s:
   cmp BYTE PTR [keystate+013h], 0
   jz not_r

   mov BYTE PTR [keystate+013h], 0

   mov graph_mode, 4

not_r:

   cmp BYTE PTR [keystate+19h], 0
   jz not_p

   mov BYTE PTR [keystate+19h], 0

   cmp graph_mode, 1
   jne not_p_attack_mode

   mov ax, attack_point
   inc al
   mov bx, decay_point
   cmp al, bl
   je not_p
   mov attack_point, ax
   jmp done_p

not_p_attack_mode:
   cmp graph_mode, 2
   jne not_p_decay_mode

   mov ax, decay_point
   inc al
   mov bx, sustain_point
   cmp al, bl
   je not_p
   mov decay_point, ax
   jmp done_p

not_p_decay_mode:
   cmp graph_mode, 3
   jne not_p_sustain_mode

   mov ax, sustain_point
   inc al
   mov bx, release_point
   cmp al, bl
   je not_p
   mov sustain_point, ax
   jmp done_p

not_p_sustain_mode:
   mov ax, release_point
   inc al
   cmp al, 242
   je not_p
   mov release_point, ax

done_p:
   call re_adsr

not_p:
   cmp BYTE PTR [keystate+17h], 0
   jz not_i

   mov BYTE PTR [keystate+17h], 0

   cmp graph_mode, 1
   jne not_i_attack_mode

   mov ax, attack_point
   dec al
   cmp al, 0
   je not_i
   mov attack_point, ax
   jmp done_i

not_i_attack_mode:
   cmp graph_mode, 2
   jne not_i_decay_mode

   mov ax, decay_point
   dec al
   mov bx, attack_point
   cmp al, bl
   je not_i
   mov decay_point, ax
   jmp done_i

not_i_decay_mode:
   cmp graph_mode, 3
   jne not_i_sustain_mode

   mov ax, sustain_point
   dec al
   mov bx, decay_point
   cmp al, bl
   je not_i
   mov sustain_point, ax
   jmp done_i

not_i_sustain_mode:
   mov ax, release_point
   dec al
   mov bx, sustain_point
   cmp al, bl
   je not_i
   mov release_point, ax

done_i:
   call re_adsr

not_i:
   cmp BYTE PTR [keystate+18h], 0
   jz not_o

   mov BYTE PTR [keystate+18h], 0

   cmp graph_mode, 1
   jne not_o_attack_mode

   mov ax, attack_point
   dec ah
   js not_o
   mov attack_point, ax
   jmp done_o

not_o_attack_mode:
   cmp graph_mode, 4
   je not_o

   mov ax, decay_point
   dec ah
   mov bx, attack_point
   cmp ah, bh
   je not_o
   mov decay_point, ax
   mov bx, sustain_point
   mov bh, ah
   mov sustain_point, bx

done_o:
   call re_adsr

not_o:
   cmp BYTE PTR [keystate+26h], 0
   jz not_l

   mov BYTE PTR [keystate+26h], 0

   cmp graph_mode, 1
   jne not_l_attack_mode

   mov ax, attack_point
   inc ah
   mov bx, decay_point
   cmp bh, ah
   je not_l
   mov attack_point, ax
   jmp done_l

not_l_attack_mode:
   cmp graph_mode, 4
   je not_l

   mov ax, decay_point
   inc ah
   mov bx, release_point
   cmp bh, ah
   je not_l
   mov decay_point, ax
   mov bx, sustain_point
   mov bh, ah
   mov sustain_point, bx

done_l:
   call re_adsr

not_l:

   jmp runloop

tandy_exit:

   cli

   mov al, 0ffh                     ; restore system timer value
   out 040h, al
   out 040h, al

   mov si, old_irq0_off
   mov di, old_irq0_seg

   mov cx, old_kb_off
   mov dx, old_kb_seg

   xor ax, ax
   mov ds, ax

   mov ds:[8*4], si                 ; restore old handler
   mov ds:[8*4+2], di

   mov ds:[9*4], cx
   mov ds:[9*4+2], dx

   mov ax, 3                        ; text mode
   int 010h

   mov  ah, 04ch                    ; DOS terminate program function
   int  21h                         ; terminate the program

re_adsr PROC
   mov ax, 1                        ; channel 1
   push ax
   mov ax, release_point
   mov dx, ax
   mov bx, sustain_point
   sub ax, bx
   xor ah, ah
   push ax
   mov al, dh
   push ax
   mov ax, bx
   mov dx, ax
   mov bx, decay_point
   sub ax, bx
   xor ah, ah
   push ax
   mov al, dh
   push ax
   mov ax, bx
   mov dx, ax
   mov bx, attack_point
   sub ax, bx
   xor ah, ah
   push ax
   mov al, dh
   push ax
   mov ax, bx
   mov dx, ax
   xor ah, ah
   push ax
   mov al, dh
   push ax
   mov ax, frequency
   push ax
   call ADSR
   add sp, 20

   call adsr_graph

   ret
re_adsr ENDP

adsr_graph PROC
    push si
    push di

    ; channel 1 blank old graph
    xor bx, bx                      ; colour 0
    push bx
    mov ax, old_attack_point
    xchg ah, bl
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    mov si, ax
    mov di, bx
    mov ax, 45
    push ax
    xor ax, ax
    push ax
    call _tga_line
    add sp, 10

    xor bx, bx                      ; colour 0
    push bx
    mov ax, old_decay_point
    xchg ah, bl
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    xchg si, ax
    xchg di, bx
    push bx
    push ax
    call _tga_line
    add sp, 10

    xor bx, bx                      ; colour 0
    push bx
    mov ax, old_sustain_point
    xchg ah, bl
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    xchg si, ax
    xchg di, bx
    push bx
    push ax
    call _tga_line
    add sp, 10

    xor bx, bx                      ; colour 0
    push bx
    mov ax, old_release_point
    xchg ah, bl
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    xchg si, ax
    xchg di, bx
    push bx
    push ax
    call _tga_line
    add sp, 10

    ; draw axes
    mov ax, 1                         ; colour 1
    push ax
    mov ax, 45
    push ax
    xor ax, ax
    push ax
    push ax
    push ax
    call _tga_line
    add sp, 10

    mov ax, 1                          ; colour 1
    push ax
    mov ax, 45
    push ax
    mov ax, 239
    push ax
    mov ax, 45
    push ax
    xor ax, ax
    push ax
    call _tga_line
    add sp, 10

    ; channel 1 draw new graph
    mov bx, 12                         ; colour 12
    push bx
    mov ax, attack_point
    mov old_attack_point, ax
    mov bl, ah
    xor ah, ah
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    mov si, ax
    mov di, bx
    mov ax, 45
    push ax
    xor ax, ax
    push ax
    call _tga_line
    add sp, 10

    mov bx, 12                      ; colour 12
    push bx
    mov ax, decay_point
    mov old_decay_point, ax
    mov bl, ah
    xor ah, ah
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    xchg si, ax
    xchg di, bx
    push bx
    push ax
    call _tga_line
    add sp, 10

    mov bx, 12                      ; colour 12
    push bx
    mov ax, sustain_point
    mov old_sustain_point, ax
    mov bl, ah
    xor ah, ah
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    xchg si, ax
    xchg di, bx
    push bx
    push ax
    call _tga_line
    add sp, 10

    mov bx, 12                      ; colour 12
    push bx
    mov ax, release_point
    mov old_release_point, ax
    mov bl, ah
    xor ah, ah
    mov dx, bx
    shl dx, 1
    add bx, dx
    push bx
    push ax
    xchg si, ax
    xchg di, bx
    push bx
    push ax
    call _tga_line
    add sp, 10

    pop di
    pop si
    ret
adsr_graph ENDP

ADSR PROC
   ARG freq:WORD, attack:WORD, attack_run:WORD, decay:WORD, decay_run:WORD, sustain:WORD, sustain_run:WORD, release:WORD, release_run:WORD, channel:BYTE
   ; freq = wave length, tone frequency = 3579545/32.0/freq Hz
   ;        0feh ~= 440Hz
   ; attack = att. value of attack point
   ; attack_run = number of 120Hz ticks
   ; decay, sustain, release similar

   push bp
   mov bp, sp

   mov ax, ds                        ; duplicate ds into es
   mov es, ax

   mov al, channel                   ; channel 1
   cmp al, 1
   jbe channel_eq1

   jmp channel_ne1

channel_eq1:
   mov di, offset sound1

   mov ax, freq                      ; convert freq to 6:4 format
   mov bx, ax
   and al, 0fh
   shr bx, 1
   shr bx, 1
   shr bx, 1
   shr bx, 1

   stosb                             ; write freq
   mov al, bl
   stosb

   mov bx, 0f000h                    ; max. att. = vol. 0
   mov cx, attack_run                ; count
   shl cx, 1
   shl cx, 1
   shl cx, 1
   shl cx, 1
   mov dx, 15
   sub dx, attack
   xor ax, ax
   div cx
   shr cx, 1
   shr cx, 1
   shr cx, 1
   shr cx, 1
   mov dx, ax

attack_loop:
   mov al, bh
   shr al, 1
   shr al, 1
   shr al, 1
   shr al, 1
   stosb

   sub bx, dx
   jnc attack_ok
   xor bx, bx                         ; 0 = minimum value allowed
attack_ok:

   loop attack_loop

   mov cx, decay_run                  ; count
   mov dx, decay
   sub dx, attack
   shl cx, 1
   shl cx, 1
   shl cx, 1
   shl cx, 1
   xor ax, ax
   div cx
   shr cx, 1
   shr cx, 1
   shr cx, 1
   shr cx, 1
   mov dx, ax

decay_loop:
   mov al, bh
   shr al, 1
   shr al, 1
   shr al, 1
   shr al, 1
   stosb

   add bx, dx
   jnc decay_ok
   mov bx, 0f000h                         ; 15 = maximum value allowed
decay_ok:

   loop decay_loop

   mov cx, sustain_run                    ; count
   mov ax, sustain
   
   rep
   stosb

   mov cx, release_run                    ; count
   mov dx, release
   sub dx, sustain
   shl cx, 1
   shl cx, 1
   shl cx, 1
   shl cx, 1
   xor ax, ax
   div cx
   shr cx, 1
   shr cx, 1
   shr cx, 1
   shr cx, 1
   mov dx, ax

release_loop:
   mov al, bh
   shr al, 1
   shr al, 1
   shr al, 1
   shr al, 1
   stosb

   add bx, dx
   jnc release_ok
   mov bx, 0f000h                         ; 15 = maximum value allowed
release_ok:

   loop release_loop

   mov cx, offset sound1              ; attenuate to zero for remainder
   add cx, 242
   sub cx, di

   mov al, 15
   rep stosb

channel_ne1:

   pop bp
   ret
ADSR ENDP

irq0_handler PROC
   push ax
   push ds
   push si

irq0_patch1:
   mov ax, 1234h                    ; allow handler to access program ds
   mov ds, ax

   mov al, [mode1]
   cmp al, 1
   jb sound1_done
   je sound1_new

   mov si, [count1]                 ; set attenuation
   mov al, [sound1+si]
   or al, 090h

   out 0c0h, al                     ; output to sound chip

   inc si                           ; increment counter
   mov [count1], si

   cmp si, 242
   jne sound1_done

   mov [mode1], 0

   jmp sound1_done

sound1_new:
   xor si, si
   
   mov al, [sound1+si]              ; set tone count lo 4 bits
   or al, 080h

   out 0c0h, al                     ; output to sound chip

   inc si                           ; increment counter
   
   mov al, [sound1+si]              ; set tone count hi 6 bits

   out 0c0h, al                     ; output to sound chip

   inc si                           ; increment counter

   mov al, [sound1+si]
   or al, 090h

   out 0c0h, al                     ; output to sound chip

   inc si
   mov [count1], si              ; increment counter and save

   mov [mode1], 2                ; change to atten. mode

sound1_done:

   pop si
   pop ds
   mov al, 020h                     ; interrupt done
   out 020h, al

   pop ax
   iret
irq0_handler ENDP

kb_handler PROC
   push ax
   push bx
   push ds

kb_patch1:
   mov ax, 1234h                    ; allow handler to access program ds
   mov ds, ax

   in al, 060h                       ; read raw byte from kb
   xor bx, bx
   
   mov bl, al                        ; scancode
   and bl, 07fh

   mov ah, [last]
   cmp ah, 0e0h
   jne ignore_ext

   cmp bl, 060h
   jae nosave_ext

   and al, 080h
   xor al, 080h
   rol al, 1

   mov [bx+extstate], al

nosave_ext:
   mov BYTE PTR [last], 0

   jmp key_done

ignore_ext:
   cmp ah, 0e1h
   jne not_e1

   mov [last], 0

   jmp key_done

not_e1:
   cmp ah, 0e2h
   jne not_e2

   mov [last], 0

   jmp key_done

not_e2:
   
   cmp al, 0e0h
   jb scancode
   cmp al, 0e2h
   ja key_done

   mov [last], al
   
   jmp key_done

scancode:

   cmp bl, 060h
   jae key_done

   and al, 080h
   xor al, 080h
   rol al, 1

   mov [keystate+bx], al

key_done:

   in al, 061h
   or al, 080h
   out 061h, al
   xor al, 080h
   out 061h, al

   pop ds
   pop bx
   mov al, 020h                     ; interrupt done
   out 020h, al
   
   pop ax
   iret
kb_handler ENDP

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

   END
