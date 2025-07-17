;
; textview+
;
; a C64OS application to view
; text files in a full screen
; interface
;
; author(s):
; 
; paul hocker (paul@spocker.net)
;
; see readme for more information
;

        *= appbase

; ------------------------------------
; application jump table

        .word a_init
        .word a_mcmd
        .word a_quit
        .word raw_rts
        .word a_thaw

; ------------------------------------
layer
        .word l_update
        .word l_mouse
        .word l_cmd
        .word l_prnt
        .byte 0
drawctx
        .word scrbuf
        .word colbuf
        .byte screen_cols
        .byte screen_cols
        .byte screen_rows
        .word 0
        .word 0
tkenv
        .word drawctx ;draw contex
        .byte 0       ;memory pool
        .byte 1       ;dirty
        .byte 0       ;scrlayer 0
        .word 0       ;root view
        .word 0       ;1st key view
        .word 0       ;1st mus view
        .word 0       ;clikmus view
        .byte 0       ;ctx2scr ppsx
        .byte 0       ;ctx2scr posy

; ------------------------------------
; user interface space

views
        .word 0 ;root

widgets
        .word 0,0

tkpath
        .null "tk"

classes
        .word 0

csizes
        .byte 8
        
cnames  #strxyget
        .null "tktext.r"

ui_s
        #strxyget 

        .null "Open"

; ------------------------------------
; pointer to the location of
; text for the tktext widget 
txtbuf
        .byte 0,0

; open file reference
frefpg
        .byte 0

; flag to tell us if a file
; has already been loaded
pload
        .byte 0

; where is the starting page of
; memory where we loaded the last
; files data
ppage
        .byte 0

; how many pages were allocated for 
; the last file loaded
psize
        .byte 0

; used as a flag to tell us when the
; open button was pressed on the open
; file utility so that when we get the
; next free memory callback we can 
; use it
popen
        .byte 0

; flag to determine current state
; of word wrap, the default is
; 0 = no wrap

pwrap
        .byte mnu_sel

; flag to determine the current
; state of viewing text in ascii
; 0 = not ascii

pascii
        .byte 0 

; flag to detemine the current
; state of viewing the text in petscii
; 0 = not petscii

ppetscii
        .byte mnu_sel 

; work pointer
ptr     = $fb;$fc

; ------------------------------------
a_init
        .block

        #ldxy extern
        jsr initextern

; config root draw context
; 1K color memory and 1K text memory

a_init1
        lda #mapapp
        ldx #4
        jsr pgalloc
        sty drawctx+d_coloro+1

        lda #mapapp
        ldx #4
        jsr pgalloc
        sty drawctx+d_origin+1

; allocating memory for
; the toolkit widgets
;
; TKVIEW      39
; TKSCROLL    46
; TKSBAR      65
; TKSBAR      65
; TKTEXT      52
;
;            267
;
; OBJS 3*5    15
;
; TOTAL      282
;
; 282 % 256 = 2 page

        lda #mapapp
        ldx #2
        jsr pgalloc
        sty tkenv+te_mpool

; load shared libs

        ldx #"p"
        ldy #"a"
        lda #2
        jsr loadlib

        sta setname+2
        sta pathadd+2
        sta gopath+2

; load TKText

        ldx #tkview
        jsr classptr

        lda #0
        jsr loadclass
        #storeset classes,0

; creating view

        #ldxy tkenv
        jsr settkenv

        ldx #tkview
        jsr classptr
        jsr tknew

        #stxy tkenv+te_rview

        ldy #init_
        jsr getmethod
        jsr sysjmp

        #setflag this,dflags,df_opaqu

; create the tkscroll

        ldx #tkscroll
        jsr classptr
        jsr tknew

        #storeset widgets,0

        ldy #init_
        jsr getmethod
        jsr sysjmp

        #setobj8 this,offtop,1
        #setobj8 this,offbot,1
        #setobj8 this,offleft,0
        #setobj8 this,offrght,0

        #rdxy tkenv+te_rview
        jsr appendto

