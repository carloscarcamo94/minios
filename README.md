# minios

# Como ejecutar
"C:\Program Files\qemu\qemu-system-x86_64.exe" -fda boot

# Como ensamblar
"C:\Program Files\NASM\nasm.exe" -fbin boot.asm

# Función limpiar pantalla
.clear:
    mov bx, CLEARING
    call print_string

    ; Pequeño bucle de retardo para mostrar el mensaje
    mov cx, 0xFFFF
.delay:
    loop .delay
    call clear_screen
    ret

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

CLEARING: db "Limpiando pantalla...", 0 