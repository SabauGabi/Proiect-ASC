STIVA SEGMENT PARA STACK 'STACK'
    DB 200h DUP(0)
STIVA ENDS

DATA SEGMENT
    msg_intro       db 13,10,'Introduceti octetii in format HEX (8-16 valori, ex: 3F 1A 0B).',13,10,' Separati prin spatiu: $'
    msg_eroare      db 13,10,'EROARE: Numar incorect de octeti! Trebuie intre 8 si 16.',13,10,'$'
    msg_invalid     db 13,10,'EROARE: Format HEX invalid! Folositi doar 0-9, A-F si separati cu spatiu.',13,10,'$'
    msg_succes      db 13,10,'Datele au fost citite si convertite in memorie.',13,10,'$'
    msg_C           db 13,10,13,10,'Cuvantul C calculat (HEX): $'
    msg_sortat      db 13,10,'Sirul sortat descrescator: $'
    msg_idx_max1    db 13,10,'Pozitia octetului cu cei mai multi biti 1 (>3): $'
    msg_no_max1     db 13,10,'Nu exista octet cu mai mult de 3 biti de 1.',13,10,'$'
    msg_rotiri      db 13,10,13,10,'Sirul dupa rotiri (Binar | Hex):',13,10,'$'
    newline_str     db 13,10,'$'
    bar_str         db ' | $'
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

    cuvantul_C      dw 0

    index_one       db 0
    max_one         db 0
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STIVA

START:
    mov ax, DATA
    mov ds, ax

CITIRE_LOOP:
    mov ah, 09h
    lea dx, msg_intro
    int 21h

    mov ah, 0Ah
    lea dx, citire
    int 21h

    call PARSARE
    jc EROARE_INVALID

    cmp lungime_sir, 8
    jl EROARE_LUNGIME
    cmp lungime_sir, 16
    jg EROARE_LUNGIME

    mov ah, 09h
    lea dx, msg_succes
    int 21h
    jmp ETAPA_2

EROARE_INVALID:
    mov ah, 09h
    lea dx, msg_invalid
    int 21h
    jmp CITIRE_LOOP

EROARE_LUNGIME:
    mov ah, 09h
    lea dx, msg_eroare
    int 21h
    jmp CITIRE_LOOP

ETAPA_2:
    call CALCUL_CUVANT_C

    mov ah, 09h
    lea dx, msg_C
    int 21h

    mov ax, cuvantul_C
    mov bl, al
    mov al, ah
    call PRINT_HEX_BYTE
    mov al, bl
    call PRINT_HEX_BYTE

    call SORT_DESC

    mov ah, 09h
    lea dx, msg_sortat
    int 21h
    call AFISARE_SIR_HEX

    call max_de_1

    cmp index_one, 0
    je NU_EXISTA_MAX

    mov ah, 09h
    lea dx, msg_idx_max1
    int 21h

    mov al, index_one
    call PRINT_DEC_BYTE
    jmp ETAPA_4

NU_EXISTA_MAX:
    mov ah, 09h
    lea dx, msg_no_max1
    int 21h

ETAPA_4:
    call APLICA_ROTIRI

    mov ah, 09h
    lea dx, msg_rotiri
    int 21h

    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti

BUCLA_AFISARE_ROTIRI:
    mov al, [si]
    call PRINT_BIN_BYTE

    push ax
    push dx
    mov ah, 09h
    lea dx, bar_str
    int 21h
    pop dx
    pop ax

    call PRINT_HEX_BYTE

    push ax
    push dx
    mov ah, 09h
    lea dx, newline_str
    int 21h
    pop dx
    pop ax

    inc si
    loop BUCLA_AFISARE_ROTIRI

    mov ax, 4C00h
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

CALCUL_CUVANT_C PROC NEAR
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti
    xor bl, bl

CC_SUM:
    mov al, [si]
    add bl, al
    inc si
    loop CC_SUM

    mov ah, bl

    xor dl, dl
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti

CC_OR:
    mov al, [si]
    and al, 00111100b
    shr al, 2
    or  dl, al
    inc si
    loop CC_OR

    shl dl, 4

    mov al, sir_octeti
    and al, 00001111b

    mov bl, lungime_sir
    xor bh, bh
    dec bl
    lea si, sir_octeti
    add si, bx
    mov bl, [si]
    and bl, 11110000b
    shr bl, 4

    xor al, bl
    or  dl, al

    mov bh, ah
    mov bl, dl
    mov cuvantul_C, bx
    ret
