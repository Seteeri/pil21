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

(local) (execAt runAt dbg)

(de execAt (Prg)
   (let At (save (val $At))
      (exec Prg)
      (set $At At) ) )

(de runAt (Prg)
   (let At (save (val $At))
      (prog1
         (run Prg)
         (set $At At) ) ) )


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

(de NIL finish ((i32 . N)) (outString ($ "finish\n")))

(de NIL giveup ((i8* . Fmt) (i8* . Msg))
   (outString Fmt) (space) (outString Msg) (newline)
   (finish 1) )

(de NIL bye ((i32 . N)) (outString ($ "bye\n")))

(de NIL execErr ((i8* . Cmd))
   (outString ($ "%s: Can't exec\n")) (space) (outString Cmd) (newline)
   (outString ($ "exit\n")) )

# Signals
(local) (sig sigTerm sighandler)

(de void sigTerm ((i32 . N)) (outString ($ "sigTerm\n")))

(de void sig ((i8* . E))

  # Handle gic here only
  # Specific intr handle in lisp
  #
  # volatile

  # An IRQ is taken from inactive to pending when it is asserted by its device.
  # The IRQ is then taken from pending to active when the CPU reads the Interrupt Acknowledge Register.
  # Finally, the IRQ is fully retired and the EOI signal is sent, when the CPU writes to the End of Interrupt register.

  (let Ia (val (i32* (any CPUI-IAR)))

    #(newline)
    #(outString ($ "dist-icenabler/cpendr: "))
    #(outWord (i64 (val (i32* (any DIST-ICENABLER)))))
    #(outString ($ ", "))
    #(outWord (i64 (val (i32* (any DIST-ICPENDR)))))
    #(newline)

    (when (== Ia 1023)
      (newline)
      (outString ($ "sig: ")) (outWord (i64 Ia))
      (newline)
      # Dump e
      (loop Ia))

    (unless (== Ia 1023)

      (set (i32* (any DIST-ICENABLER))
        (i32 (shl 1 (% (i64 Ia) 32))))

      (set $Signal (+ (val $Signal) 1))

      # need to shift to get id...
      (let P (ofs $Signal (+ Ia 1))
        (set P (+ (val P) 1)) )

      #(outString ($ "dist-icenabler/cpendr: "))
      #(outWord (i64 (val (i32* (any DIST-ICENABLER)))))
      #(outString ($ ", "))
      #(outWord (i64 (val (i32* (any DIST-ICPENDR)))))
      #(newline)

      # only when Ia not 1023
      # write will be ignored
      (set (i32* (any CPUI-EOIR)) Ia)

      #(outString ($ "dist-icenabler/cpendr: "))
      #(outWord (i64 (val (i32* (any DIST-ICENABLER)))))
      #(outString ($ ", "))
      #(outWord (i64 (val (i32* (any DIST-ICPENDR)))))
      #(newline)
      ))

  # timer will keep asserting since it is not disabled...

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
                    (outString ($ "\nsighandler\n"))
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
   (let Msg Fmt #(b8 240)
      #(gPrintf Msg 240 Fmt Arg)
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
      # Should not go here...
      (outString ($ "pil21 err loop wfe"))
      (loop (wfe))))

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
   (err 0 0 ($ "File lock: <ERRNO>") null) )

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

# (usec ['flg]) -> num
(de _usec (Exe)
  # need date for flg
   (cnt
    (- (any (cntvct)) (val $USec))))

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
                        (undefined Fun Exe) )
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
                           (undefined F Exe) )
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
         (box64 (i64 (val P))) # get val
         (let # set/get val
            (Y (needCnt Exe (eval (car X)))
               N (int @) )
            (set P
               (i64 (any (if (sign? Y) (- N) N))))
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
(local) (loadKern setPeri main wfi wfe daif)

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
            Put (val (i8** $Put))
            Get (val (i8** $Get))
            Pars (val $Parser) )

          (set
            $Put (fun (void i8) putChr)
            $Get (fun (i32) getChr) # getParse
            $Parser (push 0 (save Nm) 0) )

          (loop
            (let Y (read1 0)
              (? (nil? Y))
              (set V Y) # store on stack to prevent GC
              (eval Y)))

          (set
              $Parser Pars
              (i8** $Put) Put
              (i8** $Get) Get
              $Chr Chr ) )

      (set 2 $Transient Tr2)
      (set $Transient Tr1)
      (set 2 $PrivT Pr2)
      (set $PrivT Pr1)
      (set $Intern Int)))


