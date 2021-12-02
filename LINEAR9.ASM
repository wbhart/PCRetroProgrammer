   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; change into CGA mode 4
   mov ax, 4
   int 10h

   ; offset = 0
   xor di, di

   ; fill first bank with cyan black cyan black....
   mov cx, 8192
   mov al, 044h

   rep stosb

   ; first scanline of 2nd bank white black white black...
   mov cx, 64
   mov al, 0cch

   rep stosb

   ; fill second bank with magenta black magenta black....
   
   mov cx, 8128
   mov al, 088h

   rep stosb

   cli

   mov dx, 03d4h
   
   mov ax, 32*256+1    ; horizontal displayed = 32
   out dx, ax

   mov dl, 0dah

   ; wait for vertical retrace
wait_v_retrace:
   in al, dx
   test al, 8
   jz wait_v_retrace

   ; wait for active region
wait_active:
   in al, dx
   test al, 1
   jnz wait_active

   mov dl, 0d4h
   
   mov ax, 0*256+9     ; max char scanline = 0
   out dx, ax
   mov ax, 6*256+5     ; vertical adjust = 6
   out dx, ax
   mov ax, 127*256+4   ; vertical total = 127
   out dx, ax
   mov ax, 127*256+6   ; vertical displayed = 127
   out dx, ax

   jmp skip_first

crt_loop:

   ; wait for vertical retrace
   mov dx, 03dah
wait_retrace:
   in al, dx
   test al, 8
   jz wait_retrace

   ; wait for active region
wait_active_0:
   in al, dx
   test al, 1
   jnz wait_active_0

   mov dl, 0d4h

skip_first:

   mov ax, 127*256+7   ; vertical sync position = 127 (won't be reached)
   out dx, ax

   ; wait for non-active region
   mov dl, 0dah
wait_non_active_0:
   in al, dx
   test al, 1
   jz wait_non_active_0

   mov cx, 96

wait_1_96_loop:

   ; wait for active region
wait_active_1_96:
   in al, dx
   test al, 1
   jnz wait_active_1_96

   ; wait for non-active region
wait_non_active_1_96:
   in al, dx
   test al, 1
   jz wait_non_active_1_96

   loop wait_1_96_loop

   ; wait for active region
wait_active_97:
   in al, dx
   test al, 1
   jnz wait_active_97

   mov dl, 0d4h

   mov ax, 87*256+4     ; vertical total = 87 (out of the way)
   out dx, ax
   mov ax, 72*256+6     ; vertical displayed = 72 (128 + 72 = 200)
   out dx, ax
   mov ax, 95*256+7     ; vertical sync position = 95
   out dx, ax

   ; wait for non-active region
   mov dl, 0dah
wait_non_active_97:
   in al, dx
   test al, 1
   jz wait_non_active_97

   mov cx, 29

wait_98_126_loop:

   ; wait for active region
wait_active_98_126:
   in al, dx
   test al, 1
   jnz wait_active_98_126

   ; wait for non-active region
wait_non_active_98_126:
   in al, dx
   test al, 1
   jz wait_non_active_98_126

   loop wait_98_126_loop

   ; *********** rasterline 127 ******************

   ; wait for active region
wait_active_127:
   in al, dx
   test al, 1
   jnz wait_active_127

   mov dl, 0d4h
   
   mov ax, 56*256+0     ; horizontal total = 56
   out dx, ax
   mov ax, 32*256+1     ; horizontal displayed = 32
   out dx, ax

   ; delay
   REPT 10
   nop
   ENDM

   mov ax, 45*256+2     ; horizontal sync pos = 45
   out dx, ax

   mov dl, 0d9h         ; background colour 12
   mov al, 02ch
   out dx, al

   ; wait for non-active region
   mov dl, 0dah
wait_non_active_127:
   in al, dx
   test al, 1
   jz wait_non_active_127

   mov dl, 0d4h
   
   mov ax, 0*256+9      ; max char scanline = 0
   out dx, ax
   mov ax, 56*256+0     ; horizontal total = 56
   out dx, ax
   mov ax, 32*256+1     ; horizontal displayed = 32
   out dx, ax

   ; *********** rasterline 128 ******************

   ; wait for active region
   mov dl, 0dah
wait_active_128:
   in al, dx
   test al, 1
   jnz wait_active_128

   mov dl, 0d4h

   mov ax, 45*256+2     ; horizontal sync pos = 45
   out dx, ax
   mov ax, 56*256+0     ; horizontal total = 56
   out dx, ax

   ; wait for non-active region
   mov dl, 0dah
wait_non_active_128:
   in al, dx
   test al, 1
   jz wait_non_active_128

   ; *********** rasterline 129 ******************

   ; wait for active region
wait_active_129:
   in al, dx
   test al, 1
   jnz wait_active_129

   mov dl, 0d4h
   
   mov ax, 0*256+9      ; max char scanline = 0
   out dx, ax

   mov dl, 0d9h         ; background colour 0
   mov al, 20h
   out dx, al

   ; wait for non-active region
   mov dl, 0dah
wait_non_active_129:
   in al, dx
   test al, 1
   jz wait_non_active_129

   ; *********** remaining rasterlines ******************

   mov cx, 70

wait_130_199_loop:

   ; wait for active region
wait_active_130_199:
   in al, dx
   test al, 1
   jnz wait_active_130_199

   ; wait for non-active region
wait_non_active_130_199:
   in al, dx
   test al, 1
   jz wait_non_active_130_199

   loop wait_130_199_loop
   
   ; delay
   mov cl, 100
   shl ax, cl

   mov dl, 0d4h

   mov ax, 127*256+4   ; vertical total = 127
   out dx, ax
   mov ax, 127*256+6   ; vertical displayed = 127
   out dx, ax

   ; read Interrupt Request Register
   mov al, 0ah        ; next command read IRR
   out 20h, al
   in al, 20h

   ; is keyboard (IRQ1) requesting service
   test al, 02h
   jnz key_pressed

   jmp crt_loop

key_pressed:

   sti

   ; restore text mode
   mov ax, 3
   int 10h

   ; exit to DOS
   mov ah, 4ch
   int 21h

   END
