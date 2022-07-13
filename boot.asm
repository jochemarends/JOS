[BITS 16]
[ORG 0x7C00]

; FAT12 Header
jmp short start
nop
times 8 db 0
bytes_per_sector        dw 512
sectors_per_cluster     dw 1
reserved_sectors        dw 1
fat_count               db 2
dir_entry_count         dw 0x00E0
total_sectors           dw 0x0B40
media_descriptor_type   db 0x0F0
sectors_per_fat         dw 9
sectors_per_track       dw 18
heads                   dw 2
hidden_sectors          dd 0
large_sector_count      dd 0

; Extended boot record
drive_number            db 0
                        db 0
signature               db 0x29
volume_id               dw 0x1234, 0x5678
volume_label            times 11 db ' '
system_id               db 'FAT12   '       ; 8 bytes

start:
    cli
    mov     si, welcome_msg
    call    write

    mov     [boot_drive], dl    ; Saving the boot drive
    mov     sp, 0x7C00          ; Make the stack pointer point to the memory below the bootloader

    mov     ah, 0x00            ; Reset Disk drives
    int     0x13                ; Low Level Disk Serivces

    mov     ah, 0x02            ; Read Sectors
    mov     al, 0x10            ; Sectors to read (16)
    mov     ch, 0x00            ; Cylinder
    mov     cl, 2               ; Sector
    mov     dh, 0x00            ; Head
    mov     dl, [boot_drive]    ; Drive
    mov     bp, 0x1000          ; ES:BX = Buffer Address Pointer
    mov     es, bp
    mov     bx, 0x0000          
    int     0x13                ; Low Level Disk Serivces
    mov     ds, bp              ; Setting correct data segment
    sti
    jmp     0x1000:0x0000       ; Jump to the kernel

;----------------------------------------------------------
lba_to_chs:
; Receives: AX = LBA
; Returns:  CH = Cylinder
;           CL = Sector
;           DH = Head
;----------------------------------------------------------
; Calculate the sector
    push    ax
    xor     dx, dx
    div     word [sectors_per_track]
    inc     dx
    push    dx    
    mov     cl, al

; Calculate the cylinder & head
    xor     dx, dx
    div     word [heads]
    mov     dh, dl
    mov     ch, al
    pop     dx
    pop     ax
    ret

;----------------------------------------------------------
read_disk:
; Receives: AX = LBA
;           CL = Number of sectors to read
;           DL = Drive number
;           ES:BX = Buffer address pointer
;----------------------------------------------------------
    push    cx
    call    lba_to_chs
    mov     ah, 0x02            ; Read secotrs
    pop     ax                  ; Number of sectors to read

; Try 3 times since floppy disks are somewhat unreliable
    mov     bp, 3               ; Loop counter
.L1:
    pusha
    int     0x13                ; Low level disk services
    popa
    jnc     .L2
    dec     bp
    cmp     bp, 0
    je      .L1
    mov     si, failed_to_read_disk_msg
    call    write
.L2:
    ret

;----------------------------------------------------------
write:
; Receives: SI = Address pointing to an ASCIZ string
; Returns:  nothing
;----------------------------------------------------------
    mov     al, [si]
    cmp     al, 0
    je      .L1
    mov     ah, 0x0E
    int     0x10
    inc     si
    jmp     write
.L1:
    ret

boot_drive db 0
welcome_msg db "welcome to the bootloader!", 0x0A, 0x0D, 0
failed_to_read_disk_msg db "failed to read from disk", 0

times 510-($-$$) db 0           ; Padding
dw 0xAA55                       ; Boot signature
