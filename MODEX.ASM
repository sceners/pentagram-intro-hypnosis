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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ This Library contains a few ModeX routines which may come handy in        ³
;³ graphics programming.                                                     ³
;³                                                                           ³
;³ ModeX routines :                                                          ³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;³       Name      ³     Function                                            ³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;³ Set320X240Mode  ³ Enable ModeX (in 320 X 240 resolution)                  ³
;³ WaitRetrace     ³ Wait until the Vertical Retrace has ended               ³
;³ WaitPulse       ³ Wait for the Vertical Pulse (Retracing has started)     ³
;³ DisplayWindow   ³ Display Window in Virtual Page at (X, Y) Coordinates    ³
;³ SplitScreen     ³ Split Screen, page 0 will show under the splitline      ³
;³ ShowImage       ³ Show Image on screen (must be multiple of four)         ³
;³ GetOldState     ³ Store current video State                               ³
;³ SetOldState     ³ Restore data from GetOldState                           ³
;³ WipeScrPalette  ³ Clear all colors to black in screen palette             ³
;³ WipePalette     ³ Clear all colors to black in palette array              ³
;³ CopyPalette     ³ Copy source palette to destination palette              ³
;³ SetPalette      ³ Set a palette                                           ³
;³ GetPalette      ³ Store old Screen Palette                                ³
;³ FadeScreenDn    ³ Fade screen palette down                                ³
;³ FadePalDn       ³ Fade Palette Down                                       ³
;³ FadeScreenUp    ³ Fade screen palette up                                  ³
;³ FadePalUp       ³ Fade Palette up                                         ³
;³ FadePaltoPal    ³ Fade Palette to another Palette                         ³
;³ CopyLine        ³ Copy Line from video memory to video memory             ³
;³                 ³                                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		Segment Code Para Public 'Code' Use16
                Assume cs:Code,ds:Data

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Set VGA screen mode in Tweaked Mode, resolution 320 X 400                 ³
;³                                                                           ³
;³ In  :  None                                                               ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Wait until the vertical retrace has ended                                 ³
;³                                                                           ³
;³ In  :  None                                                               ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Wait for the vertical pulse (Retracing has started)                       ³
;³                                                                           ³
;³ In  :  None                                                               ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
                PUBLIC  WaitPulse
WaitPulse:      push    ax dx

                mov     dx, 3DAh

                mov     ah, 08h
  Check3:       in      al, dx
                test    al, ah
                jz      Check3

                pop     dx ax
                ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Set Active page at an offset of video mem.                                ³
;³                                                                           ³
;³ In  :  DX = Addr of far Left Pixel to Display.                            ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Display Window in Virtual Page at (X, Y) Coordinates                      ³
;³                                                                           ³
;³ In  :  AX = X Offset                                                      ³
;³        BX = Y Offset                                                      ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Split screen at the splitline, data at Offset 0 of the video memory will  ³
;³ appear below the splitline.                                               ³
;³                                                                           ³
;³ In  :  AX = Line where the screen is to be split                          ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ read and store image from memory to video mem.                            ³
;³                                                                           ³
;³ In  :  DS:SI = Pointer to image                                           ³
;³        AX = Y coordinate        (used to be) AH Height                    ³
;³        BX = X coordinate        (used to be) AL YCoord                    ³
;³        CX = Width                                                         ³
;³        DH = Height                                                        ³
;³        DI = PageBase                                                      ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ GetOldState:  Store current video mode.                                   ³
;³                                                                           ³
;³ In  :  None                                                               ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		PUBLIC  GetOldState
GetOldState:    push    ax

                mov     ah, 0Fh                 ;Get current video state
		int	10h
		
		mov     [OldMode], al           ;Store current screen mode
		
                pop     ax
                ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ SetOldState:  Return  video mode to last state.                           ³
;³                                                                           ³
;³ In  :  None                                                               ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Clear all colors to black in palette so updates on screen are NOT visible ³
;³                                                                           ³
;³ In  :  None                                                               ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Clear all colors to black in palette array.                               ³
;³                                                                           ³
;³ In  :  DS:DI = Pointer to Palette to Wipe                                 ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		PUBLIC  WipePalette
WipePalette:    push    eax ax cx di es

                mov     ax, ds
		mov	es, ax
		xor     eax, eax

		mov     cx, 3*256/4             ;Wipe 256 RGB values
		rep     stosd

                pop     es di cx ax eax         ;Restore REGS
                ret                             ;Return

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ copy source palette to destination palette                                ³
;³                                                                           ³
;³ In  :  DS:SI = src  palette pointer                                       ³
;³        DS:DI = dest palette pointer                                       ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		PUBLIC  CopyPalette
CopyPalette:    push    ax cx si di es

                push    ds                      ;!
                pop     es                      ;!

                mov     cx, 3*256/4             ;Copy 256 RGB values
		rep     movsd

                pop     es di si cx ax
                ret                             ;Return

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ set screen palette                                                        ³
;³                                                                           ³
;³ In  :  DS:SI = palette pointer                                            ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Store old Screen Palette                                                  ³
;³                                                                           ³
;³ In  :  ES:DI = palette pointer                                            ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Fade screen palette down                                                  ³
;³                                                                           ³
;³ In  :  None                                                               ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Fade screen palette up                                                    ³
;³                                                                           ³
;³ In  :  DS:SI = pointer to palette to fade to                              ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Fade Palette to another palette                                           ³
;³                                                                           ³
;³ In  :  DS:SI = pointer to palette to fade to.                             ³
;³ Out :  AX = 0 if ready                                                    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Copy Line from video memory to video memory                               ³
;³                                                                           ³
;³ In  :  ES:SI = source line                                                ³
;³        ES:DI = destination line                                           ³
;³        CX    = number of lines to copy                                    ³
;³ Out :  None                                                               ³
;³                                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
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
