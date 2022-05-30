;
;               Object <Num.Faces, Num.Verts, Ptr.to.Verts, Ptr.to.Faces>
; Y     Z
; |    /
; |  /
; |/____X       ObjectVerts    X, Y, Z
;

PtgObject       Object <15,20,PtgVerts,PtgFaceDefs>

PtgVerts        DW       -100,    0,   10
                DW        -88,    4,   10
                DW        100,    0,   10
                DW         88,    4,   10
                DW        -75,  100,   10
                DW        -68,   92,   10
                DW          0,  -80,   10
                DW          0,  -74,   10
                DW         75,  100,   10
                DW         68,   92,   10
                DW       -100,    0,  -10
                DW        -88,    4,  -10
                DW        100,    0,  -10
                DW         88,    4,  -10
                DW        -75,  100,  -10
                DW        -68,   92,  -10
                DW          0,  -80,  -10
                DW          0,  -74,  -10
                DW         75,  100,  -10
                DW         68,   92,  -10

PtgFaceDefs     DB          5,    1,    3,    4,    2,    1     ;Front Ptg
                DB          5,    3,    5,    6,    4,    3     ;Faces
                DB          5,    5,    7,    8,    6,    5
                DB          5,    7,    9,   10,    8,    7
                DB          5,    9,    1,    2,   10,    9
                DB          5,   11,   13,   14,   12,   11     ;Back Prg
                DB          5,   13,   15,   16,   14,   13     ;Faces
                DB          5,   15,   17,   18,   16,   15
                DB          5,   17,   19,   20,   18,   17
                DB          5,   19,   11,   12,   20,   19
                DB          5,    1,   11,   13,    3,    1
                DB          5,    3,   13,   15,    5,    3
                DB          5,    5,   15,   17,    7,    5
                DB          5,    7,   17,   19,    9,    7
                DB          5,    9,   19,   11,    1,    9
