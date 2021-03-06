		Ideal
                p386
                DOSSEG

		;Constants for VGA card (ModeX)

CRTC_INDEX      EQU     03d4h   ;CRT Controller Index
GC_INDEX        EQU     03ceh   ;Graphics Controller Index
SC_INDEX        EQU     03c4h   ;Sequence Controller Index
MISC_OUTPUT	EQU	03c2h	;Miscellaneous Output Register
READ_MAP	EQU	04h	;Index in SC of Map Mask register
MAP_MASK	EQU	02h	;Index in SC of Map Mask register
BIT_MASK        EQU     08h     ;Index in GC of Bit Mask register
SCREEN_SEG      EQU     0a000h  ;Segment of display memory in mode X

START_ADDR_LOW  EQU     0dh
START_ADDR_HIGH EQU     0ch

VirtualWidth    = 320
VirtualHeight   = 1 Shl 18 / VirtualWidth

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� This Library contains a few ModeX routines which may come handy in        �
;� graphics programming.                                                     �
;�                                                                           �
;� ModeX routines :                                                          �
;쳐컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;�       Name      �     Function                                            �
;쳐컴컴컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Set320X240Mode  � Enable ModeX (in 320 X 240 resolution)                  �
;� WaitRetrace     � Wait until the Vertical Retrace has ended               �
;� WaitPulse       � Wait for the Vertical Pulse (Retracing has started)     �
;� DisplayWindow   � Display Window in Virtual Page at (X, Y) Coordinates    �
;� SplitScreen     � Split Screen, page 0 will show under the splitline      �
;� ShowImage       � Show Image on screen (must be multiple of four)         �
;� GetOldState     � Store current video State                               �
;� SetOldState     � Restore data from GetOldState                           �
;� WipeScrPalette  � Clear all colors to black in screen palette             �
;� WipePalette     � Clear all colors to black in palette array              �
;� CopyPalette     � Copy source palette to destination palette              �
;� SetPalette      � Set a palette                                           �
;� GetPalette      � Store old Screen Palette                                �
;� FadeScreenDn    � Fade screen palette down                                �
;� FadePalDn       � Fade Palette Down                                       �
;� FadeScreenUp    � Fade screen palette up                                  �
;� FadePalUp       � Fade Palette up                                         �
;� FadePaltoPal    � Fade Palette to another Palette                         �
;� CopyLine        � Copy Line from video memory to video memory             �
;�                 �                                                         �
;읕컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

		Segment Code Para Public 'Code' Use16
                Assume cs:Code,ds:Data

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Set VGA screen mode in Tweaked Mode, resolution 320 X 400                 �
;�                                                                           �
;� In  :  None                                                               �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
                PUBLIC  Set320x400Mode
Set320x400Mode: push    eax ax cx dx di es

                call    WipeScrPalette
		mov     ax, 13h         ;let the BIOS set standard 256-color
		int     10h             ; mode (320x200 linear)
		call    WipeScrPalette

                mov     dx, CRTC_INDEX
                mov     ax, 04009h      ;Set 400 Mode & Disable SplitScreen
                out     dx, ax
                mov     ax, 00014h
                out     dx, ax
                mov     ax, 0E317h
                out     dx, ax
                
		mov	dx, SC_INDEX
                mov     ax, 0604h
                out     dx, ax          ;Disable chain 4 mode
                mov     ax, 0f02h
                out     dx, ax          ;Enable writes to all 4 planes
                mov     ax, SCREEN_SEG  ;Clear all of display memory,
                mov     es, ax          ; 16 pixels at a time
                xor     di, di          ;Point ES:DI to start of display memory
                xor     eax, eax        ;Clear with zero bytes
                mov     cx, 4000h       ;# of DWords in display memory
                rep     stosd           ;Clear display memory

                pop     es di dx cx ax eax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Wait until the vertical retrace has ended                                 �
;�                                                                           �
;� In  :  None                                                               �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
                PUBLIC  WaitRetrace
WaitRetrace:    push    ax dx

                cmp     [RasterTime], 0
                je      CheckRt

                mov     dx, 03C8h
                xor     al, al
                out     dx, al
                mov     dx, 03C9h
                mov     al, 63
                out     dx, al
                mov     al, 63
                out     dx, al
                mov     al, 63
                out     dx, al

  CheckRt:      mov     dx, 3DAh

                mov     ah, 08h
  Check1:       in      al, dx
                test    al, ah
                jnz     Check1

  Check2:       in      al, dx
                test    al, ah
                jz      Check2

                cmp     [RasterTime], 0
                je      EndRt

                mov     dx, 03C8h
                xor     al, al
                out     dx, al
                mov     dx, 03C9h
                xor     al, al
                out     dx, al
                xor     al, al
                out     dx, al
                xor     al, al
                out     dx, al

  EndRt:        pop     dx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Wait for the vertical pulse (Retracing has started)                       �
