include 'PROC16.INC'
include 'Interface.const'

org 100h
Main:

	stdcall Interface.Init
	stdcall Interface.Highlight,word[HighlightPos],HAttr
	stdcall Interface.ReadAllEntrys

.WaitForKey:
	mov ah,01h
	int 16h
	jz .WaitForKey
	
	xor ah,ah
	int 16h

	cmp ah,50h
	jne .ArrUp
	;arr down
	
	
.ArrDown:
	mov ax, word[HighlightPos]
	inc ax
	cmp ax, word[PrintedEntCount]
	je .Check

	cmp word[HighlightPos],LastLineNum-1
	je .Check

	;Move highlighter
	stdcall Interface.Highlight,word[HighlightPos],SAttr
	inc word[HighlightPos]
	stdcall Interface.Highlight,word[HighlightPos],HAttr
	jmp .NextIt

.Check:
	cmp word[PrintedEntCount],LastLineNum
	je .ScrollDown

	jmp .NextIt

.ScrollDown:

	stdcall Interface.CleanScreenDirs
	inc word[ScrollPos]
	stdcall Interface.ReadAllEntrys

	cmp word[PrintedEntCount],LastLineNum
	je .SkipDec
	inc word[HighlightPos]
.SkipDec:
	stdcall Interface.Highlight,word[HighlightPos],HAttr
	jmp .NextIt
	

.ArrUp:
	    cmp ah,48h
        jne .Exec

        cmp word[HighlightPos],0
        je .CheckU

        ;Move highlighter
        stdcall Interface.Highlight,word[HighlightPos],SAttr
        dec word[HighlightPos]
        stdcall Interface.Highlight,word[HighlightPos],HAttr
        jmp .NextIt

.CheckU:
        cmp word[ScrollPos],0
        jne .ScrollUp

        jmp .NextIt

.ScrollUp:

        stdcall Interface.CleanScreenDirs
        dec word[ScrollPos]
        stdcall Interface.ReadAllEntrys
        stdcall Interface.Highlight,word[HighlightPos],HAttr
        jmp .NextIt


.Exec:
		cmp ah,1ch
        jne .PowerOff
        ;execute
		
		
		mov cx,word[ScrollPos]
		add cx,word[HighlightPos]
		inc cx
		
		mov ah,4eh
		mov dx,search_all_str
		int 21h
		dec cx
		test cx,cx
		jz .EndRead
		
.ReadLoop:
		mov ah,4fh
		mov dx,search_all_str
		int 21h		
		loop .ReadLoop	
		
.EndRead:		
		

        stdcall Interface.CheckIfDir,word[HighlightPos]      ;ax=0 => not dir  ax=1 => dir
        test ax,ax
        jz .Com
		
		mov ah,3bh
		mov dx,80h+1eh
		int 21h			
		
		stdcall Interface.CleanScreenDirs
		mov word[ScrollPos],0
		mov word[HighlightPos],0		
		stdcall Interface.ReadAllEntrys
		stdcall Interface.Highlight,word[HighlightPos],HAttr
		
		jmp .NextIt
		
.Com:
        stdcall Interface.CheckIfCom,word[HighlightPos]		;ax=0 => not Com  ax=1 => Com
        test ax,ax
        jz .Exe
		
		mov ah,4bh
		mov dx,80h+1eh
		int 21h	

		mov ah,9
		mov dx,strcont
		int 21h
		
		mov ah,08h
		int 21h
		
		stdcall Interface.SetTextMode
        stdcall Interface.Redraw
        stdcall Interface.HideCursor
		mov word[ScrollPos],0
		mov word[HighlightPos],0		
		stdcall Interface.ReadAllEntrys
		stdcall Interface.Highlight,word[HighlightPos],HAttr
		
		jmp .NextIt
		
.Exe:
		stdcall Interface.CheckIfExe,word[HighlightPos]		;ax=0 => not Exe  ax=1 => Exe
        test ax,ax		
		jz .NextIt
		
		mov ah,4bh
		mov dx,80h+1eh
		int 21h		
		
		mov ah,9
		mov dx,strcont
		int 21h
		
		mov ah,08h
		int 21h
		
		stdcall Interface.SetTextMode
        stdcall Interface.Redraw
        stdcall Interface.HideCursor
		mov word[ScrollPos],0
		mov word[HighlightPos],0		
		stdcall Interface.ReadAllEntrys
		stdcall Interface.Highlight,word[HighlightPos],HAttr
		
        jmp .NextIt ;!
		
.PowerOff:
		cmp ah,0fh
		jne .NextIt
		
		mov ax,5307h
		mov bx,1
		mov cx,3
		int 15h
		jmp .NextIt ;!
.NextIt:

		
		
	jmp .WaitForKey
	
	

	
	int 20h
	
include 'Interface.code'
include 'Interface.dat'