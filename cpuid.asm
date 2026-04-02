; =========================================================================
; NEKKO-OS BARE-METAL CPUID EXTRACTOR v1.0 (OPEN-SOURCE EDITION)
; Author: Bạo Chúa Nekko (và đồng minh)
; Architecture: x86_64 (Windows ABI)
; Assembler: NASM
; =========================================================================

default rel
extern printf
extern ExitProcess

section .data
    fmt_brand db "==========================================", 10
              db "   [NEKKO-OS] BARE-METAL CPUID EXTRACTOR  ", 10
              db "==========================================", 10
              db "CPU Brand: %s", 10, 10, 0
              
    fmt_eax   db "[RAW EAX VALUE (CPUID EAX=1)]: 0x%08X", 10
              db "------------------------------------------", 10
              db "[31:28] Reserved        : 0x%X", 10
              db "[27:20] Extended Family : 0x%X", 10
              db "[19:16] Extended Model  : 0x%X", 10
              db "[15:14] Reserved        : 0x%X", 10
              db "[13:12] Processor Type  : 0x%X", 10
              db "[11:08] Family Code     : 0x%X", 10
              db "[07:04] Model Number    : 0x%X", 10
              db "[03:00] Stepping ID     : 0x%X", 10
              db "------------------------------------------", 10
              db "=> Full Family : %d", 10
              db "=> Full Model  : %d (0x%X)", 10
              db "=> Stepping    : %d (0x%X) <--- MANG DI SO VOI PDF INTEL!", 10, 10, 0

    fmt_ebx   db "[ADDITIONAL INFO (EBX)]: 0x%08X", 10
              db "[31:24] Local APIC ID   : %d", 10
              db "[23:16] Max Logical CPUs: %d", 10
              db "[15:08] CLFLUSH Size    : %d Bytes", 10, 10, 0
              
    brand_str times 48 db 0

section .text
global main

main:
    ; Căn lề Stack 16-byte chuẩn Windows ABI (8 byte return address + 136 = 144 chia hết cho 16)
    sub rsp, 136 

    ; ==========================================
    ; 1. LẤY BRAND STRING (TÊN KHAI SINH CPU)
    ; ==========================================
    mov eax, 0x80000002
    cpuid
    mov dword [brand_str], eax
    mov dword [brand_str+4], ebx
    mov dword [brand_str+8], ecx
    mov dword [brand_str+12], edx

    mov eax, 0x80000003
    cpuid
    mov dword [brand_str+16], eax
    mov dword [brand_str+20], ebx
    mov dword [brand_str+24], ecx
    mov dword [brand_str+28], edx

    mov eax, 0x80000004
    cpuid
    mov dword [brand_str+32], eax
    mov dword [brand_str+36], ebx
    mov dword [brand_str+40], ecx
    mov dword [brand_str+44], edx

    lea rcx, [fmt_brand]
    lea rdx, [brand_str]
    call printf

    ; ==========================================
    ; 2. PHẪU THUẬT THANH GHI EAX (VERSION INFO)
    ; ==========================================
    mov eax, 1
    cpuid
    mov r12d, eax ; Lưu RAW EAX
    mov r13d, ebx ; Lưu RAW EBX

    ; Bóc tách từng mảng bit
    mov eax, r12d
    shr eax, 28
    and eax, 0xF
    mov r14d, eax       ; [31:28] Reserved

    mov eax, r12d
    shr eax, 20
    and eax, 0xFF
    mov r15d, eax       ; [27:20] Ext Family

    mov eax, r12d
    shr eax, 16
    and eax, 0xF
    mov esi, eax        ; [19:16] Ext Model

    mov eax, r12d
    shr eax, 14
    and eax, 0x3
    mov edi, eax        ; [15:14] Reserved

    mov eax, r12d
    shr eax, 12
    and eax, 0x3
    mov ebp, eax        ; [13:12] Proc Type

    mov eax, r12d
    shr eax, 8
    and eax, 0xF
    mov ebx, eax        ; [11:8] Family Code

    mov eax, r12d
    shr eax, 4
    and eax, 0xF
    mov r10d, eax       ; [7:4] Model Number

    mov eax, r12d
    and eax, 0xF
    mov r11d, eax       ; [3:0] Stepping ID

    ; Tính Full Model = (Ext Model << 4) | Model Number
    mov eax, esi
    shl eax, 4
    or eax, r10d        ; EAX bây giờ là Full Model an toàn!

    ; --- [FIX BUG CHÍ MẠNG] ĐẨY VÀO STACK TRƯỚC KHI ĐỤNG TỚI RCX ---
    mov [rsp+32], esi      ; Arg 4: [19:16] Ext Model
    mov [rsp+40], edi      ; Arg 5: [15:14] Rsvd
    mov [rsp+48], ebp      ; Arg 6: [13:12] Proc Type
    mov [rsp+56], ebx      ; Arg 7: [11:8]  Fam Code
    mov [rsp+64], r10d     ; Arg 8: [7:4]   Model Num
    mov [rsp+72], r11d     ; Arg 9: [3:0]   Stepping
    mov [rsp+80], ebx      ; Arg 10: Full Fam
    mov [rsp+88], eax      ; Arg 11: Full Model (Dec)
    mov [rsp+96], eax      ; Arg 12: Full Model (Hex)
    mov [rsp+104], r11d    ; Arg 13: Stepping (Dec)
    mov [rsp+112], r11d    ; Arg 14: Stepping (Hex)

    ; Giờ mới nạp RCX, RDX, R8, R9 một cách an toàn!
    mov r9d, r15d          ; Arg 3: [27:20] Ext Family
    mov r8d, r14d          ; Arg 2: [31:28] Rsvd
    mov edx, r12d          ; Arg 1: Raw EAX
    lea rcx, [fmt_eax]     ; Arg 0: Format
    call printf

    ; ==========================================
    ; 3. PHẪU THUẬT THANH GHI EBX (ADDITIONAL INFO)
    ; ==========================================
    mov eax, r13d
    shr eax, 24
    and eax, 0xFF
    mov r14d, eax       ; APIC ID

    mov eax, r13d
    shr eax, 16
    and eax, 0xFF
    mov r15d, eax       ; Max Logical CPUs

    mov eax, r13d
    shr eax, 8
    and eax, 0xFF
    shl eax, 3 
    mov r12d, eax       ; CLFLUSH Size

    mov [rsp+32], r12d
    mov r9d, r15d
    mov r8d, r14d
    mov edx, r13d
    lea rcx, [fmt_ebx]
    call printf

    ; TỬ HÌNH CHƯƠNG TRÌNH
    xor ecx, ecx
    call ExitProcess