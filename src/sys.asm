
extern

        #inc_h "memory"
pgalloc
        #syscall lmem,pgalloc_
pgfree
        #syscall lmem,pgfree_
memcpy
        #syscall lmem,memcpy_


        #inc_h "input"
initmouse
        #syscall linp,initmouse_
killmouse
        #syscall linp,killmouse_
hidemouse
        #syscall linp,hidemouse_


        #inc_h "screen"
layerpush
        #syscall lscr,layerpush_
markredraw
        #syscall lscr,markredraw_
ctx2scr
        #syscall lscr,ctx2scr_


        #inc_h "service"
quitapp
        #syscall lser,quitapp_
loadutil
        #syscall lser,loadutil_
loadreloc
        #syscall lser,loadreloc_
loadlib
        #syscall lser,loadlib_

        #inc_h "toolkit"
classptr
        #syscall ltkt,classptr_
tknew
        #syscall ltkt,tknew_
appendto
        #syscall ltkt,appendto_
settkenv
        #syscall ltkt,settkenv_
getmethod
        #syscall ltkt,getmethod_
tkupdate
        #syscall ltkt,tkupdate_
tkmouse
        #syscall ltkt,tkmouse_
ptrthis
        #syscall ltkt,ptrthis_
tkkcmd
        #syscall ltkt,tkkcmd_
tkkprnt
        #syscall ltkt,tkkprnt_

        #inc_h "file"

fopen
        #syscall lfil,fopen_
fread
        #syscall lfil,fread_
fwrite
        #syscall lfil,fwrite_
fclose
        #syscall lfil,fclose_


