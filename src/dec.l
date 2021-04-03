# 12dec20 Software Lab. Alexander Burger

(symbols '(llvm))

(local) (dbFile)

(struct dbFile
   (fd 4 i32)           # File descriptor
   (db 4 i32)           # File number
   (sh 4 i32)           # Block shift
   (siz 4 i32)          # Block size (64 << sh)
   (mark 8 i8*)         # Mark bit vector
   (mrks 8 i64)         # Mark vector size
   (flu 8 i64)          # Free list use count
   (lck 1 i1)           # Lock flag
   (drt 1 i1) )         # Dirty flag

# Catch/throw
(local) caFrame

(struct caFrame
   (link 8 i8*)         # Frame link
   (tag 8 any)          # Catch tag
   (fin 8 any)          # 'finally' expression
   (env (env T) i8)     # Saved environment
   (rst 0 i8) )         # Restart jmp_buf (JmpBufSize)

# Coroutines
(local) coroutine

(struct coroutine
   (tag 8 any)          # Coroutine tag
   (prv 8 i8*)          # Previous coroutine
   (nxt 8 i8*)          # Next coroutine
   (org 8 i8*)          # Originator
   (prg 8 any)          # Code body
   (lim 8 i8*)          # Stack limit
   (at 8 any)           # Saved [@]
   (lnk 8 any)          # Link marker
   (bnd 8 any)          # Bind marker
   (ca 8 i8*)           # Catch marker
   (in 8 i8*)           # InFrames marker
   (out 8 i8*)          # OutFrames marker
   (err 8 i8*)          # ErrFrames marker
   (ctl 8 i8*)          # CtlFrames marker
   (env (env T) i8)     # Saved environment
   (rst 0 i8) )         # Restart jmp_buf (JmpBufSize)

# libc
(local) (_end malloc realloc free
putc_unlocked getc_unlocked
memcmp strchr2 setjmp longjmp)

(var _end i8 0)

(de i8* malloc        () null)
(de i8* realloc       () null)
(de void free         () null)
(de i32 putc_unlocked () 0)
(de i32 getc_unlocked () 0)
(de i32 memcmp        () 0)

(de i8* strchr2 ((i8* . Str) (i32 . Chr))
   (let (X (i8* Str))
      (while (val X)
         (? (== @ (i8 Chr)) (ret X))
         (inc 'X) )
      null))

(de T i32 setjmp (i8*))
(de T NIL longjmp (i8* i32))

### Forward references ###

# main.l
(local) (equal compare evList)

(de i1 equal (any any))
(de i64 compare (any any))
(de evList (any))

# gc.l
(local) (cons consStr)

(de cons (any any))
(de consStr (any))

# sym.l
(local) (bufSize bufString mkStr firstByte pack xSym subStr)

(de i64 bufSize (any))
(de i8* bufString (any i8*))
(de mkStr (i8*))
(de i8 firstByte (any))
(de void pack (any i64*))
(de i1 subStr (any any))

# io.l
(local) (newline space outWord outString print repl)

(de void newline ())
(de void space ())
(de void outWord (i64))
(de void outString (i8*))
(de void print (any))
(de repl (any i8* any))

# db.l
(local) (dbFetch dbTouch dbZap)

(de void dbFetch (any any))
(de void dbTouch (any any))
(de void dbZap (any))

# flow.l
(local) brkLoad

(de brkLoad (any))

### Primitives ###
(local) (caar cadr cdar cddr int cnt sign sym name memq member length boxNum
box64 eval run)

(inline caar (X)
   (car (car X)) )

(inline cadr (X)
   (car (cdr X)) )

(inline cdar (X)
   (cdr (car X)) )

(inline cddr (X)
   (cdr (cdr X)) )

(inline int (X)
   (shr X 4) )

(inline cnt (X)
   (any (| (shl X 4) 2)) )

(inline sign (X)
   (any (| X 8)) )

(inline sym (X)
   (any (| X 8)) )

(inline name (Tail)
   (until (num? Tail)
      (shift Tail) )
   Tail )

(inline memq (X L)
   (use @
      (loop
         (? (atom L) NO)
         (? (== X (car L)) YES)
         (shift L) ) ) )

(inline member (X L)
   (use @
      (loop
         (? (atom L) NO)
         (? (equal X (car L)) YES)
         (shift L) ) ) )

(inline nth (N X)
   (use @
      (let C (int N)
         (while (dec 'C)
            (shift X) )
         (if (sign? N)
            (cdr X)
            (car X) ) ) ) )

(inline length (X)
   (use @
      (let N 0
         (while (pair X)
            (inc 'N)
            (shift X) )
         N ) ) )

(inline box64 (N)
   (use @
      (if (& N (hex "F000000000000000"))  # Fit in short number
         (boxNum N)
         (cnt N) ) ) )

(inline eval (X)
   (use @
      (cond
         ((num? X) X)
         ((sym? X) (val X))
         (T (evList X)) ) ) )

(inline exec (Prg)
   (use @
      (loop
         (when (pair (++ Prg))
            (evList @) )
         (? (atom Prg)) ) ) )

(inline run (Prg)
   (use @
      (loop
         (let X (++ Prg)
            (? (atom Prg) (eval X))
            (and (pair X) (evList X)) ) ) ) )

# Runtime checks
(local) (stkChk sigChk)

(inline stkChk (Exe)
   (when (> (val $StkLimit) (stack))
      (stkErr Exe) ) )

(inline sigChk (Exe)
   (when (val $Signal)
      (sighandler Exe) ) )

# Argument checks
(local) (needCnt needNum needSymb needPair needLst needVar chkVar needChkVar needNsp)

(inline needCnt (Exe X)
   (unless (cnt? X)
      (cntErr Exe X) )
   X )

(inline needNum (Exe X)
   (unless (num? X)
      (numErr Exe X) )
   X )

(inline needSymb (Exe X)
   (unless (symb? X)
      (symErr Exe X) )
   X )

(inline needPair (Exe X)
   (when (atom X)
      (pairErr Exe X) )
   X )

(inline needLst (Exe X)
   (unless (or (pair X) (nil? X))
      (lstErr Exe X) )
   X )

(inline needVar (Exe X)
   (when (num? X)
      (varErr Exe X) )
   X )

(inline chkVar (Exe X)
   (when (and (>= X $Nil) (>= $T X))
      (protErr Exe X) )
   X )

(inline needChkVar (Exe X)
   (when (num? X)
      (varErr Exe X) )
   (chkVar Exe X)
   X )

(inline needNsp (Exe X)
   (unless (and (pair (val X)) (== $Tilde (car @)))
      (symNspErr Exe X) )
   X )
