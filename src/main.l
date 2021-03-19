# 23dec20 Software Lab. Alexander Burger

(symbols '(llvm))

(begin "base" NIL
   "vers.l" "defs.l" "glob.l" "dec.l" )

# Memory
(local) (memset2 memcpy2 alloc heapAlloc)

# naive implementation
# void *memset(void *str, int c, size_t n)
(de i8* memset2 ((i8* . S) (i32 . C) (i64 . N))
  (let (A (i8* (any S))
        I 0)
    (loop
      (? (== I N) A)
      (set A (i8 C))
      (inc 'I))))

# naive implementation
# void *memcpy(void *dest, const void * src, size_t n)
(de i8* memcpy2 ((i8* . D) (i8* . S) (i64 . N))
  (let (A (i8* (any D))
        B (i8* (any S))
        I 0)
    (loop
      (? (== I N) D)
      (set A (val B))
      (inc 'A)
      (inc 'B)
      (inc 'I))))

(de i8* alloc ((i8* . Ptr) (i64 . Siz))
  # verify stack/heap limits
  #(giveup ($ "No memory") null) 
  # ret $Limit then increase
  (prog1
    (i8* (any (val $Limit)))
    (set $Limit (ofs (any (val $Limit)) Siz))))
      
(de void heapAlloc ()
   (let
      (H (any (alloc null (* 8 (inc HEAP))))
         P (ofs H HEAP)
         A (val $Avail) )
      (set P (val $Heaps) 
           $Heaps H)
      (loop
         (set (setq P (ofs P -2)) A)  # Link avail
         (? (== (setq A P) H)) )
      (set $Avail A)))   
   
(local) (execAt runAt wrnl dbg)

(de execAt (Prg)
   (let At (save (val $At))
      (exec Prg)
      (set $At At) ) )

(de runAt (Prg)
   (let At (save (val $At))
      (prog1
         (run Prg)
         (set $At At) ) ) )

(de wrnl ()
   (write 1 ($ "\n") 1) )

(de dbg ((i64 . N) X)
   (let (Out (val $OutFile)  Put (val (i8** $Put)))
      (set
         $OutFile (val 3 (val $OutFiles))  # Stderr
         $Put (fun (void i8) _putStdout) )
      (outWord N)
      (when X
         (space)
         (print X) )
      (newline)
      (set (i8** $Put) Put  $OutFile Out) )
   X )


(local) (tosInFile popInFiles tosOutFile popOutFiles popErrFiles popCtlFiles)

(de void tosInFile ())
(de void popInFiles ())
(de void tosOutFile ())
(de void popOutFiles ())
(de void popErrFiles ())
(de void popCtlFiles ())

(local) (stop unwind)

# Stop coroutine
(de void stop ((i8* . Crt))
   ((coroutine Crt) tag 0)  # Set unused
   (while ((coroutine Crt) nxt)  # Find bottom
      (setq Crt @) )
   (until ((coroutine Crt) tag)  # Free stack space
      (setq Crt ((coroutine Crt) prv))
      ((coroutine Crt) nxt null) ) )

# Unwind stack
(de void unwind ((i8* . Catch))
   (when (val $Current)
      (unless (== @ (val $Coroutines))
         (stop @)
         (set $Current (val $Coroutines)) ) )
   (let (Ca (val $Catch)  Bnd (val $Bind))
      (while Ca
         (let Ca: (caFrame Ca)
            (while (and Bnd (<> Bnd (Ca: (env $Bind any))))
               (set (val 2 Bnd) (val Bnd))  # Restore values
               (setq Bnd (val 3 Bnd)) )
            (until (== (val $CtlFrames) (Ca: (env $CtlFrames i8*)))
               (popCtlFiles) )
            (until (== (val $ErrFrames) (Ca: (env $ErrFrames i8*)))
               (popErrFiles) )
            (unless (== (val $OutFrames) (Ca: (env $OutFrames i8*)))
               (loop
                  (popOutFiles)
                  (? (== (val $OutFrames) (Ca: (env $OutFrames i8*)))) )
               (tosOutFile) )
            (unless (== (val $InFrames) (Ca: (env $InFrames i8*)))
               (loop
                  (popInFiles)
                  (? (== (val $InFrames) (Ca: (env $InFrames i8*)))) )
               (tosInFile) )
            (memcpy2 (env) (Ca: (env)) (env T))
            (eval (Ca: fin))  # Evaluate 'finally' expression
            (set $Catch (Ca: link))
            (when (== Ca Catch)
               (ret) )
            (setq Ca (Ca: link)) ) )
      (while Bnd
         (set (val 2 Bnd) (val Bnd))  # Restore values
         (setq Bnd (val 3 Bnd)) )
      (set $Bind 0)
      (while (val $CtlFrames)
         (popCtlFiles) )
      (while (val $ErrFrames)
         (popErrFiles) )
      (unless (== (val $OutFrames) (val $Stdout))
         (loop
            (popOutFiles)
            (? (== (val $OutFrames) (val $Stdout))) )
         (tosOutFile) )
      (unless (== (val $InFrames) (val $Stdin))
         (loop
            (popInFiles)
            (? (== (val $InFrames) (val $Stdin))) )
         (tosInFile) ) ) )

# Exit
(local) (finish giveup bye execErr)

(de NIL finish ((i32 . N))
   #(setCooked)
   (exit N) )

(de NIL giveup ((i8* . Fmt) (i8* . Msg))
   (stderrMsg Fmt Msg)
   (finish 1) )

(de NIL bye ((i32 . N)) (outString ($ "bye\n")))

(de NIL execErr ((i8* . Cmd))
   (stderrMsg ($ "%s: Can't exec\n") Cmd)
   (exit 127) )

# Signals
(local) (sig sigTerm sighandler)

(de void sigTerm ((i32 . N))
   (if (val $TtyPid)
      (kill @ N)
      (set $Signal (+ (val $Signal) 1))
      (let P (ofs $Signal (gSignal (val SIGTERM Sig)))
         (set P (+ (val P) 1)) ) ) )

(de void sig ((i8* . E))
  
  # Handle gic here only
  # Specific intr handle in lisp
  #
  # volatile
  
  # disable interrupt
  (let Ia (val (i32* (any GICC-IA)))
  
    (set (i32* (any GICD-IC-ENAB))
      (i32 (shl 1 (% (i64 Ia) 32))))
  
    (newline)
    (outString ($ "sig: ")) (outWord (i64 Ia))
    (newline)
    
    (set $Signal (+ (val $Signal) 1))
    
    # need to shift to get id...
    (let P (ofs $Signal (+ Ia 1))
      (set P (+ (val P) 1)) )
    
    (set (i32* (any GICC-EOI)) Ia))
  
  null)


(de void sighandler (Exe)
  # sigChk calls this if $Signal set
  # $Signal set by sig
  # sig called by exception vector
   (unless (val $Protect)
      (set $Protect 1)
      (let P T
         # loop through all interrupts equally
         (loop
            (let N 1
              (loop
                (when (val (setq P (ofs $Signal N)))
                    (set P (dec @))
                    (set $Signal (dec (val $Signal)))
                    (set $IntID (cnt (- N 1))) # cons needed?
                    (execAt (val $Int)) )
                (inc 'N)              
                (? (== N IRQ-MAX)) ) )
            (? (=0 (val $Signal))) ) )
      (set $Protect 0) ) )

# Error handling
(local) (pushOutFile err stkErr argErr cntErr numErr symErr extErr nameErr
atomErr pairErr lstErr varErr itemErr protErr lockErr forkErr symNspErr)

(de void pushOutFile (i8* i8* i32))

(de NIL err (Exe X (i8* . Fmt) (i8* . Arg))
   (set $Up (if Exe @ $Nil))
   (when X
      (link (push X NIL)) )  # Save
   (let Msg (b8 240)
      #(gPrintf Msg 240 Fmt Arg)
      (set Msg (val Fmt))
      (when (val Msg)
         (set $Msg (mkStr Msg))
         (let Ca (val $Catch)
            (while Ca
               (let Ca: (caFrame Ca)
                  (let Tag (Ca: tag)
                     (when Tag
                        (while (pair Tag)
                           (when (subStr (car Tag) (val $Msg))
                              (unwind (Ca:))
                              (set $Ret
                                 (if (nil? (car Tag))
                                    (val $Msg)
                                    @ ) )
                              (longjmp (Ca: (rst)) 1) )
                           (shift Tag) ) ) )
                  (setq Ca (Ca: link)) ) ) ) )
      (set $Chr (set $ExtN 0))
      (set $Break 0)
      #(set $LinePtr null)
      #(set $Alarm (set $Sigio $Nil))
      (when Exe
         (outString ($ "!? "))
         (print Exe)
         (newline) )
      (when X
         (print X)
         (outString ($ " -- ")) )
      (when (val Msg)
         #(outString Msg)
         (outString Fmt)       
         (newline)
         (unless (or (nil? (val $Err)) (val $Jam))
            (set $Jam YES)
            (execAt (val $Err))
            (set $Jam NO) )
         #(unless (and (isatty 0) (isatty 1))
         #   (bye 1) )
         (set $Get (fun (i32) _getStdin))         
         (repl2 0 ($ "? ") $Nil))
      (outString ($ "err 1\n"))
      (unwind null)
      (outString ($ "err 2\n"))      
      (set
         $Link 0
         $Protect 0
         $Next $Nil
         $Make 0
         $Yoke 0
         $Trace 0 )
      #(set $Put (fun (void i8) _putStdout))
      #(set $Get (fun (i32) _getStdin))
      (outString ($ "err 3\n"))      
      (longjmp $QuitRst 1)
      ) )

(de NIL stkErr (Exe)
   (set $StkLimit null)
   (err Exe 0 ($ "Stack overflow") null) )

(de NIL argErr (Exe X)
   (err Exe X ($ "Bad argument") null) )

(de NIL cntErr (Exe X)
   (err Exe X ($ "Small number expected") null) )

(de NIL numErr (Exe X)
   (err Exe X ($ "Number expected") null) )

(de NIL symErr (Exe X)
   (err Exe X ($ "Symbol expected") null) )

(de NIL extErr (Exe X)
   (err Exe X ($ "External symbol expected") null) )

(de NIL nameErr (Exe X)
   (err Exe X ($ "Name expected") null) )

(de NIL atomErr (Exe X)
   (err Exe X ($ "Atom expected") null) )

(de NIL pairErr (Exe X)
   (err Exe X ($ "Cons pair expected") null) )

(de NIL lstErr (Exe X)
   (err Exe X ($ "List expected") null) )

(de NIL varErr (Exe X)
   (err Exe X ($ "Variable expected") null) )

(de NIL itemErr (Exe X)
   (err Exe X ($ "Item not found") null) )

(de NIL protErr (Exe X)
   (err Exe X ($ "Protected") null) )

(de NIL lockErr ()
   (err 0 0 ($ "File lock: %s") (strErrno)) )

(de NIL forkErr (Exe)
   (err Exe 0 ($ "Can't fork") null) )

(de NIL symNspErr (Exe X)
   (err Exe X ($ "Bad symbol namespace") null) )

# Value access
(local) (xCnt evCnt evLst xSym evSym xName)

(de i64 xCnt (Exe X)
   (let N (int (needCnt Exe X))
      (if (sign? X) (- N) N) ) )

(de i64 evCnt (Exe X)
   (xCnt Exe (eval (car X))) )

(de evLst (Exe)
   (let X (eval (car Exe))
      (unless (or (pair X) (nil? X))
         (lstErr Exe X) )
      X ) )

(de xSym (X)
   (if (symb? X)
      X
      (let P (push 4 NIL ZERO NIL)  # [cnt last name link]
         (link (ofs P 2) T)
         (pack X P)
         (consStr (val 3 P)) ) ) )

(de evSym (Exe)
   (xSym (eval (car Exe))) )

(de xName (Exe Sym)
   (cond
      ((nil? Sym) ZERO)
      ((sym? (val (tail Sym))) (nameErr Exe Sym))
      (T (name @)) ) )

# Structure checks
(local) (circ funq)

(de circ (X)
   (if (atom X)
      0
      (let Y X
         (loop
            (set Y (| (val Y) 1))  # Mark
            (? (atom (shift Y))  # No circularity found
               (loop
                  (set X (& (val X) -2))  # Unmark
                  (? (atom (shift X))) )
               0 )
            (? (& (val Y) 1)  # Detected circularity
               (until (== X Y)  # Skip non-circular part
                  (set X (& (val X) -2))  # Unmark
                  (shift X) )
               (loop
                  (set X (& (val X) -2))  # Unmark
                  (? (== Y (shift X))) )
               Y ) ) ) ) )

(de funq (X)
   (cond
      ((cnt? X) X)
      ((or (big? X) (sym? X)) 0)
      ((circ X) 0)
      (T
         (let Y (cdr X)
            (loop
               (? (atom Y)
                  (cond
                     ((not (nil? Y)) 0)
                     ((nil? (setq X (car X))) $T)
                     ((== X $Tilde) 0)
                     ((circ (setq Y X)) 0)
                     (T
                        (loop
                           (? (atom Y)
                              (if (or (num? Y) (t? Y))
                                 0
                                 X ) )
                           (?
                              (or
                                 (not (symb? (++ Y)))
                                 (nil? @)
                                 (t? @) )
                              0 ) ) ) ) )
               (let Z (++ Y)
                  (if (pair Z)
                     (if (num? (car Z))
                        (? (pair Y) 0)
                        (? (or (nil? (car Z)) (t? (car Z)))
                           0 ) )
                     (? (not (nil? Y)) 0) ) ) ) ) ) ) )

# (tty . prg) -> any
(de _tty (Exe) (outString ($ "tty\n")) $Nil)

# (raw ['flg]) -> flg
(de _raw (Exe) (outString ($ "raw\n")) $Nil)

# (alarm 'cnt . prg) -> cnt
(de _alarm (Exe)
   (let X (cdr Exe)
      (prog #prog1
         #(cnt (i64 (alarm (i32 (evCnt Exe X)))))
         (set $Alarm (cdr X)) ) ) )

# (sigio 'cnt . prg) -> cnt
(de _sigio (Exe) (outString ($ "sigio\n")) $Nil)

# (kids) -> lst
(de _kids (Exe) (outString ($ "kids\n")) $Nil)

# (protect . prg) -> any
(de _protect (Exe)
   (let X (cdr Exe)
      (prog2
         (set $Protect (+ (val $Protect) 1))
         (run X)
         (set $Protect (- (val $Protect) 1)) ) ) )

# (heap 'flg) -> cnt
(de _heap (Exe)
   (if (nil? (eval (cadr Exe)))
      (let (N 1  P (val $Heaps))
         (while (setq P (val (ofs P HEAP)))
            (inc 'N) )
         (cnt N) )
      (let (N 0  P (val $Avail))
         (while P
            (inc 'N)
            (setq P (car P)) )
         (cnt (shr N (- 20 4))) ) ) )  # Divide by CELLS (1M/16)

# (stack ['cnt]) -> cnt | (.. sym . cnt)
(de _stack (Exe)
   (let (X (cdr Exe)  Crt (val $Coroutines))
      (if (or (atom X) (and Crt ((coroutine Crt) nxt)))
         (let R (cnt (shr (val $StkSize) 10))
            (while Crt
               (let Crt: (coroutine Crt)
                  (when (Crt: tag)  # In use
                     (setq R (cons @ R)) )
                  (setq Crt (Crt: nxt)) ) )
            R )
         (let
            (N (evCnt Exe X)
               Old (val $StkSize)
               New (shl N 10) )
            (set $StkSize New)
            (when Crt
               ((coroutine Crt) lim
                  (ofs ((coroutine Crt) lim) (- Old New)) ) )
            (cnt N) ) ) ) )

# Date and time
(local) (tmDate tmTime)

(de tmDate ((i64 . Y) (i64 . M) (i64 . D))
   (if
      (and
         (gt0 Y)
         (gt0 M)
         (>= 12 M)
         (gt0 D)
         (or
            (>= (i64 (val (ofs $Month M))) D)
            (and
               (== D 29)
               (== M 2)
               (=0 (% Y 4))
               (or (% Y 100) (=0 (% Y 400))) ) ) )
      (let N (/ (+ (* Y 12) M -3) 12)
         (cnt
            (-
               (+
                  (/
                     (+ (* Y 4404) (* M 367) -1094)
                     12 )
                  (/ N 4)
                  (/ N 400)
                  D )
               (* 2 N)
               (/ N 100) ) ) )
      $Nil ) )

(de tmTime ((i64 . H) (i64 . M) (i64 . S))
   (if
      (and
         (ge0 H)
         (ge0 M)
         (> 60 M)
         (ge0 S)
         (> 60 S) )
      (cnt (+ (* H 3600) (* M 60) S))
      $Nil ) )

# (date ['T]) -> dat
# (date 'dat) -> (y m d)
# (date 'y 'm 'd) -> dat | NIL
# (date '(y m d)) -> dat | NIL
(de _date (Exe)
         $Nil )

# (time ['T]) -> tim
# (time 'tim) -> (h m s)
# (time 'h 'm ['s]) -> tim | NIL
# (time '(h m [s])) -> tim | NIL
(de _time (Exe)
         $Nil )

# (usec ['flg]) -> num
(de _usec (Exe)
  # need date for flg
   (cnt
    (- (any (cntvct)) (val $USec))))

# Try to load dynamic library
(local) sharedLib

(de i1 sharedLib (Sym)
   0 )

(load "gc.l" "big.l" "sym.l")

# Comparisons
(local) (equalBig equal compare)

(inline equalBig (X Y)
   (loop
      (? (<> (val (dig X)) (val (dig Y))) NO)
      (?
         (==
            (setq X (val (big X)))
            (setq Y (val (big Y))) )
         YES )
      (? (cnt? X) NO)
      (? (cnt? Y) NO) ) )

(de i1 equal (X Y)
   (cond
      ((== X Y) YES)
      ((cnt? X) NO)
      ((big? X)
         (if (cnt? Y)
            NO
            (when (sign? X)
               (unless (sign? Y)
                  (ret NO) )
               (setq X (pos X)  Y (pos Y)) )
            (equalBig X Y) ) )
      ((sym? X)
         (cond
            ((num? Y) NO)
            ((pair Y) NO)
            ((sym? (val (tail X))) NO)
            ((== ZERO (setq X (name @))) NO)
            ((sym? (val (tail Y))) NO)
            ((== ZERO (setq Y (name @))) NO)
            ((== X Y) YES)
            ((cnt? X) NO)
            ((cnt? Y) NO)
            (T (equalBig X Y)) ) )
      ((atom Y) NO)
      (T
         (stkChk 0)
         (let (A X  B Y)
            (prog1
               (loop
                  (? (not (equal (car X) (& (car Y) -2)))
                     NO)
                  (? (atom (cdr X))
                     (equal (cdr X) (cdr Y)) )
                  (? (atom (cdr Y)) NO)
                  (set X (| (val X) 1))  # Mark
                  (shift X)
                  (shift Y)
                  (? (& (val X) 1)  # Detected circularity
                     (prog1
                        (loop
                           (? (== A X)
                              (if (== B Y)
                                 (loop
                                    (shift A)
                                    (? (== (shift B) Y) (== A X))
                                    (? (== A X) YES) )
                                 NO ) )
                           (? (== B Y) NO)
                           (set A (& (val A) -2))  # Unmark
                           (shift A)
                           (shift B) )
                        (set A (& (val A) -2))  # Unmark
                        (shift A) ) ) )
               (until (== A X)
                  (set A (& (val A) -2))  # Unmark
                  (shift A) ) ) ) ) ) )

(de i64 compare (X Y)
   (cond
      ((== X Y) 0)
      ((nil? X) -1)
      ((t? X) +1)
      ((num? X)
         (cond
            ((num? Y) (cmpNum X Y))
            ((nil? Y) +1)
            (T -1) ) )
      ((sym? X)
         (cond
            ((or (num? Y) (nil? Y)) +1)
            ((or (pair Y) (t? Y)) -1)
            (T
               (let
                  (NmX (name (& (val (tail X)) -9))
                     NmY (name (& (val (tail Y)) -9)) )
                  (cond
                     ((== ZERO NmX)
                        (nond
                           ((== ZERO NmY) -1)
                           ((== X Y) 0)
                           ((> X Y) +1)
                           (NIL -1) ) )
                     ((== ZERO NmY) +1)
                     (T
                        (loop
                           (let
                              (A
                                 (if (cnt? NmX)
                                    (prog1
                                       (shr (shl (name NmX) 2) 6)  # Clear status bits
                                       (setq NmX 0) )
                                    (prog1
                                       (val (dig NmX))  # Next digit
                                       (setq NmX (val (big NmX))) ) )
                                 B
                                 (if (cnt? NmY)
                                    (prog1
                                       (shr (shl (name NmY) 2) 6)  # Clear status bits
                                       (setq NmY 0) )
                                    (prog1
                                       (val (dig NmY))  # Next digit
                                       (setq NmY (val (big NmY))) ) ) )
                              (loop
                                 (when (- (& A 255) (& B 255))
                                    (ret (if (gt0 @) +1 -1)) )
                                 (? (=0 (setq A (shr A 8)))
                                    (when (setq B (shr B 8))
                                       (ret -1) )
                                    (unless NmX
                                       (ret (if NmY -1 0)) )
                                    (unless NmY
                                       (ret +1) ) )
                                 (unless (setq B (shr B 8))
                                    (ret +1) ) ) ) ) ) ) ) ) ) )
      ((atom Y) (if (t? Y) -1 +1))
      (T
         (stkChk 0)
         (let (A X  B Y)
            (loop
               (? (compare (car X) (car Y)) @)
               (? (atom (shift X))
                  (compare X (cdr Y)) )
               (? (atom (shift Y))
                  (if (t? Y) -1 +1) )
               (? (and (== X A) (== Y B)) 0)
               (sigChk 0) ) ) ) ) )

# Evaluation
(local) (undefined evExpr evList)

(de NIL undefined (Fun Exe)
   (err Exe Fun ($ "Undefined") null) )

# Apply EXPR to CDR of list
(de evExpr (Exe Lst)
   (stkChk Exe)
   (let
      (X (cdr Lst)  # Arguments
         Y (car Exe)  # Parameters
         P (set $Bind (push (val $At) $At (val $Bind) Lst)) )  # [[@] @ LINK Expr]
      (while (pair Y)
         (let (V (eval (++ X))  Z (++ Y))  # Evaluate next argument
            (if (atom Z)
               (set $Bind
                  (setq P (push V (needChkVar Exe Z) P)) )  # [val sym LINK]
               (loop
                  (set $Bind
                     (setq P
                        (push  # [val sym LINK]
                           (if (pair V) (++ V) $Nil)
                           (needChkVar Exe (++ Z))
                           P ) ) )
                  (? (atom Z)) )
               (unless (nil? Z)
                  (set $Bind
                     (setq P (push V (needChkVar Exe Z) P)) ) ) ) ) )  # [val sym LINK]
      (prog1
         (if (== Y $At)  # VarArgs
            (if (pair X)
               (let (L (push NIL (eval (car X)) NIL)  Q L)
                  (link (ofs L 1))
                  (while (pair (shift X))
                     (setq L
                        (set L (push NIL (eval (car X)) NIL)) )
                     (link (ofs L 1)) )
                  (let Next (val $Next)
                     (set L $Nil  $Next Q)
                     (loop
                        (let Sym (val 2 P)
                           (xchg Sym P)  # Exchange symbol value
                           (? (== $At Sym))
                           (setq P (val 3 P)) ) )
                     (prog1
                        (run (cdr Exe))  # Run body
                        (set $Next Next)
                        (drop (ofs Q 1)) ) ) )
               (let Next (val $Next)
                  (set $Next $Nil)
                  (loop
                     (let Sym (val 2 P)
                        (xchg Sym P)  # Exchange symbol value
                        (? (== $At Sym))
                        (setq P (val 3 P)) ) )
                  (prog1
                     (run (cdr Exe))  # Run body
                     (set $Next Next) ) ) )
            (unless (nil? Y)
               (needChkVar Exe Y)
               (set
                  $Bind (push (val Y) Y P)  # Last parameter
                  Y X ) )  # Set to unevaluated argument(s)
            (loop
               (let Sym (val 2 P)
                  (xchg Sym P)  # Exchange symbol value
                  (? (== $At Sym))
                  (setq P (val 3 P)) ) )
            (run (cdr Exe)) )  # Run body
         (setq P (val $Bind))
         (loop
            (let Sym (val 2 P)
               (set Sym (val P))  # Restore values
               (? (== $At Sym))
               (setq P (val 3 P)) ) )
         (set $Bind (val 3 P)) ) ) )

(de evList (Exe)
   (let Fun (car Exe)
      (cond
         ((num? Fun) Exe)  # Number: Return list
         ((sym? Fun)  # Symbol: Find function
            (loop
               (sigChk Exe)
               (let V (val Fun)  # Get VAL
                  (? (num? V)  (subr V Exe Fun))
                  (? (pair V) (evExpr V Exe))
                  (? (== V (val V))
                     (if (sharedLib Fun)
                        (subr (val Fun) Exe Fun)
                        (undefined Fun Exe) ) )
                  (setq Fun V) ) ) )
         (T  # List: Evaluate
            (stkChk Exe)
            (let F (save (evList Fun))  # Save computed function
               (loop
                  (sigChk Exe)
                  (? (num? F) (subr F Exe Fun))
                  (? (pair F) (evExpr F Exe))
                  (let V (val F)
                     (? (== V (val V))
                        (if (sharedLib F)
                           (subr (val F) Exe F)
                           (undefined F Exe) ) )
                     (setq Fun F  F V) ) ) ) ) ) ) )

(load "io.l" "db.l" "apply.l" "flow.l" "subr.l")

# (quit ['any ['any]])
(de _quit (Exe)
   (let
      (X (cdr Exe)
         Nm (xName Exe (evSym X))
         Msg (bufString Nm (b8 (bufSize Nm))) )
      (err 0
         (if (atom (shift X))
            0
            (eval (car X)) )
         ($ "%s")
         Msg ) ) )

# (sys 'any ['any]) -> sym
(de _sys (Exe) $Nil)

# (pwd) -> sym
(de _pwd (Exe) $Nil)

# (cd 'any) -> sym
(de _cd (Exe) $Nil)

# (ctty 'sym|NIL|pid) -> flg
(de _ctty (Exe) $Nil)

# (cmd ['any]) -> sym
(de _cmd (Exe) $Nil)

# (dir ['any] ['flg]) -> lst
(de _dir (Exe) $Nil)

# (info 'any ['flg]) -> (cnt|flg dat . tim)
(de _info (Exe) $Nil)

# (file) -> (sym1 sym2 . num) | NIL
(de _file (Exe) $Nil)

# (argv [var ..] [. sym]) -> lst|sym
(de _argv (Exe) $Nil)

# (opt) -> sym
(de _opt (Exe) $Nil)

# (errno) -> cnt
(de _errno (Exe) $Nil)

# Native calls
(local) (fetchChar natBuf natErr natRetBuf ffi)

(de i32 fetchChar ((i8** . Ptr))
   (let (P (val Ptr)  C (i32 (val P)))
      (prog2
         (inc 'P)
         (cond
            ((>= 127 C) C)  # Single byte
            ((== C (hex "FF")) (i32 TOP))  # Infinite
            (T
               (|
                  (shl
                     (ifn (& C (hex "20"))
                        (& C (hex "1F"))
                        (|
                           (shl
                              (ifn (& C (hex "10"))
                                 (& C (hex "0F"))
                                 (|
                                    (shl (& C (hex "7")) 6)
                                    (&
                                       (i32 (prog1 (val P) (inc 'P)))
                                       (hex "3F") ) ) )
                              6 )
                           (&
                              (i32 (prog1 (val P) (inc 'P)))
                              (hex "3F") ) ) )
                     6 )
                  (&
                     (i32 (prog1 (val P) (inc 'P)))
                     (hex "3F") ) ) ) )
         (set Ptr P) ) ) )

(de i64 natBuf (Val (i8* . Ptr))
         $Nil )

(de NIL natErr (Spec)
   (err 0 Spec ($ "Bad result spec") null) )

(de natRetBuf (Spec (i8** . Ptr))
         $Nil )

(de ffi (Exe (i8* . Lib) Fun Args)
         $Nil )

# (%@ 'cnt2|sym2 'any 'any ..) -> any
(de _nat (Exe)
   (let
      (X (cdr Exe)
         Fun (save (eval (++ X)))  # Eval function 'cnt2|sym2'
         Args (save (cons (eval (++ X)) $Nil))
         L Args )  # [ret args]
      (while (pair X)
         (let Z (push (save (eval (++ X))) $Nil)  # [argN next]
            (set 2 L Z)
            (setq L Z) ) )
      (tailcall (ffi Exe null Fun Args)) ) )

# (native 'cnt1|sym1 'cnt2|sym2 'any 'any ..) -> any
(de _native (Exe)
         $Nil )

# (struct 'num 'any 'any ..) -> any
(de _struct (Exe)
   (let
      (X (cdr Exe)
         N  # Native value (pointer or scalar)
         (if (cnt? (needNum Exe (eval (++ X))))
            (int @)
            (val (dig @)) )
         P (i8* N)
         Y (save (eval (car X))) )  # Result specification
      (while (pair (shift X))
         (setq P
            (ofs P (natBuf (eval (car X)) P)) ) )
      (cond
         ((nil? Y) @)
         ((== Y $S) (mkStr (i8* N)))
         (T (natRetBuf Y (i8** (push N)))) ) ) )

# Lisp callbacks
(local) cbl

(de cbl (Fun A B C D E)
   (let Exe (push NIL NIL ZERO Fun)  # [car cdr name fun]
      (set Exe (ofs Exe 3))
      (let P (set 2 Exe (push NIL NIL ZERO (box A)))
         (set P (ofs P 3))
         (setq P
            (set 2 P (push NIL NIL ZERO (box B))) )
         (set P (ofs P 3))
         (setq P
            (set 2 P (push NIL NIL ZERO (box C))) )
         (set P (ofs P 3))
         (setq P
            (set 2 P (push NIL NIL ZERO (box D))) )
         (set P (ofs P 3))
         (setq P
            (set 2 P (push NIL $Nil ZERO (box E))) )
         (set P (ofs P 3)) )
      (xCnt 0 (evList Exe)) ) )

(de _cb1 (A B C D E)
   (cbl (val 2 $Lisp) A B C D E) )

(de _cb2 (A B C D E)
   (cbl (val 4 $Lisp) A B C D E) )

(de _cb3 (A B C D E)
   (cbl (val 6 $Lisp) A B C D E) )

(de _cb4 (A B C D E)
   (cbl (val 8 $Lisp) A B C D E) )

(de _cb5 (A B C D E)
   (cbl (val 10 $Lisp) A B C D E) )

(de _cb6 (A B C D E)
   (cbl (val 12 $Lisp) A B C D E) )

(de _cb7 (A B C D E)
   (cbl (val 14 $Lisp) A B C D E) )

(de _cb8 (A B C D E)
   (cbl (val 16 $Lisp) A B C D E) )

(de _cb9 (A B C D E)
   (cbl (val 18 $Lisp) A B C D E) )

(de _cb10 (A B C D E)
   (cbl (val 20 $Lisp) A B C D E) )

(de _cb11 (A B C D E)
   (cbl (val 22 $Lisp) A B C D E) )

(de _cb12 (A B C D E)
   (cbl (val 24 $Lisp) A B C D E) )

(de _cb13 (A B C D E)
   (cbl (val 26 $Lisp) A B C D E) )

(de _cb14 (A B C D E)
   (cbl (val 28 $Lisp) A B C D E) )

(de _cb15 (A B C D E)
   (cbl (val 30 $Lisp) A B C D E) )

(de _cb16 (A B C D E)
   (cbl (val 32 $Lisp) A B C D E) )

(de _cb17 (A B C D E)
   (cbl (val 34 $Lisp) A B C D E) )

(de _cb18 (A B C D E)
   (cbl (val 36 $Lisp) A B C D E) )

(de _cb19 (A B C D E)
   (cbl (val 38 $Lisp) A B C D E) )

(de _cb20 (A B C D E)
   (cbl (val 40 $Lisp) A B C D E) )

(de _cb21 (A B C D E)
   (cbl (val 42 $Lisp) A B C D E) )

(de _cb22 (A B C D E)
   (cbl (val 44 $Lisp) A B C D E) )

(de _cb23 (A B C D E)
   (cbl (val 46 $Lisp) A B C D E) )

(de _cb24 (A B C D E)
   (cbl (val 48 $Lisp) A B C D E) )

# (lisp 'sym ['fun]) -> num
(de _lisp (Exe)
   (let (X (cdr Exe)  Y (evSym X))
      (let (P $Lisp  Q (i8** (cbFuns)))
         (loop  # Search for tag 'sym'
            (? (== Y (val P)))  # Found
            (setq P (ofs P 2)  Q (ofs Q 1))
            (? (> P $LispEnd)  # Not found
               (setq P $Lisp  Q (i8** (cbFuns)))
               (until (nil? (val 2 P))  # Search for empty slot
                  (setq P (ofs P 2)  Q (ofs Q 1))
                  (when (> P $LispEnd)
                     (err Exe 0 ($ "Too many callbacks") null) ) )
               (set P Y) ) )
         (set 2 P (eval (cadr X)))  # Eval 'fun'
         (box64 (i64 (val Q))) ) ) )

# (args) -> flg
(de _args (Exe)
   (if (pair (val $Next)) $T $Nil) )

# (next) -> any
(de _next (Exe)
   (let X (val $Next)
      (set $Next (car X))
      (cdr X) ) )

# (arg 'cnt) -> any
(de _arg (Exe)
   (if (le0 (evCnt Exe (cdr Exe)))
      $Nil
      (let (N @  X (val $Next))
         (while (gt0 (dec 'N))
            (setq X (car X)) )
         (cdr X) ) ) )

# (rest) -> lst
(de _rest (Exe)
   (let X (val $Next)
      (if (atom X)
         X
         (let (Y (cons (cdr X) $Nil)  R (save Y))
            (while (pair (setq X (car X)))
               (setq Y (set 2 Y (cons (cdr X) $Nil))) )
            R ) ) ) )

# (adr 'var) -> num
# (adr 'num) -> var
(de _adr (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (int @))  # Make 'var'
      ((big? @) (val (dig @)))
      (T (box64 @)) ) )  # Make 'num'

# (byte 'num ['cnt]) -> cnt
(de _byte (Exe)
   (let
      (X (cdr Exe)
         P
         (i8*
            (if (cnt? (needNum Exe (eval (++ X))))
               (int @)
               (val (dig @)) ) ) )
      (if (atom X)
         (cnt (i64 (val P)))
         (let
            (Y (needCnt Exe (eval (car X)))
               N (int @) )
            (set P
               (i8 (if (sign? Y) (- N) N)) )
            Y ) ) ) )        
            
# (ptr32 'num ['cnt]) -> cnt            
(de _ptr32 (Exe)
   (let
      (X (cdr Exe)
         P
         (i32*
            (if (cnt? (needNum Exe (eval (++ X))))
               (int @)
               (val (dig @)) ) ) )
      (if (atom X)
         (cnt (& (i64 (val P)) (hex "FFFFFFFF"))) # get val
         (let # set val
            (Y (needCnt Exe (eval (car X)))
               N (int @) )
            (set P
               (i32 (if (sign? Y) (- N) N)) )
            Y ) ) ) )

# (ptr64 'num ['cnt]) -> cnt            
(de _ptr64 (Exe)
   (let
      (X (cdr Exe)
         P
         (any
            (if (cnt? (needNum Exe (eval (++ X))))
               (int @)
               (val (dig @)) ) ) )
      (if (atom X)
         (cnt (i64 (val P))) # get val
         (let # set/get val
            (Y (needCnt Exe (eval (car X)))
               N (int @) )
            (set P
               (any (if (sign? Y) (- N) N)))
            Y ) ) ) )            
            
# (env ['lst] | ['sym 'val] ..) -> lst
(de _env (Exe)
   (let (X (cdr Exe)  R (save $Nil))
      (if (atom X)
         (let Bnd (val $Bind)
            (while Bnd
               (let (S (val 2 Bnd)  Y R)
                  (loop
                     (? (atom Y)
                        (setq R
                           (safe (cons (cons S (val S)) R)) ) )  # (sym . val)
                     (? (== S (caar Y)))
                     (shift Y) ) )
               (setq Bnd (val 3 Bnd)) ) )
         (let Y (link (push $Nil NIL))
            (loop
               (let Z (set Y (eval (++ X)))  # Eval 'lst' or 'sym'
                  (nond
                     ((atom Z)
                        (loop
                           (let V (++ Z)
                              (setq R
                                 (safe
                                    (cons
                                       (if (pair V)
                                          (cons (car V) (cdr V))
                                          (cons V (val V)) )
                                       R ) ) ) )
                           (? (atom Z)) ) )
                     ((nil? Z)
                        (setq R
                           (safe (cons (cons Z (eval (++ X))) R)) ) ) ) )
                  (? (atom X)) ) ) )
      R ) )

# (trail ['flg]) -> lst
(de _trail (Exe)
   (let
      (F (not (nil? (eval (cadr Exe))))
         Bnd (val $Bind)
         R $Nil )
      (while Bnd
         (let S (val 2 Bnd)
            (cond
               ((== S $At)
                  (when (val 4 Bnd)
                     (setq R (cons @ R)) ) )  # Expr
               (F
                  (setq R (cons S (cons (val S) R)))
                  (set S (val Bnd)) ) ) )
         (setq Bnd (val 3 Bnd)) )
      (let X R
         (until (atom X)
            (when (atom (++ X))
               (set @ (++ X)) ) ) )
      R ) )

# (up [cnt] sym ['val]) -> any
(de _up (Exe)
   (let
      (X (cdr Exe)
         Y (car X)
         N 1
         Bnd (val $Bind) )
      (when (num? Y)
         (setq N (int Y)  Y (car (shift X))) )
      (if (nil? Y)
         (if N
            (loop
               (? (=0 Bnd) $Nil)
               (?
                  (and
                     (== $At (val 2 Bnd))
                     (=0 (dec 'N)) )
                  (if (val 4 Bnd) @ $Nil) )
               (setq Bnd (val 3 Bnd)) )
            $Nil )
         (let Z Y
            (when N
               (loop
                  (? (=0 Bnd))
                  (?
                     (and
                        (== Y (val 2 Bnd))
                        (prog
                           (setq Z Bnd)
                           (=0 (dec 'N)) ) ) )
                  (setq Bnd (val 3 Bnd)) ) )
            (if (atom (shift X))
               (val Z)
               (set Z (eval (car X))) ) ) ) ) )

# (history ['lst]) -> lst
(de _history (Exe)
         $Nil )

# (version ['flg]) -> lst
(de _version (Exe)
   (when (nil? (eval (cadr Exe)))
      (outWord (int (val $Y)))
      (call $Put (char "."))
      (outWord (int (val $M)))
      (call $Put (char "."))
      (outWord (int (val $D)))
      (newline) )
   (cons (val $Y)
      (cons (val $M)
         (cons (val $D) $Nil) ) ) )

# Main entry point
(local) (loadKern main wfi wfe daif)

(de loadKern ()
  (let
      (Int (save (val $Intern))
        Pr1 (save (val $PrivT))
        Pr2 (save (val 2 $PrivT))
        Tr1 (save (val $Transient))
        Tr2 (save (val 2 $Transient))
        V (link (push -ZERO NIL))
        At (link (push -ZERO NIL)))
      (set $PrivT (set 2 $PrivT $Nil))
      (set $Transient (set 2 $Transient $Nil))
      
      (let
          (Nm (name (val (tail (val $Kern))))
            Chr (val $Chr)
            Get (val (i8** $Get))
            Pars (val $Parser) )
            
          (set
            $Get (fun (i32) getParse)
            $Parser (push 0 (save Nm) 0) )
          
          (loop
            (let Y (read1 0)
              (? (nil? Y))
              (set V Y) # store on stack to prevent GC
              (eval Y)))
            
          (set
              $Parser Pars
              (i8** $Get) Get
              $Chr Chr ) )
      
      (set 2 $Transient Tr2)
      (set $Transient Tr1)
      (set 2 $PrivT Pr2)
      (set $PrivT Pr1)
      (set $Intern Int)))

      
(de void main ()

   # init mmu
   # init gic
   # init uart

   # ... 512 KB : stack
   # ... 4   MB : interpreter
   #     4   MB : VC mem start
   # ... 64  MB : ARM mem start
   # ... 144 B  : mailbox (align 16 bytes)
   # ... 1   KB : Prompt
   # ....       : heap star
  
   (set
      #$MBox     (box64 (hex "4000000"))
      $QuitRst  (hex "4000090")
      $Heap     (hex "4000490")
      $Limit    (hex "4000490")
      $Put      (fun (void i8) _putStdout)
      $Get      (fun (i32) _getStdin))
      
   # set gic symbols
   
   (call $Put (char "\n"))
   
   (outString ($ "$QuitRst="))  (outWord (any $QuitRst))  (newline)   
   (outString ($ "$Heap="))  (outWord (val $Heap))  (newline)
   (outString ($ "$Limit="))  (outWord (val $Limit)) (newline)
   
   (outString ($ "Call heapAlloc...\n"))
   (heapAlloc)
   
   (outString ($ "Init internal symbols...\n"))
   (let P $Nil
      (loop
         (let Nm (val (tail P))
            (when (num? Nm)
               (intern P 0 @ (cdr $Pico) $Nil NO)
               (? (== P $LastSym))
               (when (big? Nm)  # Max 15 chars
                  (setq P (ofs P 2)) ) ) )
         (setq P (ofs P 2)) ) )

   (set
      $Dbg $Nil
      $DB $Db1  # Database root constant
      (tail $Db1) DB1  # Name of external root symbol '{1}'
      $Extern (cons $Db1 $Nil))  # External symbol tree root node
  
   # load kernel, then drop to repl
   (set
      $USec (any (cntvct))
      $Kern (mkStr $Kerns)
      $Signal 0)
   (loadKern)
   
   # mov before
   # mov loadKern in repl2f
   (setjmp $QuitRst)   
   (repl2 0 ($ ": ") $Nil)
   
   # repl implemented in pil21
   # bc err handling
   
   (outString ($ "pil21 bye")))


(de _kern (Exe)
  # TODO: pass flag whether dynamic repl or top-level
  (loadKern))   

(de _isb (Exe)
  (isb)
  $Nil)  
  
(de _wfi (Exe)
  (wfi)
  $Nil)

(de _wfe (Exe)
  (wfe)
  $Nil)
  
(de _daif (Exe)
  (let X (cdr Exe) 
    (if (atom X)
        (cnt (any (daif)))
        (let N (evCnt Exe X)
          (daif N)
          (cnt N)))))
      
(de _daif2 (Exe)
  (if (nil? (eval (cadr Exe)))
      (prog (daif2) $Nil)
      (prog (daif2 T) $T)))      

# r/o
(de _cnt-frq (Exe)
   (cnt
    (any (cnt-frq))))   
   
# virt   
   
# r/w
(de _cntv-ctl (Exe)
  (let X (cdr Exe) 
    (if (atom X)
        (cnt (any (cntv-ctl)))
        (let N (evCnt Exe X)
          (cntv-ctl N)
          (cnt N)))))

# r/w
(de _cntv-cval (Exe)
  (let X (cdr Exe) 
    (if (atom X)
        (cnt (any (cntv-cval)))
        (let N (evCnt Exe X)
          (cntv-cval N)
          (cnt N)))))
          
# r/w
(de _cntv-tval (Exe)
  (let X (cdr Exe) 
    (if (atom X)
        (cnt (any (cntv-tval)))
        (let N (evCnt Exe X)
          (cntv-tval N)
          (cnt N)))))          

# r/o
(de _cntvct (Exe)
   (cnt
    (any (cntvct))))

    
# phys

# r/w
(de _cntp-ctl (Exe)
  (let X (cdr Exe) 
    (if (atom X)
        (cnt (any (cntp-ctl)))
        (let N (evCnt Exe X)
          (cntp-ctl N)
          (cnt N)))))

# r/w
(de _cntp-cval (Exe)
  (let X (cdr Exe) 
    (if (atom X)
        (cnt (any (cntp-cval)))
        (let N (evCnt Exe X)
          (cntp-cval N)
          (cnt N)))))
          
# r/w
(de _cntp-tval (Exe)
  (let X (cdr Exe) 
    (if (atom X)
        (cnt (any (cntp-tval)))
        (let N (evCnt Exe X)
          (cntp-tval N)
          (cnt N)))))       

# r/o
(de _cntpct (Exe)
   (cnt
    (any (cntpct))))
  
(end "base.map")
