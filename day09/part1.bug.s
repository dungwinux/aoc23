; [BITS 64]

extern atoll

SECTION .data
    inp     incbin  'input'
    inplen  equ     $-inp
    ;inp     dq  0, 3, 6, 9, 12, 15
    ;inp     dq  1, 3, 6, 10, 15, 21
    ;inp     dq  10, 13, 16, 21, 30, 45
    ;inp     db "0 3 6 9 12 15", 0
SECTION .text
    global main


main:
    sub     rbp, 0x20
    mov     rcx, inp
    mov     rdx, inplen
    call    parse_file
    add     rbp, 0x20
    ret

predict:
    ; Predict the next value of the series
    ; rcx: Array address
    ; rdx: Array length
    
    push    rsi
    push    rdi
    push    rbp
    push    rbx
    mov     rbp, rsp

    ; First, we try copying the array
    lea     rdi, [rdx * 8 + 0x20]
    sub     rsp, rdi
    lea     rdi, [rsp + 0x20]
    mov     rsi, rcx
    mov     rcx, rdx
    rep movsq

    ; Now, we try to differentiate the array
    lea     rdi, [rsp + 0x20]
    mov     rsi, rdx
    mov     r8, rdx
.outer_loop:
    xor     ebx, ebx
    dec     r8
    jle     .loop_end

.inner_loop:
    mov     rdx, [rdi + rbx * 8 + 8]
    sub     rdx, [rdi + rbx * 8]
    mov     [rdi + rbx * 8], rdx
    inc     rbx
    cmp     rbx, r8
    jb      .inner_loop

    mov     rcx, rdi
    mov     rdx, rbx
    call    is_all_zero
    test    al, al
    jz      .outer_loop
.loop_end:

    xor     edx, edx
.sum:
    add     rdx, [rdi + rbx * 8]
    inc     rbx
    cmp     rbx, rsi
    jb      .sum

    mov     rax, rdx
    mov     rsp, rbp
    pop     rbx
    pop     rbp
    pop     rdi
    pop     rsi
    ret

get_strlen:
    ; rcx: Constant byte pointer
    push    rdi
    mov     rdi, rcx
    xor     al, al
    repne scasb
    sub     rdi, rcx
    mov     rax, rdi
    pop     rdi
    ret

parse_line:
    ; Extract number in line into array
    ; rcx: Source byte ptr, NULL-terminated, writeable
    push    rdi
    push    rsi
    push    rbp
    push    r12
    push    r13
    sub     rsp, 0x820
    lea     rbp, [rsp + 0x28]

    mov     r13, rdx

    ; Second, we search for the space character between number
    xor     r12, r12
    mov     rdi, rcx
    mov     rsi, rcx
.loop:
    mov     al, 0x20
    mov     rcx, r13
    repne scasb
    mov     r13, rcx
    mov     byte [rdi - 1], 0
    mov     rcx, rsi
    call    atoll
    mov     [rbp + r12 * 8], rax
    inc     r12
    mov     rsi, rdi
    test    r13, r13
    jnz     .loop

    mov     rcx, rbp
    mov     rdx, r12
    call    predict

    add     rsp, 0x820
    pop     r13
    pop     r12
    pop     rbp
    pop     rsi
    pop     rdi
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
    mov     rbp, rcx
    mov     byte [rdi - 1], 0
    mov     rcx, rsi
    call    get_strlen
    mov     rdx, rax
    call    parse_line
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

is_all_zero:
    ; Check if array is all 0
    ; rcx: qword array pointer
    ; rdx: qword array length
    push    rdi

    mov     rdi, rcx
    mov     rcx, rdx
    xor     eax, eax
    repe scasq
    test    rcx, rcx
    setz    al

    pop     rdi
    ret