;�                                                                           �
;� In  :  None                                                               �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
                PUBLIC  WaitPulse
WaitPulse:      push    ax dx

                mov     dx, 3DAh

                mov     ah, 08h
  Check3:       in      al, dx
                test    al, ah
                jz      Check3

                pop     dx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Set Active page at an offset of video mem.                                �
;�                                                                           �
;� In  :  DX = Addr of far Left Pixel to Display.                            �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
                PUBLIC  PanScreen
PanScreen:      push    ax bx cx dx

                mov     bl, START_ADDR_LOW
                mov     bh, dl
                mov     cl, START_ADDR_HIGH
                mov     ch, dh
                mov     dx, CRTC_INDEX

                mov     ax, bx
                out     dx, ax
                mov     ax, cx
                out     dx, ax

                call    WaitPulse

                pop     dx cx bx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Display Window in Virtual Page at (X, Y) Coordinates                      �
;�                                                                           �
;� In  :  AX = X Offset                                                      �
;�        BX = Y Offset                                                      �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
                PUBLIC  DisplayWindow
DisplayWindow:	cmp ax,VirtualWidth-320
		ja ScrollWindow0
		cmp bx,VirtualHeight-240
		ja ScrollWindow0
		mov dx,ax

		mov ax,VirtualWidth/4
		mul bx
		mov bh,dl
		shr dx,2
		add ax,dx			; Calculate VRAM Offset
		mov bl,al

		mov dx,3D4h			; Set VRAM Base Address
		mov al,0Ch
		out dx,ax
		mov ah,bl
		inc al
		out dx,ax

		mov dl,0C0h			; Set Horizontal PEL Panning
		mov al,13h
		out dx,al
		mov al,bh
		and al,3
		shl al,1
		out dx,al
		mov al,20h
		out dx,al
ScrollWindow0:	ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Split screen at the splitline, data at Offset 0 of the video memory will  �
;� appear below the splitline.                                               �
;�                                                                           �
;� In  :  AX = Line where the screen is to be split                          �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC	SplitScreen
SplitScreen:    mov cx,ax
		mov dx,03D4h			; Set Line Compare Reg. (b0-b7)
		mov al,18h
		out dx,al
		inc dl
		mov al,cl
		out dx,al
		dec dl

		mov al,07h			; Set Line Compare Reg. (b8)
		out dx,al
		inc dl
		in al,dx
		and al,0EFh
		test ch,1
		jz SplitS_b8Low
		or al,10h
SplitS_b8Low:	out dx,al

		mov dl,0D4h			; Set Line Compare Reg. (b9)
		mov al,09h
		out dx,al
		inc dl
		in al,dx
		and al,0BFh
		test ch,2
		jz SplitS_b9Low
		or al,40h
SplitS_b9Low:	out dx,al

		mov dl,0DAh			; Reset FlipFlop to Adr. Mode
		in al,dx

		mov dl,0C0h
		mov al,10h			; Set Attribute Register
		out dx,al
		inc dl
		in al,dx
		or al,20h			; Enable b5, PEL Panning Reg.
		dec dl
		out dx,al
		mov al,20h
		out dx,al
		ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� read and store image from memory to video mem.                            �
;�                                                                           �
;� In  :  DS:SI = Pointer to image                                           �
;�        AX = Y coordinate        (used to be) AH Height                    �
;�        BX = X coordinate        (used to be) AL YCoord                    �
;�        CX = Width                                                         �
;�        DH = Height                                                        �
;�        DI = PageBase                                                      �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
                PUBLIC  ShowImage
ShowImage:      push    ax bx cx dx si di es

                shr     bx, 2                   ;Divide BX by 4
                add     di, bx                  ;Add column to DI

                mov     bh, dh                  ;BH = Height

                mov     dx, 80
                mul     dx
                add     di, ax                  ;Add line to DI

                shr     cx, 2                   ;BL = Width / 4
                mov     bl, cl

                mov     bp, 80                  ;BP = NextLine
                sub     bp, cx
                
                mov     dx, SCREEN_SEG
                mov     es, dx

                mov     cl, 3                   ;Copy 3 to 0 Planes
  DoPlanes:     push    si di

                mov     ax, 0100h + MAP_MASK
                shl     ah, cl                  ;CX = Plane
                mov     dx, SC_INDEX            ;Select new plane
                out     dx, ax
                xor     ch, ch
                add     si, cx                  ;SI + Plane

                mov     ch, bh                  ;Copy height
  DoHeight:     mov     ah, bl                  ;Copy width
  DoWidth:      mov     al, [si]
                mov     [es:di], al
                inc     di
                add     si, 4
                dec     ah
                jnz     DoWidth

                add     di, bp
                dec     ch
                jnz     DoHeight

                pop     di si
                dec     cl
                jns     DoPlanes

                pop     es di si dx cx bx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� GetOldState:  Store current video mode.                                   �
