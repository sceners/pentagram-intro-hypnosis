;**********************************************************************;
; VECTOR.ASM                                                           ;
;                                                                      ;
; This source file contains the actual engine and the main program of  ;
; this little vector demo.                                             ;
;**********************************************************************;

                Ideal                           ; Enable TASM Ideal Mode

		p386				; Enable 80386 Code
		
		DOSSeg				; Enable DOS Segmentation
						; Segment ordering:
						; - Code
						; - Data
						; - All other segments
						; - Stack

                INCLUDE "modex.inc"             ;ModeX constants & routines
                INCLUDE "draw.inc"              ;Screen related funcs
                INCLUDE "image.inc"

                EXTRN   PlayAdlib       :       FAR
                EXTRN   StopAdlib       :       FAR
                EXTRN   MusicData       :       FAR


SizeOfMsg       EQU     80*10           ;Size of End Message
SPACE           EQU     39h             ;Exit Key Code

Depth           EQU     10000           ;Object is removed into Depth when
DepthSpeed      EQU     200             ;CycleTime=0, with DepthSpeed

Struc           Object
  NumFaces      DW      0
  NumVerts      DW      0
  VertTable     DW      0
  FaceTable     DW      0
                Ends

MaxFaces        EQU      15             ; For small objects, this is enough
MaxVerts        EQU      20             ; space to store the object info...
MaxVertsInFace  EQU       5

                Segment Code Para Public 'Code' Use16
		Assume cs:Code,ds:Data,ss:ProgramStack

Main:           call    InstallKeyb             ;Install Keyboard Int.

                mov     ax, Data
                mov     ds, ax
                mov     [PSPSegment], es
                mov     ax, sp
                add     ax, 4+15                ; Paragraph Align
                mov     cl, 4
                shr     ax, cl                  ; Could be shr ax, 4 but we
                mov     bx, ss                  ; haven't tested the CPU Type
                add     bx, ax
                mov     ax, es
                sub     bx, ax
                mov     ah, 4Ah                 ; Adjust Memory Block Size
                int     21h                     ; must be done before ES
                cld                             ; is screwed!

                mov     [RasterTime], 0

                mov     ax, 1A00h               ;Get display type
                int     10h                     
                cmp     al, 1Ah                 ;VGA card found
                jne     NoVga                   ;Yes, Proceed
                cmp     bl, 07                  ;VGA mono active ?
                je      OkToProceed
                cmp     bl, 08                  ;VGA color active ?
                je      OkToProceed

  NoVga:        lea     dx, [NoVgaMsg]          ;No, Display 'No VGA' Message
                mov     ah, 9
                int     21h
                mov     al, 1                   ;Use exitcode 1
                jmp     ExitMain                ;Exit the demo

  OkToProceed:  call    GetOldState             ;Store current Video State

                mov     ah, 03h                 ;Get Cursor
                int     10h
                mov     [Cursor], cx

                mov     ah, 01h                 ;Disable Cursor
                mov     ch, 9
                mov     cl, 0
                int     10h

                mov     ax, SEG MusicData
                mov     es, ax                  ;ES = Music Data
                mov     si, OFFSET MusicData
                call    PlayAdlib               ;Start playing Adlib music

                call    PrepareScreen           ;Initialize the video display

                mov     ax, SCREEN_SEG
                mov     es, ax                  ;ES = ALWAYS Video Segment

                call    Introduction
                call    PrepareForDemo

                mov     [cs:Keyhit], 0

  MainLoop:     call    UpdateScript            ;Update script info
                call    Perspective             ;Calculated rotated vertices
                call    BuildFaceList           ;Build list of face coords
                call    CalcAverageZ
                call    SortFaces       ;Een van deze MOET traag zijn
                call    DrawObject              ;Time to show the *f* object
                call    MirrorObject    ;Neemt veel tijd
                call    UpdateWriter    ;Neemt weinig tijd
                call    FlipPages               ;DrawPage<->ShowPage
                call    EraseObject             ;Erase previous object image
                call    AddSteps

                mov     ax, [BounceX]
                add     [ViewerX], ax
                cmp     [ViewerX], 40
                jb      ChangeX
                cmp     [ViewerX], 280
                ja      ChangeX
                jmp     DoY
  ChangeX:      neg     [BounceX]

  DoY:          mov     ax, [BounceY]
                add     [ViewerY], ax
                cmp     [ViewerY],  20
                jb      ChangeY
                cmp     [ViewerY], 300
                ja      ChangeY
                jmp     ContVex
  ChangeY:      neg     [BounceY]

  ContVex:      cmp     [cs:KeyHit], 1          ;Check Keyb. flag
                jnz     MainLoop                ;Hotkey not pressed,
                                                ;so do again

                mov     di, Offset TmpPalette
                call    WipePalette             ;Wipe Palette
                mov     si, di

  FadeDnLoop:   call    UpdateScript            ;Update script info
                call    Perspective             ;Calculated rotated vertices
                call    BuildFaceList           ;Build list of face coords
                call    CalcAverageZ
                call    SortFaces
                call    DrawObject              ;Time to show the *f* object
                call    MirrorObject
                call    FlipPages               ;DrawPage<->ShowPage
                call    EraseObject             ;Erase previous object image
                call    AddSteps

                push    si
                call    FadePalToPal            ;ScreenPal to ZeroPal
                pop     si

                or      al, al
                jnz     FadeDnLoop

                call    SetOldState             ;Set old Video State

                mov     ah, 01h                 ;Disable Cursor
                mov     ch, 9
                mov     cl, 0
                int     10h

                call    PanDosScreen            ;Pan DOS screen with EndMsg

                call    StopAdlib               ;Stop playing Adlib music

                mov     ah, 02h                 ;Function Set Cursor Position
                xor     bx, bx                  ;Page 0
                xor     dl, dl                  ;Column 0
                mov     dh, (SizeOfMsg / 80)    ;Line After ANSI
                int     10h                     ;Video Bios Call

                mov     ah, 01h                 ;Enable Cursor
                mov     cx, [Cursor]
                int     10h

                xor     al, al                  ;Use exitcode 0

  ExitMain:     call    RemoveKeyb              ;Remove Keyboard Interrupt

                mov     ah, 4Ch                 ;Exit the program
                int     21h


