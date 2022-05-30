;**********************************************************************;
; DRAW.ASM                                                             ;
;                                                                      ;
; This source file contains the screen related routines for the vector ;
; demo, like FlipPages, DrawObject, etc.                               ;
;**********************************************************************;

                Ideal                           ;Enable TASM Ideal Mode
                p386                            ;Enable 80386 Code
                DOSSeg                          ;Enable DOS Segmentation

                INCLUDE "image.inc"             ;Image Constants
                INCLUDE "object.inc"            ;Object definitions
                INCLUDE "modex.inc"             ;ModeX constants & routines
                INCLUDE "scroll.inc"

Macro           WaitMacro
                LOCAL   Wait, WaitLoop
                push    cx

                mov     cx, 8
  Wait:         push    cx

                mov     cx, 65535
  WaitLoop:     loop    WaitLoop

                pop     cx
                loop    Wait

                pop     cx
                ENDM

; Gold            1 -  31
; Blue          xxx - xxx

BackColor       EQU   214
EdgeColor       EQU     4

FillDir         EQU     1       ; inc (1), hold (0) or dec (-1) palette colors
BeginColor      EQU     8
EndColor        EQU     31

ClipMinX        EQU     2
ClipMaxX        EQU     318
ClipMinY        EQU     97
ClipMaxY        EQU     247


                Segment Code Para Public 'Code' Use16
                Assume cs:Code,ds:Data


                PUBLIC  UpdateWriter
UpdateWriter:   push    ax bx cx dx si di

                cmp     [TextLen], 0            ;All Text on screen?
                ja      NextChar                ;No, put next char.

                mov     dx, [YTable+(2*ScrollPos)]      ;Put last char on other
                add     dx, [CurrPos]                   ; page also.
                sub     dx, (FontWidth / 4)
                mov     si, [ShowPage]
                add     si, dx
                mov     di, [DrawPage]
                add     di, dx
                mov     bx, FontHeight
                mov     dx, (FontWidth / 4)
                call    CopyArea

                cmp     [FadeUp], 1             ;Text visible?
                je      ReadWait                ;Yes, let user read it.
                                                        
                mov     si, Offset VectorPalette
                call    FadePaltoPal            ;ScreenPal to VectorPal
                or      al, al
                jnz     ExitWriter              ;Fade more.

                mov     [FadeUp], 1             ;FadeUp finished.

  ReadWait:     cmp     [WaitCycles], 0         ;Text Read?
                je      FadeDnWriter            ;Yes, fade down.

                dec     [WaitCycles]            ;No, wait some more.
                jmp     ExitWriter

  FadeDnWriter: mov     si, Offset NoWriterPalette
                call    FadePaltoPal            ;ScreenPal to NoWriterPal
                or      al, al
                jnz     ExitWriter              ;Fade more.

  NextLine:     mov     [WaitCycles], 40
                mov     [FadeUp], 0

                mov     ax, [YTable+(2*ScrollPos)]      ;Pos on screen
                mov     cx, [Ytable+(2*FontHeight)]     ;Amount to Wipe
                mov     di, [ShowPage]
                add     di, ax
                mov     al, BackColor
                mov     ah, al
                shr     cx, 1
                rep     stosw
                mov     ax, [YTable+(2*ScrollPos)]      ;Pos on screen
                mov     cx, [Ytable+(2*FontHeight)]     ;Amount to Wipe
                mov     di, [DrawPage]
                add     di, ax
                mov     al, BackColor
                mov     ah, al
                shr     cx, 1
                rep     stosw

                mov     bx, [TextPos]

                cmp     [ScrollText+bx], 0      ;Check for EOT
                jne     CheckNew

                xor     bx, bx                  ;On end, so restart

  CheckNew:     mov     si, [ScrollText+bx]     ;Check for EOL
                mov     di, Offset char42
                cmp     si, di
                je      CheckNext
                add     bx, 2
                jmp     CheckNew

  CheckNext:    mov     [TextPos], bx
                xor     ax, ax

  FindNext:     add     bx, 2
                inc     ax                      ;There are always 2 chars!!
                mov     si, [ScrollText+bx]     ;Check for EOL
                mov     di, Offset char42
                cmp     si, di
                je      FoundNext
                jmp     FindNext

  FoundNext:    inc     ax
                mov     [TextLen], ax
                mov     bx, (320 / FontWidth)
                sub     bx, ax
                shr     bx, 1
                mov     ax, (FontWidth / 4)
                mul     bx
                mov     [CurrPos], ax           ;Centrated Position

  NextChar:     dec     [TextLen]

                mov     dx, [YTable+(2*ScrollPos)]
                add     dx, [CurrPos]
                sub     dx, (FontWidth / 4)

                mov     si, [ShowPage]
                add     si, dx

                mov     di, [DrawPage]
                add     di, dx

                mov     bx, FontHeight
                mov     dx, (FontWidth / 4)
                call    CopyArea

                mov     bx, [TextPos]
                mov     si, [ScrollText+bx]
                mov     bx, [CurrPos]           ;X Coord
                shl     bx, 2
                mov     ax, ScrollPos           ;Y Coord
                mov     dh, FontHeight          ;Height
                mov     cx, FontWidth           ;Width
                mov     di, [Drawpage]
                call    ShowImage

                add     [CurrPos], (FontWidth / 4)
                add     [TextPos], 2

  ExitWriter:   pop     di si dx cx bx ax
                ret

