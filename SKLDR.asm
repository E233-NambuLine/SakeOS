[org 0x8000]
[bits 16]

start:
    cli
    lgdt [gdt_descriptor]     ; 1. GDT を先にロード

    mov eax, cr0
    or eax, 1                 ; 2. PE=1
    mov cr0, eax

    jmp 0x08:pm_entry         ; 3. far jump で PM へ

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
    mov esp, 0x90000           ; スタック
    ; ここから32bitコード

global isr_common

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
ret

jmp 0x10000
jc disk_err

disk_err:
mov ax, 0x000E
cli
hlt