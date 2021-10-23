   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA
   
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
   mov ax, 041eh
   push ax
   mov ax, 01eh
   push ax
   mov ax, 041eh
   push ax
   mov ax, 081eh
   push ax
   mov ax, 0feh
   push ax
   call ADSR
   add sp, 12

runloop:

   cmp BYTE PTR [keystate+01h], 0
   jnz tandy_exit

   cmp BYTE PTR [keystate+039h], 0
   jz not_space

   mov BYTE PTR [mode1], 1
   mov BYTE PTR [keystate+039h], 0
not_space:

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

   mov  ah, 04ch                    ; DOS terminate program function
   int  21h                         ; terminate the program

ADSR PROC
   ARG freq:WORD, attack:WORD, decay:WORD, sustain:WORD, release:WORD, channel:BYTE
   ; freq = wave length, tone frequency = 3579545/32.0/freq Hz
   ;        0feh ~= 440Hz
   ; attack = hi byte: 4:4 bit att. dec. per 120Hz tick,
   ;          lo byte: number of 120Hz ticks
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

   mov bx, 0f00h                     ; max. att. = vol. 0
   xor cx, cx
   mov dx, attack
   mov cl, dl                        ; count

   xor dl, dl
   shr dx, 1
   shr dx, 1
   shr dx, 1
   shr dx, 1

attack_loop:
   mov al, bh
   stosb

   sub bx, dx
   jge attack_ok
   xor bx, bx                         ; 0 = minimum value allowed
attack_ok:

   loop attack_loop

   mov dx, decay
   mov cl, dl                        ; count

   xor dl, dl
   shr dx, 1
   shr dx, 1
   shr dx, 1
   shr dx, 1
   
decay_loop:
   mov al, bh
   stosb

   add bx, dx
   cmp bx, 15
   jle decay_ok
   mov bx, 15                         ; 15 = maximum value allowed
decay_ok:

   loop decay_loop

   mov dx, sustain
   mov cl, dl                        ; count
   
   rep
   stosb

   mov dx, release
   mov cl, dl                        ; count

   xor dl, dl
   shr dx, 1
   shr dx, 1
   shr dx, 1
   shr dx, 1

release_loop:
   mov al, bh
   stosb

   add bx, dx
   cmp bh, 15
   jle release_ok
   mov bh, 15                         ; 15 = maximum value allowed
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

   END
