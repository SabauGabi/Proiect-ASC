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
