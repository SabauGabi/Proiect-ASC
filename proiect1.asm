<<<<<<< HEAD
ASSUME cs:code, ds:data,ss:stiva
STIVA segment PARA STACK 'STACK'
 DB 200h dup(0)
 STIVA ends
data segment
msg_intro       db 13,10,'Introduceti octetii in format HEX (8-16 valori, ex: 3F 1A 0B).',13,10,' Separati prin spatiu: $'
    msg_eroare      db 13,10,'EROARE: Numar incorect de octeti! Trebuie intre 8 si 16.',13,10,'$'
    msg_invalid     db 13,10,'EROARE: Format HEX invalid! Folositi doar 0-9, A-F si separati cu spatiu.',13,10,'$'
    msg_succes      db 13,10,'Datele au fost citite si convertite in memorie.',13,10,'$'

    citire          db 60, ?, 60 dup(?)
    sir_octeti      db 16 dup(0)
    lungime_sir     db 0
data ends

code segment
start:
move ax,data
move ds,ax
mov ax,4C00h
int 21h
PARSARE PROC NEAR
    lea si, citire + 2
    lea di, sir_octeti
    mov cl, citire[1]
    xor ch, ch
    mov lungime_sir, 0

P_SKIP:
    cmp cx, 0
    je P_OK
    mov al, [si]
    cmp al, ' '
    jne P_NEED2
    inc si
    dec cx
    jmp P_SKIP

P_NEED2:
    cmp cx, 2
    jb P_ERR

    mov al, [si]
    call CHAR_TO_VAL
    jc P_ERR
    mov dh, al
    shl dh, 4
    inc si
    dec cx

    mov al, [si]
    call CHAR_TO_VAL
    jc P_ERR
    or dh, al
    inc si
    dec cx

    cmp cx, 0
    je P_STORE
    mov al, [si]
    cmp al, ' '
    jne P_ERR

P_STORE:
    mov al, lungime_sir
    cmp al, 16
    jae P_TOO_MANY
    mov [di], dh
    inc di
    inc lungime_sir
    jmp P_SKIP

P_TOO_MANY:
    mov lungime_sir, 17
    clc
    ret

P_ERR:
    stc
    ret

P_OK:
    clc
    ret
PARSARE ENDP

CHAR_TO_VAL PROC NEAR
    cmp al, '0'
    jb CTV_BAD
    cmp al, '9'
    jbe CTV_DIG

    cmp al, 'A'
    jb CTV_LOWCHK
    cmp al, 'F'
    jbe CTV_UP

CTV_LOWCHK:
    cmp al, 'a'
    jb CTV_BAD
    cmp al, 'f'
    jbe CTV_LOW
    jmp CTV_BAD

CTV_DIG:
    sub al, '0'
    clc
    ret

CTV_UP:
    sub al, 'A'
    add al, 10
    clc
    ret

CTV_LOW:
    sub al, 'a'
    add al, 10
    clc
    ret

CTV_BAD:
    stc
    ret
CHAR_TO_VAL ENDP
code ends
end start
=======
ASSUME cs:code,ds:data
data segment
;datele de intrare
data ends
code segment
start:
mov ax,data
move ds,ax
mov ax,4C00h
int 21h
code ends
end start