; In: DI = Destination Area.
;     SI = Source Area.
;     BX = Height.
;     DX = Width.

CopyArea:       push    ds
                mov     cx, dx

                mov     ax, SCREEN_SEG
                mov     es, ax
                mov     ds, ax

                mov     dx, GC_INDEX            ;Read all data from Latches
                mov     al, BIT_MASK
                xor     ah, ah
                out     dx, ax

                mov     dx, SC_INDEX            ;All Planes for writing
                mov     al, MAP_MASK
                mov     ah, 0Fh                 
                out     dx, ax

                mov     dx, cx

  VerArea:      rep     movsb
                add     si, 80
                add     di, 80
                sub     si, dx
                sub     di, dx
                mov     cx, dx
                dec     bx
                or      bx, bx
                jnz     VerArea

                mov     dx, GC_INDEX            ;Read all data from CPU
                mov     al, BIT_MASK
                mov     ah, 0FFh
                out     dx, ax
                pop     ds
                ret


                PUBLIC  Introduction
Introduction:   push    ax bx cx dx si di eax ds

                mov     ax, SEG Product
                mov     ds, ax
                mov     si, Offset Product
                mov     bx, ProductXCoord       ;X Coord
                mov     ax, ProductYCoord       ;Y Coord
                mov     cx, ProductWidth        ;Width
                mov     dh, ProductHeight       ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG IntroPalette
                mov     ds, ax
                mov     si, Offset IntroPalette
                call    FadeScreenUp            ;Fade from Zero to IntroPalette

                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro

                call    FadeScreenDn            ;Fade from IntroPalette to Zero

                mov     dx, SC_INDEX
                mov     ax, 0f02h
                out     dx, ax                  ;Enable writes to all 4 planes
                xor     di, di                  ;Point ES:DI to display memory
                xor     eax, eax                ;Clear with zero bytes
                mov     cx, 2000h               ;# of DWords in display memory
                call    WaitPulse
                rep     stosd                   ;Clear display memory

                mov     ax, SEG Vivian
                mov     ds, ax
                mov     si, Offset Vivian
                mov     bx, VivianXCoord        ;X Coord
                mov     ax, VivianYCoord        ;Y Coord
                mov     cx, VivianWidth         ;Width
                mov     dh, VivianHeight        ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG Program
                mov     ds, ax
                mov     si, Offset Program
                mov     bx, ProgramXCoord       ;X Coord
                mov     ax, ProgramYCoord       ;Y Coord
                mov     cx, ProgramWidth        ;Width
                mov     dh, ProgramHeight       ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG IntroPalette
                mov     ds, ax
                mov     si, Offset IntroPalette
                call    FadeScreenUp            ;Fade from Zero to IntroPalette

                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro

                call    FadeScreenDn            ;Fade from IntroPalette to Zero

                mov     dx, SC_INDEX
                mov     ax, 0f02h
                out     dx, ax                  ;Enable writes to all 4 planes
                xor     di, di                  ;Point ES:DI to display memory
                xor     eax, eax                ;Clear with zero bytes
                mov     cx, 2000h               ;# of DWords in display memory
                call    WaitPulse
                rep     stosd                   ;Clear display memory

                mov     ax, SEG ATron
                mov     ds, ax
                mov     si, Offset ATron
                mov     bx, ATronXCoord         ;X Coord
                mov     ax, ATronYCoord         ;Y Coord
                mov     cx, ATronWidth          ;Width
                mov     dh, ATronHeight         ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG Graphics
                mov     ds, ax
                mov     si, Offset Graphics
                mov     bx, GraphicsXCoord      ;X Coord
                mov     ax, GraphicsYCoord      ;Y Coord
                mov     cx, GraphicsWidth       ;Width
                mov     dh, GraphicsHeight      ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG IntroPalette
                mov     ds, ax
                mov     si, Offset IntroPalette
                call    FadeScreenUp            ;Fade from Zero to IntroPalette

                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro

                call    FadeScreenDn            ;Fade from IntroPalette to Zero

                mov     dx, SC_INDEX
                mov     ax, 0f02h
                out     dx, ax                  ;Enable writes to all 4 planes
                xor     di, di                  ;Point ES:DI to display memory
                xor     eax, eax                ;Clear with zero bytes
                mov     cx, 2000h               ;# of DWords in display memory
                call    WaitPulse
                rep     stosd                   ;Clear display memory

                mov     ax, SEG Shadow
                mov     ds, ax
                mov     si, Offset Shadow
                mov     bx, ShadowXCoord        ;X Coord
                mov     ax, ShadowYCoord        ;Y Coord
                mov     cx, ShadowWidth         ;Width
                mov     dh, ShadowHeight        ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG Music
                mov     ds, ax
                mov     si, Offset Music
                mov     bx, MusicXCoord         ;X Coord
                mov     ax, MusicYCoord         ;Y Coord
                mov     cx, MusicWidth          ;Width
                mov     dh, MusicHeight         ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG IntroPalette
                mov     ds, ax
                mov     si, Offset IntroPalette
                call    FadeScreenUp            ;Fade from Zero to IntroPalette

                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro

                call    FadeScreenDn            ;Fade from IntroPalette to Zero

                mov     dx, SC_INDEX
                mov     ax, 0f02h
                out     dx, ax                  ;Enable writes to all 4 planes
                xor     di, di                  ;Point ES:DI to display memory
                xor     eax, eax                ;Clear with zero bytes
                mov     cx, 2000h               ;# of DWords in display memory
                call    WaitPulse
                rep     stosd                   ;Clear display memory

                mov     ax, SEG ShowPage
                mov     ds, ax
                mov     dx, SC_INDEX
                mov     ax, 0f02h
                out     dx, ax                  ;enable writes to all 4 planes
                mov     di, [ShowPage]
                add     di, 80*97               ;point ES:DI to display memory
                mov     al, BackColor           ;Clear with BackColor
                mov     ah, al
                mov     cx, 8040                ;# of Words in display memory
                call    WaitPulse
                rep     stosw                   ;clear display memory
                mov     di, [DrawPage]
                add     di, 80*97               ;point ES:DI to display memory
                mov     cx, 8040                ;# of Words in display memory
                call    WaitPulse
                rep     stosw                   ;clear display memory

                mov     ax, SEG For
                mov     ds, ax
                mov     si, Offset For
                mov     bx, ForXCoord           ;X Coord
                mov     ax, ForYCoord           ;Y Coord
                mov     cx, ForWidth            ;Width
                mov     dh, ForHeight           ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG IntroPalette
                mov     ds, ax
                mov     si, Offset IntroPalette
                call    FadeScreenUp            ;Fade from Zero to IntroPalette

                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro
                WaitMacro

                mov     ax, SEG IntroPalette
                mov     ds, ax
                mov     si, Offset IntroPalette
                mov     di, Offset ScreenPalette
                call    CopyPalette

  FadeAway:     mov     si, Offset NoIntroPalette
                call    FadePalToPal            ;ScreenPal to NoIntroPal
                mov     si, Offset ScreenPalette
                call    WaitPulse
                call    SetPalette
                or      al, al
                jnz     FadeAway                ;Fade more

                pop     ds eax di si dx cx bx ax
                ret


                PUBLIC  PrepareForDemo
