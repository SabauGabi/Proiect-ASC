STIVA SEGMENT PARA STACK 'STACK'
    DB 200h DUP(0)                                  ; 512 bytes stiva
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

    citire          db 60, ?, 60 dup(?)             ; DOS 0Ah: [max][len][date...]
    sir_octeti      db 16 dup(0)                    ; aici se pun octetii convertiti (max 16)
    lungime_sir     db 0                            ; nr de octeti validi obtinuti

    cuvantul_C      dw 0                            ; rezultatul C (16 biti = BH:BL)

    index_one       db 0                            ; pozitia (1..n) a octetului cu max biti 1
    max_one         db 0                            ; nr maxim de biti 1 gasit
DATA ENDS
;NIBBLE = jumatate de octet
CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STIVA

START:
    mov ax, DATA                                    
    mov ds, ax                                      

CITIRE_LOOP:
    mov ah, 09h
    lea dx, msg_intro
    int 21h                                         ; afiseaza cerinta de introducere

    mov ah, 0Ah
    lea dx, citire
    int 21h                                         ; citeste linie in bufferul "citire"

    call PARSARE                                    ; parseaza "3F 1A 0B ..." in octeti
    jc EROARE_INVALID                                ; CF=1, atunci caracter invalid / format gresit

    cmp lungime_sir, 8                               ; minim 8 octeti
    jl EROARE_LUNGIME
    cmp lungime_sir, 16                              ; maxim 16 octeti
    jg EROARE_LUNGIME

    mov ah, 09h
    lea dx, msg_succes
    int 21h                                         ; confirma citirea corecta
    jmp ETAPA_2

EROARE_INVALID:
    mov ah, 09h
    lea dx, msg_invalid
    int 21h                                         ; format HEX invalid
    jmp CITIRE_LOOP

EROARE_LUNGIME:
    mov ah, 09h
    lea dx, msg_eroare
    int 21h                                         ; prea putini / prea multi octeti
    jmp CITIRE_LOOP

ETAPA_2:
    call CALCUL_CUVANT_C                             ; calculeaza C (BH= suma, BL= combinatie logica)

    mov ah, 09h
    lea dx, msg_C
    int 21h

    mov ax, cuvantul_C                               ; AX = C (AH=BH, AL=BL)
    mov bl, al                                       ; salveaza BL ca sa putem afisa BH apoi BL
    mov al, ah                                       ; AL = BH (byte superior)
    call PRINT_HEX_BYTE                               ; afiseaza BH in HEX
    mov al, bl                                       ; AL = BL (byte inferior)
    call PRINT_HEX_BYTE                               ; afiseaza BL in HEX

    call SORT_DESC                                   ; sorteaza descrescator sir_octeti

    mov ah, 09h
    lea dx, msg_sortat
    int 21h
    call AFISARE_SIR_HEX                              ; afiseaza sirul sortat in HEX

    call max_de_1                                     ; cauta pozitia cu cei mai multi biti 1

    cmp index_one, 0                                  ; 0, atunci nu exista octet cu >3 biti de 1
    je NU_EXISTA_MAX

    mov ah, 09h
    lea dx, msg_idx_max1
    int 21h

    mov al, index_one                                 ; afiseaza pozitia (1..n)
    call PRINT_DEC_BYTE
    jmp ETAPA_4

NU_EXISTA_MAX:
    mov ah, 09h
    lea dx, msg_no_max1
    int 21h

ETAPA_4:
    call APLICA_ROTIRI                                 ; aplica rotiri pe fiecare octet (ROL cu b0+b1)

    mov ah, 09h
    lea dx, msg_rotiri
    int 21h

    mov cl, lungime_sir                                ; numar de elemente de afisat
    xor ch, ch
    lea si, sir_octeti                                 ; SI - inceput sir

BUCLA_AFISARE_ROTIRI:
    mov al, [si]                                       ; AL = octet curent (deja rotit)
    call PRINT_BIN_BYTE                                 ; afiseaza 8 biti 

    push ax
    push dx
    mov ah, 09h
    lea dx, bar_str
    int 21h                                            ; afiseaza separator " | "
    pop dx
    pop ax

    call PRINT_HEX_BYTE                                 ; afiseaza acelasi octet in HEX

    push ax
    push dx
    mov ah, 09h
    lea dx, newline_str
    int 21h                                            ; newline dupa fiecare element
    pop dx
    pop ax

    inc si                                              ; urmatorul octet
    loop BUCLA_AFISARE_ROTIRI                           ; repeta de lungime_sir ori

    mov ax, 4C00h
    int 21h                                            ; iesire DOS

