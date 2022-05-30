; /*
;  * TEXT.ASM, Scroll Text Pointer Array.
;  * ====================================
;  *
;  * Documentation file(s): None.
;  *
;  * Part of project: XTC intro.
;  *
;  * Created at: 10/02/94
;  *
;  * Maintenance log
;  * ===============
;  * Date      Ver    Action                                Programmer(s)
;  * ====================================================================
;  * 10/02/94  0.01   Source generated.               Source File Creator
;  *
;  */
                Segment Data Para Public 'Data' Use16

                PUBLIC  ScrollText

                EXTRN   char42[ 304] : BYTE
                EXTRN   char32[ 304] : BYTE
                EXTRN   char72[ 304] : BYTE
                EXTRN   char69[ 304] : BYTE
                EXTRN   char82[ 304] : BYTE
                EXTRN   char73[ 304] : BYTE
                EXTRN   char84[ 304] : BYTE
                EXTRN   char83[ 304] : BYTE
                EXTRN   char67[ 304] : BYTE
                EXTRN   char79[ 304] : BYTE
                EXTRN   char78[ 304] : BYTE
                EXTRN   char68[ 304] : BYTE
                EXTRN   char66[ 304] : BYTE
                EXTRN   char65[ 304] : BYTE
                EXTRN   char76[ 304] : BYTE
                EXTRN   char71[ 304] : BYTE
                EXTRN   char89[ 304] : BYTE
                EXTRN   char86[ 304] : BYTE
                EXTRN   char88[ 304] : BYTE
                EXTRN   char85[ 304] : BYTE
                EXTRN   char75[ 304] : BYTE
                EXTRN   char80[ 304] : BYTE
                EXTRN   char77[ 304] : BYTE
                EXTRN   char70[ 304] : BYTE
                EXTRN   char87[ 304] : BYTE

ScrollText      DW      char42
                DW      char72
                DW      char69
                DW      char82
                DW      char69
                DW      char32
                DW      char73
                DW      char84
                DW      char32
                DW      char73
                DW      char83
                DW      char42
                DW      char42
                DW      char84
                DW      char72
                DW      char69
                DW      char32
                DW      char83
                DW      char69
                DW      char67
                DW      char79
                DW      char78
                DW      char68
                DW      char42
                DW      char42
                DW      char66
                DW      char69
                DW      char84
                DW      char65
                DW      char32
                DW      char73
                DW      char78
                DW      char84
                DW      char82
                DW      char79
                DW      char42
                DW      char42
                DW      char32
                DW      char32
                DW      char42
                DW      char42
                DW      char65
                DW      char76
                DW      char76
                DW      char32
                DW      char67
                DW      char79
                DW      char68
                DW      char73
                DW      char78
                DW      char71
                DW      char32
                DW      char66
                DW      char89
                DW      char42
                DW      char42
                DW      char86
                DW      char73
                DW      char86
                DW      char73
                DW      char65
                DW      char78
                DW      char42
                DW      char42
                DW      char32
                DW      char32
                DW      char42
                DW      char42
                DW      char84
                DW      char69
                DW      char88
                DW      char84
                DW      char32
                DW      char83
                DW      char72
                DW      char79
                DW      char85
                DW      char76
                DW      char68
                DW      char32
                DW      char66
                DW      char69
                DW      char42
                DW      char42
                DW      char76
                DW      char73
                DW      char75
                DW      char69
                DW      char32
                DW      char84
                DW      char72
                DW      char73
                DW      char83
                DW      char42
                DW      char42
                DW      char32
                DW      char32
                DW      char42
                DW      char42
                DW      char80
                DW      char69
                DW      char78
                DW      char84
                DW      char65
                DW      char71
                DW      char82
                DW      char65
                DW      char77
                DW      char42
                DW      char42
                DW      char73
                DW      char83
                DW      char32
                DW      char80
                DW      char82
                DW      char79
                DW      char85
                DW      char68
                DW      char32
                DW      char84
                DW      char79
                DW      char42
                DW      char42
                DW      char80
                DW      char82
                DW      char69
                DW      char83
                DW      char69
                DW      char78
                DW      char84
                DW      char42
                DW      char42
                DW      char76
                DW      char65
                DW      char82
                DW      char82
                DW      char89
                DW      char32
                DW      char88
                DW      char88
                DW      char73
                DW      char42
                DW      char42
                DW      char70
                DW      char82
                DW      char79
                DW      char77
                DW      char32
                DW      char83
                DW      char73
                DW      char69
                DW      char82
                DW      char82
                DW      char65
                DW      char42
                DW      char42
                DW      char32
                DW      char32
                DW      char42
                DW      char42
                DW      char77
                DW      char83
                DW      char71
                DW      char32
                DW      char84
                DW      char79
                DW      char32
                DW      char69
                DW      char82
                DW      char73
                DW      char75
                DW      char42
                DW      char42
                DW      char67
                DW      char65
                DW      char76
                DW      char76
                DW      char32
                DW      char77
                DW      char69
                DW      char32
                DW      char70
                DW      char79
                DW      char82
                DW      char32
                DW      char73
                DW      char78
                DW      char70
                DW      char79
                DW      char42
                DW      char42
                DW      char79
                DW      char78
                DW      char32
                DW      char72
                DW      char79
                DW      char87
                DW      char32
                DW      char84
                DW      char72
                DW      char73
                DW      char83
                DW      char32
                DW      char87
                DW      char65
                DW      char83
                DW      char42
                DW      char42
                DW      char67
                DW      char79
                DW      char68
                DW      char69
                DW      char68
                DW      char32
                DW      char65
                DW      char78
                DW      char68
                DW      char32
                DW      char70
                DW      char79
                DW      char82
                DW      char42
                DW      char42
                DW      char84
                DW      char72
                DW      char79
                DW      char83
                DW      char69
                DW      char32
                DW      char82
                DW      char79
                DW      char84
                DW      char65
                DW      char84
                DW      char73
                DW      char79
                DW      char78
                DW      char42
                DW      char42
                DW      char65
                DW      char78
                DW      char68
                DW      char32
                DW      char70
                DW      char65
                DW      char83
                DW      char84
                DW      char32
                DW      char76
                DW      char73
                DW      char78
                DW      char69
                DW      char42
                DW      char42
                DW      char82
                DW      char79
                DW      char85
                DW      char84
                DW      char73
                DW      char78
                DW      char69
                DW      char83
                DW      char42
                DW      char42
                DW      char32
                DW      char32
                DW      char42
                DW      char42
                DW      char84
                DW      char72
                DW      char65
                DW      char78
                DW      char75
                DW      char32
                DW      char89
                DW      char79
                DW      char85
                DW      char42
                DW      char42
                DW      char32
                DW      char32
                DW      char42
                DW      0

                Ends
                                END