PrepareForDemo: push    ax bx cx dx si di eax ds

                mov     ax, SEG ShowPage
                mov     ds, ax
                mov     dx, SC_INDEX
                mov     ax, 0f02h
                out     dx, ax                  ;enable writes to all 4 planes
                mov     di, [ShowPage]
                add     di, 80*97               ;point ES:DI to display memory
                mov     al, BackColor           ;Clear with BackColor
                mov     ah, al
                mov     cx, 8040                ;# of Words in display memory
                call    WaitPulse
                rep     stosw                   ;clear display memory
                mov     di, [DrawPage]
                add     di, 80*97               ;point ES:DI to display memory
                mov     cx, 8040                ;# of Words in display memory
                call    WaitPulse
                rep     stosw                   ;clear display memory

                mov     ax, SEG VectorPalette
                mov     ds, ax
                mov     si, Offset VectorPalette
                mov     di, Offset ScreenPalette
                call    CopyPalette
                call    WaitPulse
                call    SetPalette

                mov     ax, SEG Penta
                mov     ds, ax
                mov     si, Offset Penta
                mov     bx, PentaXCoord         ;X Coord
                mov     ax, PentaYCoord         ;Y Coord
                mov     cx, PentaWidth          ;Width
                mov     dh, PentaHeight         ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     di, 32000               ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     ax, SEG Gram
                mov     ds, ax
                mov     si, Offset Gram
                mov     bx, GramXCoord          ;X Coord
                mov     ax, GramYCoord          ;Y Coord
                mov     cx, GramWidth           ;Width
                mov     dh, GramHeight          ;Height
                xor     di, di                  ;PageBase
                call    WaitPulse
                call    ShowImage

                mov     di, 32000               ;PageBase
                call    WaitPulse
                call    ShowImage

                pop     ds eax di si dx cx bx ax
                ret