; PARSARE PROC  
; - Sare peste spatii
; - Ia cate 2 caractere HEX => 1 octet
; - Verifica sa fie spatiu intre octeti (sau final)
; - Pune octetul in sir_octeti si creste lungime_sir
; - CF=1 la eroare (format invalid), CF=0 la succes

PARSARE PROC NEAR
    lea si, citire + 2                                 ; dupa header buffer (max,len), incepe textul
    lea di, sir_octeti                                  ; destinatie octeti
    mov cl, citire[1]                                   ; nr caractere introduse 
    xor ch, ch
    mov lungime_sir, 0                                  ; reset contor valori

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
    cmp cx, 2                                           ; trebuie sa existe 2 caractere HEX
    jb P_ERR                                            ; altfel e format incomplet

    mov al, [si]                                        ; primul hex digit
    call CHAR_TO_VAL                                    ; converteste in 0..15
    jc P_ERR                                            ; daca nu e HEX, eroare
    mov dh, al                                          ; DH = nibble superior
    shl dh, 4                                           ; muta nibble in partea de sus
    inc si
    dec cx

    mov al, [si]                                        ; al doilea hex digit
    call CHAR_TO_VAL                                    ; converteste in 0..15
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
    mov al, lungime_sir                                 ; verificam sa nu depasim 16
    cmp al, 16
    jae P_TOO_MANY                                      ; prea multe valori
    mov [di], dh                                        ; scrie octetul in sir
    inc di
    inc lungime_sir                                     ; creste numarul de octeti
    jmp P_SKIP                                          ; continua cu urmatorul (spatii + 2 hex)

P_TOO_MANY:
    mov lungime_sir, 17                                 ; fortam ulterior eroare de lungime
    clc                                                
    ret

P_ERR:
    stc                                                 ; CF=1, rezulta format invalid
    ret

P_OK:
    clc                                                 ; CF=0, succes
    ret
PARSARE ENDP

; CHAR_TO_VAL PROC  
; - Primeste in AL un caracter
; - Returneaza in AL valoarea 0..15 daca e HEX (0-9, A-F, a-f)
; - CF=1 daca nu e valid

CHAR_TO_VAL PROC NEAR
    cmp al, '0'
    jb CTV_BAD
    cmp al, '9'
    jbe CTV_DIG                                         ; cifra 0..9

    cmp al, 'A'
    jb CTV_LOWCHK
    cmp al, 'F'
    jbe CTV_UP                                          ; litera mare A..F

CTV_LOWCHK:
    cmp al, 'a'
    jb CTV_BAD
    cmp al, 'f'
    jbe CTV_LOW                                         ; litera mica a..f
    jmp CTV_BAD

CTV_DIG:
    sub al, '0'                                         ; '5' -> 5
    clc
    ret

CTV_UP:
    sub al, 'A'                                         ; 'A'->0
    add al, 10                                          ; 0..5 -> 10..15
    clc
    ret

CTV_LOW:
    sub al, 'a'                                         ; 'a'->0
    add al, 10
    clc
    ret

CTV_BAD:
    stc                                                 ; caracter invalid
    ret
CHAR_TO_VAL ENDP

; CALCUL_CUVANT_C PROC  
; C = BH:BL
; 1) BH = suma tuturor octetilor (pe 8 biti, overflow se pierde)
; 2) BL se construieste astfel:
;    - se iau bitii 2..5 din fiecare octet, se aliniaza la bit0..3 si se face OR intre ei
;    - rezultatul OR se pune in nibble superior 
;    - se ia nibble inferior din primul octet
;    - se ia nibble superior din ultimul octet
;    - se face XOR intre cele doua nibble-uri si se pune in nibble inferior al lui BL

CALCUL_CUVANT_C PROC NEAR
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti
    xor bl, bl                                          ; BL va acumula suma (8-bit)

CC_SUM:
    mov al, [si]
    add bl, al                                          ; BL = BL + octet (mod 256)
    inc si
    loop CC_SUM

    mov ah, bl                                          ; AH = suma => va deveni BH

    xor dl, dl                                          ; DL va acumula OR-ul pe bitii 2..5 (aliniati)
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti

