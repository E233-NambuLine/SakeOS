[org 0x7C00]
[bits 16]

section .bss
lfb_addr db 8

section .text
start:
mov ax, 4F01h
int 0x10
mov eax, [lfb_addr]
mov ax, 0x4F02
mov bx, 0x4118      ; 800x600x32bpp (LFB)
int 0x10

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

mov al, 'O'
mov cx, 1
call vram_char_draw
jmp pm

gdt_start:
    dq 0x0000000000000000      ; ヌル

   ; コードセグメント: base=0, limit=0xFFFFF, 4GB, exec/read
    dq 0x00CF9A000000FFFF

    ; データセグメント: base=0, limit=0xFFFFF, 4GB, read/write
    dq 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

pm:
mov eax, cr0
or eax, 1
mov cr0, eax
lgdt [gdt_descriptor]
jmp dword 0x08:pm_entry
[bits 32]
pm_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax
mov al, '!'
mov bx, 0x0F
mov cx, 0x10

;initialize
;call all_disk_read

mov dword [0xB800], 0xFFFFFFFFFFFFFFFFFFFFF
cli
xor eax, eax
;mov 

jmp 0x10000:0000
jc disk_err

disk_err:
hlt
;ret

;call vram_char_draw
[bits 16]
ata_write:

ata_read:
mov dx, 0x1F6
mov al, 0xE0
out dx, al

mov dx, 0x1F2       ; sector count
mov al, 1
out dx, al

mov dx, 0x1F3       ; LBA low
mov al, 0x01
out dx, al

mov dx, 0x1F4       ; LBA mid
mov al, 0x00
out dx, al

mov dx, 0x1F5       ; LBA high
mov al, 0x00
out dx, al

mov dx, 0x1F6       ; device/head (上で書いたやつに LBA[24..27] 足す)
mov al, 0xE0 ; (<LBA3> & 0x0F)
out dx, al

mov dx, 0x1F7
mov al, 0x20        ; READ SECTORS (with retry)
out dx, al

.wait:
    in al, dx       ; dx = 0x1F7 のまま
    test al, 0x80   ; BSY
    jnz .wait
    test al, 0x08   ; DRQ
    jz .wait

mov dx, 0x1F0
mov cx, 256
.read_loop:
    in ax, dx
    mov [di], ax    ; di にバッファ
    add di, 2
    loop .read_loop

vram_char_draw:
    push ax
    push bx
    push cx
    push es
    push di

    mov ax, 0xB800
    mov es, ax

    mov di, cx
    shl di, 1        ; 文字番号 → バイトオフセット

    mov [es:di], al
    mov [es:di+1], bl

    pop di
    pop es
    pop cx
    pop bx
    pop ax
    ret

times 510-($-$$) db 0
dw 0xAA55