(de void setPeri ()
  (set
      $Peri   (box64 BASE-PERI)
      $Irq    $Nil)

  (set $Gic
      (cons (cons (mkStr ($ "DIST-CTLR"))       (box64 DIST-CTLR      ))
      (cons (cons (mkStr ($ "DIST-TYPER"))      (box64 DIST-TYPER     ))
      (cons (cons (mkStr ($ "DIST-IIDR"))       (box64 DIST-IIDR      ))
      (cons (cons (mkStr ($ "DIST-IGROUPR"))    (box64 DIST-IGROUPR   ))
      (cons (cons (mkStr ($ "DIST-ISENABLER"))  (box64 DIST-ISENABLER ))
      (cons (cons (mkStr ($ "DIST-ICENABLER"))  (box64 DIST-ICENABLER ))
      (cons (cons (mkStr ($ "DIST-ISPENDR"))    (box64 DIST-ISPENDR   ))
      (cons (cons (mkStr ($ "DIST-ICPENDR"))    (box64 DIST-ICPENDR   ))
      (cons (cons (mkStr ($ "DIST-ISACTIVER"))  (box64 DIST-ISACTIVER ))
      (cons (cons (mkStr ($ "DIST-ICACTIVER"))  (box64 DIST-ICACTIVER ))
      (cons (cons (mkStr ($ "DIST-IPRIORITYR")) (box64 DIST-IPRIORITYR))
      (cons (cons (mkStr ($ "DIST-ITARGETS"))   (box64 DIST-ITARGETSR ))
      (cons (cons (mkStr ($ "DIST-ICFGR"))      (box64 DIST-ICFGR     ))
      (cons (cons (mkStr ($ "DIST-PPISR"))      (box64 DIST-PPISR     ))
      (cons (cons (mkStr ($ "DIST-SPISR"))      (box64 DIST-SPISR     ))
      (cons (cons (mkStr ($ "DIST-SGIR"))       (box64 DIST-SGIR      ))
      (cons (cons (mkStr ($ "DIST-CPENDSGIR"))  (box64 DIST-CPENDSGIR ))
      (cons (cons (mkStr ($ "DIST-SPENDSGIR"))  (box64 DIST-SPENDSGIR ))
      (cons (cons (mkStr ($ "DIST-PIDR4"))      (box64 DIST-PIDR4     ))
      (cons (cons (mkStr ($ "DIST-PIDR5"))      (box64 DIST-PIDR5     ))
      (cons (cons (mkStr ($ "DIST-PIDR6"))      (box64 DIST-PIDR6     ))
      (cons (cons (mkStr ($ "DIST-PIDR7"))      (box64 DIST-PIDR7     ))
      (cons (cons (mkStr ($ "DIST-PIDR0"))      (box64 DIST-PIDR0     ))
      (cons (cons (mkStr ($ "DIST-PIDR1"))      (box64 DIST-PIDR1     ))
      (cons (cons (mkStr ($ "DIST-PIDR2"))      (box64 DIST-PIDR2     ))
      (cons (cons (mkStr ($ "DIST-PIDR3"))      (box64 DIST-PIDR3     ))
      (cons (cons (mkStr ($ "DIST-CIDR0"))      (box64 DIST-CIDR0     ))
      (cons (cons (mkStr ($ "DIST-CIDR1"))      (box64 DIST-CIDR1     ))
      (cons (cons (mkStr ($ "DIST-CIDR2"))      (box64 DIST-CIDR2     ))
      (cons (cons (mkStr ($ "DIST-CIDR3"))      (box64 DIST-CIDR3     ))

      (cons (cons (mkStr ($ "CPUI-CTLR"))       (box64 CPUI-CTLR      ))
      (cons (cons (mkStr ($ "CPUI-PMR"))        (box64 CPUI-PMR       ))
      (cons (cons (mkStr ($ "CPUI-BPR"))        (box64 CPUI-BPR       ))
      (cons (cons (mkStr ($ "CPUI-IAR"))        (box64 CPUI-IAR       ))
      (cons (cons (mkStr ($ "CPUI-EOIR"))       (box64 CPUI-EOIR      ))
      (cons (cons (mkStr ($ "CPUI-RPR"))        (box64 CPUI-RPR       ))
      (cons (cons (mkStr ($ "CPUI-HPPIR"))      (box64 CPUI-HPPIR     ))
      (cons (cons (mkStr ($ "CPUI-ABPR"))       (box64 CPUI-ABPR      ))
      (cons (cons (mkStr ($ "CPUI-AIAR"))       (box64 CPUI-AIAR      ))
      (cons (cons (mkStr ($ "CPUI-AEOIR"))      (box64 CPUI-AEOIR     ))
      (cons (cons (mkStr ($ "CPUI-AHPPIR"))     (box64 CPUI-AHPPIR    ))
      (cons (cons (mkStr ($ "CPUI-APR0"))       (box64 CPUI-APR0      ))
      (cons (cons (mkStr ($ "CPUI-NSAPR0"))     (box64 CPUI-NSAPR0    ))
      (cons (cons (mkStr ($ "CPUI-IIDR"))       (box64 CPUI-IIDR      ))
      (cons (cons (mkStr ($ "CPUI-DIR"))        (box64 CPUI-DIR       ))
            $Nil))))))))))))))))))))))))))))))))))))))))))))))

  (set $Aux
      (cons (cons (mkStr ($ "AUX-IRQ"))             (box64 AUX-IRQ))             # Auxiliary Interrupt status 3
      (cons (cons (mkStr ($ "AUX-ENABLES"))         (box64 AUX-ENABLES))         # Auxiliary enables 3
      (cons (cons (mkStr ($ "AUX-MU-IO-REG"))       (box64 AUX-MU-IO-REG))       # Mini UART I/O Data 8
      (cons (cons (mkStr ($ "AUX-MU-IER-REG"))      (box64 AUX-MU-IER-REG))      # Mini UART Interrupt Enable 8
      (cons (cons (mkStr ($ "AUX-MU-IIR-REG"))      (box64 AUX-MU-IIR-REG))      # Mini UART Interrupt Identify 8
      (cons (cons (mkStr ($ "AUX-MU-LCR-REG"))      (box64 AUX-MU-LCR-REG))      # Mini UART Line Control 8
      (cons (cons (mkStr ($ "AUX-MU-MCR-REG"))      (box64 AUX-MU-MCR-REG))      # Mini UART Modem Control 8
      (cons (cons (mkStr ($ "AUX-MU-LSR-REG"))      (box64 AUX-MU-LSR-REG))      # Mini UART Line Status 8
      (cons (cons (mkStr ($ "AUX-MU-MSR-REG"))      (box64 AUX-MU-MSR-REG))      # Mini UART Modem Status 8
      (cons (cons (mkStr ($ "AUX-MU-SCRATCH"))      (box64 AUX-MU-SCRATCH))      # Mini UART Scratch 8
      (cons (cons (mkStr ($ "AUX-MU-CNTL-REG"))     (box64 AUX-MU-CNTL-REG))     # Mini UART Extra Control 8
      (cons (cons (mkStr ($ "AUX-MU-STAT-REG"))     (box64 AUX-MU-STAT-REG))     # Mini UART Extra Status 32
      (cons (cons (mkStr ($ "AUX-MU-BAUD-REG"))     (box64 AUX-MU-BAUD-REG))     # Mini UART Baudrate 16
      (cons (cons (mkStr ($ "AUX-SPI1-CNTL0-REG"))  (box64 AUX-SPI1-CNTL0-REG))  # SPI 1 Control register 0 32
      (cons (cons (mkStr ($ "AUX-SPI1-CNTL1-REG"))  (box64 AUX-SPI1-CNTL1-REG))  # SPI 1 Control register 1 8
      (cons (cons (mkStr ($ "AUX-SPI1-STAT-REG"))   (box64 AUX-SPI1-STAT-REG))   # SPI 1 Status 32
      (cons (cons (mkStr ($ "AUX-SPI1-PEEK-REG"))   (box64 AUX-SPI1-PEEK-REG))   # SPI 1 Peek 16
      (cons (cons (mkStr ($ "AUX-SPI1-IO-REG"))     (box64 AUX-SPI1-IO-REG))     # SPI 1 Data 32
      (cons (cons (mkStr ($ "AUX-SPI1-IO-REG"))     (box64 AUX-SPI1-IO-REG))     # SPI 1 Data 32
      (cons (cons (mkStr ($ "AUX-SPI1-IO-REG"))     (box64 AUX-SPI1-IO-REG))     # SPI 1 Data 32
      (cons (cons (mkStr ($ "AUX-SPI1-IO-REG"))     (box64 AUX-SPI1-IO-REG))     # SPI 1 Data 32
      (cons (cons (mkStr ($ "AUX-SPI1-TXHOLD-REG")) (box64 AUX-SPI1-TXHOLD-REG)) # SPI 1 Extended Data 32
      (cons (cons (mkStr ($ "AUX-SPI1-TXHOLD-REG")) (box64 AUX-SPI1-TXHOLD-REG)) # SPI 1 Extended Data 32
      (cons (cons (mkStr ($ "AUX-SPI1-TXHOLD-REG")) (box64 AUX-SPI1-TXHOLD-REG)) # SPI 1 Extended Data 32
      (cons (cons (mkStr ($ "AUX-SPI1-TXHOLD-REG")) (box64 AUX-SPI1-TXHOLD-REG)) # SPI 1 Extended Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-CNTL0-REG"))  (box64 AUX-SPI2-CNTL0-REG))  # SPI 2 Control register 0 32
      (cons (cons (mkStr ($ "AUX-SPI2-CNTL1-REG"))  (box64 AUX-SPI2-CNTL1-REG))  # SPI 2 Control register 1 8
      (cons (cons (mkStr ($ "AUX-SPI2-STAT-REG"))   (box64 AUX-SPI2-STAT-REG))   # SPI 2 Status 32
      (cons (cons (mkStr ($ "AUX-SPI2-PEEK-REG"))   (box64 AUX-SPI2-PEEK-REG))   # SPI 2 Peek 16
      (cons (cons (mkStr ($ "AUX-SPI2-IO-REG"))     (box64 AUX-SPI2-IO-REG))     # SPI 2 Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-IO-REG"))     (box64 AUX-SPI2-IO-REG))     # SPI 2 Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-IO-REG"))     (box64 AUX-SPI2-IO-REG))     # SPI 2 Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-IO-REG"))     (box64 AUX-SPI2-IO-REG))     # SPI 2 Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-TXHOLD-REG")) (box64 AUX-SPI2-TXHOLD-REG)) # SPI 2 Extended Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-TXHOLD-REG")) (box64 AUX-SPI2-TXHOLD-REG)) # SPI 2 Extended Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-TXHOLD-REG")) (box64 AUX-SPI2-TXHOLD-REG)) # SPI 2 Extended Data 32
      (cons (cons (mkStr ($ "AUX-SPI2-TXHOLD-REG")) (box64 AUX-SPI2-TXHOLD-REG)) # SPI 2 Extended Data 32
            $Nil))))))))))))))))))))))))))))))))))))))

  (set $Uart
      (cons (cons (mkStr ($ "UART0-DR"))     (box64 UART0-DR    )) # Data Register 32
      (cons (cons (mkStr ($ "UART0-RSRECR")) (box64 UART0-RSRECR)) # 32
      (cons (cons (mkStr ($ "UART0-FR"))     (box64 UART0-FR    )) # Flag register 32
      (cons (cons (mkStr ($ "UART0-ILPR"))   (box64 UART0-ILPR  )) # not in use 32
      (cons (cons (mkStr ($ "UART0-IBRD"))   (box64 UART0-IBRD  )) # Integer Baud rate divisor 32
      (cons (cons (mkStr ($ "UART0-FBRD"))   (box64 UART0-FBRD  )) # Fractional Baud rate divisor 32
      (cons (cons (mkStr ($ "UART0-LCRH"))   (box64 UART0-LCRH  )) # Line Control register 32
      (cons (cons (mkStr ($ "UART0-CR"))     (box64 UART0-CR    )) # Control register 32
      (cons (cons (mkStr ($ "UART0-IFLS"))   (box64 UART0-IFLS  )) # Interrupt FIFO Level Select Register 32
      (cons (cons (mkStr ($ "UART0-IMSC"))   (box64 UART0-IMSC  )) # Interrupt Mask Set Clear Register 32
      (cons (cons (mkStr ($ "UART0-RIS"))    (box64 UART0-RIS   )) # Raw Interrupt Status Register 32
      (cons (cons (mkStr ($ "UART0-MIS"))    (box64 UART0-MIS   )) # Masked Interrupt Status Register 32
      (cons (cons (mkStr ($ "UART0-ICR"))    (box64 UART0-ICR   )) # Interrupt Clear Register 32
      (cons (cons (mkStr ($ "UART0-DMACR"))  (box64 UART0-DMACR )) # DMA Control Register 32
      (cons (cons (mkStr ($ "UART0-ITCR"))   (box64 UART0-ITCR  )) # Test Control register 32
      (cons (cons (mkStr ($ "UART0-ITIP"))   (box64 UART0-ITIP  )) # Integration test input reg 32
      (cons (cons (mkStr ($ "UART0-ITOP"))   (box64 UART0-ITOP  )) # Integration test output reg 32
      (cons (cons (mkStr ($ "UART0-TDR"))    (box64 UART0-TDR   )) # Test Data reg 32

      # UART1 = AUX

      (cons (cons (mkStr ($ "UART2-DR"))     (box64 UART2-DR    ))
      (cons (cons (mkStr ($ "UART2-RSRECR")) (box64 UART2-RSRECR))
      (cons (cons (mkStr ($ "UART2-FR"))     (box64 UART2-FR    ))
      (cons (cons (mkStr ($ "UART2-ILPR"))   (box64 UART2-ILPR  ))
      (cons (cons (mkStr ($ "UART2-IBRD"))   (box64 UART2-IBRD  ))
      (cons (cons (mkStr ($ "UART2-FBRD"))   (box64 UART2-FBRD  ))
      (cons (cons (mkStr ($ "UART2-LCRH"))   (box64 UART2-LCRH  ))
      (cons (cons (mkStr ($ "UART2-CR"))     (box64 UART2-CR    ))
      (cons (cons (mkStr ($ "UART2-IFLS"))   (box64 UART2-IFLS  ))
      (cons (cons (mkStr ($ "UART2-IMSC"))   (box64 UART2-IMSC  ))
      (cons (cons (mkStr ($ "UART2-RIS"))    (box64 UART2-RIS   ))
      (cons (cons (mkStr ($ "UART2-MIS"))    (box64 UART2-MIS   ))
      (cons (cons (mkStr ($ "UART2-ICR"))    (box64 UART2-ICR   ))
      (cons (cons (mkStr ($ "UART2-DMACR"))  (box64 UART2-DMACR ))
      (cons (cons (mkStr ($ "UART2-ITCR"))   (box64 UART2-ITCR  ))
      (cons (cons (mkStr ($ "UART2-ITIP"))   (box64 UART2-ITIP  ))
      (cons (cons (mkStr ($ "UART2-ITOP"))   (box64 UART2-ITOP  ))
      (cons (cons (mkStr ($ "UART2-TDR"))    (box64 UART2-TDR   ))

      (cons (cons (mkStr ($ "UART3-DR"))     (box64 UART3-DR    ))
      (cons (cons (mkStr ($ "UART3-RSRECR")) (box64 UART3-RSRECR))
      (cons (cons (mkStr ($ "UART3-FR"))     (box64 UART3-FR    ))
      (cons (cons (mkStr ($ "UART3-ILPR"))   (box64 UART3-ILPR  ))
      (cons (cons (mkStr ($ "UART3-IBRD"))   (box64 UART3-IBRD  ))
      (cons (cons (mkStr ($ "UART3-FBRD"))   (box64 UART3-FBRD  ))
      (cons (cons (mkStr ($ "UART3-LCRH"))   (box64 UART3-LCRH  ))
      (cons (cons (mkStr ($ "UART3-CR"))     (box64 UART3-CR    ))
      (cons (cons (mkStr ($ "UART3-IFLS"))   (box64 UART3-IFLS  ))
      (cons (cons (mkStr ($ "UART3-IMSC"))   (box64 UART3-IMSC  ))
      (cons (cons (mkStr ($ "UART3-RIS"))    (box64 UART3-RIS   ))
      (cons (cons (mkStr ($ "UART3-MIS"))    (box64 UART3-MIS   ))
      (cons (cons (mkStr ($ "UART3-ICR"))    (box64 UART3-ICR   ))
      (cons (cons (mkStr ($ "UART3-DMACR"))  (box64 UART3-DMACR ))
      (cons (cons (mkStr ($ "UART3-ITCR"))   (box64 UART3-ITCR  ))
      (cons (cons (mkStr ($ "UART3-ITIP"))   (box64 UART3-ITIP  ))
      (cons (cons (mkStr ($ "UART3-ITOP"))   (box64 UART3-ITOP  ))
      (cons (cons (mkStr ($ "UART3-TDR"))    (box64 UART3-TDR   ))

      (cons (cons (mkStr ($ "UART4-DR"))     (box64 UART4-DR    ))
      (cons (cons (mkStr ($ "UART4-RSRECR")) (box64 UART4-RSRECR))
      (cons (cons (mkStr ($ "UART4-FR"))     (box64 UART4-FR    ))
      (cons (cons (mkStr ($ "UART4-ILPR"))   (box64 UART4-ILPR  ))
      (cons (cons (mkStr ($ "UART4-IBRD"))   (box64 UART4-IBRD  ))
      (cons (cons (mkStr ($ "UART4-FBRD"))   (box64 UART4-FBRD  ))
      (cons (cons (mkStr ($ "UART4-LCRH"))   (box64 UART4-LCRH  ))
      (cons (cons (mkStr ($ "UART4-CR"))     (box64 UART4-CR    ))
      (cons (cons (mkStr ($ "UART4-IFLS"))   (box64 UART4-IFLS  ))
      (cons (cons (mkStr ($ "UART4-IMSC"))   (box64 UART4-IMSC  ))
      (cons (cons (mkStr ($ "UART4-RIS"))    (box64 UART4-RIS   ))
      (cons (cons (mkStr ($ "UART4-MIS"))    (box64 UART4-MIS   ))
      (cons (cons (mkStr ($ "UART4-ICR"))    (box64 UART4-ICR   ))
      (cons (cons (mkStr ($ "UART4-DMACR"))  (box64 UART4-DMACR ))
      (cons (cons (mkStr ($ "UART4-ITCR"))   (box64 UART4-ITCR  ))
      (cons (cons (mkStr ($ "UART4-ITIP"))   (box64 UART4-ITIP  ))
      (cons (cons (mkStr ($ "UART4-ITOP"))   (box64 UART4-ITOP  ))
      (cons (cons (mkStr ($ "UART4-TDR"))    (box64 UART4-TDR   ))

      (cons (cons (mkStr ($ "UART5-DR"))     (box64 UART5-DR    ))
      (cons (cons (mkStr ($ "UART5-RSRECR")) (box64 UART5-RSRECR))
      (cons (cons (mkStr ($ "UART5-FR"))     (box64 UART5-FR    ))
      (cons (cons (mkStr ($ "UART5-ILPR"))   (box64 UART5-ILPR  ))
      (cons (cons (mkStr ($ "UART5-IBRD"))   (box64 UART5-IBRD  ))
      (cons (cons (mkStr ($ "UART5-FBRD"))   (box64 UART5-FBRD  ))
      (cons (cons (mkStr ($ "UART5-LCRH"))   (box64 UART5-LCRH  ))
      (cons (cons (mkStr ($ "UART5-CR"))     (box64 UART5-CR    ))
      (cons (cons (mkStr ($ "UART5-IFLS"))   (box64 UART5-IFLS  ))
      (cons (cons (mkStr ($ "UART5-IMSC"))   (box64 UART5-IMSC  ))
      (cons (cons (mkStr ($ "UART5-RIS"))    (box64 UART5-RIS   ))
      (cons (cons (mkStr ($ "UART5-MIS"))    (box64 UART5-MIS   ))
      (cons (cons (mkStr ($ "UART5-ICR"))    (box64 UART5-ICR   ))
      (cons (cons (mkStr ($ "UART5-DMACR"))  (box64 UART5-DMACR ))
      (cons (cons (mkStr ($ "UART5-ITCR"))   (box64 UART5-ITCR  ))
      (cons (cons (mkStr ($ "UART5-ITIP"))   (box64 UART5-ITIP  ))
      (cons (cons (mkStr ($ "UART5-ITOP"))   (box64 UART5-ITOP  ))
      (cons (cons (mkStr ($ "UART5-TDR"))    (box64 UART5-TDR   ))
            $Nil)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))

  (set $Irq
      (cons (cons (mkStr ($ "IRQ-CORE-N-HP-TIMER"))      (box64 IRQ-CORE-N-HP-TIMER     ))
      (cons (cons (mkStr ($ "IRQ-CORE-N-V-TIMER"))       (box64 IRQ-CORE-N-V-TIMER      ))
      (cons (cons (mkStr ($ "IRQ-LEGACY-FIQn"))          (box64 IRQ-LEGACY-FIQn         ))
      (cons (cons (mkStr ($ "IRQ-CORE-N-PS-TIMER"))      (box64 IRQ-CORE-N-PS-TIMER     ))
      (cons (cons (mkStr ($ "IRQ-CORE-N-PNS-TIMER"))     (box64 IRQ-CORE-N-PNS-TIMER    ))
      (cons (cons (mkStr ($ "IRQ-LEGACY-IRQn"))          (box64 IRQ-LEGACY-IRQn         ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-0"))            (box64 IRQ-MAILBOX-0           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-1"))            (box64 IRQ-MAILBOX-1           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-2"))            (box64 IRQ-MAILBOX-2           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-3"))            (box64 IRQ-MAILBOX-3           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-4"))            (box64 IRQ-MAILBOX-4           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-5"))            (box64 IRQ-MAILBOX-5           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-6"))            (box64 IRQ-MAILBOX-6           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-7"))            (box64 IRQ-MAILBOX-7           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-8"))            (box64 IRQ-MAILBOX-8           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-9"))            (box64 IRQ-MAILBOX-9           ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-10"))           (box64 IRQ-MAILBOX-10          ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-11"))           (box64 IRQ-MAILBOX-11          ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-12"))           (box64 IRQ-MAILBOX-12          ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-13"))           (box64 IRQ-MAILBOX-13          ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-14"))           (box64 IRQ-MAILBOX-14          ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX-15"))           (box64 IRQ-MAILBOX-15          ))
      (cons (cons (mkStr ($ "IRQ-CORE-0-PMU"))           (box64 IRQ-CORE-0-PMU          ))
      (cons (cons (mkStr ($ "IRQ-CORE-1-PMU"))           (box64 IRQ-CORE-1-PMU          ))
      (cons (cons (mkStr ($ "IRQ-CORE-2-PMU"))           (box64 IRQ-CORE-2-PMU          ))
      (cons (cons (mkStr ($ "IRQ-CORE-3-PMU"))           (box64 IRQ-CORE-3-PMU          ))
      (cons (cons (mkStr ($ "IRQ-AXIERR"))               (box64 IRQ-AXIERR              ))
      (cons (cons (mkStr ($ "IRQ-LOCAL-TIMER"))          (box64 IRQ-LOCAL-TIMER         ))
      (cons (cons (mkStr ($ "IRQ-TIMER"))                (box64 IRQ-TIMER               ))
      (cons (cons (mkStr ($ "IRQ-MAILBOX"))              (box64 IRQ-MAILBOX             ))
      (cons (cons (mkStr ($ "IRQ-DOORBELL-0"))           (box64 IRQ-DOORBELL-0          ))
      (cons (cons (mkStr ($ "IRQ-DOORBELL-1"))           (box64 IRQ-DOORBELL-1          ))
      (cons (cons (mkStr ($ "IRQ-VPU0-HALTED"))          (box64 IRQ-VPU0-HALTED         ))
      (cons (cons (mkStr ($ "IRQ-VPU1-HALTED"))          (box64 IRQ-VPU1-HALTED         ))
      (cons (cons (mkStr ($ "IRQ-ARM-ADDRESS-ERROR"))    (box64 IRQ-ARM-ADDRESS-ERROR   ))
      (cons (cons (mkStr ($ "IRQ-ARM-AXI-ERROR"))        (box64 IRQ-ARM-AXI-ERROR       ))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-0")) (box64 IRQ-SOFTWARE-INTERRUPT-0))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-1")) (box64 IRQ-SOFTWARE-INTERRUPT-1))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-2")) (box64 IRQ-SOFTWARE-INTERRUPT-2))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-3")) (box64 IRQ-SOFTWARE-INTERRUPT-3))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-4")) (box64 IRQ-SOFTWARE-INTERRUPT-4))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-5")) (box64 IRQ-SOFTWARE-INTERRUPT-5))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-6")) (box64 IRQ-SOFTWARE-INTERRUPT-6))
      (cons (cons (mkStr ($ "IRQ-SOFTWARE-INTERRUPT-7")) (box64 IRQ-SOFTWARE-INTERRUPT-7))
      (cons (cons (mkStr ($ "IRQ-TIMER-0"))              (box64 IRQ-TIMER-0             ))
      (cons (cons (mkStr ($ "IRQ-TIMER-1"))              (box64 IRQ-TIMER-1             ))
      (cons (cons (mkStr ($ "IRQ-TIMER-2"))              (box64 IRQ-TIMER-2             ))
      (cons (cons (mkStr ($ "IRQ-TIMER-3"))              (box64 IRQ-TIMER-3             ))
      (cons (cons (mkStr ($ "IRQ-H264-0"))               (box64 IRQ-H264-0              ))
      (cons (cons (mkStr ($ "IRQ-H264-1"))               (box64 IRQ-H264-1              ))
      (cons (cons (mkStr ($ "IRQ-H264-2"))               (box64 IRQ-H264-2              ))
      (cons (cons (mkStr ($ "IRQ-JPEG"))                 (box64 IRQ-JPEG                ))
      (cons (cons (mkStr ($ "IRQ-ISP"))                  (box64 IRQ-ISP                 ))
      (cons (cons (mkStr ($ "IRQ-USB"))                  (box64 IRQ-USB                 ))
      (cons (cons (mkStr ($ "IRQ-V3D"))                  (box64 IRQ-V3D                 ))
      (cons (cons (mkStr ($ "IRQ-TRANSPOSER"))           (box64 IRQ-TRANSPOSER          ))
      (cons (cons (mkStr ($ "IRQ-MULTICORE-SYNC-0"))     (box64 IRQ-MULTICORE-SYNC-0    ))
      (cons (cons (mkStr ($ "IRQ-MULTICORE-SYNC-1"))     (box64 IRQ-MULTICORE-SYNC-1    ))
      (cons (cons (mkStr ($ "IRQ-MULTICORE-SYNC-2"))     (box64 IRQ-MULTICORE-SYNC-2    ))
      (cons (cons (mkStr ($ "IRQ-MULTICORE-SYNC-3"))     (box64 IRQ-MULTICORE-SYNC-3    ))
      (cons (cons (mkStr ($ "IRQ-DMA-0"))                (box64 IRQ-DMA-0               ))
      (cons (cons (mkStr ($ "IRQ-DMA-1"))                (box64 IRQ-DMA-1               ))
      (cons (cons (mkStr ($ "IRQ-DMA-2"))                (box64 IRQ-DMA-2               ))
      (cons (cons (mkStr ($ "IRQ-DMA-3"))                (box64 IRQ-DMA-3               ))
      (cons (cons (mkStr ($ "IRQ-DMA-4"))                (box64 IRQ-DMA-4               ))
      (cons (cons (mkStr ($ "IRQ-DMA-5"))                (box64 IRQ-DMA-5               ))
      (cons (cons (mkStr ($ "IRQ-DMA-6"))                (box64 IRQ-DMA-6               ))
      (cons (cons (mkStr ($ "IRQ-DMA-7&8"))              (box64 IRQ-DMA-7&8             ))
      (cons (cons (mkStr ($ "IRQ-DMA-9&10"))             (box64 IRQ-DMA-9&10            ))
      (cons (cons (mkStr ($ "IRQ-DMA-11"))               (box64 IRQ-DMA-11              ))
      (cons (cons (mkStr ($ "IRQ-DMA-12"))               (box64 IRQ-DMA-12              ))
      (cons (cons (mkStr ($ "IRQ-DMA-13"))               (box64 IRQ-DMA-13              ))
      (cons (cons (mkStr ($ "IRQ-DMA-14"))               (box64 IRQ-DMA-14              ))
      (cons (cons (mkStr ($ "IRQ-AUX"))                  (box64 IRQ-AUX                 ))
      (cons (cons (mkStr ($ "IRQ-ARM"))                  (box64 IRQ-ARM                 ))
      (cons (cons (mkStr ($ "IRQ-DMA-15"))               (box64 IRQ-DMA-15              ))
      (cons (cons (mkStr ($ "IRQ-HDMI-CEC"))             (box64 IRQ-HDMI-CEC            ))
      (cons (cons (mkStr ($ "IRQ-HVS"))                  (box64 IRQ-HVS                 ))
      (cons (cons (mkStr ($ "IRQ-RPIVID"))               (box64 IRQ-RPIVID              ))
      (cons (cons (mkStr ($ "IRQ-SDC"))                  (box64 IRQ-SDC                 ))
      (cons (cons (mkStr ($ "IRQ-DSI-0"))                (box64 IRQ-DSI-0               ))
      (cons (cons (mkStr ($ "IRQ-PIXEL-VALVE-2"))        (box64 IRQ-PIXEL-VALVE-2       ))
      (cons (cons (mkStr ($ "IRQ-CAMERA-0"))             (box64 IRQ-CAMERA-0            ))
      (cons (cons (mkStr ($ "IRQ-CAMERA-1"))             (box64 IRQ-CAMERA-1            ))
      (cons (cons (mkStr ($ "IRQ-HDMI-0"))               (box64 IRQ-HDMI-0              ))
      (cons (cons (mkStr ($ "IRQ-HDMI-1"))               (box64 IRQ-HDMI-1              ))
      (cons (cons (mkStr ($ "IRQ-PIXEL-VALVE-3"))        (box64 IRQ-PIXEL-VALVE-3       ))
      (cons (cons (mkStr ($ "IRQ-SPI/BSC-SLAVE"))        (box64 IRQ-SPI/BSC-SLAVE       ))
      (cons (cons (mkStr ($ "IRQ-DSI-1"))                (box64 IRQ-DSI-1               ))
      (cons (cons (mkStr ($ "IRQ-PIXEL-VALVE-0"))        (box64 IRQ-PIXEL-VALVE-0       ))
      (cons (cons (mkStr ($ "IRQ-PIXEL-VALVE-1&4"))      (box64 IRQ-PIXEL-VALVE-1&4     ))
      (cons (cons (mkStr ($ "IRQ-CPR"))                  (box64 IRQ-CPR                 ))
      (cons (cons (mkStr ($ "IRQ-SMI"))                  (box64 IRQ-SMI                 ))
      (cons (cons (mkStr ($ "IRQ-GPIO-0"))               (box64 IRQ-GPIO-0              ))
      (cons (cons (mkStr ($ "IRQ-GPIO-1"))               (box64 IRQ-GPIO-1              ))
      (cons (cons (mkStr ($ "IRQ-GPIO-2"))               (box64 IRQ-GPIO-2              ))
      (cons (cons (mkStr ($ "IRQ-GPIO-3"))               (box64 IRQ-GPIO-3              ))
      (cons (cons (mkStr ($ "IRQ-I2C-ALL"))              (box64 IRQ-I2C-ALL             ))
      (cons (cons (mkStr ($ "IRQ-SPI-ALL"))              (box64 IRQ-SPI-ALL             ))
      (cons (cons (mkStr ($ "IRQ-PCM/I2S"))              (box64 IRQ-PCM/I2S             ))
      (cons (cons (mkStr ($ "IRQ-SDHOST"))               (box64 IRQ-SDHOST              ))
      (cons (cons (mkStr ($ "IRQ-PL011-UART-ALL"))       (box64 IRQ-PL011-UART-ALL      ))
      (cons (cons (mkStr ($ "IRQ-ETH-PCIe-L2-ALL"))      (box64 IRQ-ETH-PCIe-L2-ALL     ))
      (cons (cons (mkStr ($ "IRQ-VEC"))                  (box64 IRQ-VEC                 ))
      (cons (cons (mkStr ($ "IRQ-CPG"))                  (box64 IRQ-CPG                 ))
      (cons (cons (mkStr ($ "IRQ-RNG"))                  (box64 IRQ-RNG                 ))
      (cons (cons (mkStr ($ "IRQ-EMMC&2"))               (box64 IRQ-EMMC&2              ))
      (cons (cons (mkStr ($ "IRQ-ETH-PCIe-SECURE"))      (box64 IRQ-ETH-PCIe-SECURE     ))
      (cons (cons (mkStr ($ "IRQ-AVS"))                  (box64 IRQ-AVS                 ))
      (cons (cons (mkStr ($ "IRQ-PCIE-0-INTA"))          (box64 IRQ-PCIE-0-INTA         ))
      (cons (cons (mkStr ($ "IRQ-PCIE-0-INTB"))          (box64 IRQ-PCIE-0-INTB         ))
      (cons (cons (mkStr ($ "IRQ-PCIE-0-INTC"))          (box64 IRQ-PCIE-0-INTC         ))
      (cons (cons (mkStr ($ "IRQ-PCIE-0-INTD"))          (box64 IRQ-PCIE-0-INTD         ))
      (cons (cons (mkStr ($ "IRQ-PCIE-0-MSI"))           (box64 IRQ-PCIE-0-MSI          ))
      (cons (cons (mkStr ($ "IRQ-GENET-0-A"))            (box64 IRQ-GENET-0-A           ))
      (cons (cons (mkStr ($ "IRQ-GENET-0-B"))            (box64 IRQ-GENET-0-B           ))
      (cons (cons (mkStr ($ "IRQ-USB0-XHCI-0"))          (box64 IRQ-USB0-XHCI-0         ))
            $Nil)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))


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
      $USec    (any (cntvct))
      $EndLd   (box64 (i64 _end))
      $MBox    (box64 (hex "4000000"))
      $QuitRst (hex "4000090")
      $Heap    (hex "4000490")
      $Limit   (hex "4000490")
      $Put     (fun (void i8) _putUART1)
      $Get     (fun (i32) _getUART1))

   (newline)
   (outString ($ "$MBox="))    (outWord (hex "4000000")) (newline)
   (outString ($ "$QuitRst=")) (outWord (any $QuitRst)) (newline)
   (outString ($ "$Heap="))    (outWord (val $Heap))    (newline)
   (outString ($ "$Limit="))   (outWord (val $Limit))   (newline)

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

   (setPeri)

   # timestamp?

   # load kern
   # on uncaught err or bye/exit:
   # * reload
   # * hang
   # * call *repl
   (set $Kern (mkStr $Kerns))
   (loadKern))


(de _kern (Exe) (loadKern))

(de _isb (Exe) (isb) $Nil)
(de _wfi (Exe) (wfi) $Nil)
(de _wfe (Exe) (wfe) $Nil)

# r/w, 64-bit
(de _daif (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (daif (int @)) @)
      ((big? @) (daif (val (dig @))) @)
      (T (box64 (any (daif))))) )

(de _daif2 (Exe)
  (if (nil? (eval (cadr Exe)))
      (prog (daif2) @)
      (prog (daif2 T) @)))

# r/o, 32-bit
(de _cnt-frq (Exe)
   (cnt (any (cnt-frq))))

# virt

# r/w, 32-bit
(de _cntv-ctl (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (cntv-ctl (int @)) @)
      ((big? @) (cntv-ctl (val (dig @))) @)
      (T (box64 (any (cntv-ctl))))) )

# r/w, 64-bit
(de _cntv-cval (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (cntv-cval (int @)) @)
      ((big? @) (cntv-cval (val (dig @))) @)
      (T (box64 (any (cntv-cval))))) )

# r/w, 32-bit
(de _cntv-tval (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (cntv-tval (int @)) @)
      ((big? @) (cntv-tval (val (dig @))) @)
      (T (box64 (any (cntv-tval))))) )

# r/o, 64-bit
(de _cntvct (Exe)
   (box64 (any (cntvct))))


# phys

# r/w, 32-bit
(de _cntp-ctl (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (cntp-ctl (int @)) @)
      ((big? @) (cntp-ctl (val (dig @))) @)
      (T (box64 (any (cntp-ctl))))) )

# r/w, 64-bit
(de _cntp-cval (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (cntp-cval (int @)) @)
      ((big? @) (cntp-cval (val (dig @))) @)
      (T (box64 (any (cntp-cval))))) )

# r/w, 32-bit
(de _cntp-tval (Exe)
   (cond
      ((cnt? (eval (cadr Exe))) (cntp-tval (int @)) @)
      ((big? @) (cntp-tval (val (dig @))) @)
      (T (box64 (any (cntp-tval))))) )

# r/o, 64-bit
(de _cntpct (Exe)
   (box64 (any (cntpct))))

(end "base.map")
