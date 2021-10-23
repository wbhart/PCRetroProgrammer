   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE
   mov cx, 47700
   mov ax, 1
   
bank_loop:
   shr ax, 1
   jnc even_line_a1
   xor di, 8192
even_line_a1:
   shr ax, 1
   jnc even_line_b1
   xor di, 8192
even_line_b1:
   inc ax

   shr ax, 1
   jnc even_line_a2
   xor di, 8192
even_line_a2:
   shr ax, 1
   jnc even_line_b2
   xor di, 8192
even_line_b2:
   inc ax

   shr ax, 1
   jnc even_line_a3
   xor di, 8192
even_line_a3:
   shr ax, 1
   jnc even_line_b3
   xor di, 8192
even_line_b3:
   inc ax

   shr ax, 1
   jnc even_line_a4
   xor di, 8192
even_line_a4:
   shr ax, 1
   jnc even_line_b4
   xor di, 8192
even_line_b4:
   inc ax

   shr ax, 1
   jnc even_line_a5
   xor di, 8192
even_line_a5:
   shr ax, 1
   jnc even_line_b5
   xor di, 8192
even_line_b5:
   inc ax

   shr ax, 1
   jnc even_line_a6
   xor di, 8192
even_line_a6:
   shr ax, 1
   jnc even_line_b6
   xor di, 8192
even_line_b6:
   inc ax

   shr ax, 1
   jnc even_line_a7
   xor di, 8192
even_line_a7:
   shr ax, 1
   jnc even_line_b7
   xor di, 8192
even_line_b7:
   inc ax

   shr ax, 1
   jnc even_line_a8
   xor di, 8192
even_line_a8:
   shr ax, 1
   jnc even_line_b8
   xor di, 8192
even_line_b8:
   inc ax

   shr ax, 1
   jnc even_line_a9
   xor di, 8192
even_line_a9:
   shr ax, 1
   jnc even_line_b9
   xor di, 8192
even_line_b9:
   inc ax

   shr ax, 1
   jnc even_line_a10
   xor di, 8192
even_line_a10:
   shr ax, 1
   jnc even_line_b10
   xor di, 8192
even_line_b10:
   inc ax

   shr ax, 1
   jnc even_line_a11
   xor di, 8192
even_line_a11:
   shr ax, 1
   jnc even_line_b11
   xor di, 8192
even_line_b11:
   inc ax

   shr ax, 1
   jnc even_line_a12
   xor di, 8192
even_line_a12:
   shr ax, 1
   jnc even_line_b12
   xor di, 8192
even_line_b12:
   inc ax
   
   shr ax, 1
   jnc even_line_a13
   xor di, 8192
even_line_a13:
   shr ax, 1
   jnc even_line_b13
   xor di, 8192
even_line_b13:
   inc ax

   shr ax, 1
   jnc even_line_a14
   xor di, 8192
even_line_a14:
   shr ax, 1
   jnc even_line_b14
   xor di, 8192
even_line_b14:
   inc ax

   shr ax, 1
   jnc even_line_a15
   xor di, 8192
even_line_a15:
   shr ax, 1
   jnc even_line_b15
   xor di, 8192
even_line_b15:
   inc ax

   shr ax, 1
   jnc even_line_a16
   xor di, 8192
even_line_a16:
   shr ax, 1
   jnc even_line_b16
   xor di, 8192
even_line_b16:
   inc ax

   shr ax, 1
   jnc even_line_a17
   xor di, 8192
even_line_a17:
   shr ax, 1
   jnc even_line_b17
   xor di, 8192
even_line_b17:
   inc ax

   shr ax, 1
   jnc even_line_a18
   xor di, 8192
even_line_a18:
   shr ax, 1
   jnc even_line_b18
   xor di, 8192
even_line_b18:
   inc ax

   shr ax, 1
   jnc even_line_a19
   xor di, 8192
even_line_a19:
   shr ax, 1
   jnc even_line_b19
   xor di, 8192
even_line_b19:
   inc ax

   shr ax, 1
   jnc even_line_a20
   xor di, 8192
even_line_a20:
   shr ax, 1
   jnc even_line_b20
   xor di, 8192
even_line_b20:
   inc ax

   shr ax, 1
   jnc even_line_a21
   xor di, 8192
even_line_a21:
   shr ax, 1
   jnc even_line_b21
   xor di, 8192
even_line_b21:
   inc ax

   shr ax, 1
   jnc even_line_a22
   xor di, 8192
even_line_a22:
   shr ax, 1
   jnc even_line_b22
   xor di, 8192
even_line_b22:
   inc ax

   shr ax, 1
   jnc even_line_a23
   xor di, 8192
even_line_a23:
   shr ax, 1
   jnc even_line_b23
   xor di, 8192
even_line_b23:
   inc ax

   shr ax, 1
   jnc even_line_a24
   xor di, 8192
even_line_a24:
   shr ax, 1
   jnc even_line_b24
   xor di, 8192
even_line_b24:
   inc ax

   shr ax, 1
   jnc even_line_a25
   xor di, 8192
even_line_a25:
   shr ax, 1
   jnc even_line_b25
   xor di, 8192
