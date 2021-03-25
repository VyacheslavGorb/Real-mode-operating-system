        ;KERNEL BOOTLOADER \ SEGMENT_SIZE = 512 BYTE

        include 'Bootloader.const'

        org CodeAddr

        xor bp,bp     ; set stack   bp:=0
        mov ss,bp     ;             ss:=0
        mov ds,bp     ;             ds:=0
        mov sp,StackAddr  ;             sp:=8000h
        mov word[DriveIndex],dx  ;save dx value
        call ReadSector  ;read MBR  (DAP is set)


        ;calc sector numbers
        mov bx,word [ds:FirstMbrEntryAddr+MbrSectorAddr+DataAddr]  ;read FirstFatSector
        mov word[ds:FirstFatSector],bx  ;                 //////////////////////


        mov ax,word[ds:FATz16]  ;FATz16
        mul byte[ds:NumFATs]     ;NumFATs*FATz16 => dx:ax  (ax)
        add ax, word[ds:BPB_ResvdSecCnt] ;BPB_ResvdSecCnt + (BPB_NumFATs * BPB_FATSz16)

        add ax,bx
        mov word[ds:FirstRootDirSecNum], ax
        mov word[ds:DAP.FirstSectMain],ax ; set DAP to read RootDirEntry (1)

        mov ax, word[ds:RootEntCount] ;Root ent count
        shl ax,5
        add ax,word[ds:BytesPerSect]  ;Bytes per sect
        dec ax
        xor dx,dx
        div word[ds:BytesPerSect]     ;RootDirSectors = ((BPB_RootEntCnt * 32) + (BPB_BytsPerSec - 1)) / BPB_BytsPerSec;
        mov word[ds:RootDirSectors],ax
        mov word[ds:DAP.SecCount],ax  ; set DAP to read RootDirEntry (2)
        add ax,word[ds:FirstRootDirSecNum]
        mov word[ds:FirstDataSector], ax

        ;search dir entry

        call ReadSector   ; DAP is set (comment above)

        mov ax,200h       ;inc DAP buffer
        mul word[ds:RootDirSectors]
        add word[ds:DAP.BufOffset],ax



        mov di,DataAddr-32
SearchLoop:
        add  di,32          ;entry size
        cmp byte[ds:di],0      ;last entry check
        je  Error_FileNotFound
        cmp byte[ds:di],0xE5   ;free entry
        je SearchLoop
        cmp byte[ds:di],0x05   ;free entry
        je SearchLoop
        cmp byte[ds:di+11],04h ;system attribute    ;must be 04h(system)
        jne .NextCmp                                ;must be je
        jmp SearchLoop
.NextCmp:
        cmp byte[ds:di],'#'  ;my value to check
        je  .Found
        jmp SearchLoop
.Found:

        mov bx, [ds:di+RootDirEntry_Sector]           ; bx <= first sectNum


        mov di,[ds:DAP.BufOffset]
        mov ax, word[ds:FirstFatSector]
        add ax, word[ds:BPB_ResvdSecCnt]           ; Reserved sectors
        mov word[ds:DAP.FirstSectMain],ax   ; es:di is set to FAT table




        push word[ds:FATz16] ;FATz16
        pop  word[ds:DAP.SecCount]




        call ReadSector     ; FAT is read es:di



        mov ax, word[DAP.BufOffset]
        shr ax,4
        add word[DAP.BufSegment],ax



        mov ax, 200h
        mul word[ds:FATz16] ;FATz16
        mov word[ds:DAP.BufOffset],ax
        mov word[ds:CodeOffset],ax


        push word[ds:DAP.BufSegment]
        pop  es


        movzx ax, byte[ds:SecPerCluster]; SecPerCluster
        mov   word[ds:DAP.SecCount],ax

        ;////////////////////////////////////////////////////////////////////////////////////////////////////////////

        add word[DAP.BufSegment],80h
ReadSectors:
        mov ax,bx
        shl bx,1   ; *2, 2 bytes per sect

        sub ax,2
        mul word[ds:DAP.SecCount]

        push word[ds:FirstDataSector]   ;change DAP to read cluster
        pop word[ds:DAP.FirstSectMain]
        add word[ds:DAP.FirstSectMain],ax



        call ReadSector              ;read cluster


                                     ;inc buffer address
        mov ax,200h
        mul word[DAP.SecCount]
        add word[DAP.BufOffset],ax


        mov bx,word[es:bx]         ;check if last sector or corrupted
        cmp bx,0xFFFF
        je EndLoad
        cmp bx,0xFFF7
        je Error_FileIsCorrupted
        jmp ReadSectors



EndLoad:
        xor eax,eax
        mov ax,es
        shl eax,4                               ;es:di
        movzx ecx,word[ds:CodeOffset]
        add eax,ecx
        shr eax,4
        add ax,80h
        mov word[JMPAddress+2],ax
        mov dx,word[ds:DriveIndex]
        mov cx,word[ds:FirstFatSector]
        jmp dword[JMPAddress]

        ;           \\\INFORMATION\\\

        ;fat segment                     ES
        ;root dir segment                0800h
        ;os segment                      AX
        ;FirstFATSector_ROM              CX
        ;Drive Index                     DX



Error_FileNotFound:
        mov si,FileNotFoundString
        call PrintString
        jmp WaitForInput

Error_FileIsCorrupted:
        mov si,FileIsCorruptedString
        call PrintString

WaitForInput:
        mov si,PressKeyString
        call PrintString
        xor ah,ah
        int 16h
ShutSystemDown:
        mov ax,5307h
        mov bx,0001h
        mov cx,0003h
        int 15h
        jc ShutSystemDown


        include 'Bootloader.code'

        include 'Bootloader.dat'








