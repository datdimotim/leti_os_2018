tasm.exe 6.asm 
tlink.exe 6.obj
del 6.MAP
del 6.OBJ

tasm.exe ovl1.asm
tlink.exe ovl1.obj
exe2bin ovl1.exe 1.ovl
del ovl1.MAP
del ovl1.OBJ
del ovl1.exe

tasm.exe ovl2.asm
tlink.exe ovl2.obj
exe2bin ovl2.exe 2.ovl
del ovl2.MAP
del ovl2.OBJ
del ovl2.exe

6.exe