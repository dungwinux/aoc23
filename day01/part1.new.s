SECTION .data
    inp       incbin    "input"
    inplen    equ       $ - inp
    s1        db        "one"
    s2        db        "two"
    s3        db        "three"
    s4        db        "four"
    s5        db        "five"
    s6        db        "six"
    s7        db        "seven"
    s8        db        "eight"
    s9        db        "nine"
    ;my_str    db        "a1b2c3d4e5f", 0

SECTION .text

global main

main:
    sub       rbp, 0x20
    mov       rcx, inp
    mov       rdx, inplen
    call      parse_file
    add       rbp, 0x20
    ret


; Expect: an array of character ended with null character (uint8_t[])
; Return: a number accumulated from number character found at the start and end of the array
extract:
    push      rbx
    push      rdi
    push      rsi

    xor       eax, eax
    cqo
    mov       esi, eax
    mov       dh, -0x30
    mov       edi, eax
.loop_start:
    mov       dl, byte [rcx + rdi]
    test      dl, dl
    jz        .loop_end
    add       dl, dh
    inc       rdi
    cmp       dl, 9
    ; Check if the character is a number
    ja        .loop_start
    test      esi, esi
    jnz       .if_esi_is_not_zero
    ; Check if this is first run
    mov       al, dl
    not       esi
.if_esi_is_not_zero:
    mov       ah, dl
    jmp       .loop_start
.loop_end:
    mov       dl, ah
    mov       ah, 0
    mov       dh, 0

    ; al and dl are two final "digits"
    lea       edx, [rdx + rax * 2]
    lea       eax, [rdx + rax * 8]
    
    pop       rsi
    pop       rdi
    pop       rbx
    ret

parse_file:
    ; Parse input file
    ; rcx: File data pointer, Non-NULL-terminated
    ; rdx: File data size
    push    rsi
    push    rdi
    push    rbx
    push    rbp
    sub     rsp, 0x20

    xor     ebx, ebx
    mov     rbp, rdx
    mov     rsi, rcx
    mov     rdi, rcx
.loop:
    mov     al, 0xA
    mov     rcx, rbp
    repne scasb
    mov     rdx, rbp
    sub     rdx, rcx
    mov     rbp, rcx
    mov     byte [rdi - 1], 0x0
    mov     rcx, rsi
    call    extract
    add     rbx, rax
    mov     rsi, rdi
    test    rbp, rbp
    jnz     .loop
    mov     rax, rbx

    add     rsp, 0x20
    pop     rbp
    pop     rbx
    pop     rdi
    pop     rsi
    ret
