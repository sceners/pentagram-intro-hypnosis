;
; Adlib Player, Coded by Prime
;

		Ideal
		DOSSeg

True		= 1
False		= 0
TimerFreq	= 1193180
AdlibPort	= 388h
NumOfChannels	= 9

		; Header
NumOfPatterns	= 4
Speed		= 5
VoiceData	= 6
PatternData	= 6+11*NumOfChannels


		Public PlayAdlib
		Public StopAdlib


		Segment AdlibCode Para Private 'Code'
		Assume cs:AdlibCode,ds:Nothing

		p286

AdlibInt:	pusha
		push ds
		dec [MusicCounter]
		jnz NoNoteUpdate
		mov al,[MusicSpeed]
		mov [MusicCounter],al

		lds si,[PatternPtr]		; DS:SI points to PatternData
		xor di,di			; Voice#
AdlibIntVcLoop:	mov al,[si]			; Get note
		inc si
		or al,al			; Nothing?
		jz NextChannel
		mov cl,al			; CL = Saved Note

		mov bl,al
		and bx,3Fh
		shl bx,1
		mov bx,[bx+MusicFreq-2]		; BH=Block/F-Num.H, BL=F-Num.L

		mov ax,di
		mov ah,al
		add ah,0B0h			; KeyOn/Block/F-Num.H Register
		mov al,bh
		xchg al,[di+SaveReg]		; Old Freq, Key=Off
		call WriteAdlib
		test cl,40h			; Key On?
		jnz NextChannel

		sub ah,0B0h-0A0h		; AH = F-Num.L Register
		mov al,bl			; AL = F-Num.L
		call WriteAdlib

		add ah,0B0h-0A0h		; KeyOn/Block/F-Num.H Register
		mov al,bh
		or al,20h			; Key=On
		call WriteAdLib

NextChannel:    inc di
		cmp di,NumOfChannels
		jb AdlibIntVcLoop

		add si,3			; Skip drums etc.
		cmp si,[MusicEnd]		; Repeat when end reached
		jb PatternOk

		mov si,[PatternStart]
PatternOk:	mov [word low PatternPtr],si	; New music pointer

NoNoteUpdate:	mov al,20h
		out 20h,al			; EOI to PIC
		pop ds
		popa
		iret


		;
		; Play Adlib - Play Adlib Music
		; In:	ES:SI = Music Pointer
		; Out:	CF    = Card not found.
		;
	
	Proc PlayAdlib Far
		mov [PlayerActive],False
		mov dx,AdlibPort
		in al,dx
		inc al
		jnz PlayAdlibOk
		stc
		ret

PlayAdlibOk:	mov [PlayerActive],True

		mov [word high PatternPtr],es
		lea bx,[si+PatternData]
		mov [word low PatternPtr],bx	; Set pointer to Pattern Data
		mov [PatternStart],bx

		mov al,64*3
		mul [byte es:si+NumOfPatterns]
		add ax,bx
		mov [MusicEnd],ax		; Set Pattern End Address

		mov al,[es:si+Speed]
		mov [MusicSpeed],al
		mov [MusicCounter],1

		call AdlibReset
		mov ax,0BDC0h			; Reg. BDh Bit 6,7 (Vibration)
		call WriteAdLib

		lea si,[si+VoiceData]		; Initialize voices
		mov di,Offset AdlibRegs
		mov cx,NumOfChannels*11
InitializeVc:	mov al,[es:si]
		mov ah,[cs:di]
		inc si
		inc di
		call WriteAdLib
		loop InitializeVc

		mov ax,3508h
		int 21h
		mov [word low OldInt08],bx
		mov [word high OldInt08],es

		push ds
		mov ax,cs
		mov ds,ax
		mov dx,Offset AdlibInt
		mov ax,2508h
		int 21h
		pop ds

		cli
		mov al,34h
		out 43h,al
		mov ax,TimerFreq/60		
		out 40h,al
		mov al,ah
		out 40h,al
		sti
		clc
		ret
	Endp


		;
		; StopAdlib - Stops the Adlib Player
		;

	Proc StopAdlib Far
		cmp [PlayerActive],True
		jne AdlibNotActive
		pushf
		cli
		mov al,34h			; Original timer rate
		out 43h,al
		xor al,al
		out 40h,al
		out 40h,al

		push ds
		lds dx,[OldInt08]
		mov ax,2508h			; Restore old timer vector
		int 21h
		pop ds

		xor di,di
		mov ah,0B0h
KeyOffVoice:	mov al,[di+SaveReg]
		and al,1Fh			; Mask Block + F-Num.H
		call WriteAdlib
		inc di
		inc ah
		cmp ah,0B8h
		jbe KeyOffVoice

		mov ax,80FFh			; Reprogram Release Rate
VoiceRelease:	call WriteAdlib
		inc ah
		cmp ah,95h
		jbe VoiceRelease

		call AdlibReset
		popf
AdlibNotActive:	ret
	Endp

		;
		; WriteAdlib
		; In:	AH = Register
		;	AL = Data
		;

WriteAdlib:	push ax dx
		mov dx,AdlibPort
		xchg ah,al
		out dx,al
		REPT 6
		  in al,dx
		ENDM
		mov al,ah
		inc dl
		out dx,al
		dec dl
		REPT 35
		  in al,dx
		ENDM
		pop dx ax
		ret


AdlibReset:	xor ax,ax
AdlibReset1:	call WriteAdlib
		inc ah
		cmp ah,0E8h
		jbe AdlibReset1
		ret


		Align 2

OldInt08	dd 0
PatternPtr	dd 0
PatternStart	dw 0
MusicEnd	dw 0
MusicCounter	db 0
MusicSpeed	db 0
PlayerActive	db False
SaveReg		db NumOfChannels Dup (0)

		Align 2

MusicFreq	= This Word
		O = 2 Shl 10			; Octave = 2
		REPT 6
		  dw 342+O, 363+O, 384+O, 408+O, 433+O, 457+O
		  dw 485+O, 515+O, 545+O, 577+O, 611+O, 646+O
		  O = O + 1 Shl 10		; Next Octave
		ENDM

AdlibRegs	db 20h,23h,40h,43h,60h,63h,80h,83h,0A0h,0B0h,0C0h
		db 21h,24h,41h,44h,61h,64h,81h,84h,0A1h,0B1h,0C1h
		db 22h,25h,42h,45h,62h,65h,82h,85h,0A2h,0B2h,0C2h
		db 28h,2Bh,48h,4Bh,68h,6Bh,88h,8Bh,0A3h,0B3h,0C3h
		db 29h,2Ch,49h,4Ch,69h,6Ch,89h,8Ch,0A4h,0B4h,0C4h
		db 2Ah,2Dh,4Ah,4Dh,6Ah,6Dh,8Ah,8Dh,0A5h,0B5h,0C5h
		db 30h,33h,50h,53h,70h,73h,90h,93h,0A6h,0B6h,0C6h
		db 31h,34h,51h,54h,71h,74h,91h,94h,0A7h,0B7h,0C7h
		db 32h,35h,52h,55h,72h,75h,92h,95h,0A8h,0B8h,0C8h

		Ends
                                End