PrepareScreen:  lea     dx, [StartMsg]          ;Display Start Message
                mov     ah, 9
                int     21h

                call    FadeScreenDn            ;Fade DOS screen to black

                mov     ax, 0B800h              ;CGA+ Color Segment
                mov     es, ax
                xor     di, di

                mov     al, 32                  ;Character : Space
                mov     ah, 07                  ;Color     : Lightgray
                mov     cx, 4000                ;Two entire pages in WORDS
                rep     stosw                   ;Clear pages

                call    Set320x400Mode          ;Switch to Graphics Mode
                ret


PanDosScreen:   call    WaitRetrace

                mov     bx, 12*80
                mov     dx, CRTC_INDEX          ;Pannen??
                mov     al, 0Ch                 ;Subfunction 0Ch??
                mov     ah, bh
                out     dx, ax
                inc     al
                mov     ah, bl
                out     dx, ax

                call    WaitRetrace

                mov     ax, SEG EndMsg
                mov     ds, ax
                mov     si, OFFSET EndMsg       ;Set SI to EndMsg Offset
        
                mov     ax, 0B800h              ;CGA+ Color Segment
                mov     es, ax
                xor     di, di

                mov     al, 32                  ;Clear with SPACE
                mov     ah, 07                  ;Color Light Gray
                mov     cx, 1000                ;Entire Screen in WORDS
                rep     stosw

                xor     di, di
                mov     cx, (SizeOfMsg / 2)     ;Size of Msg in DWORDS
                rep     movsd

                call    WaitRetrace

                mov     bp, 12*80
                mov     cx, 13                  ;PixelPan the Screen 23 Lines

  Data2:        push    cx
                mov     bx, bp

                mov     dx, CRTC_INDEX          ;Pannen??
                mov     al, 0Ch                 ;Subfunction 0Ch??
                mov     ah, bh
                out     dx, ax
                inc     al
                mov     ah, bl
                out     dx, ax
                sub     bp, 80

                mov     bl, 15
                mov     cx, 8
  Data1:        call    WaitRetrace
                mov     dx, CRTC_INDEX          ;Pannen??
                mov     al, 08h                 ;Subfunction 08h??
                mov     ah, bl
                out     dx, ax
                sub     bl, 2
                loop    Data1
                pop     cx
                loop    Data2
                ret