; FlipPages:    Swaps the values of the DrawPage and ShowPage
;               variables, and makes the new ShowPage the ac-
;               tive page.

                PUBLIC  FlipPages
FlipPages:      push    ax bx cx dx si

                mov     bx, [ShowPage]
                mov     dx, [DrawPage]
                mov     [ShowPage], dx
                mov     [DrawPage], bx

                mov     bl, START_ADDR_LOW
                mov     bh, dl
                mov     cl, START_ADDR_HIGH
                mov     ch, dh

                mov     dx, CRTC_INDEX
                mov     ax, bx                  ;Update Screen Start Addr
                out     dx, ax
                mov     ax, cx
                out     dx, ax

                call    WaitRetrace

                mov     si, Offset ScreenPalette

                mov     dx, 3C8h                ;Port to Set Palette
                xor     al, al
                out     dx, al
                inc     dx

                mov     cx, 3*256               ;Set 256 RGB values

                rep     outsb                   ;Set palette values

                pop     si dx cx bx ax
                ret


                PUBLIC  MirrorObject
MirrorObject:   push    ax bx cx dx si di ds

                mov     di, [YTable+((ClipMaxY +1)*2)]
                add     di, [DrawPage]
                mov     si, di
                sub     si, 80
                mov     ax, SCREEN_SEG
                mov     ds, ax

                mov     dx, GC_INDEX            ;Read all data from Latches
                mov     al, BIT_MASK
                xor     ah, ah
                out     dx, ax

                mov     dx, SC_INDEX
                mov     al, MAP_MASK
                mov     ah, 0Fh                 ;All Planes for writing
                out     dx, ax

                mov     cx, 297 - ClipMaxY - FontHeight
  MirrorLoop:   push    cx
                mov     cx, 80
                rep     movsb
                sub     si, 3*80
                pop     cx
                loop    MirrorLoop

                mov     dx, GC_INDEX            ;Read all data from CPU
                mov     al, BIT_MASK
                mov     ah, 0FFh
                out     dx, ax

                pop     ds di si dx cx bx ax
                ret