; create the tktext

        #storeget classes,0
        jsr tknew

        #storeset widgets,1

        ldy #init_ 
        jsr getmethod
        jsr sysjmp

        #setobj8 this,width,22 
        #setobj16 this,tonclick,onclick

        ; use default open msg to
        ; start with

        #ldxy welcome
        #stxy txtbuf

        ldy #setstrp_ 
        jsr getmethod
        ldx txtbuf
        ldy txtbuf+1
        jsr sysjmp 

        ; make tktext first key
        ; calling

        ldy #setfirst_
        jsr getmethod
        sec 
        jsr sysjmp
        
        ; set tktext as tkscroll
        ; content

        #storeget widgets,0
        jsr ptrthis

        ldy #setctnt_
        jsr getmethod

        #storeget widgets,1
        jsr sysjmp

        ldy #setbar_ 
        jsr getmethod

        ldy #1 ; enable vert bar
        ldx #0 ; enable horiz bar
        jsr sysjmp

        ; default is to show sample

        #ldxy welcome
        #stxy txtbuf

        ; move appfileref
        ; to local storage

        lda appfileref+1
        ldy #>afrcopy
        jsr memcpy

        ; free memory that the
        ; appfileref is using

        ldy appfileref+1
        ldx #1
        jsr pgfree

        ; update the location
        ; of appfileref

        ldy #>afrcopy
        ldx #0
        #stxy appfileref

        ; check to see if we
        ; opened the app from the
        ; file manager and load
        
        jsr loadapp

a_init99

        ; get the reference to 
        ; the tktext widget

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrp_
        jsr getmethod

        ; call the method to set the 
        ; string pointer

        #rdxy txtbuf
        jsr sysjmp

        ; push main screen layer

        #ldxy layer
        jsr layerpush

        ldx layer+slindx
        jsr markredraw

        rts

; A -> Class Index
; RegPtr -> SuperClass Ptr
; RegPtr <- Loaded Class Ptr
; ptr <- Ready to be loaded

loadclass 
        stx class
        sty class+1
        pha

        tax
        lda csizes,x
        tax
        lda #mapapp
        jsr pgalloc

        sty ptr+1

        tya
        ldx #"s"
        jsr gopath

        lda ptr+1
        ldx #<tkpath
        ldy #>tkpath

        jsr pathadd

; LoadClass common ending.

lc_end

         pla
         jsr cnames
         lda ptr+1
         jsr setname

         ldy ptr+1
         ldx #0
         jsr loadreloc

         ldx class
         ldy class+1

         rts         

        .bend

; ------------------------------------
a_mcmd
        .block

        #switch 5
        .byte mc_menq
        .byte mc_mnu
        .byte mc_fopn
        .byte mc_hmem
        .byte mc_memw
        .rta mnuenq
        .rta mnucmd
        .rta m_fopn
        .rta m_hmem
        .rta m_memw

        sec
        rts

mnuenq
        txa
        #switch 3
        .text "apw"
        .rta m_ascchk
        .rta m_petchk
        .rta m_wrapchk
        lda #0
        rts

m_ascchk
        lda pascii
        rts

m_petchk
        lda ppetscii
        rts

m_wrapchk

        lda pwrap
        rts

mnucmd
        txa
        #switch 6
        .text "!"
        .text "o"
        .text "c"
        .text "p"
        .text "a"
        .text "w"
        .rta quitapp
        .rta m_openfd
        .rta m_close
        .rta m_petscii
        .rta m_ascii
        .rta m_wrap
        
        sec
        rts

        .bend

; ------------------------------------
a_thaw
        .block

        ; check to see if we
        ; opened the app from the
        ; file manager and load
        
        jsr loadapp
        bcs end
        
        #ldxy tkenv
        jsr settkenv

        ; get reference to the
        ; scroll widget

        #storeget widgets,0
        jsr ptrthis

        ; reset the vertical scroll
        ; offset
        
        ldy #setoff_
        jsr getmethod
        #ldxy 0
        sec
        jsr sysjmp

        jsr thisdirt
        jsr mkdirt

        ; get the reference to 
        ; the tktext widget

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrp_
        jsr getmethod

        ; call the method to set the 
        ; string pointer

        #rdxy txtbuf
        jsr sysjmp

        ; check if the dirty

        jsr thisdirt

        ; set the toolkit environment
        ; dirty flag to force a redraw

        jsr mkdirt

        lda #0
        sta popen