CC_OR:
    mov al, [si]
    and al, 00111100b                                   ; izoleaza bitii 2..5
    shr al, 2                                           ; aduce in pozitia 0..3
    or  dl, al                                          ; OR intre toate valorile
    inc si
    loop CC_OR

    shl dl, 4                                           ; OR-ul ajunge in nibble superior al lui BL

    mov al, sir_octeti
    and al, 00001111b                                   ; nibble inferior al primului octet

    mov bl, lungime_sir
    xor bh, bh
    dec bl                                              ; index = lungime_sir - 1
    lea si, sir_octeti
    add si, bx                                          ; SI - ultimul octet
    mov bl, [si]
    and bl, 11110000b                                   ; nibble superior ultimul octet
    shr bl, 4                                           ; aliniaza la 0..3

    xor al, bl                                          ; XOR (nibble jos primul) cu (nibble sus ultimul)
    or  dl, al                                          ; pune rezultatul XOR in nibble inferior al lui DL

    mov bh, ah                                          ; BH = suma
    mov bl, dl                                          ; BL = combinatia calculata
    mov cuvantul_C, bx                                  ; salveaza C
    ret
CALCUL_CUVANT_C ENDP

; APLICA_ROTIRI PROC  
; Pentru fiecare octet:
; - calculeaza nr_rotiri = bit0 + bit1 (0..2)
; - daca nr_rotiri>0, face ROL octet cu nr_rotiri
; - scrie inapoi octetul rotit

APLICA_ROTIRI PROC NEAR
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti

AR_LOOP:
    mov al, [si]                                        ; AL = octet curent
    push cx                                             ; salvam contorul de loop (CX)

    mov bl, al
    and bl, 1                                           ; BL = bit0 (0/1)
    mov dh, al
    and dh, 2                                           ; DH = bit1 (0/2)
    shr dh, 1                                           ; DH = bit1 (0/1)
    add bl, dh                                          ; BL = bit0 + bit1 (0..2)

    mov cl, bl                                          ; CL = nr rotiri
    cmp cl, 0
    je AR_NEXT                                          ; daca 0, nu rotim
    rol al, cl                                          ; rotire circulara la stanga

AR_NEXT:
    mov [si], al                                        ; salveaza rezultatul
    pop cx                                              ; restaureaza CX
    inc si                                              ; urmatorul element
    dec cl                                              
    jnz AR_LOOP                                         
    ret
APLICA_ROTIRI ENDP

; SORT_DESC PROC  
; Bubble sort descrescator:

SORT_DESC PROC NEAR
    mov cl, lungime_sir
    cmp cl, 1
    jbe SD_DONE                                         ; 0/1 element, e deja sortat

    dec cl                                              ; nr treceri exterioare = n-1
SD_OUTER:
    mov si, OFFSET sir_octeti
    mov ch, lungime_sir
    dec ch                                              ; comparatii pe o trecere = n-1
SD_INNER:
    mov al, [si]                                        
    mov ah, [si+1]                                      
    cmp al, ah
    jge SD_NOSWAP                                       ; daca al >= ah, e ok pt descrescator
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

; max_de_1 PROC  
; - Numara bitii de 1 pentru fiecare octet (popcount)
; - Retine maximul si pozitia (index 1-based)
; - Daca maximul este <4 (adica nu are >3 biti de 1), index_one devine 0

max_de_1 PROC NEAR
    mov index_one, 0
    mov max_one, 0

    mov cl, lungime_sir
    xor ch, ch
    jcxz MO_DONE                                        ; daca sir gol (nu ar trebui), iesim

    lea si, sir_octeti
    mov dh, 1                                           ; DH = pozitie (incepe de la 1)

MO_LOOP:
    mov bl, [si]                                        ; BL = octet de analizat
    xor al, al                                          ; AL = contor biti 1
    mov dl, 8                                           ; 8 biti de procesat

MO_CNT:
    shr bl, 1                                           ; bitul scos ajunge in CF
    adc al, 0                                           ; AL += CF (0 sau 1)
    dec dl
    jnz MO_CNT

    cmp al, max_one                                     ; compar cu maximul curent
    jbe MO_NEXT                                         ; daca nu e mai mare, trec mai departe
    mov max_one, al                                     ; update maxim
    mov index_one, dh                                   ; update pozitie (1..n)