UpdateScript:   push    ax bx

                dec     [UpdCycleCount]         ;Decrease update cycle count
                jnz     ExitUpdScript           ; if not zero, just exit

                mov     [MaxViewerZ], Depth
                cmp     [ViewerZ], Depth
                je      NextScript

                add     [ViewerZ], DepthSpeed
                inc     [UpdCycleCount]         ;Increase update cycle count
                jmp     ExitUpdScript

  NextScript:   mov     bx, [ScriptIndex]
                mov     ax, [Script+bx]         ;Get object def ptr
                cmp     ax, -1                  ;End of script
                jne     StoreNewInfo            ; no, so store

                xor     bx, bx                  ; yes, so reset ScriptIndex
                mov     [ScriptIndex], bx       ; and load

                mov     ax, [Script+bx]         ; first object into AX

  StoreNewInfo: mov     [CurrObject], ax        ; and store it

                mov     ax, [Script+bx+2]       ;Get cycle count
                mov     [UpdCycleCount], ax     ; and store it

                mov     ax, [Script+bx+4]       ;Get MinViewerZ
                mov     [MinViewerZ], ax        ; and store it

                mov     ax, [Script+bx+6]       ;Get MaxViewerZ
                mov     [MaxViewerZ], ax        ; and store it

                add     bx, 8                   ;Move to next entry
                mov     [ScriptIndex], bx       ; and store index

  ExitUpdScript:pop     bx ax
                ret


Macro           @DoStep SinVar, CosVar, Step
                LOCAL   AddSinStep, ExitDoStep

                mov     ax, [Step]
                shl     ax, 1
                add     [CosVar], ax
                cmp     [CosVar], OFFSET CosineTable+(360*2)
                jb      AddSinStep

                mov     [CosVar], OFFSET CosineTable

  AddSinStep:   add     [SinVar], ax
                cmp     [SinVar], OFFSET SineTable+(360*2)
                jb      ExitDoStep

                mov     [SinVar], OFFSET SineTable
  ExitDoStep:
                Endm


AddSteps:       push    ax

                @DoStep XSin, XCos, XStep
                @DoStep YSin, YCos, YStep
                @DoStep ZSin, ZCos, ZStep

                mov     ax, [DepthStep]
                add     [ViewerZ], ax

                mov     ax, [MinViewerZ]
                cmp     [ViewerZ], ax
                jae     ChkDown

                mov     [ViewerZ], ax
                neg     [DepthStep]

  ChkDown:      mov     ax, [MaxViewerZ]
                cmp     [ViewerZ], ax
                jb      ExitAddSteps

                mov     [ViewerZ], ax
                neg     [DepthStep]

  ExitAddSteps: pop     ax
                ret

; This MACRO multiplies AX and CX (signed). Because the value
; in CX proceeds from the sine- or cosinetable, the result is
; divided by 2048 (the tables consist of sine values multiplied
; by 2048). Only register DX is screwed!

MACRO           FixedMul
                imul    cx                      ;DX:AX = AX * CX
                shr     ax, 11                  ;AX = AX / 2048
                shl     dx, 5                   ;DX = DX * 32
                add     ax, dx                  ;AX = AX + DX
                ENDM

; Perspective:  This is the actual engine. It converts the XYZ
;               vertices of the object to Screen Coordinates,
;               after having rotated the XYZ Vertices.

