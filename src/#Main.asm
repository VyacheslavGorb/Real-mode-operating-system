        include 'PROC16.INC'


        ;INITIALIZATION_ START

        ;INFORMATION:
        ;fat segment                     ES
        ;root dir segment                0800h
        ;os segment                      AX
        ;FirstFATSector_ROM              CX
        ;Drive Index                     DX

        include 'Interrupt21h\int21h.const'


        movzx bx,byte[BPB_SecPerCluster]
        mov word[DAP.SecCount],bx
        mov ds,ax
        mov word[FatSegment],es
        mov es,ax
        mov word[OSSegment],ax
        mov word[DriveIndex],dx
        mov word[ProgramSegmentArr],ax		;ProgramSegmentArr[0]
        add word[ProgramSegmentArr],500h
        mov word[FirstFatSector],cx

        mov sp,0800h       ;set stack
        sub ax,80h
        mov ss,ax
        ;INITIALIZATION_ END

        push es
        push 0
        pop es
		
		mov word[es:ProgsCount],0

        push ds
        pop  word[es:DSValueAddr]

        push sp
        pop  word[es:SPValueAddr]
		
		mov ax, ss
		mov word[es:SSValueAddr],ax

        ;set int20h jmp params

        pop es

        stdcall Int.SetInterruptHandlerAddr,20h,IntHandler.20h,ds
        stdcall Int.SetInterruptHandlerAddr,21h,IntHandler.21h,ds
        stdcall Int.SetInterruptHandlerAddr,23h,IntHandler.20h,ds

		stdcall FAT.DataInit
		
		
		

		stdcall InitComPorts
		
		
		
		add word[ProgramSegmentArr],6000h			
		mov ax,4b00h
		mov dx,strcalc
		int 21h
		sub word[ProgramSegmentArr],6000h
		
		
		
		
		stdcall Console.Init
		stdcall Execute.ComProgram, strmain
		
		jmp $
	
		
		
        include 'Interrupt21h\int21h.code'     
        include 'Interrupt21h\int21h.dat'        
		
		
		strmain db 'INTERF~1COM',0		
		strcalc db 'CALC.COM',0
		
proc InitComPorts uses dx,ax
		
		mov dx,0x3F8+1
		mov al,00h
		out dx,al
		
		mov dx,0x3F8+3
		mov al,80h
		out dx,al
		
		mov dx,0x3F8+0
		mov al,03h
		out dx,al
		
		mov dx,0x3F8+1
		mov al,00h
		out dx,al
		
		mov dx,0x3F8+3
		mov al,03h
		out dx,al
		
		mov dx,0x3F8+2
		mov al,0xC7
		out dx,al
		
		mov dx,0x3F8+4
		mov al,0x0B
		out dx,al			

		ret
endp