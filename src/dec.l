# 12dec20 Software Lab. Alexander Burger

(symbols '(llvm))

(local) (inFile outFile dbFile ioFrame)

# I/O
(struct inFile
   (name 8 i8*)         # File name
   (fd 4 i32)           # File descriptor
   (chr 4 i32)          # Next character
   (line 4 i32)         # Current line number
   (src 4 i32)          # Source start line
   (ix 4 i32)           # Buffer index
   (cnt 4 i32)          # Buffer byte count
   (buf BUFSIZ i8) )    # Buffer

(struct outFile
   (fd 4 i32)           # File descriptor
   (ix 4 i32)           # Buffer index
   (buf BUFSIZ i8)      # Buffer
   (tty 1 i1) )         # TTY flag

(struct ioFrame
   (link 8 i8*)         # Frame link
   (file 8 i8*)         # File structure
   (fun 8 i8*)          # I/O function
   (pid 4 i32) )        # Process ID

(struct ctFrame
   (link 8 i8*)         # Frame link
   (fd 4 i32) )         # File descriptor

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

# Family IPC
(local) child

(struct child
   (buf 8 i8*)          # Buffer
   (ofs 4 i32)          # Buffer offset
   (cnt 4 i32)          # Buffer byte count
   (pid 4 i32)          # Process ID
   (hear 4 i32)         # Hear pipe
   (tell 4 i32) )       # Tell pipe

# libc
(local) (pr-libc malloc realloc free fork getenv setenv getpid getpgrp setsid alarm
setpgid execvp isatty tcgetattr read write pread pwrite fread fwrite
putc_unlocked getc_unlocked fopen fflush feof fclose fileno fsync pipe memcmp
strlen strcpy strdup strcmp strchr2 strrchr dlsym dlerror dup dup2 close signal
tcsetpgrp waitpid setjmp longjmp kill exit)

(de void pr-libc ((i8* . Str))
   (while (val Str)
      (while (n0 (& (i8 (any AUX-MU-LSR)) (hex "20"))) T)
      (set (i8* (any AUX-MU-IO)) @)
      (inc 'Str) ))

(de i8* malloc        () (pr-libc ($ "malloc       ")) null)
(de i8* realloc       () (pr-libc ($ "realloc      ")) null)
(de void free         () (pr-libc ($ "free         ")) null)
(de i32 fork          () (pr-libc ($ "fork         ")) 0)
(de i8* getenv        () (pr-libc ($ "getenv       ")) null)
(de i32 setenv        () (pr-libc ($ "setenv       ")) 0)
(de i8* getcwd        () (pr-libc ($ "getcwd       ")) null)
(de i32 chdir         () (pr-libc ($ "chdir        ")) 0)
(de i32 getpid        () (pr-libc ($ "getpid       ")) 0)
(de i32 getpgrp       () (pr-libc ($ "getpgrp      ")) 0)
(de i32 setsid        () (pr-libc ($ "setsid       ")) 0)
(de i32 alarm         () (pr-libc ($ "alarm        ")) 0)
(de i32 setpgid       () (pr-libc ($ "setpgid      ")) 0)
(de i32 execvp        () (pr-libc ($ "execvp       ")) 0)
(de i32 isatty        () (pr-libc ($ "isatty       ")) 0)
(de i32 tcgetattr     () (pr-libc ($ "tcgetattr    ")) 0)
(de i64 read          () (pr-libc ($ "read         ")) 0)
(de i64 write         () (pr-libc ($ "write        ")) 0)
(de i64 pread         () (pr-libc ($ "pread        ")) 0)
(de i64 pwrite        () (pr-libc ($ "pwrite       ")) 0)
(de i32 fread         () (pr-libc ($ "fread        ")) 0)
(de i32 fwrite        () (pr-libc ($ "fwrite       ")) 0)
(de i32 putc_unlocked () (pr-libc ($ "putc_unlocked")) 0)
(de i32 getc_unlocked () (pr-libc ($ "getc_unlocked")) 0)
(de i8* fopen         () (pr-libc ($ "fopen        ")) null)
(de i32 fflush        () (pr-libc ($ "fflush       ")) 0)
(de i32 feof          () (pr-libc ($ "feof         ")) 0)
(de i32 fclose        () (pr-libc ($ "fclose       ")) 0)
(de i32 fileno        () (pr-libc ($ "fileno       ")) 0)
(de i32 fsync         () (pr-libc ($ "fsync        ")) 0)
(de i32 pipe          () (pr-libc ($ "pipe         ")) 0)
(de i32 memcmp        () (pr-libc ($ "memcmp       ")) 0)
(de i64 strlen        () (pr-libc ($ "strlen       ")) 0)
(de i8* strcpy        () (pr-libc ($ "strcpy       ")) null)
(de i8* strdup        () (pr-libc ($ "strdup       ")) null)
(de i32 strcmp        () (pr-libc ($ "strcmp       ")) 0)

(de i8* strchr2 ((i8* . Str) (i32 . Chr))
   (let (X (i8* Str))
      (while (val X)
         (? (== @ (i8 Chr)) (ret X))
         (inc 'X) )
      null))
      
(de i8* strrchr       () (pr-libc ($ "strrchr      ")) null)
(de i8* dlsym         () (pr-libc ($ "dlsym        ")) null)
(de i8* dlerror       () (pr-libc ($ "dlerror      ")) null)
(de i32 dup           () (pr-libc ($ "dup          ")) 0)
(de i32 dup2          () (pr-libc ($ "dup2         ")) 0)
(de i32 close         () (pr-libc ($ "close        ")) 0)
(de i8* signal        () (pr-libc ($ "signal       ")) null)
(de i32 tcsetpgrp     () (pr-libc ($ "tcsetpgrp    ")) 0)
(de i32 waitpid       () (pr-libc ($ "waitpid      ")) 0)
(de i32 setjmp        () (pr-libc ($ "setjmp       ")) 0)
(de NIL longjmp       () (pr-libc ($ "longjmp      ")) 0)
(de i32 kill          () (pr-libc ($ "kill         ")) 0)
(de NIL exit          () (pr-libc ($ "exit         ")) 0)

# libreadline
(local) (readline add_history history_list clear_history)

(de i8*   readline      () (pr-libc ($ "readline     ")) null)
(de void  add_history   () (pr-libc ($ "add_history  ")) null)
(de i8*** history_list  () (pr-libc ($ "history_list ")) null)
(de void  clear_history () (pr-libc ($ "clear_history")) null)

# Glue lib.c
(local) (TgOS TgCPU PipeBufSize)

(var TgOS i8 0)  # Target OS
(var TgCPU i8 0)  # Target CPU
(var PipeBufSize i32 0)  # PIPE_BUF

(local) (stderrMsg gPrintf strErrno openRd openWr openRdWr openRdWrExcl
openRdWrCreate openRdWrAppend openWrAppend fseekOfs fseek0 seek0 truncate0
socketPair fcntlCloExec fcntlSetFl nonBlocking fcntlSetOwn getDir)

(de i8*  stderrMsg      () (pr-libc ($ "stderrMsg     ")) null)
(de i32  gPrintf        () (pr-libc ($ "gPrintf       ")) 0)
(de i8*  strErrno       () (pr-libc ($ "strErrno      ")) null)
(de i32  openRd         () (pr-libc ($ "openRd        ")) 0)
(de i32  openWr         () (pr-libc ($ "openWr        ")) 0)
(de i32  openRdWr       () (pr-libc ($ "openRdWr      ")) 0)
(de i32  openRdWrExcl   () (pr-libc ($ "openRdWrExcl  ")) 0)
(de i32  openRdWrCreate () (pr-libc ($ "openRdWrCreate")) 0)
(de i32  openRdWrAppend () (pr-libc ($ "openRdWrAppend")) 0)
(de i32  openWrAppend   () (pr-libc ($ "openWrAppend  ")) 0)
(de i1   fseekOfs       () (pr-libc ($ "fseekOfs      ")) 0)
(de i1   fseek0         () (pr-libc ($ "fseek0        ")) 0)
(de i1   seek0          () (pr-libc ($ "seek0         ")) 0)
(de i1   truncate0      () (pr-libc ($ "truncate0     ")) 0)
(de i32  socketPair     () (pr-libc ($ "socketPair    ")) 0)
(de i32  fcntlCloExec   () (pr-libc ($ "fcntlCloExec  ")) 0)
(de void fcntlSetFl     () (pr-libc ($ "fcntlSetFl    ")) null)
(de i32  nonBlocking    () (pr-libc ($ "nonBlocking   ")) 0)
(de void fcntlSetOwn    () (pr-libc ($ "fcntlSetOwn   ")) null)
(de i8*  getDir         () (pr-libc ($ "getDir        ")) null)

(local) (initReadline rlHide rlShow rlSigBeg rlSigEnd currentLine)

(de void initReadline () (pr-libc ($ "initReadline")) null)
(de void rlHide       () (pr-libc ($ "rlHide      ")) null)
(de void rlShow       () (pr-libc ($ "rlShow      ")) null)
(de void rlSigBeg     () (pr-libc ($ "rlSigBeg    ")) null)
(de void rlSigEnd     () (pr-libc ($ "rlSigEnd    ")) null)
(de i8*  currentLine  () (pr-libc ($ "currentLine ")) null)

# Signals
(local) (Sig SigDfl SigIgn)

(var Sig i32 0)
(var SigDfl i8* null)
(var SigIgn i8* null)

(local) (gSignal sigUnblock iSignal sigChld waitWuntraced wifStopped)

(de i32  gSignal       ()    (pr-libc ($ "gSignal      ")) 0)
(de void sigUnblock    ()    (pr-libc ($ "sigUnblock   ")) null)
(de void iSignal       ()    (pr-libc ($ "iSignal      ")) null)
(de void sigChld       (i32) (pr-libc ($ "sigChld      ")) null)
(de i32  waitWuntraced ()    (pr-libc ($ "waitWuntraced")) 0)
(de i32  wifStopped    ()    (pr-libc ($ "wifStopped   ")) 0)

(local) (nErrno gErrno)
(de i32 nErrno () (pr-libc ($ "nErrno")) 0)
(de i32 gErrno () (pr-libc ($ "gErrno")) 0)

# Terminal
(local) (Tio OrgTermio Termio setRaw setCooked reopenTty)

(var Tio i1 0)
(var OrgTermio i8 0)
(var Termio i8* null)

(de void setRaw    () (pr-libc ($ "setRaw   ")) null)
(de void setCooked () (pr-libc ($ "setCooked")) null)

# System
(local) (getUsec getMsec getDate getGmDate getTime getGmTime fileInfo)

(de i64 getUsec  (i1)          (pr-libc ($ "getUsec ")) 0)
(de i64 getMsec  ()            (pr-libc ($ "getMsec ")) 0)
(de i64 fileInfo (i1 i8* i64*) (pr-libc ($ "fileInfo")) 0)

# Polling
(local) (pollIn pollOut pollIgn gPoll readyIn readyOut)

(de void pollIn   () (pr-libc ($ "pollIn  ")) null)
(de void pollOut  () (pr-libc ($ "pollOut ")) null)
(de void pollIgn  () (pr-libc ($ "pollIgn ")) null)
(de i32  gPoll    () (pr-libc ($ "gPoll   ")) 0)
(de i1   readyIn  () (pr-libc ($ "readyIn ")) 0)
(de i1   readyOut () (pr-libc ($ "readyOut")) 0)

# Locking
(local) (rdLock wrLock unLock getLock)

(de i32 rdLock  () (pr-libc ($ "rdLock ")) 0)
(de i32 wrLock  () (pr-libc ($ "wrLock ")) 0)
(de i32 unLock  () (pr-libc ($ "unLock ")) 0)
(de i32 getLock () (pr-libc ($ "getLock")) 0)

# Catch and Throw
(local) (JmpBufSize QuitRst)

(var JmpBufSize i64 0)  # sizeof(jmp_buf)
(var QuitRst i8 0)

# Native lib.c


# Case mappings lib.c


### Forward references ###

# main.l
(local) (dbg equal compare evList)

(de dbg (i64 any))
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
(local) (flushAll newline space outWord outString print repl)

(de void flushAll ())
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