end
        rts

        .bend

; ------------------------------------
l_update
        .block

        #ldxy tkenv
        jsr tkupdate

        ldy tkenv+te_posy
        ldx tkenv+te_posx
        jmp ctx2scr

        .bend

; ------------------------------------
l_mouse
        .block

        #ldxy tkenv
        jsr tkmouse
        jmp chkdirt

        .bend

; ------------------------------------
l_cmd
        .block

        #ldxy tkenv
        jsr tkkcmd
        jmp chkdirt

        .bend

; ------------------------------------
l_prnt
        .block

        #ldxy tkenv
        jsr tkkprnt
        jmp chkdirt

        .bend

; ------------------------------------
m_close
        .block

        ; is there a file loaded?
        
        lda pload

        ; no, reset text view

        beq m_close1

        ; free used space

        ldy ppage
        ldx psize
        jsr pgfree

        ; free file ref space used

        ldy frefpg
        ldx #1
        jsr pgfree

m_close1

        ; clear our flags and temp
        ; space for the next time
        ; we want to load a file

        lda #0
        sta pload
        sta ppage
        sta psize

        #ldxy tkenv
        jsr settkenv

        ; get the reference to 
        ; the tktext

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrp_
        jsr getmethod

        ; call the method to set the 
        ; string pointer 
        
        #ldxy welcome
        #stxy txtbuf
        jsr sysjmp

        ; check if the label is dirty

        jsr thisdirt

        ; set the toolkit environment
        ; dirty flag to force a redraw

        jmp mkdirt

        .bend

; ------------------------------------
m_fopn
        .block

        ; save the page where the 
        ; file reference is stored

        sty frefpg

        ; set flag so that when hmem
        ; callback comes we know that
        ; it was initiatied from the
        ; open file dialog

        lda #1
        sta popen

        rts

        .bend

; ------------------------------------
m_hmem
        .block

        ; was the callback triggered
        ; because the open button
        ; was selected on the file
        ; dialog and the utility
        ; has closed

        lda popen
        bne hmem0

        rts 

hmem0
        ; is the himem free
        
        lda himemuse

        ; yes, try to load the file
        
        beq hmem1

        ; no, wait for himem to
        ; free up

        rts

hmem1
        ; clear the flag that the
        ; open button was clicked
        ; from the open file util

        lda #0
        sta popen

hmem2
        ; load the file into memory

        jsr loadf

        #ldxy tkenv
        jsr settkenv

        ; get reference to the
        ; scroll widget

        #storeget widgets,0
        jsr ptrthis

        ; reset the vertical scroll
        ; offset
        
        ldy #setoff_
        jsr getmethod
        #ldxy 0
        sec
        jsr sysjmp

        jsr thisdirt
        jsr mkdirt

        ; get the reference to 
        ; the tktext widget

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrp_
        jsr getmethod

        ; call the method to set the 
        ; string pointer

        #rdxy txtbuf
        jsr sysjmp

        ; check if the dirty

        jsr thisdirt

        ; set the toolkit environment
        ; dirty flag to force a redraw

        jsr mkdirt

        lda #0
        sta popen

hmem99
        rts

        .bend

; ------------------------------------
; low memory warning
m_memw
        .block

        inc $d020
        sec
        rts

        .bend

; ------------------------------------
; show ascii on tktext
m_ascii
        .block

        #ldxy tkenv
        jsr settkenv

        ; get the reference to 
        ; the tktext widget

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrf_
        jsr getmethod

        ; set to ascii

        lda #mnu_sel
        sta pascii
        lda #0
        sta ppetscii
        ldy #tstrflgs
        lda (this),y
        ora #f_asc
        jsr sysjmp

        ; check if the dirty

        jsr thisdirt

        ; set the toolkit environment
        ; dirty flag to force a redraw

        jsr mkdirt

        rts

        .bend