MO_NEXT:
    inc si                                              ; urmator octet
    inc dh                                              ; urmatoarea pozitie
    loop MO_LOOP

    cmp max_one, 4                                      ; trebuie >3 biti de 1 => minim 4
    jae MO_DONE
    mov index_one, 0                                    ; daca nu, semnalam "nu exista"

MO_DONE:
    ret
max_de_1 ENDP

; AFISARE_SIR_HEX PROC
; - Afiseaza fiecare octet din sir in HEX, separat prin spatiu

AFISARE_SIR_HEX PROC NEAR
    mov cl, lungime_sir
    xor ch, ch
    lea si, sir_octeti
ASH_LOOP:
    mov al, [si]
    call PRINT_HEX_BYTE                                 ; 2 caractere HEX
    mov ah, 02h
    mov dl, ' '
    int 21h                                             ; spatiu intre valori
    inc si
    loop ASH_LOOP
    ret
AFISARE_SIR_HEX ENDP

; PRINT_HEX_BYTE PROC  
; - Primeste in AL un octet
; - Afiseaza nibble sus apoi nibble jos, folosind NIBBLE_TO_CHAR

PRINT_HEX_BYTE PROC NEAR
    push ax
    push bx
    push cx
    push dx

    mov bl, al                                          ; BL = octet original
    mov al, bl
    shr al, 4                                           ; AL = nibble superior
    call NIBBLE_TO_CHAR                                 ; converteste 0..15 -> '0'..'F'
    mov ah, 02h
    mov dl, al
    int 21h                                             ; afiseaza primul caracter HEX

    mov al, bl
    and al, 0Fh                                         ; AL = nibble inferior
    call NIBBLE_TO_CHAR
    mov ah, 02h
    mov dl, al
    int 21h                                             ; afiseaza al doilea caracter HEX

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_HEX_BYTE ENDP

; NIBBLE_TO_CHAR PROC
; - Converteste AL (0..15) in caracter ASCII HEX ('0'..'9','A'..'F')

NIBBLE_TO_CHAR PROC NEAR
    cmp al, 9
    jbe NTC_DIG
    add al, 7                                           ; 10..15: ajustare pentru 'A'..'F'
NTC_DIG:
    add al, '0'
    ret
NIBBLE_TO_CHAR ENDP

; PRINT_DEC_BYTE PROC  
; - Afiseaza AL in zecimal (0..255)
; - Imparte repetat la 10, pune resturile pe stiva, apoi le scoate in ordine

PRINT_DEC_BYTE PROC NEAR
    push ax
    push bx
    push cx
    push dx

    cmp al, 0
    jne PDB_GO
    mov ah, 02h
    mov dl, '0'
    int 21h                                             ; cazul 0 direct
    jmp PDB_DONE

PDB_GO:
    xor ah, ah                                          ; AX = AL
    mov bl, 10
    xor cx, cx                                          ; CX = nr cifre

PDB_DIV:
    div bl                                              ; AX / 10 => AL=cat, AH=rest
    mov dl, ah                                          ; DL = cifra (rest)
    push dx                                             ; pune cifra pe stiva
    inc cx                                              ; inca o cifra
    xor ah, ah                                          ; pregateste pentru urmatoarea impartire
    cmp al, 0
    jne PDB_DIV                                         ; continua pana catul devine 0

PDB_PRINT:
    pop dx                                              ; scoate cifrele in ordine inversa
    add dl, '0'
    mov ah, 02h
    int 21h                                             ; afiseaza cifra
    loop PDB_PRINT

PDB_DONE:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_DEC_BYTE ENDP

; PRINT_BIN_BYTE PROC  	
; - Afiseaza AL ca 8 biti '0'/'1' de la MSB la LSB
; - Testeaza bitul 7 (10000000b), afiseaza, apoi shl

PRINT_BIN_BYTE PROC NEAR
    push ax
    push cx
    push dx

    mov cx, 8                                           ; 8 biti de afisat
PBB_LOOP:
    test al, 10000000b                                  ; verifica MSB
    jz PBB_0
    mov dl, '1'
    jmp PBB_OUT
PBB_0:
    mov dl, '0'
PBB_OUT:
    push ax
    mov ah, 02h
    int 21h                                             ; afiseaza bitul curent
    pop ax
    shl al, 1                                           ; urmatorul bit devine MSB
    loop PBB_LOOP

    pop dx
    pop cx
    pop ax
    ret
PRINT_BIN_BYTE ENDP

CODE ENDS
END START