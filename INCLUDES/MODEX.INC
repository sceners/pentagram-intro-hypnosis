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

                Segment Code Para Public 'Code' Use16

                EXTRN   Set320x400Mode  : NEAR
                EXTRN   WaitRetrace     : NEAR
                EXTRN   WaitPulse       : NEAR
                EXTRN   PanScreen       : NEAR
                EXTRN   SplitScreen     : NEAR
                EXTRN   ShowImage       : NEAR
                EXTRN   GetOldState     : NEAR
                EXTRN   SetOldState     : NEAR
                EXTRN   WipeScreen      : NEAR
                EXTRN   WipeScrPalette  : NEAR
                EXTRN   WipePalette     : NEAR
                EXTRN   CopyPalette     : NEAR
                EXTRN   SetPalette      : NEAR
                EXTRN   GetPalette      : NEAR
                EXTRN   FadeScreenDn    : NEAR
                EXTRN   FadePalDn       : NEAR
                EXTRN   FadeScreenUp    : NEAR
                EXTRN   FadePalUp       : NEAR
                EXTRN   FadePalToPal    : NEAR
                EXTRN   DoNothing       : NEAR
                EXTRN   CopyLine        : NEAR

                Ends

                Segment Data Para Public 'Data' Use16

                EXTRN   RasterTime      : BYTE
                EXTRN   TmpPalette      : BYTE
                EXTRN   ScreenPalette   : BYTE

                Ends
