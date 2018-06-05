masm lab2.asm lab2.obj ;;
link lab2.obj ;;
exe2bin lab2.exe lr2.com

del lab2.exe
del lab2.obj

masm lab6.asm lr6.obj ;;

link lr6.obj ;;

del lr6.obj