CALCUL_CUVANT_C ENDP

APLICA_ROTIRI PROC NEAR
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti

AR_LOOP:
    mov al, [si]
    push cx

    mov bl, al
    and bl, 1
    mov dh, al
    and dh, 2
    shr dh, 1
    add bl, dh

    mov cl, bl
    cmp cl, 0
    je AR_NEXT
    rol al, cl

AR_NEXT:
    mov [si], al
    pop cx
    inc si
    dec cl
    jnz AR_LOOP
    ret
APLICA_ROTIRI ENDP

SORT_DESC PROC NEAR
    mov cl, lungime_sir
    cmp cl, 1
    jbe SD_DONE

    dec cl
SD_OUTER:
    mov si, OFFSET sir_octeti
    mov ch, lungime_sir
    dec ch
SD_INNER:
    mov al, [si]
    mov ah, [si+1]
    cmp al, ah
    jge SD_NOSWAP
    mov [si], ah
    mov [si+1], al
SD_NOSWAP:
    inc si
    dec ch
    jnz SD_INNER
    dec cl
    jnz SD_OUTER
SD_DONE:
    ret
SORT_DESC ENDP

max_de_1 PROC NEAR
    mov index_one, 0
    mov max_one, 0

    mov cl, lungime_sir
    xor ch, ch
    jcxz MO_DONE

    lea si, sir_octeti
    mov dh, 1

MO_LOOP:
    mov bl, [si]
    xor al, al
    mov dl, 8

MO_CNT:
    shr bl, 1
    adc al, 0
    dec dl
    jnz MO_CNT

    cmp al, max_one
    jbe MO_NEXT
    mov max_one, al
    mov index_one, dh

MO_NEXT:
    inc si
    inc dh
    loop MO_LOOP

    cmp max_one, 4
    jae MO_DONE
    mov index_one, 0

MO_DONE:
    ret
max_de_1 ENDP

AFISARE_SIR_HEX PROC NEAR
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti
ASH_LOOP:
    mov al, [si]
    call PRINT_HEX_BYTE
    mov ah, 02h
    mov dl, ' '
    int 21h
    inc si
    loop ASH_LOOP
    ret
AFISARE_SIR_HEX ENDP

PRINT_HEX_BYTE PROC NEAR
    push ax
    push bx
    push cx
    push dx

    mov bl, al
    mov al, bl
    shr al, 4
    call NIBBLE_TO_CHAR
    mov ah, 02h
    mov dl, al
    int 21h

    mov al, bl
    and al, 0Fh
    call NIBBLE_TO_CHAR
    mov ah, 02h
    mov dl, al
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_HEX_BYTE ENDP

NIBBLE_TO_CHAR PROC NEAR
    cmp al, 9
    jbe NTC_DIG
    add al, 7
NTC_DIG:
    add al, '0'
    ret
NIBBLE_TO_CHAR ENDP

PRINT_DEC_BYTE PROC NEAR
    push ax
    push bx
    push cx
    push dx

    cmp al, 0
    jne PDB_GO
    mov ah, 02h
    mov dl, '0'
    int 21h
    jmp PDB_DONE

PDB_GO:
    xor ah, ah
    mov bl, 10
    xor cx, cx

PDB_DIV:
    div bl
    mov dl, ah
    push dx
    inc cx
    xor ah, ah
    cmp al, 0
    jne PDB_DIV

PDB_PRINT:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop PDB_PRINT

PDB_DONE:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_DEC_BYTE ENDP

PRINT_BIN_BYTE PROC NEAR
    push ax
    push cx
    push dx

    mov cx, 8
PBB_LOOP:
    test al, 10000000b
    jz PBB_0
    mov dl, '1'
    jmp PBB_OUT
PBB_0:
    mov dl, '0'
PBB_OUT:
    push ax
    mov ah, 02h
    int 21h
    pop ax
    shl al, 1
    loop PBB_LOOP

    pop dx
    pop cx
    pop ax
    ret
PRINT_BIN_BYTE ENDP

CODE ENDS
END START	
