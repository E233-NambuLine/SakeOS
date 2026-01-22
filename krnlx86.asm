[org 0x1000]
[bits 32]

start:
mov eax, 0x00008365
mov ebx, eax

sofs:
cmp ah, 0x02
je sofs_read
cmp ah, 0x03
je sofs_write