even_line_b25:
   inc ax

   shr ax, 1
   jnc even_line_a26
   xor di, 8192
even_line_a26:
   shr ax, 1
   jnc even_line_b26
   xor di, 8192
even_line_b26:
   inc ax

   shr ax, 1
   jnc even_line_a27
   xor di, 8192
even_line_a27:
   shr ax, 1
   jnc even_line_b27
   xor di, 8192
even_line_b27:
   inc ax

   shr ax, 1
   jnc even_line_a28
   xor di, 8192
even_line_a28:
   shr ax, 1
   jnc even_line_b28
   xor di, 8192
even_line_b28:
   inc ax

   shr ax, 1
   jnc even_line_a29
   xor di, 8192
even_line_a29:
   shr ax, 1
   jnc even_line_b29
   xor di, 8192
even_line_b29:
   inc ax

   shr ax, 1
   jnc even_line_a30
   xor di, 8192
even_line_a30:
   shr ax, 1
   jnc even_line_b30
   xor di, 8192
even_line_b30:
   inc ax

   shr ax, 1
   jnc even_line_a31
   xor di, 8192
even_line_a31:
   shr ax, 1
   jnc even_line_b31
   xor di, 8192
even_line_b31:
   inc ax

   shr ax, 1
   jnc even_line_a32
   xor di, 8192
even_line_a32:
   shr ax, 1
   jnc even_line_b32
   xor di, 8192
even_line_b32:
   inc ax

   shr ax, 1
   jnc even_line_a33
   xor di, 8192
even_line_a33:
   shr ax, 1
   jnc even_line_b33
   xor di, 8192
even_line_b33:
   inc ax

   shr ax, 1
   jnc even_line_a34
   xor di, 8192
even_line_a34:
   shr ax, 1
   jnc even_line_b34
   xor di, 8192
even_line_b34:
   inc ax

   shr ax, 1
   jnc even_line_a35
   xor di, 8192
even_line_a35:
   shr ax, 1
   jnc even_line_b35
   xor di, 8192
even_line_b35:
   inc ax

   shr ax, 1
   jnc even_line_a36
   xor di, 8192
even_line_a36:
   shr ax, 1
   jnc even_line_b36
   xor di, 8192
even_line_b36:
   inc ax

   shr ax, 1
   jnc even_line_a37
   xor di, 8192
even_line_a37:
   shr ax, 1
   jnc even_line_b37
   xor di, 8192
even_line_b37:
   inc ax

   shr ax, 1
   jnc even_line_a38
   xor di, 8192
even_line_a38:
   shr ax, 1
   jnc even_line_b38
   xor di, 8192
even_line_b38:
   inc ax

   shr ax, 1
   jnc even_line_a39
   xor di, 8192
even_line_a39:
   shr ax, 1
   jnc even_line_b39
   xor di, 8192
even_line_b39:
   inc ax

   shr ax, 1
   jnc even_line_a40
   xor di, 8192
even_line_a40:
   shr ax, 1
   jnc even_line_b40
   xor di, 8192
even_line_b40:
   inc ax

   shr ax, 1
   jnc even_line_a41
   xor di, 8192
even_line_a41:
   shr ax, 1
   jnc even_line_b41
   xor di, 8192
even_line_b41:
   inc ax

   shr ax, 1
   jnc even_line_a42
   xor di, 8192
even_line_a42:
   shr ax, 1
   jnc even_line_b42
   xor di, 8192
even_line_b42:
   inc ax

   shr ax, 1
   jnc even_line_a43
   xor di, 8192
even_line_a43:
   shr ax, 1
   jnc even_line_b43
   xor di, 8192
even_line_b43:
   inc ax

   shr ax, 1
   jnc even_line_a44
   xor di, 8192
even_line_a44:
   shr ax, 1
   jnc even_line_b44
   xor di, 8192
even_line_b44:
   inc ax

   shr ax, 1
   jnc even_line_a45
   xor di, 8192
even_line_a45:
   shr ax, 1
   jnc even_line_b45
   xor di, 8192
even_line_b45:
   inc ax

   shr ax, 1
   jnc even_line_a46
   xor di, 8192
even_line_a46:
   shr ax, 1
   jnc even_line_b46
   xor di, 8192
even_line_b46:
   inc ax

   shr ax, 1
   jnc even_line_a47
   xor di, 8192
even_line_a47:
   shr ax, 1
   jnc even_line_b47
   xor di, 8192
even_line_b47:
   inc ax

   shr ax, 1
   jnc even_line_a48
   xor di, 8192
even_line_a48:
   shr ax, 1
   jnc even_line_b48
   xor di, 8192
even_line_b48:
   inc ax

   shr ax, 1
   jnc even_line_a49
   xor di, 8192
even_line_a49:
   shr ax, 1
   jnc even_line_b49
   xor di, 8192
even_line_b49:
   inc ax

   shr ax, 1
   jnc even_line_a50
   xor di, 8192
even_line_a50:
   shr ax, 1
   jnc even_line_b50
   xor di, 8192
even_line_b50:
   inc ax

   dec cx
   jz bank_done
   jmp bank_loop

bank_done:
   mov  ah,4ch                      ;DOS terminate program function
   int  21h                         ;terminate the program
   END