; EraseObject:  This routine wipes the object
;               by pumping BackColor onto the
;               DrawPage.

                PUBLIC  EraseObject
EraseObject:    push    ax bx cx dx si di ds

                mov     dx, GC_INDEX            ;Read all data from CPU
                mov     al, BIT_MASK
                mov     ah, 0FFh
                out     dx, ax

                mov     dx, SC_INDEX
                mov     al, MAP_MASK
                mov     ah, 0Fh                 ;All Planes for writing
                out     dx, ax

                mov     di, [DrawPage]

                mov     bx, [yMintoErase]
                cmp     bx, [yMaxtoErase]
                jle     Okay
                mov     [yMaxtoErase], bx
  Okay:         shl     bx, 1
                mov     ax, [YTable+bx]
                add     di, ax                  ;Calc offset in page

                mov     bx, [yMaxtoErase]
                sub     bx, [yMintoErase]
                inc     bx
                shl     bx, 1
                mov     cx, [YTable+bx]         ;Calc size of boundary to erase

                mov     ax, BackColor           ;Fill with BackColor
                rep     stosb

                pop     ds di si dx cx bx ax
                ret


; DrawObject:   This routine loops through all faces
;               in current object and calls DrawFace
;               to draw them.

                PUBLIC  DrawObject
DrawObject:     push    ax cx si bp

                mov     ax, [yMinErase]         ;Copy Erase Boundaries
                mov     [yMintoErase], ax       ; of previous object

                mov     ax, [yMaxErase]
                mov     [yMaxtoErase], ax

                mov     [yMinErase], ClipMaxY   ;Reset Erase Boundaries
                mov     [yMaxErase], ClipMinY

                mov     si, [CurrObject]
                mov     cx, [si+Object.NumFaces];CX = Number of faces
                xor     bp, bp                  ;BP = Index into FaceIndices

  ProcessFace:  push    cx                      ;Save Face Count
                mov     si, [ds:FaceIndices+bp] ;DS:SI = Ptr to face coords
                add     bp, 2                   ;Move to next entry

                lodsw                           ;Get number of coords in face
                mov     cx, ax                  ; into CX
                call    DrawFace                ;Draw the face
                pop     cx                      ;Restore Face Count
                loop    ProcessFace             ;Do for all faces in object

                pop     bp si cx ax
                ret


; DrawFace:      This routine draws one face of the
;                current object on the DrawPage.

DrawFace:       push    ax

                mov     [FillColor], BeginColor         ;Reset fill color
                mov     [FillSign], FillDir             ; and sign

                ;This would test if the Face is
                ;actually visible, but you should
                ;not do it with the PentaGram Object.

;                call    SurfaceTest                     ;Face Visible?
;                cmp     ax, 0
;                jge     ExitDrawFace                    ;No, so exit

                call    CalcPoly                        ;Calc poly boundaries
                call    FillWithBuf                     ;Fill with buffer

                ;This would draw the Frame of the
                ;Object in One Color, but you should
                ;not do it with the PentaGram Object.

;                call    DrawEdge                        ;Draw edge of poly

  ExitDrawFace: pop     ax
                ret


; In:   SI = Pointer to polygon coordinates.
;       CX = Num of coordinates.
;
; Out:  AX = The Normal to the face.

SurfaceTest:    push    bx cx dx di

                mov     di, si
                sub     cx, 2
                shl     cx, 2
                add     di, cx

                mov     ax, [si+4]
                sub     ax, [si]

                mov     bx, [di+2]
                sub     bx, [si+2]

                xor     dx, dx
                imul    bx
                mov     cx, ax

                mov     ax, [di]
                sub     ax, [si]

                mov     bx, [si+6]
                sub     bx, [si+2]

                xor     dx, dx
                imul    bx

                sub     cx, ax
                mov     ax, cx                  ;AX = the Normal to the face

                pop     di dx cx bx
                ret


; SI = Pointer to polygon coordinates
; CX = Num of coordinates

