; Since they fit into 64-bit number, we encode them as a cell for quicker comparisons
%xdefine s1             "one"
%xdefine s2             "two"
%xdefine s3             "three"
%xdefine s4             "four"
%xdefine s5             "five"
%xdefine s6             "six"
%xdefine s7             "seven"
%xdefine s8             "eight"
%xdefine s9             "nine"


SECTION .data
    inp       incbin    "input"
    inplen    equ       $ - inp
    ;my_str    db        "dpkrlbxfdvone", 0

SECTION .text

global main

main:
    sub       rsp, 0x20
    mov       rcx, inp
    mov       rdx, inplen
    call      parse_file
    ;mov       rcx, my_str
    ;call      extract
    add       rsp, 0x20
    ret


; Expect: an array of character ended with null character (uint8_t[])
; Return: a number accumulated from number character found at the start and end of the array
extract:
    push      rbx
    push      rdi
    push      rsi
    push      rbp
    sub       rsp, 0x20

    xor       eax, eax
    cqo
    xor       esi, esi
    xor       ebp, ebp
    mov       dh, 0x30
    xor       edi, edi
    xor       ebx, ebx
    xor       r8, r8
.loop_start:
    mov       dl, byte [rcx + rdi]
    test      dl, dl
    jz        .loop_end
    sub       dl, dh
    inc       rdi
    cmp       dl, 9
    ; Check if the character is a number
    ja        .non_numeric
    xor       ebx, ebx
    mov       rax, rdi
    shl       rax, 8
    mov       al, dl
    mov       qword [rsp + 0x10], rax
    test      esi, esi
    jnz       .loop_start
    not       esi
    mov       qword [rsp + 0x18], rax
    jmp       .loop_start
.non_numeric:
    add       dl, dh
    ; a1z26-like hash
    ; ebx: 5-byte
    movzx     rax, dl
    shl       rbx, 24
    shrd      rbx, rax, 32
    ; 5-byte variant (rbx)
    mov       r8b, 3
    mov       r9, s3
    cmp       rbx, r9
    je        .ascii_equal_5
    mov       r8b, 7
    mov       r9, s7
    cmp       rbx, r9
    je        .ascii_equal_5
    mov       r8b, 8
    mov       r9, s8
    cmp       rbx, r9
    je        .ascii_equal_5
    
    mov       r9, 3
    mov       rax, rbx
    ; Off by one
    shr       rax, 8
    ; 4-byte variant (eax)
    mov       r8b, 4
    cmp       eax, s4
    je        .ascii_equal
    mov       r8b, 5
    cmp       eax, s5
    je        .ascii_equal
    mov       r8b, 9
    cmp       eax, s9
    je        .ascii_equal
    
    dec       r9
    shr       eax, 8
    ; 3-byte variant (eax)
    mov       r8b, 1
    cmp       eax, s1
    je        .ascii_equal
    mov       r8b, 2
    cmp       eax, s2
    je        .ascii_equal
    mov       r8b, 6
    cmp       eax, s6
    je        .ascii_equal
    ; ascii_non_equal
    jmp       .loop_start
.ascii_equal_5:
    mov       r9, 4
.ascii_equal:
    mov       rax, rdi
    sub       rax, r9
    shl       rax, 8
    mov       al, r8b
    mov       qword [rsp], rax
    test      ebp, ebp
    jnz       .loop_start
    not       ebp
    mov       qword [rsp + 8], rax
    jmp       .loop_start

.loop_end:

    test      ebp, ebp
    ; letter digit are not exist
    jz        .digit_digit_only
    test      esi, esi
    ; digit digit are not exist
    jnz       .both_letter_n_digit
    ; Special cases:

.letter_digit_only:
    movzx     eax, byte [rsp + 8]
    movzx     edx, byte [rsp]
    jmp       .end_check
.digit_digit_only:
    movzx     eax, byte [rsp + 0x18]
    movzx     edx, byte [rsp + 0x10]
    jmp       .end_check
.both_letter_n_digit:
    ; Check first "digit"
    mov       r8, qword [rsp + 8]
    mov       r9, qword [rsp + 0x18]
    movzx     eax, r9b
    shr       r8, 8
    shr       r9, 8
    cmp       r8, r9
    ja        .next_check
    mov       al, byte [rsp + 8]
.next_check:
    ; Check last "digit"
    mov       r8, qword [rsp]
    mov       r9, qword [rsp + 0x10]
    movzx     edx, r9b
    shr       r8, 8
    shr       r9, 8
    cmp       r8, r9
    jb        .end_check
    mov       dl, byte [rsp]
.end_check:

    lea       edx, [rdx + rax * 2]
    lea       eax, [rdx + rax * 8]
   
    add       rsp, 0x20
    pop       rbp
    pop       rsi
    pop       rdi
    pop       rbx
    ret

parse_file:
    ; Parse input file
    ; rcx: File data pointer, Non-NULL-terminated
    ; rdx: File data size
    push      rsi
    push      rdi
    push      rbx
    push      rbp
    sub       rsp, 0x20

    xor       ebx, ebx
    mov       rbp, rdx
    mov       rsi, rcx
    mov       rdi, rcx
.loop:
    mov       al, 0xA
    mov       rcx, rbp
    repne scasb
    mov       rdx, rbp
    sub       rdx, rcx
    mov       rbp, rcx
    mov       byte [rdi - 1], 0x0
    mov       rcx, rsi
    call      extract
    add       rbx, rax
    mov       rsi, rdi
    test      rbp, rbp
    jnz       .loop
    mov       rax, rbx

    add       rsp, 0x20
    pop       rbp
    pop       rbx
    pop       rdi
    pop       rsi
    ret

