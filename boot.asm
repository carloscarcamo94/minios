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

call second_stage

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
    cmp al, 'c'
    je .clear
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
.clear:
    mov bx, CLEARING
    call print_string

    ; Pequeño bucle de retardo para mostrar el mensaje
    mov cx, 0xFFFF
.delay:
    loop .delay
    call clear_screen
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

clear_screen:
    push ax
    push bx
    push cx
    push dx

    mov ax, 0x0600     ; Scroll up entire screen
    mov bh, 0x07       ; Atributo (gris claro sobre negro)
    mov cx, 0x0000     ; Coordenada superior izquierda (fila 0, col 0)
    mov dx, 0x184F     ; Coordenada inferior derecha (fila 24, col 79)
    int 0x10           ; Llamada BIOS para limpiar

    mov ah, 0x02       ; Mover cursor a esquina superior
    mov bh, 0x00
    mov dx, 0x0000
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax
    ret

WORD_SIZE: db 0
WRD: times 64 db 0
STRING: db "Hola Mundo!", 0
STRONG: db "Adios Mundo!", 0
INVALID: db "Comando invalido", 0
CLEARING: db "Limpiando pantalla...", 0 
MAIN_DISK: db 0
KEYBOARD_INTERRUPT EQU 9
HANDLER: dw 0


keymap:
%include "keymap.inc"

times 510-($-$$) db 0
dw 0xaa55

second_stage:
    jmp $

times 1024-($-$$) db 0

db "Este es la lectura que hemos almacenado en el disco", 0x0

times 2048- ($-$$) db 0