CalcPoly:       push    ax bx cx dx si di es

                push    cx                      ;Save Coordinate count

                mov     ax, ds
                mov     es, ax                  ;ES = DS = Data segment

                mov     di, Offset AllFaceCoorBuf
                xor     ax, ax                  ;Fill with zero
                mov     cx, 2*250               ; 2 words an entry
                rep     stosw

                pop     cx                      ;Restore Coordinate count

                lodsw                           ;Get first X Coord
                mov     [gcurx], ax             ; store it as current
                lodsw                           ;Get first Y Coord
                mov     [gcury], ax             ; store it as current
                dec     cx                      ;One coordinate processed

  ProcessCoord: lodsw                           ;Get X Coord
                mov     dx, ax                  ; into DX
                lodsw                           ;Get Y Coord
                mov     bx, ax                  ; into BX
                call    DrawLineTo              ;Draw line to (DX,BX)
                loop    ProcessCoord            ; Do for all coords in face

                pop     es di si dx cx bx ax
                ret


;draw line from (gcurx,gcury) to (dx,bx) with color (color)
;requires es=vram, changes: ax

DrawLineTo:     push    cx si di bp

                push    dx bx

  lt5:          mov     [xtmp], dx
                mov     [ytmp], bx
	;calc differencies xdif,ydif (+-) & abs difs, xabs,yabs (+)
	;and signs xsgn,ysgn (-1/0/1)
                xor     cx, cx
                mov     ax, [gcurx]
                sub     ax, dx
                mov     [xdif], ax
                or      ax, ax
                je      lt1
                inc     cx
                test    ax, 32768
                jz      lt1

                neg     ax
                dec     cx
                dec     cx
  lt1:          mov     [xabs], ax
                mov     [xsgn], cx

                xor     cx, cx
                mov     ax, [gcury]
                sub     ax, bx
                mov     [ydif], ax
                or      ax, ax
                je      lt2

                inc     cx
                test    ax, 32768
                jz      lt2

                neg     ax
                dec     cx
                dec     cx
  lt2:          mov     [yabs], ax
                mov     [ysgn], cx

                ;which is bigger?
                cmp     ax, [xabs]
                ja      lt3

                ;xbigger

                ;calc addl/h (si,di)
                jne     lt9
                ;1/1 addition, 45 degree curve
                cmp     ax, 0
                jne     lt15

                mov     dx, [gcurx]
                mov     bx, [gcury]
                call    pset
                jmp     lt10

  lt15:         mov     di, [ysgn]
                mov     si, 65535
                jmp     lt10

  lt9:          mov     dx, ax                  ;dx=yabs
                xor     ax, ax
                div     [xabs]                  ;ax=lowadd
                mov     si, ax
                mov     di, [ysgn]

  lt10:         mov     ax, 32767
                mov     bp, [xsgn]
                mov     cx, [xabs]
                inc     cx
                mov     dx, [xtmp]
                mov     bx, [ytmp]

  lt7:          call    pset
                add     dx, bp                  ;xsgn
                add     ax, si                  ;yaddl
                jnc     lt8
                add     bx, di                  ;ysgn
  lt8:          loop    lt7

                jmp     lt0


  lt3:          ;ybigger

                mov     dx, [xabs]
                xor     ax, ax
                div     [yabs]                  ;ax=lowadd
                mov     si, ax
                mov     di, [xsgn]

  lt12:         mov     ax, 32767
                mov     bp, [ysgn]
                mov     cx, [yabs]
                inc     cx
                mov     dx, [xtmp]
                mov     bx, [ytmp]

  lt13:         call    pset
                add     bx, bp                  ;ysgn
                add     ax, si                  ;xaddl
                jnc     lt14
                add     dx, di                  ;xsgn
  lt14:         loop    lt13
	
  lt0:          pop     bx dx
                mov     [gcurx], dx
                mov     [gcury], bx

                pop     bp di si cx
                ret


; Add Point(dx,bx) to point buffer