;�                                                                           �
;� In  :  None                                                               �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  GetOldState
GetOldState:    push    ax

                mov     ah, 0Fh                 ;Get current video state
		int	10h
		
		mov     [OldMode], al           ;Store current screen mode
		
                pop     ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� SetOldState:  Return  video mode to last state.                           �
;�                                                                           �
;� In  :  None                                                               �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  SetOldState
SetOldState:    push    eax ax cx dx di es

                call    WipeScrPalette

                mov     dx, SC_INDEX
                mov     ax, 0f02h
                out     dx, ax          ;enable writes to all four planes
                mov     ax, SCREEN_SEG  ;now clear all of display memory,
                mov     es, ax          ; 16 pixels at a time
                xor     di, di          ;point ES:DI to display memory
                xor     eax, eax        ;Clear with zero bytes
                mov     cx, 4000h       ;# of DWords in display memory
                rep     stosd           ;clear all of display memory

                xor     ah, ah                  ;Restore old video mode
		mov	al, [OldMode]
		int     10h

                pop     es di dx cx ax eax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Clear all colors to black in palette so updates on screen are NOT visible �
;�                                                                           �
;� In  :  None                                                               �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  WipeScrPalette
WipeScrPalette: push    ax cx dx

                mov     dx, 3C8h
		xor	al, al
		out	dx, al			;Change palette
		inc	dx

		mov     cx, 3*256
  WipePalLoop:  out	dx, al			;Clear palette values
		dec	cx
		jnz     WipePalLoop

                pop     dx cx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Clear all colors to black in palette array.                               �
;�                                                                           �
;� In  :  DS:DI = Pointer to Palette to Wipe                                 �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  WipePalette
WipePalette:    push    eax ax cx di es

                mov     ax, ds
		mov	es, ax
		xor     eax, eax

		mov     cx, 3*256/4             ;Wipe 256 RGB values
		rep     stosd

                pop     es di cx ax eax         ;Restore REGS
                ret                             ;Return

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� copy source palette to destination palette                                �
;�                                                                           �
;� In  :  DS:SI = src  palette pointer                                       �
;�        DS:DI = dest palette pointer                                       �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  CopyPalette
CopyPalette:    push    ax cx si di es

                push    ds                      ;!
                pop     es                      ;!

                mov     cx, 3*256/4             ;Copy 256 RGB values
		rep     movsd

                pop     es di si cx ax
                ret                             ;Return

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� set screen palette                                                        �
;�                                                                           �
;� In  :  DS:SI = palette pointer                                            �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  SetPalette
SetPalette:     push    ax cx dx si

                mov     dx, 3C8h                ;Port to Set Palette
		xor     al, al
		out     dx, al
		inc     dx

		mov     cx, 3*256               ;Set 256 RGB values
		rep     outsb                   ;Set palette values

                pop     si dx cx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Store old Screen Palette                                                  �
;�                                                                           �
;� In  :  ES:DI = palette pointer                                            �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  GetPalette
GetPalette:     push    ax cx dx di es

                mov     dx, 3C7h                ;Port to Get Palette
		xor	al, al
		out	dx, al
		add	dl, 2

		mov     cx, 3*256               ;Get 256 RGB values
                rep	insb			;Move palette values

                pop     es di dx cx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Fade screen palette down                                                  �
;�                                                                           �
;� In  :  None                                                               �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  FadeScreenDn
FadeScreenDn:   push    ax cx si di ds es

                mov     di, Offset TmpPalette
                mov     ax, Seg TmpPalette
		mov	es, ax
		mov	ds, ax
		call    GetPalette              ;Copy palette to tmp
				
		mov	ax, 100
  FadeDn:       mov     si, Offset TmpPalette   ;SI = ptr to tmp. palette
		mov	cx, 256
                push    ax
                call    ColorFade
                pop     ax
                dec     ax
		jns	FadeDn

                pop     es ds di si cx ax
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Fade screen palette up                                                    �
;�                                                                           �
;� In  :  DS:SI = pointer to palette to fade to                              �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  FadeScreenUp
FadeScreenUp:   push    ax cx si di

                mov     di, Offset TmpPalette
                call    CopyPalette             ;Copy palette to tmp
                                
		xor	ax, ax 
  FadeUp:       push    ax
  		mov     si, Offset TmpPalette   ;SI = ptr to tmp. palette
		mov	cx, 256
		call	ColorFade
		pop	ax
		inc	al
		cmp	al, 100
                jbe     FadeUp

                pop     di si cx ax
                ret