; ------------------------------------
; show petscii on tktext
m_petscii
        .block

        #ldxy tkenv
        jsr settkenv

        ; get the reference to 
        ; the tktext widget

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrf_
        jsr getmethod

        ; set to ascii

        lda #mnu_sel
        sta ppetscii
        lda #0 
        sta pascii
        ldy #tstrflgs
        lda (this),y
        and #f_asc:$ff
        jsr sysjmp

        ; check if the dirty

        jsr thisdirt

        ; set the toolkit environment
        ; dirty flag to force a redraw

        jsr mkdirt

        rts

        .bend

; ------------------------------------
; wrap text on tktext
m_wrap
        .block

        #ldxy tkenv
        jsr settkenv

        lda pwrap
        bne unwrap

wrap
        ; set tktext as tkscroll
        ; content

        #storeget widgets,0
        jsr ptrthis

        ldy #setbar_ 
        jsr getmethod

        ldy #1 ; enable vert bar
        ldx #0 ; enable horiz bar
        jsr sysjmp

        jsr thisdirt
        jsr mkdirt

        ; get the reference to 
        ; the tktext widget

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrf_
        jsr getmethod

        ; set the tktext flag
        ; to unwrap text

        lda #mnu_sel
        sta pwrap
        ldy #tstrflgs
        lda (this),y
        ora #f_wrap
        jmp done

unwrap
        ; set tktext as tkscroll
        ; content

        #storeget widgets,0
        jsr ptrthis

        ldy #setbar_ 
        jsr getmethod

        ldy #1 ; enable vert bar
        ldx #1 ; enable horiz bar
        jsr sysjmp

        jsr thisdirt
        jsr mkdirt

        ; get the reference to 
        ; the tktext widget

        #storeget widgets,1
        jsr ptrthis

        ; prepare the pointer 
        ; reference for the function
        ; to set a string pointer

        ldy #setstrf_
        jsr getmethod

        ; set the tktext flag
        ; to unwrap text

        lda #0
        sta pwrap
        ldy #tstrflgs
        lda (this),y
        and #f_wrap:$ff

done
        jsr sysjmp

        ; check if the dirty

        jsr thisdirt

        ; set the toolkit environment
        ; dirty flag to force a redraw

        jsr mkdirt

        rts

        .bend

; ------------------------------------
a_quit
        .block

        ; clear memory here

        lda pload

        ; no, reset text view

        beq end

        ; free used space

        ldy ppage
        ldx psize
        jsr pgfree

        ; free file ref space used

        ldy frefpg
        ldx #1
        jsr pgfree
end        
        rts

        .bend

; ------------------------------------
xytoax
        .block

        txa
        pha
        tya
        tax
        pla

        rts

        .bend

; ------------------------------------
m_openfd
        .block

        lda #mc_mptr
        sta opnutilmcmd

        #ldxy openjob
        #stxy opnutilmdlo

        #ldxy openutil
        jsr loadutil

        rts

openutil
        .null "Open"

openjob
        .text "ojof"
        .word clc_rts

        .bend

; ------------------------------------
loadf
        .block

        ; was a text file already
        ; loaded in memory?
        
        lda pload

        ; no, go ahead and load
        ; the file

        beq noload

        ; yes, free up memory from 
        ; the last loaded file first

        ldy ppage
        ldx psize
        jsr pgfree

noload
        ; copy page aligned file
        ; reference to app memory
        ; and free memory

        lda frefpg
        ldy #>ofrcopy
        jsr memcpy

        ; free file ref space

        ldy frefpg
        ldx #1
        jsr pgfree

        ; use our page aligned 
        ; reference from the 
        ; file open we saved
        ; earlier

        ldy #>ofrcopy
        ldx #0
        lda #ff_r.ff_s
        jsr fopen

        ; was there an error?

        bcs error

        ; get blocks from file

        #stxy ptr
        ldy #frefblks
        lda (ptr),y
        sta bsize+1
        sta psize

        tax 
        lda #mapapp
        jsr pgalloc

        ; no errors allocating?

        bcc loadf0

        ; otherwise show a message
        ; that there is not enough
        ; memory

        #ldxy err1
        #stxy txtbuf

        jmp close