Pset:           push    ax bx cx dx si

                cmp     bx, ClipMinY            ;Clip the Min Y Coord
                jb      ExitPset
                cmp     bx, ClipMaxY            ;Clip the Max Y Coord
                ja      ExitPset

                cmp     dx, ClipMinX
                ja      CheckMaxX
                je      CheckErase
                mov     dx, ClipMinX            ;Clip the Min X Coord
                jmp     CheckErase

  CheckMaxX:    cmp     dx, ClipMaxX
                jbe     CheckErase
                mov     dx, ClipMaxX            ;Clip the Max X Coord

  CheckErase:   cmp     bx, [yMinErase]
                ja      CheckMaxDel
                mov     [yMinErase], bx

  CheckMaxDel:  cmp     bx, [yMaxErase]
                jb      DoPset
                mov     [yMaxErase], bx
                jmp     DoPset

  DoPset:       inc     dx
                mov     si, Offset AllFaceCoorBuf

                shl     bx, 2
                add     si, bx

                mov     bx, [si]                ;BX = Left coor
                mov     cx, [si+2]              ;CX = Right coor

                or      bx, bx
                jnz     PCheck1
                mov     bx, dx
                jmp     StoreCoorPos

  PCheck1:      cmp     dx, bx                  ;Compare X coor with left
                jb      CheckForRight           ;Below, so check any right coor

                cmp     dx, cx                  ;Compare X coor with right
                jbe     ExitPset                ;Below/Eq, so already in

                mov     cx, dx                  ;Above, so new right is DX
                jmp     StoreCoorPos

  CheckForRight:or      cx, cx                  ;Any right coor yet?
                jz      LowToHigh               ; yes, so shift coords
                mov     bx, dx                  ; no, so DX is new left coor
                jmp     StoreCoorPos

  LowToHigh:    mov     cx, bx                  ;New Right is curr Left
                mov     bx, dx                  ;New Left is DX

  StoreCoorPos: mov     [si], bx                ;Store left X Coordinate
                mov     [si+2], cx              ;Store right X Coordinate

  ExitPset:     pop     si dx cx bx ax          ;And exit
                ret


DrawEdge:       push    ax bx cx dx si

                mov     si, Offset AllFaceCoorBuf

                mov     cx, 250                 ;Try 240 scanlines
  ScanMinY1:    lodsw                           ;Get Left X coor
                or      ax, ax                  ;Is it zero?
                jnz     FoundMinY1              ;No, so try drawing this one
                add     si, 2                   ;Yes, so try next left X coor
                loop    ScanMinY1               ; Do for all possible scanlines
                jmp     ExitFill1               ;All done, so exit

  FoundMinY1:   sub     si, 2

  FillNextLine1:cmp     [word si], 0
                jz      ExitFill1
                push    si cx
                mov     bx, 250
                sub     bx, cx

                mov     cx, 2
  FillScanLine1:lodsw
                or      ax, ax
                jz      EOFScanLine1
                mov     dx, ax
                dec     dx
                mov     ax, EdgeColor
                call    PutPixel
                loop    FillScanLine1

  EOFScanLine1: pop     cx si
                add     si, 4
                loop    FillNextLine1

  ExitFill1:    pop     si dx cx bx ax
                ret


; Put pixel on screen at (dx,bx) in
; color al.

PutPixel:       push    ax bx cx dx di es

                mov     cx, ax                  ;CX = Color
                mov     ax, dx                  ;AX = X Coordinate

                shr     dx, 2                   ;DX = DX / 4
                mov     di, dx

                shl     bx, 1
                add     di, [YTable+bx]
                add     di, [DrawPage]

                mov     ah, al
                and     ah, 011b                ;AH = pixel's plane
                mov     dx, cx
                mov     cl, ah
                mov     ah, 1
                shl     ah, cl
                mov     cx, dx
                mov     al, MAP_MASK
                mov     dx, SC_INDEX
                out     dx, ax                  ;Select plane AH

                mov     ax, 0a000h
                mov     es, ax
                mov     ax, cx
                stosb                           ;Write pixel

                pop     es di dx cx bx ax
                ret


