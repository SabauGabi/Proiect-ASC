ASSUME cs:code,ds:data
data segment
data ends
code segment
start:
move ax,data
move ds,ax
mov ax,4C00h
int 21h
code ends
end start