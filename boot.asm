[org 0x7C00]
[bits 16]

section .bss
mem_pos resb 2
readpos: resb 1
sectors: resb 1

section .text
start:
in al, 0x92
or al, 0b00000010
out 0x92, al

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

mov byte [readpos], 1        ; LBA = 1 から
mov word [mem_pos], 0x8000   ; 読み込み先
mov byte [sectors], 3        ; 読むセクタ数 = 3

read_loop:
    mov dx, 0x1F2            ; Sector Count
    mov al, 0x01
    out dx, al

    mov dx, 0x1F3            ; LBA low
    mov al, [readpos]
    out dx, al

    mov dx, 0x1F4            ; LBA mid
    mov al, 0x00
    out dx, al

    mov dx, 0x1F5            ; LBA high
    mov al, 0x00
    out dx, al

    mov dx, 0x1F6            ; Drive/Head
    mov al, 0xE0             ; LBA, master
    out dx, al

    mov dx, 0x1F7
    mov al, 0x20             ; READ SECTORS
    out dx, al

    mov dx, 0x1F7
.wait:
    in  al, dx
    test al, 0x80            ; BSY?
    jnz .wait
    test al, 0x08            ; DRQ?
    jz  .wait

    mov dx, 0x1F0
    mov di, [mem_pos]
    mov cx, 256
    rep insw                  ; 1セクタ分読む

    ; 次のセクタへ
    inc byte [readpos]        ; LBA++
    add word [mem_pos], 512   ; バッファ +512

    dec byte [sectors]
    jnz read_loop
jmp word 0x0000:0x8000
jc jmp_err

jmp_err:
mov ax, 0x000E
cli
hlt

times 510-($-$$) db 0
dw 0xAA55