FillWithBuf:    push    ax bx cx dx si

                mov     si, Offset AllFaceCoorBuf
                cld

                mov     cx, 250
  ScanMinY:     lodsw
                or      ax, ax
                jnz     FoundMinY
                add     si, 2
                loop    ScanMinY
                jmp     ExitFill

  FoundMinY:    sub     si, 2

  FillNextLine: cmp     [word si], 0
                jz      ExitFill
                mov     bx, 250
                sub     bx, cx

                push    cx

                mov     cx, [FillColor]
                add     cx, [FillSign]

  Check1:       cmp     cx, BeginColor
                ja      Check2
                je      FillScanLine
                mov     cx, BeginColor
                neg     [FillSign]
                jmp     FillScanLine

  Check2:       cmp     cx, EndColor
                jbe     FillScanLine
                mov     cx, EndColor
                neg     [FillSign]

  FillScanLine: lodsw
                dec     ax
                mov     dx, ax
                lodsw
                or      ax, ax
                jnz     FillHorzLn
                mov     ax, cx
                call    PutPixel
                jmp     EOFScanLine
  FillHorzLn:   dec     ax
                call    DrawHorzLine

  EOFScanLine:  mov     [FillColor], cx
                pop     cx
                loop    FillNextLine

  ExitFill:     pop     si dx cx bx ax
                ret


; Draws a Horizontal Line in Tweaked Mode.
; AX = End coor.
; BX = Scanline.
; DX = Begin coor.

DrawHorzLine:   pusha

                cld

                push    dx ax
                mov     dx, SC_INDEX
                mov     al, MAP_MASK
                out     dx, al
                pop     ax dx

                shl     bx, 1
                mov     di, [YTable+bx]
                mov     bx, dx
                shr     bx, 2
                add     di, bx
                add     di, [DrawPage]          ;DI = Dest. on screen

                mov     si, dx                  ;SI = Xmin
                and     si, 3
                mov     bl, [LeftMask+si]       ;BL = LeftBits

                mov     si, ax                  ;SI = Xmax
                and     si, 3
                mov     bh, [RightMask+si]      ;BH = RightBits

                and     dx, not 011b            ;DX = Xmin & 11111100
                mov     cx, ax                  ;CX = Xmax
                sub     cx, dx                  ;CX = CX - Xmin
                shr     cx, 2                   ;CX = Width / 4
                jnz     MasksSet                ;Bits lost, so set masks
                and     bl,bh                   ;Otherwise combine masks

  MasksSet:     mov     dx, SC_INDEX +1
                mov     al, bl                  ;Set left mask
                out     dx, al
                mov     al, [byte Fillcolor]
                stosb                           ;Write left bits
                dec     cx                      ;One less to process

                js      ExitHorzLine            ;Sign set, so exit
                jz      DoRightEdge             ;Zero left, so right bits

                mov     al, 0Fh                 ;All planes for writing
                out     dx, al
                mov     al, [byte Fillcolor]
                rep     stosb                   ;Store bytes

  DoRightEdge:  mov     al, bh                  ;Set right mask
                out     dx, al
                mov     al, [byte Fillcolor]
                stosb                           ;Write right bits

  ExitHorzLine: popa
                ret

                Ends


                Segment Data Para Public 'Data' Use16

                EXTRN   ScrollText      : WORD
                EXTRN   char42          : BYTE

                INCLUDE "VECTPAL.INC"

yMinErase       DW      ClipMinY        ;Recalculated when object is drawn
yMaxErase       DW      ClipMaxY

yMintoErase     DW      ClipMinY
yMaxtoErase     DW      ClipMaxY

                PUBLIC  DrawPage
DrawPage        DW      32000
ShowPage        DW      0

                PUBLIC  YTable
Label           YTable  WORD
                off = 0
                REPT    400
                    DW      off
                    off = off + 80
                Endm

AllFaceCoorBuf  DW      2*250   dup(0)

FillColor       DW      BeginColor
FillSign        DW      FillDir

;********************************************************line variables

xdif    dw      0
ydif	dw	0
xabs	dw	0
yabs	dw	0
xsgn	dw	0
ysgn	dw	0
xtmp	dw	0
ytmp	dw	0
gcurx	dw	0
gcury   dw      0

LeftMask        DB      00fh, 00eh, 00ch, 008h
RightMask       DB      001h, 003h, 007h, 00fh

CurrPos         DW      0               ;Current Position on screen
TextPos         DW      0               ;Index into text array
TextLen         DW      0               ;Lenght of text
WaitCycles      DW      40              ;Pause after each line
FadeUp          DW      1               ;Fade status indicator

                Ends
                                END
