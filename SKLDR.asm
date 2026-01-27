[org 0x8000]
[bits 16]

section .bss
sectors: resb 1
mem_pos: resb 3
readpos: resb 2
vram_seg: resb 3
vram_off: resb 4

section .text
start:
mov ax, 0x0000
mov es, ax
mov di, 0x7E01
mov ax, 0x4F00
int 0x10

xor ax, ax

cmp ax, 0x004F
jne vbe_inop

mov bx, [es:di+0x0E] ; offset
mov cx, [es:di+0x10] ; segment
mov [vram_seg],  cx
mov [vram_off], bx

push ax
mov ax, [vram_seg]
mov es, ax
pop ax

push bx

mov bx, [vram_off]

; モード番号一覧を読む
next_mode:
    mov cx, [es:bx]
    cmp cx, 0xFFFF
    je end
    ; ここで cx がモード番号
    add bx, 2
    jmp next_mode

end:
mov es, ax
mov di, 0x7F01
mov ax, 0x4F01
int 0x10



vbe_inop:
hlt

forpm:
    cli
    lgdt [gdt_descriptor]     ; ① GDT を先にロード

    mov eax, cr0
    or eax, 1                 ; ② PE=1
    mov cr0, eax

    jmp 0x08:pm_entry         ; ③ far jump で PM へ

; -------------------------
; GDT
; -------------------------
gdt_start:
    dq 0x0000000000000000      ; null

    dq 0x00CF9A000000FFFF      ; code
    dq 0x00CF92000000FFFF      ; data
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; -------------------------
; PM entry
; -------------------------
[bits 32]
pm_entry:
    mov ax, 0x10               ; data selector
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000           ; 適当なスタック
    ; ここから32bitコード

global isr_common
call init_idt
jmp start32

isr_common:
cli
hlt

init_idt:
    mov eax, isr_common
    xor edi, edi
call .fill_loop

.fill_loop:
    push eax
    push edi
    call set_idt_entry
    pop edi
    pop eax

    inc edi
    cmp edi, 256
    jl .fill_loop
    ret

idt_ptr:
    dw idt_end - idt - 1
    dd idt

load_idt:
    lidt [idt_ptr]
    ret

idt:
    times 256-($-$$) dq 0
idt_end:

set_idt_entry:
mov ebx, idt
lea ebx, [ebx + ebx*8]

mov word [ebx], ax
mov word [ebx+2], 0x08
mov word [ebx+4], 0
mov word [ebx+5], 0x8E
shr eax, 16
mov word [ebx+6], ax
ret

start32:

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ;mov 
;ret

call krnlread

krnlread:
mov dx, 0x1F2
mov al, 0x01
out dx, al

mov dx, 0x1F3
mov al, [readpos]
out dx, al

shr byte [readpos], 1

mov dx, 0x1F4
mov al, [readpos]
out dx, al

shr byte [readpos], 1

mov dx, 0x1F5
mov al, [readpos]
out dx, al

mov dx, 0x1F6
mov al, [readpos]
out dx, al

shr byte [readpos], 8

mov dx, 0x1F7
mov al, [readpos]
out dx, al

.wait:
in al, dx
test al, 0x80
jnz .wait
in al, dx
test al, 0x08
jnz .wait

mov dx, 0x1F0
mov di, [mem_pos]
mov cx, 256

rep insw

inc byte [readpos]
add word [mem_pos], 512

dec byte [sectors]
jnz krnlread

jmp 0x10000
jc disk_err

disk_err:
mov ax, 0x000E
cli
hlt