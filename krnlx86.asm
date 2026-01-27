[org 0x10000]
[bits 32]

section .bss
draw_x: resb 4
draw_y: resb 4
readpos: resb 6
mem_pos: resb 6
sector: resb 6
color_r: resb 1
color_g: resb 1
color_b : resb 1
draw_a: resb 1
excldr_ver: resb 1
vram_addr: resb 12
draw_vram_addr resb 12

section .text
start:
mov word [excldr_ver], 0x0A
cli
hlt

draw_rect:
call reg_push
draw:
mov ebx, [vram_addr]
mov ecx, [draw_x]
mov eax, [ebx+ecx]
mov dword [draw_vram_addr], eax

call reg_pop
ret

reg_push:
push eax
push ebx
push ecx
push edi
push edx
push esi
ret

reg_pop:
pop esi
pop edx
pop edi
pop ecx
pop ebx
pop eax
ret

