# 15jan21 Software Lab. Alexander Burger

(symbols '(llvm))

(local) (openErr closeErr pipeErr sizeErr eofErr badInput badFd
selectErr)

(de NIL openErr (Exe X)
   (err Exe X ($ "Open error: <ERRNO>") null) )

(de NIL closeErr ()
   (err 0 0 ($ "Close error: <ERRNO>") null) )

(de NIL pipeErr (Exe)
   (err Exe 0 ($ "Pipe error: <ERRNO>") null) )

(de NIL sizeErr (Exe)
   (err Exe 0 ($ "Size overflow") null) )

(de NIL eofErr ()
   (err 0 0 ($ "EOF Overrun") null) )

(de NIL badInput ()
   (let S (b8 2)
      (set S (i8 (val $Chr)))
      (set 2 S 0)
      (err 0 0 ($ "Bad input '%s'") S) ) )

(de NIL badFd (Exe Fd)
   (err Exe Fd ($ "Bad FD") null) )

(de NIL selectErr (Exe)
   (err Exe 0 ($ "Select error: <ERRNO>") null) )

(local) (stdinByte getBinary binRead)

(de i32 stdinByte ()
   (call $Get))

(de i32 getBinary ()
   (call $Get))

# Read binary PLIO expression
(de binRead ()
   (case (call $GetBin)
      (NIX $Nil)  # NIL
      (BEG
         (ifn (binRead)
            0
            (let (X (cons @ $Nil)  R (save X))
               (loop
                  (? (=0 (binRead)) @)
                  (? (== @ END) R)
                  (? (== @ -ZERO)  # DOT
                     (ifn (binRead)
                        0
                        (set 2 X (if (== @ END) R @))
                        R ) )
                  (setq X (set 2 X (cons @ $Nil))) ) ) ) )
      (DOT -ZERO)  # DOT -> -ZERO
      (END (i64 @))  # END
      (T
         (if (lt0 @)
            0  # EOF
            (let  # Atom
               (Tag (& @ 3)
                  Cnt (shr @ 2)
                  P (i64* (push NIL NIL ZERO NIL))  # [cnt last name link]
                  Q (link (ofs P 2)) )
               (cond
                  ((== Tag NUMBER)
                     (set P 3)  # 'cnt' for signed number
                     (when (== Cnt 63)  # More than one chunk
                        (loop
                           (loop
                              (when (lt0 (call $GetBin))
                                 (: 1
                                    (drop Q)
                                    (ret 0) ) )
                              (byteNum (i8 @) P)
                              (? (=0 (dec 'Cnt))) )
                           (when (lt0 (setq Cnt (call $GetBin)))
                              (goto 1) )
                           (? (<> Cnt 255)) )
                        (unless Cnt
                           (goto 2) ) )
                     (loop
                        (when (lt0 (call $GetBin))
                           (goto 1) )
                        (byteNum (i8 @) P)
                        (? (=0 (dec 'Cnt))) )
                     (: 2
                        (drop Q
                           (if (cnt? (val Q))
                              @
                              (let S (& (val (dig @)) 1)
                                 (| (half @) (shl S 3)) ) ) ) ) )
                  (T  # Symbol
                     (set P 4)  # 'cnt' for symbol name
                     (when (== Cnt 63)  # More than one chunk
                        (loop
                           (loop
                              (when (lt0 (call $GetBin))
                                 (goto 1) )
                              (byteSym (i8 @) P)
                              (? (=0 (dec 'Cnt))) )
                           (when (lt0 (setq Cnt (call $GetBin)))
                              (goto 1) )
                           (? (<> Cnt 255)) )
                        (unless Cnt
                           (goto 3) ) )
                     (loop
                        (when (lt0 (call $GetBin))
                           (goto 1) )
                        (byteSym (i8 @) P)
                        (? (=0 (dec 'Cnt))) )
                     (: 3
                        (drop Q
                           (let Nm (val Q)
                              (case Tag
                                 (TRANSIENT (consStr Nm))
                                 (INTERN (requestSym Nm))
                                 (T  # External
                                    (when (val $Extn)
                                       (let N
                                          (shl
                                             (& (i64 (+ (objFile Nm) @)) (hex "FFFF"))
                                             24 )  # Mask overflow
                                          (setq Nm
                                             (|
                                                (& Nm (hex "FFF00FFF00FFFFFF"))  # Mask object ID
                                                (&
                                                   (| N (shl N 12))
                                                   (hex "000FF000FF000000") ) ) ) ) )  # Mask file number
                                    (extern Nm) ) ) ) ) ) ) ) ) ) ) ) )

(local) (prCnt binPrint pr)

# Binary print short number
(de void prCnt ((i8 . Tag) Num)
   (let N Num
      (while (setq N (shr N 8))
         (inc 'Tag 4) ) )
   (call $PutBin Tag)
   (loop
      (call $PutBin (i8 Num))
      (? (=0 (setq Num (shr Num 8)))) ) )

# Binary print expression
(de void binPrint (X)
   (cond
      ((cnt? X)
         (tailcall (prCnt (+ NUMBER 4) (shr X 3))) )
      ((big? X)
         (let (Y (pos X)  Z Y  N 8)
            (loop
               (let C (val (dig Z))
                  (? (cnt? (setq Z (val (big Z))))
                     (setq
                        Z (int Z)  # Normalize short
                        C (add C C)  # Get most significant bit of last digit
                        Z (add Z Z @@) ) )
                  (inc 'N 8) ) )
            (when Z  # Significant bits in short number
               (loop
                  (inc 'N)
                  (? (=0 (setq Z (shr Z 8)))) ) )
            (let (M (- N 63)  D (val (dig Y)))
               (when (ge0 M)
                  (setq N 63) )
               (setq Y (val (big Y)))
               (setq X (shr X X 4))  # Sign into highest bit
               (add X X)  # Keep in carry
               (setq D (add D D @@))
               (call $PutBin (i8 (shl N 2)))  # Output tag byte
               (let (S @@  C 8)
                  (loop
                     (loop
                        (call $PutBin (i8 D))  # Output next byte
                        (if (dec 'C)
                           (setq D (shr D 8))
                           (setq C 8)
                           (if (cnt? Y)
                              (setq D (int Y))
                              (setq
                                 D (val (dig Y))
                                 Y (val (big Y)) ) )
                           (setq
                              D (add D D S)
                              S @@ ) )
                        (? (=0 (dec 'N))) )
                     (? (lt0 M))
                     (? (=0 M) (call $PutBin 0))  # Output final zero
                     (when (ge0 (setq M (- (setq N M) 255)))
                        (setq N 255) )
                     (call $PutBin (i8 N)) ) ) ) ) )  # Output next chunk size
      ((nil? X) (call $PutBin NIX))
      ((pair X)
         (call $PutBin BEG)
         (let P (circ X)
            (ifn P
               (loop  # Non-circular
                  (binPrint (car X))
                  (? (nil? (shift X))
                     (call $PutBin END) )
                  (? (atom X)
                     (call $PutBin DOT)
                     (binPrint X) ) )
               (let Flg (== P X)  # Fully circular
                  (loop  # Non-circular part
                     (binPrint (car X))
                     (? (== P (shift X))) )
                  (call $PutBin DOT)
                  (unless Flg
                     (call $PutBin BEG)
                     (loop  # Circular part
                        (binPrint (car X))
                        (? (== P (shift X))) )
                     (call $PutBin DOT) )
                  (call $PutBin END) ) ) ) )
      ((sym? (val (tail X)))  # External symbol
         (let Nm (name (& @ -9))
            (when (val $Extn)
               (let N
                  (shl
                     (& (i64 (- (objFile Nm) @)) (hex "FFFF"))
                     24 )  # Mask overflow
                  (setq Nm
                     (|
                        (& Nm (hex "FFF00FFF00FFFFFF"))  # Mask object ID
                        (&
                           (| N (shl N 12))
                           (hex "000FF000FF000000") ) ) ) ) )  # Mask file number
            (tailcall
               (prCnt (+ EXTERN 4) (shr (shl Nm 2) 6)) ) ) )  # Strip status bits
      ((== (name @) ZERO) (call $PutBin NIX))
      (T
         (let
            (Nm @
               Tag
               (if (findSym X Nm (val $Intern))
                  (i8 INTERN)
                  (i8 TRANSIENT) ) )
            (if (cnt? Nm)
               (prCnt (+ Tag 4) (int Nm))
               (let (Y Nm  N 8)
                  (while (big? (setq Y (val (big Y))))
                     (inc 'N 8) )
                  (setq Y (int Y))
                  (while Y
                     (inc 'N)
                     (setq Y (shr Y 8)) )
                  (let (P (push 0 Nm)  M (- N 63)  C 8)  # [cnt name]
                     (when (ge0 M)
                        (setq N 63) )
                     (call $PutBin (+ Tag (i8 (shl N 2))))
                     (loop
                        (loop
                           (call $PutBin (symByte P))
                           (? (=0 (dec 'N))) )
                        (? (lt0 M))
                        (? (=0 M) (call $PutBin 0))
                        (when (ge0 (setq M (- (setq N M) 255)))
                           (setq N 255) )
                        (call $PutBin (i8 N)) ) ) ) ) ) ) ) )

(de void pr (X)
   (set $PutBin (fun (void i8) _putOutMini))
   (tailcall (binPrint X)) )

(local) (popInFiles tosInFile popOutFiles tosOutFile popErrFiles popCtlFiles)

(de void popInFiles () (outString ($ "popInFiles\n")))

(de void tosInFile ()  (outString ($ "tosInFile\n")))

(de void popOutFiles () (outString ($ "popOutFiles\n")))

(de void tosOutFile ()  (outString ($ "tosOutFile\n")))

(de void popErrFiles ()  (outString ($ "popErrFiles\n")))

(de void popCtlFiles ()  (outString ($ "popCtlFiles\n")))

(local) (read0 getChar skipc comment skip testEsc anonymous rdAtom rdl rdList)

(de read0 (i1))

(de i32 _getStdin ()
  (loop
    (let X (val (i32* (any AUX-MU-LSR-REG)))
      (? (n0 (& X (hex "01")))) @))
  (let Y (val (i32* (any AUX-MU-IO-REG)))
    (call $Put (i8 Y)) # echo
    (set $Chr Y)))

(de i32 getChar ((i32 . C))
   (cond
      ((>= 127 C) C)  # Single byte
      ((== C (hex "FF")) (i32 TOP))  # Infinite
      (T
         (let B
            (ifn (& C (hex "20"))  # Two bytes
               (& C (hex "1F"))  # First byte 110xxxxx
               (let A
                  (ifn (& C (hex "10"))  # Three bytes
                     (& C (hex "0F"))  # First byte 1110xxxx
                     (|  # Four bytes
                        (shl (& C 7) 6)  # First byte 11110xxx
                        (& (call $Get) (hex "3F")) ) )  # 10xxxxxx
                  (| (shl A 6) (& (call $Get) (hex "3F"))) ) )
            (| (shl B 6) (& (call $Get) (hex "3F"))) ) ) ) )

# Skip White Space and Comments
(de i32 skipc ((i32 . C))
   (let Chr (val $Chr)
      (loop
         (while (>= 32 Chr)  # White space
            (when (lt0 (setq Chr (call $Get)))
               (ret Chr) ) )
         (unless (== Chr C)
            (ret Chr) )
         (until (== (setq Chr (call $Get)) (char "\n"))
            (when (lt0 Chr)
               (ret Chr) ) )
         (setq Chr (call $Get)) ) ) )

(de void comment ()
   (let Chr (call $Get)
      (if (== Chr (char "{"))
         (let N 0
            (loop
               (? (lt0 (setq Chr (call $Get))))
               (if
                  (and
                     (== Chr (char "#"))
                     (== (setq Chr (call $Get)) (char "{")) )
                  (inc 'N)
                  (?
                     (and
                        (== Chr (char "}"))
                        (== (setq Chr (call $Get)) (char "#"))
                        (lt0 (dec 'N)) ) ) ) ) )
         (until (== Chr (char "\n"))
            (? (lt0 Chr))
            (setq Chr (call $Get)) ) )
      (call $Get) ) )

(de i32 skip ()
   (loop
      #(outString ($ "skip(0): ")) (outWord (i64 (val $Chr))) (newline)
      (let Chr (val $Chr)
         (when (lt0 Chr)
            #(outString ($ "skip(1): ")) (outWord (i64 (val $Chr))) (newline)
            (ret Chr) )
         (while (>= (char " ") Chr)
            #(outString ($ "skip(2): ")) (outWord (i64 (val $Chr))) (newline)
            (when (lt0 (setq Chr (call $Get)))
               #(outString ($ "skip(3): ")) (outWord (i64 (val $Chr))) (newline)
               (ret Chr) ) )
         (unless (== Chr (char "#"))
            (ret Chr) )
         (comment) ) ) )

(de i1 testEsc ((i32 . Chr))
   (loop
      (? (lt0 Chr) NO)
      (? (== Chr (char "\^"))  # Control character
         (when (== (setq Chr (call $Get)) (char "@"))
            (badInput) )
         (set $Chr
            (if (== Chr (char "?"))
               127
               (& Chr (hex "1F")) ) )
         YES )
      (? (<> Chr (char "\\"))  # No Backslash
         (set $Chr (getChar Chr))
         YES )
      (? (<> (char "\n") (setq Chr (call $Get)))  # Backslash: Skip '\'
         (case Chr
            ((char "b") (set $Chr (char "\b")))
            ((char "n") (set $Chr (char "\n")))
            ((char "r") (set $Chr (char "\r")))
            ((char "t") (set $Chr (char "\t")))
            (T
               (when (and (>= Chr (char "0")) (>= (char "9") Chr))
                  (dec 'Chr (char "0"))
                  (until (== (call $Get) (char "\\"))
                     (unless
                        (and
                           (>= (val $Chr) (char "0"))
                           (>= (char "9") (val $Chr)) )
                        (badInput) )
                     (setq Chr
                        (+ (* Chr 10) (- (val $Chr) (char "0"))) ) ) )
               (set $Chr Chr) ) )
         YES )
      (loop
         (setq Chr (call $Get))
         (?
            (and
               (<> Chr (char " "))
               (<> Chr (char "\t")) ) ) ) ) )

(de anonymous (Nm)
   (let P (push 0 Nm)  # [cnt name]
      (unless (== (symByte P) (char "$"))  # Starting with '$'
         (ret 0) )
      (let B (- (symByte P) (char "0"))
         (unless (>= 7 B)  # Octal Digit
            (ret 0) )
         (let N (i64 B)
            (loop
               (? (=0 (symByte P))
                  (sym (shl N 4)) )  # Make symbol pointer
               (? (> (- @ (char "0")) 7) 0)
               (setq N (| (i64 @) (shl N 3))) ) ) ) ) )

(de rdAtom ((i32 . Chr))
   (let
      (Int (save (val $Intern))  # Current symbol namespaces
         P (push 4 NIL ZERO NIL)  # [cnt last name link]
         C (val $Chr) )
      (when
         (and
            (== Chr (char "%"))
            (== C (char "~")) )
         (when (nil? (cdr Int))
            (symNspErr 0 $rem) )
         (set $Intern @)
         (setq Chr (call $Get)  C (call $Get)) )
      (link (ofs P 2))
      (charSym Chr P)  # Pack first char
      (setq Chr C)
      (while (ge0 Chr)
         (if (== Chr (char "~"))  # Namespace
            (let S (requestSym (val 3 P))  # Find or create symbol
               (needNsp 0 S)
               (set (set $Intern (any $Cell)) S)  # Switch symbol namespace
               (set P 4  3 P ZERO) )  # Build new name
            (? (strchr2 $Delim Chr))
            (when (== Chr (char "\\")) (setq Chr (call $Get)))
            (charSym Chr P) )
         (setq Chr (call $Get)) )
      (prog1
         (let (Nm (val 3 P)  L (val $Intern))
            (cond
               ((== Nm ZERO) (badInput))
               ((== L (any $Cell))
                  (intern 0 $Nil Nm (cdar (car @)) $Nil NO) )
               ((symToNum Nm (int (val $Scl)) (char ".") 0) @)
               ((anonymous Nm) @)
               ((and (== (car L) $priv) (nil? (cdr L)))
                  (intern (consSym Nm $Nil) 0 Nm $PrivT $Nil YES) )
               (T
                (prog1
                  (requestSym Nm)) )))
         (set $Intern Int) ) ) )

(de void rdl (R P)
   (loop
      (? (== (skip) (char ")"))
         (call $Get) )
      (? (== @ (char "]")))
      (cond
         ((== @ (char "."))
            (? (strchr2 $Delim (call $Get))
               (setq P
                  (set 2 P
                     (if
                        (or
                           (== (skip) (char ")"))
                           (== @ (char "]")) )
                        R
                        (read0 NO) ) ) )
               (cond
                  ((== (skip) (char ")"))
                     (call $Get) )
                  ((<> (val $Chr) (char "]"))
                     (err 0 P ($ "Bad dotted pair") null) ) ) )
            (setq P
               (set 2 P (cons (rdAtom (char ".")) $Nil)) ) )
         ((== @ (char "~"))
            (call $Get)
            (set 2 P
               (eval
                  (set 2 P (read0 NO)) ) )
            (while (pair (cdr P))
               (shift P) ) )
         (T
            (let (X (read0 NO)
                  Y (cons X $Nil))
              (prog1
                (setq P
                  (set 2 P Y) )))))))


(de rdList ()
   (stkChk 0)
   (call $Get)
   (loop
      (? (== (skip) (char ")"))  # Empty list
         (call $Get)
         $Nil )
      (? (== @ (char "]")) $Nil)  # Empty list
      (? (<> @ (char "~"))  # Read macro
         (let R (save (cons (read0 NO) $Nil))
            (rdl R R)
            R ) )
      (call $Get)
      (let R (let X (save (read0 NO))
                (eval X))
         (? (pair R)
            (let L (save R)
               (while (pair (cdr L))
                  (setq L @) )
               (rdl R L) )
            R ) ) ) )

(de read0 ((i1 . Top))
   (let C (skip)
      #(outString ($ "read0: ")) (outWord (i64 (val $Chr))) (newline)
      (cond
         ((lt0 C)
            (unless Top (eofErr))
            $Nil )
         ((== C (char "("))
            (prog1
               (rdList)
               (and
                  Top
                  (== (val $Chr) (char "]"))
                  (call $Get))))
         ((== C (char "["))
            (let X (rdList)
               (unless (== (val $Chr) (char "]"))
                  (err 0 X ($ "Super parentheses mismatch") null) )
               (call $Get)
               X ) )
         ((== C (char "'"))
            (call $Get)
            (cons $Quote (read0 Top)) )
         ((== C (char ","))
            (call $Get)
            (let X (read0 Top)
               (if (t? (val $Uni))
                  X
                  (save X
                     (if (pair (idxPut $Uni X))
                        (car @)
                        X ) ) ) ) )
         ((== C (char "`"))
            (call $Get)
            (let E (read0 Top)
               (save E
                  (eval E) ) ) )
         ((== C (char "\""))
            (if (== (setq C (call $Get)) (char "\""))
               (prog
                (call $Get) $Nil)  # Empty string
               (unless (testEsc C) (eofErr))
               (let
                  (P (push 4 NIL ZERO NIL)  # [cnt last name link]
                     Q (link (ofs P 2)) )
                  (loop
                     (charSym (val $Chr) P)
                     (? (== (setq C (call $Get)) (char "\"")))
                     (unless (testEsc C) (eofErr)) )
                  (call $Get)  # Skip "\""
                  (drop Q (intern 0 0 (val Q) $Transient $Nil NO)))))
         ((== C (char "{"))
            (prog1
               (if (== (setq C (call $Get)) (char "}"))
                  (consSym ZERO $Nil)  # Empty: New anonymous symbol
                  (let F (i32 0)  # File number
                     (while (>= C (char "@"))
                        (when (> C (char "O"))  # A-O range
                           (badInput) )
                        (setq
                           F (| (shl F 4) (- C (char "@")))
                           C (call $Get) ) )
                     (let N 0  # Id
                        (loop
                           (unless (and (>= C (char "0")) (>= (char "7") C))
                              (badInput) )
                           (setq N
                              (|
                                 (shl N 3)
                                 (i64 (- C (char "0"))) ) )
                           (? (== (setq C (call $Get)) (char "}"))) )
                        (extern (extNm F N)) ) ) )
               (call $Get) ) )  # Skip "}"
         ((or (== C (char ")")) (== C (char "]")) (== C (char "~")))
            (badInput) )
         (T
            (when (== C (char "\\"))
               (call $Get) )
            (setq C (val $Chr))
            (call $Get)
            (rdAtom C)))))

(local) (read1 noToken token)

(de read1 ((i32 . End))
   (unless (val $Chr)
      (call $Get) )
   #(outString ($ "\nread1: ")) (outWord (i64 (val $Chr))) (newline)
   (if (== End (val $Chr))
      $Nil
      (read0 YES) ) )

(inline noToken (C Set)
   (not
      (or
         (== C (char "\\"))
         (and (>= (char "z") C) (>= C (char "a")))
         (and (>= (char "Z") C) (>= C (char "A")))
         (strchr2 Set C) ) ) )

(de token (Set (i32 . Cmt))
   (let C (val $Chr)
      (unless C
         (setq C (call $Get)) )
      (cond
         ((lt0 (skipc Cmt)) 0)  # Skip white space and comments
         ((== (setq C @) (char "\""))
            (cond
               ((== (setq C (call $Get)) (char "\""))  # Empty string
                  (call $Get)
                  $Nil )
               ((not (testEsc C)) $Nil)
               (T
                  (let
                     (Y (cons (mkChar (val $Chr)) $Nil)
                        R (save Y) )
                     (loop
                        (? (== (setq C (call $Get)) (char "\""))
                           (call $Get) )  # Skip "\""
                        (? (not (testEsc C)))
                        (setq Y
                           (set 2 Y (cons (mkChar (val $Chr)) $Nil)) ) )
                     R ) ) ) )
         ((and (>= (char "9") C) (>= C (char "0")))
            (let P (push 4 NIL ZERO NIL)  # [cnt last name link]
               (link (ofs P 2) T)
               (loop
                  (byteSym (i8 C) P)
                  (?
                     (and
                        (<> (setq C (call $Get)) (char "."))
                        (or (> (char "0") C) (> C (char "9"))) ) ) )
               (symToNum
                  (val 3 P)
                  (int (val $Scl))
                  (char ".")
                  0 ) ) )
         (T
            (let
               (Nm (xName 0 Set)
                  S (bufString Nm (b8 (bufSize Nm))) )
               (if
                  (or
                     (== C (char "+"))
                     (== C (char "-"))
                     (noToken C S) )
                  (prog1
                     (mkChar (getChar C))
                     (call $Get) )
                  (when (== C (char "\\"))
                     (call $Get) )
                  (let P (push 4 NIL ZERO NIL)  # [cnt last name link]
                     (link (ofs P 2) T)
                     (loop
                        (byteSym (i8 C) P)
                        (?
                           (and
                              (noToken (setq C (call $Get)) S)
                              (or (> (char "0") C) (> C (char "9"))) ) )
                        (when (== C (char "\\"))
                           (call $Get) ) )
                     (requestSym (val 3 P)) ) ) ) ) ) ) )

# (read ['sym1 ['sym2]]) -> any
(de _read (Exe)
   (let X (cdr Exe)
      (prog1
         (if (atom X)
            (read1 0)
            (let Y (save (needSymb Exe (eval (++ X))))
               (if (token Y (firstChar (needSymb Exe (eval (car X)))))
                  @
                  $Nil ) ) )
         (and
            (== (val $Chr) (char "\n"))
            (set $Chr 0) ) ) ) )

# (key ['cnt]) -> sym
(de _key (Exe)
  (let C (stdinByte)
      (mkChar
        (cond
            ((>= 127 C) C)  # Single byte
            ((== C (hex "FF")) (i32 TOP))  # Infinite
            (T
              (let B
                  (ifn (& C (hex "20"))  # Two bytes
                    (& C (hex "1F"))  # First byte 110xxxxx
                    (let A
                        (ifn (& C (hex "10"))  # Three bytes
                          (& C (hex "0F"))  # First byte 1110xxxx
                          (|  # Four bytes
                              (shl (& C 7) 6)  # First byte 11110xxx
                              (& (stdinByte) (hex "3F")) ) )  # 10xxxxxx
                        (| (shl A 6) (& (stdinByte) (hex "3F"))) ) )
                  (| (shl B 6) (& (stdinByte) (hex "3F"))) ) ) ) ) ))

# (peek) -> sym
(de _peek (Exe)
   (let Chr (val $Chr)
      (unless Chr
         (setq Chr (call $Get)) )
      (if (lt0 Chr) $Nil (mkChar Chr)) ) )

# (char) -> sym
# (char 'cnt) -> sym
# (char T) -> sym
# (char 'sym) -> cnt
(de _char (Exe)
   (let X (cdr Exe)
      (cond
         ((atom X)
            (let Chr (val $Chr)
               (unless Chr
                  (setq Chr (call $Get)) )
               (prog1
                  (if (lt0 Chr)
                     $Nil
                     (mkChar (getChar Chr)) )
                  (call $Get) ) ) )
         ((cnt? (eval (car X)))
            (if (int @)
               (mkChar (i32 @))
               $Nil ) )
         ((t? @) (mkChar TOP))
         ((symb? @) (cnt (i64 (firstChar @))))
         (T (atomErr Exe @)) ) ) )

# (skip ['any]) -> sym
(de _skip (Exe)
   (if (lt0 (skipc (firstChar (evSym (cdr Exe)))))
      $Nil
      (mkChar @) ) )

# (eol) -> flg
(de _eol (Exe)
   (let C (if (val $Chr) @ (call $Get))
      (if (or (le0 C) (== C (char "\n")))
         $T
         $Nil ) ) )

# (eof ['flg]) -> flg
(de _eof (Exe)
   (nond
      ((nil? (eval (cadr Exe)))
         (set $Chr -1)
         $T )
      ((=0 (val $Chr))
         (if (lt0 @) $T $Nil) )
      (NIL
         (if (lt0 (call $Get)) $T $Nil) ) ) )

# (from 'any ..) -> sym
(de _from (Exe)
   (let
      (X (cdr Exe)
         N 1
         Y (evSym X)
         Nm (xName Exe Y)
         L
         (link
            (push Y NIL 0  # [sym link ix str]
               (any (bufString Nm (b8 (bufSize Nm)))) ) )
         P L )
      (while (pair (shift X))
         (setq
            Y (evSym X)
            Nm (xName Exe Y)
            L
            (link
               (push Y NIL 0  # [sym link ix str]
                  (any (bufString Nm (b8 (bufSize Nm)))) ) ) )
         (inc 'N) )
      (unless (val $Chr)
         (call $Get) )
      (while (ge0 (val $Chr))
         (let (B (i8 @)  Q (i64* L)  I N)
            (loop
               (loop
                  (let S (ofs (i8* (val 4 Q)) (val 3 Q))
                     (when (== B (val S))  # Bytes match
                        (set 3 Q (inc (val 3 Q)))  # Increment index
                        (? (val 2 S))  # Not end of string
                        (call $Get) # Skip next input byte
                        (drop P)
                        (ret (val Q)) ) )  # Return matched symbol
                  (? (=0 (val 3 Q)))  # Still at beginning of string
                  (let S (ofs (i8* (val 4 Q)) 1)  # Pointer to second byte
                     (while (set 3 Q (dec (val 3 Q)))  # Decrement index
                        (? (=0 (memcmp (i8* (val 4 Q)) S @)))
                        (inc 'S) ) ) )
               (? (=0 (dec 'I)))
               (setq Q (i64* (val 2 Q))) ) )
         (call $Get) )
      (drop P)
      $Nil ) )

# (till 'any ['flg]) -> lst|sym
(de _till (Exe)
   (let
      (X (cdr Exe)
         Nm (xName Exe (evSym X))
         S (bufString Nm (b8 (bufSize Nm))) )
      (let C (if (val $Chr) @ (call $Get))
         (cond
            ((or (lt0 C) (strchr2 S C))
               $Nil )
            ((nil? (eval (cadr X)))
               (let
                  (Y (cons (mkChar (getChar C)) $Nil)
                     R (save Y) )
                  (until
                     (or
                        (le0 (setq C (call $Get)))
                        (strchr2 S C) )
                     (setq Y
                        (set 2 Y (cons (mkChar C) $Nil)) ) )
                  R ) )
            (T
               (let
                  (P (push 4 NIL ZERO NIL)  # [cnt last name link]
                     Q (link (ofs P 2)) )
                  (loop
                     (charSym (getChar C) P)
                     (? (le0 (setq C (call $Get))))
                     (? (strchr2 S C)) )
                  (drop Q
                     (consStr (val 3 P)) ) ) ) ) ) ) )

(local) eol

(de i1 eol ((i32 . C))
   (cond
      ((lt0 C) YES)
      ((== C (char "\n"))
         (set $Chr 0)
         YES )
      ((== C (char "\r"))
         (when (== (call $Get) (char "\n"))
            (set $Chr 0) )
         YES )
      (T NO) ) )

# (line 'flg ['cnt ..]) -> lst|sym
(de _line (Exe)
   (let C (val $Chr)
      (unless C
         (setq C (call $Get)) )
      (if (eol C)
         $Nil
         (let X (cdr Exe)
            (cond
               ((nil? (eval (++ X)))
                  (let  # List of characters
                     (Y (cons (mkChar (getChar C)) $Nil)
                        R (save Y) )
                     (when (pair X)
                        (let Z (set Y (cons (car Y) $Nil))
                           (loop
                              (let N (evCnt Exe X)
                                 (while (gt0 (dec 'N))
                                    (when (eol (setq C (call $Get)))
                                       (ret R) )
                                    (setq Z
                                       (set 2 Z (cons (mkChar (getChar C)) $Nil)) ) ) )
                              (? (atom (shift X)))
                              (when (eol (setq C (call $Get)))
                                 (ret R) )
                              (setq Y
                                 (set 2 Y
                                    (cons
                                       (setq Z (cons (mkChar (getChar C)) $Nil))
                                       $Nil ) ) ) ) ) )
                     (until (eol (setq C (call $Get)))
                        (setq Y
                           (set 2 Y (cons (mkChar (getChar C)) $Nil)) ) )
                     R ) )
               ((atom X)  # Pack single string
                  (let
                     (P (push 4 NIL ZERO NIL)  # [cnt last name link]
                        Q (link (ofs P 2)) )
                     (loop
                        (charSym (getChar C) P)
                        (? (eol (setq C (call $Get)))) )
                     (drop Q
                        (consStr (val 3 P)) ) ) )
               (T
                  (let
                     (N (evCnt Exe X)
                        P (push 4 NIL ZERO NIL)  # [cnt last name link]
                        Q (link (ofs P 2) T) )
                     (loop
                        (charSym (getChar C) P)
                        (when (eol (setq C (call $Get)))
                           (ret (cons (consStr (val Q)) $Nil)) )
                        (? (=0 (dec 'N))) )
                     (let
                        (Y (cons (consStr (val Q)) $Nil)
                           R (save Y) )
                        (while (pair (shift X))
                           (setq N (evCnt Exe X))
                           (set P 4  3 P ZERO)
                           (loop
                              (charSym (getChar C) P)
                              (when (eol (setq C (call $Get)))
                                 (set 2 Y (cons (consStr (val Q)) $Nil))
                                 (ret R) )
                              (? (=0 (dec 'N))) )
                           (setq Y
                              (set 2 Y (cons (consStr (val Q)) $Nil)) ) )
                        (loop
                           (setq Y
                              (set 2 Y (cons (mkChar (getChar C)) $Nil)) )
                           (? (eol (setq C (call $Get)))) )
                        R ) ) ) ) ) ) ) )

# (echo ['cnt ['cnt]] | ['sym ..]) -> sym
(de _echo (Exe)
   (let (X (cdr Exe)  Y (eval (++ X)))
      (cond
         ((and (nil? Y) (atom X))
            (let C (if (val $Chr) @ (call $Get))
               (until (lt0 C)
                  (call $Put (i8 C))
                  (setq C (call $Get)) ) )
            $T )
         ((num? Y)
            (let N (xCnt Exe Y)
               (when (pair X)
                  (let C (evCnt Exe X)
                     (while (ge0 (dec 'N))
                        (when (lt0 (call $Get))
                           (ret $Nil) ) )
                     (setq N C) ) )
               (while (ge0 (dec 'N))
                  (when (lt0 (call $Get))
                     (ret $Nil) )
                  (call $Put (i8 @)) )
               (set $Chr 0)
               $T ) )
         ((pair Y) (argErr Exe Y))
         (T  # sym
            (let
               (M (i64* null)
                  N 1
                  Nm (xName Exe Y)
                  L
                  (link
                     (push Y NIL 0  # [sym link ix str]
                        (any (bufString Nm (b8 (bufSize Nm)))) ) )
                  P L )
               (while (pair X)
                  (setq
                     Y (evSym (++ X))
                     Nm (xName Exe Y)
                     L
                     (link
                        (push Y NIL 0  # [sym link ix str]
                           (any (bufString Nm (b8 (bufSize Nm)))) ) ) )
                  (inc 'N) )
               (unless (val $Chr)
                  (call $Get) )
               (while (ge0 (val $Chr))
                  (let
                     (B (i8 @)
                        Q (i64* L)
                        I N
                        OutM M
                        OutC (if M (val 3 M) 0) )
                     (loop
                        (loop
                           (let S (ofs (i8* (val 4 Q)) (val 3 Q))
                              (when (== B (val S))  # Bytes match
                                 (set 3 Q (inc (val 3 Q)))  # Increment index
                                 (? (val 2 S)  # Not end of string
                                    (unless (and M (>= (val 3 M) (val 3 Q)))
                                       (setq M Q) ) )
                                 (when OutM
                                    (setq S (i8* (val 4 OutM)))
                                    (dec 'OutC (val 3 Q))
                                    (until (lt0 OutC)
                                       (call $Put (val S))
                                       (inc 'S)
                                       (dec 'OutC) ) )
                                 (set $Chr 0)  # Clear look ahead
                                 (drop P)
                                 (ret (val Q)) ) )  # Return matched symbol
                           (? (=0 (val 3 Q)))  # Still at beginning of string
                           (let S (ofs (i8* (val 4 Q)) 1)  # Pointer to second byte
                              (while (set 3 Q (dec (val 3 Q)))  # Decrement index
                                 (? (=0 (memcmp (i8* (val 4 Q)) S @)))
                                 (inc 'S) ) )
                           (when (== Q M)  # On current max
                              (setq M (i64* null))
                              (let (Z (i64* L)  J N)
                                 (loop
                                    (when (val 3 Z)
                                       (unless (and M (>= (val 3 M) (val 3 Z)))
                                          (setq M Z) ) )
                                    (? (=0 (dec 'J)))
                                    (setq Z (i64* (val 2 Z))) ) ) ) )
                        (? (=0 (dec 'I)))
                        (setq Q (i64* (val 2 Q))) )
                     (cond
                        ((=0 M)
                           (when OutM
                              (let (S (i8* (val 4 OutM))  C OutC)
                                 (loop
                                    (call $Put (val S))
                                    (inc 'S)
                                    (? (=0 (dec 'C))) ) ) )
                           (call $Put B) )
                        (OutM
                           (let S (i8* (val 4 OutM))
                              (dec 'OutC (val 3 M))
                              (until (lt0 OutC)
                                 (call $Put (val S))
                                 (inc 'S)
                                 (dec 'OutC) ) ) ) ) )
                  (call $Get) )
               (drop P)
               $Nil ) ) ) ) )

(de void _putOutUart ((i8 . B))
  # pl011
  (loop
    (let X (val (i32* (any UART0-FR)))
      (? (=0 (& X (hex "20")))) @))
  (set (i32* (any UART0-DR)) (i32 B)))

(de void _putOutMini ((i8 . B))
  # mini
  (loop
    (let X (val (i32* (any AUX-MU-LSR-REG)))
      (? (n0 (& X (hex "20")))) @))
  (set (i32* (any AUX-MU-IO-REG)) (i32 B)))

(local) (newline space)

(de void newline ()
   (call $Put (char "\n")) )

(de void space ()
   (call $Put (char " ")) )

(local) (outWord outNum outOct outAo bufAo prExt)

# Output decimal number
(de void outWord ((i64 . N))
   (when (> N 9)
      (outWord (/ N 10))
      (setq N (% N 10)) )
   (call $Put (+ (i8 N) (char "0"))) )

(de void outNum (X)
   (when (sign? X)
      (call $Put (char "-")) )
   (outWord (shr (i64 X) 4)) )

# Output octal number
(de void outOct ((i64 . N))
   (when (> N 7)
      (outOct (shr N 3))
      (setq N (& N 7)) )
   (call $Put (+ (i8 N) (char "0"))) )

# Output A-O encoding
(de void outAo ((i32 . N))
   (when (> N 15)
      (outAo (shr N 4))
      (setq N (& N 15)) )
   (call $Put (+ (i8 N) (char "@"))) )

# Append A-O encoding to buffer
(de i8* bufAo ((i8* . P) (i32 . N))
   (when (> N 15)
      (setq
         P (bufAo P (shr N 4))
         N (& N 15) ) )
   (set P (+ (i8 N) (char "@")))
   (inc P) )

# Output external symbol name
(de void prExt (Nm)
   (when (objFile Nm)
      (outAo @) )
   (outOct (objId Nm)) )

(local) (outString prName prSym printName printSym)

# Output string
(de void outString ((i8* . S))
   (while (val S)
      (call $Put @)
      (inc 'S) ) )

(de void prName (Nm)
   (let P (push 0 Nm)  # [cnt name]
      (while (symByte P)
         (call $Put @) ) ) )

(de void prSym (Sym)
   (prName (name (val (tail Sym)))) )

(de void printName (Nm)
   (ifn (== Nm (hex "2E2"))  # Dot
      (let (P (push 0 Nm)  B (symByte P))  # [cnt name]
         (when (== B (char "#"))
            (call $Put (char "\\")) )  # Escape leading hash
         (loop
            (when
               (or
                  (== B (char "\\"))
                  (strchr2 $Delim (i32 B)) )
               (call $Put (char "\\")) )  # Escape backslash and delimiters
            (call $Put B)
            (? (=0 (setq B (symByte P))) ) ) )
      (call $Put (char "\\"))
      (call $Put (char ".")) ) )

(de void printSym (Sym)
   (printName (name (val (tail Sym)))) )

(local) (print prin)

(de void print (X)
   (sigChk 0)
   (cond
      ((cnt? X)
        (outNum X))
      ((big? X)
        (fmtNum X -1 0 0 null))
      ((sym? X)
         (cond
            ((sym? (val (tail X)))  # External
               (call $Put (char "{"))
               (prExt (name (& @ -9)))
               (call $Put (char "}")) )
            ((== (name @) ZERO)  # Anonymous
               (call $Put (char "$"))
               (outOct (int X)) )
            (T
               (let Nm @
                  (ifn (== X (isIntern Nm $PrivT))
                     (let (Lst (val $Intern)  F NO)  # Search namespaces
                        (loop
                           (? (atom Lst) # Transient
                              (call $Put (char "\""))
                              (let (P (push 0 Nm)  B (symByte P))  # [cnt name]
                                 (loop
                                    (cond
                                       ((or
                                             (== B (char "\\"))
                                             (== B (char "\^"))
                                             (== B (char "\"")) )
                                          (call $Put (char "\\")) )
                                       ((== B 127)  # DEL
                                          (call $Put (char "\^"))  # Print ^?
                                          (setq B (char "?")) )
                                       ((> 32 B)  # White space
                                          (call $Put (char "\^"))  # Escape with caret
                                          (setq B (| B 64)) ) )
                                    (call $Put B)
                                    (? (=0 (setq B (symByte P))) ) ) )
                              (call $Put (char "\"")) )
                           (let Nsp (car Lst)
                              (when (isIntern Nm (cdar Nsp))
                                 (? (== @ X)  # Internal
                                    (when F  # Found in other namespace
                                       (printSym Nsp)
                                       (call $Put (char "~")) )
                                    (printName Nm) )
                                 (setq F YES) ) )
                           (shift Lst) ) )
                     (outString ($ "priv~"))  # Found in 'priv'
                     (printName Nm) ) ) ) ) )
      ((and (== (car X) $Quote) (<> X (cdr X)))
         (call $Put (char "'"))
         (print (cdr X)) )
      (T
         (stkChk 0)
         (call $Put (char "("))
         (let P (circ X)
            (ifn P
               (loop  # Non-circular
                  (print (car X))
                  (? (nil? (shift X)))
                  (? (atom X)
                     (outString ($ " . "))
                     (print X) )
                  (space) )
               (let Flg (== P X)  # Fully circular
                  (loop  # Non-circular part
                     (print (car X))
                     (space)
                     (? (== P (shift X))) )
                  (call $Put (char "."))
                  (unless Flg
                     (space)
                     (call $Put (char "("))
                     (loop  # Circular part
                        (print (car X))
                        (space)
                        (? (== P (shift X))) )
                     (call $Put (char "."))
                     (call $Put (char ")")) ) ) ) )
         (call $Put (char ")")) ) ) )

(de void prin (X)
   (sigChk 0)
   (unless (nil? X)
      (cond
         ((cnt? X) (outNum X))
         ((big? X) (fmtNum X -1 0 0 null))
         ((pair X)
            (stkChk 0)
            (loop
               (prin (car X))
               (? (nil? (shift X)))
               (? (atom X) (prin X)) ) )
         ((sym? (val (tail X)))
            (call $Put (char "{"))
            (prExt (name (& @ -9)))
            (call $Put (char "}")) )
         (T (prName (name @))) ) ) )

# (prin 'any ..) -> any
(de _prin (Exe)
   (let X (cdr Exe)
      (loop
         (let Y (eval (++ X))
            (prin Y)
            (? (atom X) Y) ) ) ) )

# (prinl 'any ..) -> any
(de _prinl (Exe)
   (prog1 (_prin Exe) (newline)) )

# (space ['cnt]) -> cnt
(de _space (Exe)
   (let X (eval (cadr Exe))
      (ifn (nil? X)
         (let N (xCnt Exe X)
            (while (ge0 (dec 'N))
               (space) )
            X )
         (space)
         ONE ) ) )

# (print 'any ..) -> any
(de _print (Exe)
   (let X (cdr Exe)
      (loop
         (let Y (eval (++ X))
            (print Y)
            (? (atom X) Y)
            (space) ) ) ) )

# (printsp 'any ..) -> any
(de _printsp (Exe)
   (prog1 (_print Exe) (space)) )

# (println 'any ..) -> any
(de _println (Exe)
   (prog1 (_print Exe) (newline)) )

# (ext 'cnt . prg) -> any
(de _ext (Exe)
   (let (X (cdr Exe)  N (evCnt Exe X)  Old (val $ExtN))
      (set $ExtN (i32 N))
      (prog1
         (run (cdr X))
         (set $ExtN Old) ) ) )

(local) (getPlio putPlio)

(de i32 getPlio ()
   (let P (val $Ptr)
      (set $Ptr (inc P))
      (i32 (val P)) ) )

(de void putPlio ((i8 . B))
   (let P (val $Ptr)
      (set P B)
      (when (== (set $Ptr (inc P)) (val $End))
         (sizeErr 0) ) ) )

# (plio 'num) -> any
# (plio 'num 'cnt 'any) -> cnt
(de _plio (Exe)
   (let
      (X (cdr Exe)
         P
         (i8*
            (if (cnt? (needNum Exe (eval (++ X))))
               (int @)
               (val (dig @)) ) ) )
      (set
         $Extn (val $ExtN)  # Set external symbol offset
         $Ptr P )
      (if (pair X)
         (let (N (evCnt Exe X)  Y (eval (car (shift X))))
            (set
               $PutBin (fun (void i8) putPlio)
               $End (ofs P N) )
            (binPrint Y)
            (cnt (- (val $Ptr) P)) )
         (set $GetBin (fun (i32) getPlio))
         (if (binRead) @ $Nil) ) ) )

# (rd ['sym]) -> any
# (rd 'cnt) -> num | NIL
(de _rd (Exe)
   (let X (save (eval (cadr Exe)))
      (cond
         ((lt0 ((inFile (val $InFile)) fd)) $Nil)
         ((num? X)
            (let
               (P (push 3 NIL ZERO NIL)  # [cnt last name link]
                  Q (link (ofs P 2))
                  Cnt (int X) )
               (cond
                  ((=0 Cnt) $Nil)
                  ((sign? X)  # Little endian
                     (loop
                        (when (lt0 (getBinary))
                           (: 1 (ret $Nil)) )
                        (byteNum (i8 @) P)
                        (? (=0 (dec 'Cnt))) )
                     (if (cnt? (val Q))
                        (twice @)
                        (zapZero @) ) )
                  (T
                     (loop
                        (when (lt0 (getBinary))
                           (goto 1) )
                        (set Q
                           (addu
                              (cnt (i64 @))
                              (set Q (mulu (val Q) (hex "1002"))) ) )  # Multiply number by 256
                        (? (=0 (dec 'Cnt))) )
                     (if (cnt? (val Q))
                        @
                        (zapZero @) ) ) ) ) )
         (T
            (set
               $GetBin (fun (i32) getBinary)
               $Extn (val $ExtN) )
            (if (binRead) @ X) ) ) ) )

# (pr 'any ..) -> any
(de _pr (Exe)
   (let X (cdr Exe)
      (loop
         (let Y (eval (++ X))
            (set $Extn (val $ExtN))  # Set external symbol offset
            (pr Y)  # Print binary
            (? (atom X) Y) ) ) ) )

# (wr 'cnt ..) -> cnt
(de _wr (Exe)
   (let X (cdr Exe)
      (loop
         (let N (eval (++ X))
            (_putOutMini (i8 (int N)))
            (? (atom X) N) ) ) ) )

(local) (getParse parse)

(de i32 getParse ()
   (let P (val $Parser)
      (set $Chr
         (if (i32 (symByte P))
            @
            (let C (val 3 P) # term chars
               #(outString ($ "getParse: ")) (outWord C) (newline)
               (set 3 P (shr C 8))
               (if C (i32 (i8 C)) -1) ) ) ) ) )

(de parse (Nm (i1 . Skip) Eof Set)
   (let
      (Chr (val $Chr)
         Get (val (i8** $Get))
         Pars (val $Parser) )
      (set
         $Chr 0
         $Get (fun (i32) getParse)
         $Parser (push 0 (save Nm) Eof) )
      (when Skip
         (getParse) )
      (prog1
         (cond
            ((=0 Set) (rdList))
            ((== 1 Set) (read0 YES))
            ((=0 (token Set 0)) $Nil)
            (T
               (let (R (save (cons @ $Nil))  P R)
                  (while (token Set 0)
                     (setq P (set 2 P (cons @ $Nil))) )
                  R ) ) )
         (set
            $Parser Pars
            (i8** $Get) Get
            $Chr Chr ) ) ) )

(de void putString ((i8 . B))
   (byteSym B (val $StrP)) )

(de void begString ((i64* . P))  # [cnt last name link fun ptr]
   (set 6 P (i64 (val $StrP)))
   (link (ofs (set $StrP P) 2))
   (set
      5 P (val (i64* $Put))
      $Put (fun (void i8) putString) ) )

(de void tglString ((i64* . P))
   (xchg (any (ofs P 4)) (any (i64* $Put))) )

(de endString ()
   (let (P (val $StrP)  Q (ofs P 2))
      (set
         (i64* $Put) (val 5 P)
         $StrP (i64* (val 6 P)) )
      (drop Q
         (consStr (val Q)) ) ) )

# (any 'sym) -> any
(de _any (Exe)
   (cond
      ((nil? (needSymb Exe (eval (cadr Exe)))) @)
      ((sym? (val (tail @))) $Nil)
      (T (parse (name @) YES (hex "20") 1)) ) )  # Blank, EOF

# (sym 'any) -> sym
(de _sym (Exe)
   (let X (eval (cadr Exe))
      (begString (push 4 NIL ZERO NIL NIL NIL))  # [cnt last name link fun ptr]
      (print X)
      (endString) ) )

# (str 'sym ['sym1]) -> lst
# (str 'lst) -> sym
(de _str (Exe)
   (let (X (cdr Exe)  Y (eval (car X)))
      (cond
         ((nil? Y) Y)
         ((num? Y) (argErr Exe Y))
         ((pair Y)
            (begString (push 4 NIL ZERO NIL NIL NIL))  # [cnt last name link fun ptr]
            (loop
               (print (++ Y))
               (? (atom Y))
               (space) )
            (endString) )
         ((sym? (setq Y (val (tail @)))) $Nil)
         ((atom (shift X))
            (parse (name Y) NO (hex "5D0A") 0) )  # '\n', ']', EOF
         (T
            (save Y
               (parse (name Y) NO 0 (save (evSym X))) ) ) ) ) )

(local) (repl)

(de repl (Exe (i8* . Prmt) X)
  (let
      (Int (save (val $Intern))
        Pr1 (save (val $PrivT))
        Pr2 (save (val 2 $PrivT))
        Tr1 (save (val $Transient))
        Tr2 (save (val 2 $Transient))
        V (link (push -ZERO NIL))
        At (link (push -ZERO NIL))
        Y $Nil)
      (set $PrivT (set 2 $PrivT $Nil))
      (set $Transient (set 2 $Transient $Nil))
      (setq X $Nil)

      (loop
        (outString Prmt)
        (setq Y (read1 (char "\n")))
        (set $Chr 0)
        (? (nil? Y))
        (set V Y)
        (newline)
        (let A (set At (val $At))
            (setq X (eval Y))
            (set
              $At3 (val $At2)
              $At2 A
              $At X ) )
        (outString ($ "-> "))
        (print X)
        (newline))

      (set 2 $Transient Tr2)
      (set $Transient Tr1)
      (set 2 $PrivT Pr2)
      (set $PrivT Pr1)
      (set $Intern Int)

      X))