loadf0
        ; save our allocated
        ; memory for later
        
        sty txtbuf+1
        sty baddr+1
        sty ppage

        ; make sure we are on
        ; zero page boundry for
        ; file contents

        lda #0
        sta txtbuf

        ; read the file contents
        ; into our text buffer

        ldy #>ofrcopy
        ldx #0

        jsr fread
baddr   .word $00
bsize   .word $ff

        ; close the file

        ldy #>ofrcopy
        ldx #0
        jsr fclose

        ; make sure that the pointer
        ; for open files is using
        ; our loaded file

        ldy #>ofrcopy
        ldx #0
        #stxy opnfileref

        ; set flag that we have
        ; loaded a file

        lda #1
        sta pload

        rts

error
        ; file open error

        #ldxy err2
        #stxy txtbuf

close
        ; clear the file ref

        ldy #0
        ldx #0
        #stxy opnfileref

        ; close the file

        ldy #>ofrcopy
        ldx #0
        jsr fclose

        lda #0
        sta pload

        rts

        .bend

; ------------------------------------
loadapp
        .block

        ; check for app was opened
        ; from file manager

        lda opnappmcmd

        ; if not, finish

        cmp #mc_fopn
        beq load

        ; set carry flag to indicate
        ; that no file was passed
        ; to the app

        sec
        rts

load

        ; if it was, get the pointer
        ; to the file information
        ; and load it

        lda opnappmdhi
        sta frefpg

        jsr loadf

        ; set carry flag off to 
        ; indicate that a file was
        ; loaded into memory 

        clc
        rts

        .bend

; ------------------------------------
thisdirt
        #setflag this,dflags,df_dirty
        rts

; ------------------------------------
chkdirt
        lda tkenv+te_flags
        and #tf_dirty
        bne redraw
        sec
        rts

; ------------------------------------
mkdirt
        lda tkenv+te_flags
        ora #tf_dirty
        sta tkenv+te_flags

redraw

        ldx layer+slindx
        jsr markredraw

        clc
        rts

; ------------------------------------
ptr2    = $fd ; $fe
onclick
        ; save pointer to link text to ptr
        #stxy ptr

        ; check for 'fn:' link first
        ldy #0
        lda (ptr), y
        cmp #"f"
        bne endclick
        iny
        lda (ptr), y
        cmp #"n"
        bne endclick
        iny
        lda (ptr), y
        cmp #":"
        bne endclick
        ; we have a file name (fn:) link
        ; allocate page for new file reference
        lda #mapapp
        ldx #1
        jsr pgalloc
        sty frefpg
        sty ptr2+1          ; save new file ref page to ptr2 high byte
        ; copy current open file reference
        lda #>ofrcopy
        jsr memcpy

        ; load filename offset to ptr2 low byte (high byte of new file ref loaded above)
        lda #frefname
        sta ptr2

        ; move to start of filename
        inc ptr
        inc ptr
        inc ptr

        ; copy filename
        ldy #0
clicklp lda(ptr),y
        cmp #$03    ; end of link byte
        beq endfnm
        sta(ptr2),y
        iny
        jmp clicklp

endfnm  lda #0
        sta(ptr2),y ; null-terminate filename in new file ref
        lda #1
        sta popen
        jsr m_hmem
endclick
        rts

; ------------------------------------
welcome

.byte $0d,$f6,$f1
.text "[ Welcome to TextView+ ]"
.byte $0d,$00

err1

.byte $0d,$f6,$f1
.text "< Not Enough Memory >"
.byte $0d,$00

err2

.byte $0d,$f6,$f1
.text "< Error Loading File >"
.byte $0d,$00

; path.lib

setname jmp 3
pathadd jmp 6
gopath  jmp 18

* = $1000

; appfilref copy

afrcopy

.repeat 256, $aa

; openfileref copy

ofrcopy

.repeat 256, $bb