Perspective:    pusha

                mov     di, Offset ScreenCoords ;DS:DI = Buf for screen coords
                mov     bx, [CurrObject]        ;DS:SI = Object XYZ Vertices
                mov     si, [bx+Object.VertTable]
                mov     cx, [bx+Object.NumVerts] ;Get number of XYZ Vertices
                xor     bp, bp

  ConvertVertex:push    cx                      ;Save Vertex Count
                ;-------------  Rotate Y Coord  -------------------
                mov     ax, [si+2]              ;AX = Y Coord
                mov     bx, [XCos]
                mov     cx, [bx]                ;CX = COS value
                FixedMul                        ;AX = AX * CX
                push    ax                      ;Save result

                mov     ax, [si+4]              ;AX = Z Coord
                mov     bx, [XSin]
                mov     cx, [bx]                ;CX = SIN value
                FixedMul                        ;AX = AX * CX

                pop     bx                      ;Restore prev result in BX
                add     ax, bx                  ;AX = Both results Added
                add     ax, [ObjectY]           ;AX = Absolute Y Coord again!
                mov     [RotatedY], ax          ; Store as Rotated Y Coord

                ;-------------  Rotate Z Coord  -------------------
                mov     ax, [si+4]              ;AX = Z Coord
                mov     bx, [XCos]
                mov     cx, [bx]                ;CX = COS value
                FixedMul                        ;AX = AX * CX
                push    ax                      ;Save result

                mov     ax, [si+2]              ;AX = Y Coord
                mov     bx, [XSin]
                mov     cx, [bx]                ;CX = SIN value
                FixedMul                        ;AX = AX * CX

                pop     bx                      ;Restore prev result in BX
                sub     bx, ax                  ;BX = Result1 - Result2
                add     bx, [ObjectZ]           ;BX = Absolute Z Coord again!
                mov     [RotatedZ], bx          ; Store as rotated Z Coord

                ;-------------  Rotate X Coord  -------------------
                mov     ax, [si]                ;AX = X Coord
                mov     bx, [YCos]
                mov     cx, [bx]                ;CX = COS value
                FixedMul                        ;AX = AX * CX
                push    ax                      ;Save result

                mov     ax, [RotatedZ]          ;AX = Rotated (Abs) Z Coord
                sub     ax, [ObjectZ]           ;AX = Relative Rotated Z Coord
                mov     bx, [YSin]
                mov     cx, [bx]                ;CX = SIN value
                FixedMul                        ;CX = AX * CX

                pop     bx                      ;Restore prev result in BX
                sub     bx, ax                  ;BX = Result1 - Result2
                add     bx, [ObjectX]           ;BX = Absolute X Coord again!
                mov     [RotatedX], bx          ; Store as rotated X Coord

                mov     ax, [RotatedZ]
                sub     ax, [ObjectZ]
                mov     bx, [YCos]
                mov     cx, [bx]
                FixedMul
                push    ax
                mov     ax, [si]
                mov     bx, [YSin]
                mov     cx, [bx]
                FixedMul
                pop     bx
                add     ax, bx
                mov     [ds:RotatedZTable+bp], ax
                add     bp, 2
                add     ax, [ObjectZ]
                mov     [RotatedZ], ax          ; -- store Z coord --

                mov     ax, [RotatedX]
                mov     [RotatedB], ax
                sub     ax, [ObjectX]
                mov     bx, [ZCos]
                mov     cx, [bx]
                FixedMul
                push    ax
                mov     ax, [RotatedY]
                sub     ax, [ObjectY]
                mov     bx, [ZSin]
                mov     cx, [bx]
                FixedMul
                pop     bx
                add     ax, bx
                add     ax, [ObjectX]
                mov     [RotatedX], ax         ; -- store X coord --

                mov     ax, [RotatedY]
                sub     ax, [ObjectY]
                mov     bx, [ZCos]
                mov     cx, [bx]
                FixedMul
                push    ax
                mov     ax, [RotatedB]
                sub     ax, [ObjectX]
                mov     bx, [ZSin]
                mov     cx, [bx]
                FixedMul
                pop     bx
                sub     bx, ax
                add     bx, [ObjectY]
                mov     [RotatedY], bx         ; -- store Y coord --

                ; ---- WORLDSPACE TO SCREENSPACE ----

                mov     ax, [ViewerX]
                sub     ax, [RotatedX]
                mov     cx, 200
                imul    cx

                mov     cx, [RotatedZ]
                sub     cx, [ViewerZ]
                idiv    cx
                add     ax, [ViewerX]
                mov     [di], ax

                mov     ax, [ViewerY]
                sub     ax, [RotatedY]
                mov     bx, 200
                imul    bx
                idiv    cx
                add     ax, [ViewerY]
                mov     [di+2], ax

                add     di, 4
                add     si, 6
                pop     cx
                loop    ConvertVertex

                popa
                ret

