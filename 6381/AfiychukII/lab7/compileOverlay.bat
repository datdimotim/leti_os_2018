masm OVERLAY1.asm OVERLAY1.obj ;;
link OVERLAY1.obj ;;
exe2bin.exe OVERLAY1.exe OVERLAY1.ovl
del OVERLAY1.obj
del OVERLAY1.exe

masm OVERLAY2.asm OVERLAY2.obj ;;
link OVERLAY2.obj ;;
exe2bin.exe OVERLAY2.exe OVERLAY2.ovl
del OVERLAY2.obj
del OVERLAY2.exe