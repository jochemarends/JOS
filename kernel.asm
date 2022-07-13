[BITS 16]
start:
    mov     si, welcome_msg
    call    write_string
.L1:    
    mov     si, buffer
    call    read_string
    jmp     .L1

; Command table

welcome_msg db "welcome to the kernel!", 0
buflen equ 512
buffer times buflen db 0

; Constants for colors
black           equ 0
blue            equ 1
green           equ 2
cyan            equ 3
red             equ 4
magenta         equ 5
brown           equ 6
light_grey      equ 7
dark_grey       equ 8
light_blue      equ 9
light_green     equ 10
light_cyan      equ 11
light_red       equ 12
light_magenta   equ 13
light_brown     equ 14
white           equ 15

;----------------------------------------------------------
get_video_mode:
; Receives: nothing
; Returns:  AL = Video mode flag
;           AH = Number of character columns
;           BH = active page
;----------------------------------------------------------
    mov     ah, 0xF     ; Get Video Mode
    int     0x10        ; Video Services
    ret

;----------------------------------------------------------
set_video_mode:
; Receives: AL = Video mode flag
; Returns:  nothing
;----------------------------------------------------------
    mov     ah, 0x00    ; Set Video Mode
    int     0x10        ; Video Services
    ret

;----------------------------------------------------------
read_char:
; Receives: nothing
; Returns:  AH = Scan code
;           AL = ASCII code
;----------------------------------------------------------
    mov     ah, 0x00    ; Read character
    int     0x16        ; Keyboard Services
    ret

;----------------------------------------------------------
read_string:
; Receives: SI = Address pointing to a buffer which is
;           expected to be large enough to hold all ASCII
;           characters plus a null-terminator
; Returns:  nothing
;----------------------------------------------------------
%define char_count bp - 2
backspace_sc    equ 0x0E
backspace_ac    equ 0x08
enter_sc        equ 0x1C
    push    bp
    mov     bp, sp
    push    0
.L1:
    mov     ah, 0x00    ; Read character
    int     0x16        ; Keyboard services

; Handle backspace press
    cmp     ah, backspace_sc
    jne     .L2
    cmp     WORD [char_count], 0
    je      .L1
    call    write_char
    mov     ah, 0x0A    ; Write character only at cursor position
    mov     al, ' '     ; Clear the character at the current cursor position
    mov     bh, 0x00    ; Video page
    mov     cx, 1       ; Number of times to print
    int     0x10
    dec     WORD [char_count]
    dec     si
    jmp     .L1
.L2:
; Handle enter press
    cmp     ah, enter_sc
    jne     .L3
    mov     al, 0x0D
    call    write_char
    mov     al, 0x0A
    call    write_char
    jmp     .L4
.L3:
; Handle other characters
    cmp     al, 0
    je      .L1
    call    write_char
    mov     BYTE [si], al
    inc     si
    inc     WORD [char_count]
    jmp     .L1
.L4:
    mov     BYTE [si], 0
    mov     sp, bp
    pop     bp
    ret

;----------------------------------------------------------
write_char:
; Receives: AL = ASCII character
; Returns:  nothing
;----------------------------------------------------------
    push    ax
    push    bx
    mov     ah, 0xE     ; Write character in TTY Mode
    mov     bh, 0x00    ; Page number
    int     0x10        ; Video Services
    pop     bx
    pop     ax
    ret

;----------------------------------------------------------
write_string:
; Receives: SI = Address pointing to an ASCIZ string
; Returns:  nothing
;----------------------------------------------------------
.L1:    
    mov     al, [si]    ; Move the value at [si] into al
    cmp     al, 0       ; Check for a null-terminator
    je      .L2
    call    write_char
    inc     si          ; Look at the next character
    jmp    .L1
.L2:
    ret

;----------------------------------------------------------
write_int:
; Receives: AX = A 16-bit integer
; Returns:  nothing
;----------------------------------------------------------
    push    sp
    sub     sp, 10      ; Allocate 10 bytes for a buffer
    mov     si, sp
    call    to_string
    mov     si, sp
    call    write_string
    pop     sp
    ret

;----------------------------------------------------------
to_string:
; Converts an unsigned integer to an ASCIZ string
;
; Receives: AX = A 16-bit integer
;           SI = Address pointing to a buffer which is
;           expected to be large enough to hold all ASCII
;           characters plus a null-terminator
; Returns:  nothing
;----------------------------------------------------------
    pusha
    mov     bx, 10      ; The base we need to divide by
    mov     cx, 0       ; Digit counter
.L1:
    xor     dx, dx
    div     bx
    add     dx, '0'     ; Convert the remainder to ASCII
    push    dx          ; Save the value on the stack
    inc     cx          ; Increment digit counter
    cmp     ax, 0
    jne     .L1         ; Repeat while the quotient does not equal zero
.L2:
    pop     ax
    mov     [si], al
    inc     si
    loop    .L2
    mov     BYTE [si], 0
    popa
    ret

;----------------------------------------------------------
to_s_string:
; Converts a signed integer to an ASCIZ string
;
; Receives: AX = A 16-bit integer
;           SI = Address pointing to a buffer which is
;           expected to be large enough to hold all ASCII
;           characters plus a null-terminator
; Returns:  nothing
;----------------------------------------------------------
    mov     bx, 10      ; The base we need to divide by
    mov     cx, 0       ; Digit counter
    cmp     ax, 0       ; Check for sign
    jnb     .L1
    neg     ax
    push    '-'
    inc     cx
.L1:
    xor     dx, dx
    div     bx
    add     dx, '0'     ; Convert the remainder to ASCII
    push    dx          ; Save the value on the stack
    inc     cx          ; Increment digit counter
    cmp     ax, 0
    jne      .L1        ; Repeat while the quotient does not equal zero
    
.L2:
    pop     ax
    mov     [si], al
    inc     si
    loop    .L2
    mov     BYTE [si], 0
    ret
