[ORG 0x7c00]
[BITS 16]

mov [MAIN_DISK], dl

; Codigo de arranque
mov bp, 0x1000
mov sp, bp

mov bx, STRING
call print_string

;Configurar la lectura del disco
    mov dl, [MAIN_DISK]
    mov ah, 0x02 ; Operacion de lectura
    mov al, 0x01 ; Nº de sectores a leer
    mov ch, 0x00 ; Cilindro
    mov dh, 0x00 ; Cabezal
    mov cl, 0x02 ; Sector
    mov bx, 0x8000 ; Dirección a la que escribimos
    int 0x13 ; Llamada a la bios

mov ax, handler_kbd
call install_keyboard

call Sector2
jmp $

;bx direccion de la string
print_string:
    pusha
    xor si, si
.loop:
    mov al, byte [bx+si]
    inc si
    cmp al, 0
    je .end
    call print_char
    jmp .loop
.end:
    popa
    ret

print_char:
    push ax
    mov ah, 0x0E
    int 0x10
    pop ax
    ret

;ax = handler address
install_keyboard:
    push word 0
    pop ds
    cli
    ; Instalar el ISR del teclado
    mov [4 * KEYBOARD_INTERRUPT], word keyboardHandler
    mov [4 * KEYBOARD_INTERRUPT + 2], cs
    mov word [HANDLER], ax
    sti
    ret

handler_kbd:
    mov al, [bx]
    cmp al, 'h'
    je .hola
    cmp al, 'a'
    je .adios
    cmp al, 'r'
    je .read
    cmp al, 'l'
    je .logo
    cmp al, 'v'
    je .version
    cmp al, 's'
    je .status
    mov bx, INVALID
    call print_string
    ret
.read:
    mov dl, [MAIN_DISK]
    mov ah, 0x02 ; Operacion de lectura
    mov al, 0x01 ; Nº de sectores a leer
    mov ch, 0x00 ; Cilindro
    mov dh, 0x00 ; Cabezal
    mov cl, 0x03 ; Sector
    mov bx, 0x9000 ; Dirección a la que escribimos
    int 0x13 ; Llamada a la bios
    call print_string
    ret
.hola:
    mov bx, STRING
    call print_string
    ret
.adios:
    mov bx, STRONG
    call print_string
    ret
.logo:
    mov bx, LOGO
    call print_string
    ret
.version:
    mov bx, VERSION
    call print_string
    ret
.status:
    mov bx, STATUS
    call print_string
    ret

;bx = direccion de la string, cl = tamanho string (max 64c)
keyboardHandler:
    pusha
    in al, 0x60
    test al, 0x80
    jnz .end
    mov bl, al
    xor bh, bh
    mov al, [cs:bx + keymap]
    cmp al, 13
    je .enter
    mov bl, [WORD_SIZE]
    mov [WRD+bx], al
    inc bx
    mov [WORD_SIZE], bl
    mov ah, 0x0e
    int 0x10
.end:
    mov al, 0x61
    out 0x20, al
    popa
    iret
.enter:
    mov bx, WRD
    mov cl, [WORD_SIZE]
    mov dx, [HANDLER]
    call dx
    mov byte [WORD_SIZE], 0
    jmp .end

WORD_SIZE: db 0
WRD: times 64 db 0
STRING: db "Hola!", 0
STRONG: db "Adios", 0
INVALID: db "Comando invalido", 0
LOGO: db "*MINI OS*", 0
VERSION: db "Version 0.1", 0
STATUS: db "Sistema funcionando", 0
MAIN_DISK: db 0
KEYBOARD_INTERRUPT EQU 9
HANDLER: dw 0

keymap:
%include "keymap.inc"

; Sector 1
times 510-($-$$) db 0
dw 0xaa55
; Sector 2 (segunda etapa)
Sector2:
jmp $
times 1024-($-$$) db 0
; Sector 3 (Lectura del disco)
db "Mensaje almacenado en el disco, estos son los comandos disponibles: h = Hola, a = Adios, r = Leer sector, c = Limpiar, v = Version, s = Estado, l = Logo", 0x0
times 2048- ($-$$) db 0