; BuildFaceList: This routine builds a list of screen coor-
;                dinates for all faces of the object. It also
;                builds a table called FaceIndices, which con-
;                tains offsets to the coord list for every object.

BuildFaceList:  push    ax bx cx si di es bp

                mov     ax, ds
                mov     es, ax                  ;ES:DI = Ptr to face coordinates
                mov     di, Offset FaceCoordList;        list.
                mov     bx, [CurrObject]
                mov     si, [bx+Object.FaceTable] ; DS:SI = Ptr to face defs
                xor     bp, bp                  ;   BP = Index into FaceIndices

                mov     cx, [bx+Object.NumFaces];Get number of faces

  ProcessFace:  push    cx                      ;Save face count
                mov     [ds:FaceIndices+bp], di ;Store offset of coor list of
                add     bp, 2                   ; face being processed

                lodsb                           ;Get number of coordinates
                xor     ah, ah                  ; from FaceDefinitions
                stosw                           ;Store in FaceCoordList
                mov     cx, ax                  ; and move into CX

  ProcFaceCoor: lodsb                           ;Get number of vertex
                xor     ah, ah                  ; into AX
                dec     ax                      ;Make it index into ScreenCoords
                shl     ax, 2                   ; (2 words per entry)
                mov     bx, ax                  ;Into BX (can't index with AX)
                mov     ax, [ScreenCoords+bx]   ;Get Screen X Coord
                stosw                           ; Store in FaceCoordList
                mov     ax, [ScreenCoords+bx+2] ;Get Screen Y Coord
                stosw                           ; Store in FaceCoordList
                loop    ProcFaceCoor            ;Do for all coords in face

                pop     cx                      ;Restore face count
                loop    ProcessFace             ; Do for all faces in object
                
                pop     bp es di si cx bx ax
                ret


CalcAverageZ:   pusha

                mov     bx, [CurrObject]
                mov     si, [bx+Object.FaceTable]
                mov     cx, [bx+Object.NumFaces]
                xor     bp, bp

  FaceLoopZ:    push    cx
                lodsb
                xor     ah, ah
                mov     cx, ax                  ;Num. verts in face
                dec     cx
                mov     [TempAvgZ], 0

                push    cx
  VertLoopZ:    lodsb
                dec     al
                xor     ah, ah
                mov     bx, ax
                shl     bx, 1
                mov     ax, [RotatedZTable+bx]
                add     [TempAvgZ], ax
                loop    VertLoopZ
                pop     cx
                inc     si

                mov     ax, [TempAvgZ]
                cwd
                idiv    cx
                mov     [ds:AvgZTable+bp], ax
                add     bp, 2

                pop     cx
                loop    FaceLoopZ

                popa
                ret

; SortFaces: Sort Faces on the basis of their average Z coordinate.
;
; In:   None.
; Out:  None.

SortFaces:      pusha

                mov     bx, [CurrObject]
                mov     si, Offset AvgZTable
                mov     di, Offset FaceIndices
                mov     cx, [bx+Object.NumFaces]
                mov     dx, cx
                dec     dx

  SortFaceLoop: push    cx si di

                mov     cx, dx
  SortZLoop:    lodsw                   ;SI and DI are parallel
                add     di, 2
                cmp     [si], ax        ;Current < Read, so do nothing
                jge     NextAvgZ

                mov     bx, [si]        ;Swap AverageZ
                mov     [si], ax
                mov     [si-2], bx

                mov     ax, [di-2]      ;Swap FaceIndices
                mov     bx, [di]
                mov     [di], ax
                mov     [di-2], bx

  NextAvgZ:     loop    SortZLoop

                pop     di si cx
                loop    SortFaceLoop

                popa
                ret


InstallKeyb:    push    ax es

                xor     ax, ax
                mov     es, ax

                cli
                lea     ax, [NewKeybInt]
                xchg    [es:24h], ax    ;Swap keyboard vector offset
                mov     [Word Low OldKeybInt], ax
                mov     ax, cs
                xchg    [es:26h], ax    ;Swap keyboard vector segment
                mov     [Word High OldKeybInt], ax
                sti

                pop     es ax
                ret


RemoveKeyb:     push    ax es

                xor     ax, ax
                mov     es, ax

                cli
                mov     ax, [Word Low OldKeybInt]
                xchg    [es:24h], ax    ;Swap keyboard vector offset
                mov     ax, [Word High OldKeybInt]
                xchg    [es:26h], ax    ;Swap keyboard vector segment
                sti

                pop     es ax
                ret


KeyHit          DB      0
OldKeybInt      DD      0


NewKeybInt:     push    ax

                in      al, 60h
                cmp     al, SPACE
                jne     ExitInt

                mov     [cs:KeyHit], 1

  ExitInt:      mov     al, 20h         ;Remove these to call OldKeybInt
                out     20h, al

                pop     ax
                                        ;jmp    [OldKeybInt]
                iret

                Ends

;******************************************************************************

                Segment Data Para Public 'Data' Use16

Cursor          DW      0

PSPSegment      DW      0

NoVgaMsg        DB      'Unable to detect a VGA Card...'
                DB      13,10,'$'

StartMsg        DB      '旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커'
                DB      '낡같같같같같� S T A R T I N G 같� P E N T A G R A M 같� I N T R O 같같같같같같개'
                DB      '읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸'
                DB      '$'

                INCLUDE "ENDMSG.ASM"

;***********************************************************************;
;                         OBJECT ROTATION VARIABLES                     ;
;***********************************************************************;

ViewerX         DW      160                     ;XYZ Position of Viewer
ViewerY         DW      202
ViewerZ         DW      Depth                   ;See UpdateScript, this is
                                                ; the initialize value
ObjectX         DW      160                     ;XYZ Rotation point
ObjectY         DW      198
ObjectZ         DW      1

RotatedX        DW      0                       ;Last XYZ Vertice rotated
RotatedY        DW      0                       ;  -Tmp vars for Perspective-
RotatedZ        DW      0

RotatedB        DW      0                       ;  -Tmp var for Perspective-

XCos            DW      CosineTable             ;Ptrs to pos in COS/SIN tables
XSin            DW      SineTable
XStep           DW      4

YCos            DW      CosineTable
YSin            DW      SineTable
YStep           DW      2

ZCos            DW      CosineTable
ZSin            DW      SineTable
ZStep           DW      3

MinViewerZ      DW      280
MaxViewerZ      DW      1200

DepthStep       DW      -20

BounceX         DW      2
BounceY         DW      4

;***********************************************************************;
;                         OBJECT DEFINITION VARIABLES                   ;
;***********************************************************************;

                PUBLIC  CurrObject
CurrObject      DW      0

UpdCycleCount   DW      1
ScriptIndex     DW      0

; This is the script for all Vector Objects.
;
;                     ------------------------------------------
; Currently Settable: |   Object   | Cycles | MinVwrZ | MaxVwZ |
;                     ------------------------------------------
Script          DW      PtgObject,   20000,     240,    2000
                DW      -1

                PUBLIC  ScreenCoords
ScreenCoords    DW      2*MaxVerts      dup (0) ;XY screen coords of object
                                                ;-Filled by Perspective-

                PUBLIC  FaceIndices
FaceIndices     DW      MaxFaces        dup (0) ;Offsets to face coord list
                                                ;-Filled by BuildFaceList-

                PUBLIC  FaceCoordList           ;XY screen coords of every face
FaceCoordList   DW      MaxFaces*MaxVertsInFace*2       dup (0)
                                                ;-Filled by BuildFaceList-

RotatedZTable   DW      MaxVerts        dup (0) ;Rotated Z Coords of Object
                                                ;-Filled by Perspective-

AvgZTable       DW      MaxFaces        dup (0) ;Average Z coords of Faces
                                                ;-Filled by CalcAverageZ-
TempAvgZ        DW      0

                INCLUDE "objects.asm"

;***********************************************************************;
;                         MISCELANEOUS TABLES                           ;
;***********************************************************************;

                INCLUDE "SinTable.inc"          ;Sine   Table
                INCLUDE "CosTable.inc"          ;CoSine Table

                Ends

                Segment ProgramStack Para Stack 'Stack' Use16
                dw 0100h Dup (0)
                Ends
                                END     Main