; ColorFade (Waits for VSync)
; Input: SI = Offset ColorTable
;        AL = Percentage of color
;        AH = Color #
;        CX = Number of Colors

ColorFade:      push es
		mov bx,cx
		shl cx,1
		add cx,bx
                mov di,Offset TempColorTable
		mov bx,ds
		mov es,bx
                cld
                mov bh,al
                mov bl,100
		push ax
                push cx
                push di
ColorFade1:	lodsb			; NewValue:=OldValue*Percent/100
                mul bh
                div bl
                cmp al,64
                jc ColorFade2
                mov al,63
ColorFade2:	stosb
                loop ColorFade1
                pop si
		pop cx
		pop ax

		mov dx,03DAh			; Wait for Vertical Retrace
		mov bl,8
ColorFade3:	in al,dx
		test al,bl
		jz ColorFade3

                mov dl,0C8h			; Set Palette
                mov al,ah
                out dx,al
                inc dl
                rep outsb

		mov dl,0DAh
		mov bl,8
ColorFade4:	in al,dx
		test al,bl
		jnz ColorFade4
                pop es
		ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Fade Palette to another palette                                           �
;�                                                                           �
;� In  :  DS:SI = pointer to palette to fade to.                             �
;� Out :  AX = 0 if ready                                                    �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  FadePalToPal
FadePalToPal:   push    es
                mov     ax, SEG ScreenPalette
                mov     es, ax
                mov     di, Offset ScreenPalette
                xor     ah, ah                  ;Return Code = 0

		mov     cx, 3*256               ;Check 256 RGB values
  CheckPal:     lodsb                           ;Get palette value
                cmp     [es:di], al
                je      CheckNext               ;Same, so check next
                mov     ah, 1                   ;Return Code = 1
                ja      Higher

                inc     [byte es:di]            ;Increase new palette
		jmp     CheckNext

  Higher:       dec     [byte es:di]            ;Decrease new palette
		
  CheckNext:    inc     di                      ;Next Target
		loop    CheckPal                ;Check next

                mov     al, ah                  ;Copy Return Code
                pop     es
                ret

;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;� Copy Line from video memory to video memory                               �
;�                                                                           �
;� In  :  ES:SI = source line                                                �
;�        ES:DI = destination line                                           �
;�        CX    = number of lines to copy                                    �
;� Out :  None                                                               �
;�                                                                           �
;읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
		PUBLIC  CopyLine
CopyLine:       push    ax bx cx dx si di ds es

		mov     ax, SCREEN_SEG
		mov     es, ax
		mov     ds, ax

		mov     dx, GC_INDEX            ;Read all data from Latches
		mov     al, BIT_MASK
		xor     ah, ah
		out     dx, ax

		mov     dx, SC_INDEX
		mov     al, MAP_MASK
		mov     ah, 0Fh                 ;All Planes for writing
		out     dx, ax

		mov     ax, 320/4
		mul     cx
		mov     cx, ax
		rep     movsb

		mov     dx, GC_INDEX            ;Read all data from CPU
		mov     al, BIT_MASK
		mov     ah, 0FFh
		out     dx, ax

		pop     es ds di si dx cx bx ax
		ret

                Ends
                Segment Data Para Public 'Data' Use16

Label           CRTparms        WORD
                DW      00d06h  ;Vertical total
                DW      03e07h  ;Overflow (bit 8 of vertical count)
                DW      04109h  ;Cell height (2 to double-scan)
                DW      0ea10h  ;v sync start
                DW      0ac11h  ;v sync end and protect cr0-cr7?
                DW      0df12h  ;Verical displayed
                DW      00014h  ;Turn off dword mode
                DW      0e715h  ;v blank start
                DW      00616h  ;v blank end
                DW      0e317h  ;Turn on byte mode
CRT_PARM_LENGTH EQU     10

                ;Variables of WaitRetrace
                PUBLIC  RasterTime
RasterTime      DB      0               ;If not zero, show RasterTime

		;Variables of GetOldState
OldMode         DB      0               ;Old BIOS video mode

                ;Variables used by palette routines
                PUBLIC  TmpPalette
                PUBLIC  ScreenPalette
TmpPalette      DB      3*256   dup(0)          ;Tmp palette contents
ScreenPalette   DB      3*256   dup(0)          ;Visible palette contents
TempColorTable  DB      3*256   dup(0)          ;Used by ColorFade

                Ends
				END
