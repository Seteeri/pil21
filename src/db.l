# 23oct20 Software Lab. Alexander Burger

(symbols '(llvm))

(local) (dbfErr dbRdErr dbWrErr jnlErr dbSyncErr)

(de NIL dbfErr (Exe)
   (err Exe 0 ($ "Bad DB file") null) )

(de NIL dbRdErr ()
   (err 0 0 ($ "DB read: %s") (strErrno)) )

(de NIL dbWrErr ()
   (err 0 0 ($ "DB write: %s") (strErrno)) )

(de NIL jnlErr (Exe)
   (err Exe 0 ($ "Bad Journal") null) )

(de NIL dbSyncErr (Exe)
   (err Exe 0 ($ "DB fsync error: %s") (strErrno)) )

(local) (getAdr setAdr dbfBuf)

# 6 bytes in little endian format
# Get block address from buffer
(de i64 getAdr ((i8* . P))
   (|
      (shl
         (|
            (shl
               (|
                  (shl
                     (|
                        (shl
                           (|
                              (shl (i64 (val 6 P)) 8)
                              (i64 (val 5 P)) )
                           8 )
                        (i64 (val 4 P)) )
                     8 )
                  (i64 (val 3 P)) )
               8 )
            (i64 (val 2 P)) )
         8 )
      (i64 (val P)) ) )

# Set block address in buffer
(de void setAdr ((i64 . N) (i8* . P))
   (set P (i8 N))
   (set 2 P (i8 (setq N (shr N 8))))
   (set 3 P (i8 (setq N (shr N 8))))
   (set 4 P (i8 (setq N (shr N 8))))
   (set 5 P (i8 (setq N (shr N 8))))
   (set 6 P (i8 (shr N 8))) )

# Read file number from buffer into '$DbFile'
(de i8* dbfBuf ((i8* . P))
   (let N
      (|  # Two bytes little endian
         (shl (i32 (val 2 P)) 8)
         (i32 (val P)) )
      (if (> (val $DBs) N)  # Local file
         (set $DbFile  # Set current file
            (ofs (val $DbFiles) (* N (dbFile T))) )
         null ) ) )

# Locking
(local) (rdLockDb wrLockDb unLockDb tryLock lockJnl unLockJnl)

(de void rdLockDb ()
   (unless (t? (val $Solo))  # Not already locked whole DB
      (rdLockWait ((dbFile (val $DbFiles)) fd) 1) ) )  # Descriptor of first file

(de void wrLockDb ()
   (unless (t? (val $Solo))  # Not already locked whole DB
      (wrLockWait ((dbFile (val $DbFiles)) fd) 1) ) )  # Descriptor of first file

(de void unLockDb ((i64 . Len))
   (unless (t? (val $Solo))  # Not already locked whole DB
      (unless Len
         (let (Db (val $DbFiles)  C (val $DBs))  # Iterate DB files
            (while (dec 'C)
               (let Db: (dbFile (setq Db (ofs Db (dbFile T))))  # Skip first, increment by size of dbFile
                  (when (Db: lck)
                     (unLock (Db: fd) 0 0)
                     (Db: lck NO) ) ) ) )
         (set $Solo ZERO) )
      (unLock ((dbFile (val $DbFiles)) fd) 0 Len) ) )  # Descriptor of first file

(de i32 tryLock ((i8* . DbFile) (i64 . N) (i64 . Len))
   (let Db: (dbFile DbFile)
      (loop
         (? (ge0 (wrLock (Db: fd) N Len NO))  # Try to lock
            (Db: lck YES)  # Set lock flag
            (nond
               (N (set $Solo $T))  # Set solo mode
               ((t? (val $Solo)) (set $Solo $Nil)) )  # Clear solo mode
            0 )
         (unless
            (or
               (== (gErrno) EINTR)  # Interrupted
               (== @ EACCES)  # Locked by another process
               (== @ EAGAIN) )  # Memory-mapped by another process
            (lockErr) )
         (while (lt0 (getLock (Db: fd) N Len))
            (unless (== (gErrno) EINTR)
               (lockErr) ) )
         (? (gt0 @) @) ) ) )

(de void lockJnl ()
   (wrLockWait (fileno (val $DbJnl)) 0) )

(de void unLockJnl ()
   (let Jnl (val $DbJnl)
      (fflush Jnl)
      (unLock (fileno Jnl) 0 0) ) )

(local) (blkPeek rdBlock blkPoke wrBlock logBlock)

(de void blkPeek ((i64 . Pos) (i8* . Buf) (i32 . Siz))
   (let (S (i64 Siz)  Db: (dbFile (val $DbFile)))
      (unless (== S (pread (Db: fd) Buf S Pos))
         (dbRdErr) ) ) )

(de i8* rdBlock ((i64 . N))
   (let (Db: (dbFile (val $DbFile))  Blk (val $DbBlock))
      (blkPeek  # Read block
         (shl (set $BlkIndex N) (i64 (Db: sh)))
         Blk
         (Db: siz) )
      (set
         $BlkLink (& (getAdr Blk) BLKMASK)
         $BlkEnd (ofs Blk (Db: siz))
         $BlkPtr (ofs Blk BLK) )  # Pointer to data
      Blk ) )  # Pointer to block

(de void blkPoke ((i64 . Pos) (i8* . Buf) (i32 . Siz))
   (let Db: (dbFile (val $DbFile))
      (unless (== Siz (i32 (pwrite (Db: fd) Buf (i64 Siz) Pos)))
         (dbWrErr) )
      (when (val $DbJnl)
         (let Jnl @
            (putc_unlocked (if (== Siz (Db: siz)) 0 Siz) Jnl)
            (let P (b8 (+ BLK 2))  # Allocate buffer
               (set P (i8 (Db: db)))  # Store file number
               (set 2 P (i8 (shr (Db: db) 8)))
               (setAdr
                  (shr Pos (i64 (Db: sh)))  # Un-shift position
                  (ofs P 2) )
               (unless
                  (and
                     (== 1 (fwrite P (+ BLK 2) 1 Jnl))  # Write file number and address
                     (== 1 (fwrite Buf (i64 Siz) 1 Jnl)) )  # Write 'Buf'
                  (err 0 0 ($ "Journal write: %s") (strErrno)) ) ) ) ) ) )

(de void wrBlock ()
   (let Db: (dbFile (val $DbFile))
      (blkPoke
         (shl (val $BlkIndex) (i64 (Db: sh)))
         (val $DbBlock)
         (Db: siz) ) ) )

(de void logBlock ()
   (let
      (Db: (dbFile (val $DbFile))
         Log (val $DbLog)
         P (b8 (+ BLK 2)) )
      (set P (i8 (Db: db)))  # Store file number
      (set 2 P (i8 (shr (Db: db) 8)))
      (setAdr (val $BlkIndex) (ofs P 2))  # and block
      (unless
         (and
            (== 1 (fwrite P (+ BLK 2) 1 Log))  # Write file number and address
            (== 1 (fwrite (val $DbBlock) (i64 (Db: siz)) 1 Log)) )  # Write block
         (err 0 0 ($ "Log write: %s") (strErrno)) ) ) )

(local) (newBlock newId isLife cleanUp getBlock putBlock)

(de i64 newBlock ()
   (let
      (Db: (dbFile (val $DbFile))
         Siz (Db: siz)
         P (b8 Siz) )
      (blkPeek 0 P (* 2 BLK))  # Read 'free' and 'next' from block zero
      (let N (getAdr P)
         (cond
            ((and N (Db: flu))
               (blkPeek (shl N (i64 (Db: sh))) P BLK)  # Get free link
               (Db: flu (dec (Db: flu))) )
            ((== (setq N (getAdr (ofs P BLK))) (hex "FFFFFFFFFFC0"))  # Max object ID
               (err 0 0 ($ "DB Oversize") null) )
            (T (setAdr (+ N BLKSIZE) (ofs P BLK))) )  # Increment next
         (blkPoke 0 P (* 2 BLK))  # Write back
         (memset P 0 (i64 Siz))  # Init new block
         (blkPoke (shl N (i64 (Db: sh))) P Siz)
         N ) ) )

(de newId (Exe (i32 . N))
   (when (>= (dec 'N) (val $DBs))
      (dbfErr Exe) )
   (set $DbFile  # Set current file
      (ofs (val $DbFiles) (* N (dbFile T))) )
   (set $Protect (inc (val $Protect)))
   (wrLockDb)
   (when (val $DbJnl)
      (lockJnl) )
   (prog1
      (extNm
         ((dbFile (val $DbFile)) db)
         (shr (newBlock) 6) )
      (when (val $DbJnl)
         (unLockJnl) )
      (unLockDb 1)
      (set $Protect (dec (val $Protect))) ) )

(de i1 isLife (Sym)
   (let
      (Nm (name (& (val (tail Sym)) -9))
         F (objFile Nm)
         N (shl (objId Nm) 6) )
      (when N
         (cond
            ((> (val $DBs) F)  # Local file
               (setq Nm (add Nm Nm))
               (when @@  # Dirty
                  (ret YES) )
               (add Nm Nm)
               (when @@  # Loaded
                  (ret YES) )
               (let
                  (Db:
                     (dbFile
                        (set $DbFile  # Set current file
                           (ofs (val $DbFiles) (* F (dbFile T))) ) )
                     P (b8 (* BLK 2)) )
                  (blkPeek BLK P BLK)  # Read 'next'
                  (when (> (getAdr P) N)
                     (blkPeek (shl N (i64 (Db: sh))) P BLK)  # Read link field
                     (when (== 1 (& (val P) BLKTAG))  # ID-Block
                        (ret YES) ) ) ) )
            ((pair (val $Ext))
               (ret YES) ) ) )
      NO ) )

# (ext? 'any) -> sym | NIL
(de _extQ (Exe)
   (let X (eval (cadr Exe))
      (if
         (and
            (symb? X)
            (sym? (val (tail X)))
            (isLife X) )
         X
         $Nil ) ) )

(de void cleanUp ((i64 . N))
   (let (P (b8 BLK)  Db: (dbFile (val $DbFile)))
      (blkPeek 0 P BLK)  # Read 'free'
      (let Free (getAdr P)
         (setAdr N P)
         (blkPoke 0 P BLK)  # Set new 'free'
         (loop
            (let Pos (shl N (i64 (Db: sh)))
               (blkPeek Pos P BLK)  # Get block link
               (set P (& (val P) BLKMASK))  # Clear tag
               (? (=0 (setq N (getAdr P)))  # No more links
                  (setAdr Free P)  # Append old 'free' list
                  (blkPoke Pos P BLK) )
               (blkPoke Pos P BLK) ) ) ) ) )

(de i32 getBlock ()
   (let P (val $BlkPtr)
      (when (== P (val $BlkEnd))
         (unless (val $BlkLink)
            (ret -1) )
         (setq P (ofs (rdBlock @) BLK)) )
      (set $BlkPtr (inc P))
      (i32 (val P)) ) )

(de void putBlock ((i8 . B))
   (let P (val $BlkPtr)
      (when (== P (val $BlkEnd))
         (let Link (val $BlkLink)
            (ifn Link
               (let
                  (New (newBlock)
                     Cnt (i64 (val (setq P (val $DbBlock)))) )  # Block count (link is zero)
                  (setAdr (| New Cnt) P)
                  (wrBlock)  # Write new block
                  (set $BlkIndex New)  # Set new block index
                  (setAdr (if (== Cnt BLKTAG) Cnt (inc Cnt)) P)
                  (setq P (ofs P BLK)) )
               (wrBlock)  # Write current block
               (setq P (ofs (rdBlock Link) BLK)) ) ) )  # Read next block
      (set P B)
      (set $BlkPtr (inc P)) ) )

# (rollback) -> flg
(de _rollback (Exe)
         $Nil )

# (extern 'sym) -> sym | NIL
(de _extern (Exe)
   (let
      (Sym (needSymb Exe (eval (cadr Exe)))
         Nm (name (& (val (tail Sym)) -9)) )
      (when (== Nm ZERO)
         (ret $Nil) )
      (let
         (P (push 0 Nm)  # [cnt name]
            C (symChar P)
            F (i32 0) )
         (when (== C (char "{"))
            (setq C (symChar P)) )
         (while (>= C (char "@"))
            (when (> C (char "O"))  # A-O range
               (ret $Nil) )
            (setq
               F (| (shl F 4) (- C (char "@")))
               C (symChar P) ) )
         (let N 0
            (loop
               (unless (and (>= C (char "0")) (>= (char "7") C))
                  (ret $Nil) )
               (setq N
                  (|
                     (shl N 3)
                     (i64 (- C (char "0"))) ) )
               (?
                  (or
                     (=0 (setq C (symChar P)))
                     (== C (char "}")) ) ) )
            (if (isLife (setq Sym (extern (extNm F N))))
               Sym
               $Nil ) ) ) ) )

(local) (ignLog transaction fsyncDB restore truncLog)

(de void ignLog ()
   (stderrMsg ($ "Discarding incomplete transaction\n") null))

# Test for existing transaction
(de i1 transaction ()
   (let (Log (val $DbLog)  Blk (b8 BLK))
      (fseek0 Log)
      (if (fread Blk 2 1 Log)  # Read first file number
         (loop
            (? (== (val (i16* Blk)) (hex "FFFF")) YES)  # Byte order doesn't matter
            (?
               (or
                  (=0 (dbfBuf Blk))
                  (<> (fread Blk BLK 1 Log) 1)
                  (not (fseekOfs Log ((dbFile (val $DbFile)) siz)))
                  (<> (fread Blk 2 1 Log) 1) )
               (ignLog)
               NO ) )
         (unless (feof Log)
            (ignLog) )  # Discard incomplete transaction
         NO ) ) )

(de void fsyncDB (Exe)
   (let (Db (val $DbFiles)  C (val $DBs))  # Iterate DB files
      (loop
         (let Db: (dbFile Db)
            (when (and (Db: drt) (lt0 (fsync (Db: fd))))
               (dbSyncErr Exe) ) )
         (? (=0 (dec 'C)))
         (setq Db (ofs Db (dbFile T))) ) ) )

(de void restore (Exe)
   (stderrMsg ($ "Last transaction not completed: Rollback\n") null)
   (let Log (val $DbLog)
      (fseek0 Log)
      (let (Db (val $DbFiles)  C (val $DBs))  # Iterate DB files
         (loop
            ((dbFile Db) drt NO)
            (? (=0 (dec 'C)))
            (setq Db (ofs Db (dbFile T))) ) )
      (let (Blk (b8 BLK)  Buf (b8 (val $MaxBlkSize)))
         (loop
            (unless (== (fread Blk 2 1 Log) 1)  # Get file number
               (jnlErr Exe) )
            (? (== (val (i16* Blk)) (hex "FFFF")))  # Byte order doesn't matter
            (if (dbfBuf Blk)
               (let Db: (dbFile @)
                  (unless
                     (and
                        (== (fread Blk BLK 1 Log) 1)
                        (== (fread Buf (i64 (Db: siz)) 1 Log) 1) )
                     (jnlErr Exe) )
                  (unless
                     (==
                        (pwrite
                           (Db: fd)
                           Buf
                           (i64 (Db: siz))
                           (shl (getAdr Blk) (i64 (Db: sh))) )
                        (i64 (Db: siz)) )
                     (dbWrErr) )
                  (Db: drt YES) )
               (jnlErr Exe) ) )
         (fsyncDB Exe) ) ) )

(de void truncLog (Exe)
   (let Log (val $DbLog)
      (unless (and (fseek0 Log) (truncate0 (fileno Log)))
         (err Exe 0 ($ "Log truncate error: %s") (strErrno)) ) ) )

# (pool ['sym1 ['lst] ['sym2] ['sym3]]) -> T
(de _pool (Exe)
         $Nil )

# (pool2 'sym . prg) -> any
(de _pool2 (Exe)
         $Nil )

# (journal ['T] 'any ..) -> T
(de _journal (Exe)
   (let
      (X (cdr Exe)
         Sym (evSym X)
         Jnl (val $DbJnl)
         Log (val $DbLog)
         Buf (b8 (val $MaxBlkSize))
         Blk (b8 BLK) )
      (stkChk Exe)
      (when (t? Sym)
         (set $DbJnl null  $DbLog null)  # Stop journal and transaction log
         (setq Sym (evSym (shift X))) )
      (loop
         (let
            (Nm (xName Exe Sym)  # Journal name
               Fp (fopen (pathString Nm (b8 (pathSize Nm))) ($ "r")) )
            (unless Fp
               (openErr Exe Sym) )
            (while (ge0 (getc_unlocked Fp))
               (let Siz @
                  (unless (== (fread Blk 2 1 Fp) 1)  # Read file number
                     (jnlErr Exe) )
                  (if (dbfBuf Blk)  # Get file number from 'Buf' to 'DbFile'
                     (let Db: (dbFile @)
                        #! Temporary backward compatibility
                        (when (== Siz BLKSIZE)
                           (setq Siz (Db: siz)) )
                        #!
                        (unless Siz
                           (setq Siz (Db: siz)) )
                        (unless
                           (and
                              (== (fread Blk BLK 1 Fp) 1)
                              (== (fread Buf (i64 Siz) 1 Fp) 1) )
                           (jnlErr Exe) )
                        (blkPoke
                           (shl (getAdr Blk) (i64 (Db: sh)))
                           Buf
                           Siz ) )
                     (dbfErr Exe) ) ) )  # No local file
            (fclose Fp)
            (? (atom (shift X)))
            (setq Sym (evSym X)) ) )
      (set $DbLog Log  $DbJnl Jnl)
      $T ) )

# (id 'num ['num]) -> sym
# (id 'sym [NIL]) -> num
# (id 'sym T) -> (num . num)
(de _id (Exe)
   (let (X (cdr Exe)  Y (eval (++ X)))
      (if (cnt? Y)  # File number or object ID
         (extern
            (if (nil? (eval (car X)))
               (extNm 0 (int Y))
               (extNm (dec (i32 (int Y))) (xCnt Exe @)) ) )
         (needSymb Exe Y)
         (unless (sym? (val (tail (needSymb Exe Y))))
            (extErr Exe Y) )
         (let
            (Nm (name (& (val (tail Y)) -9))
               Z (cnt (objId Nm)) )
            (if (nil? (eval (car X)))  # Return only object ID
               Z
               (cons
                  (cnt (i64 (inc (objFile Nm))))
                  Z ) ) ) ) ) )

# (blk 'fd 'cnt 'siz ['fd2]) -> lst
# (blk 'fd 0) -> (cnt . siz)
(de _blk (Exe)
         $Nil )

# (seq 'cnt|sym1) -> sym | NIL
(de _seq (Exe)
         $Nil )

# (lieu 'any) -> sym | NIL
(de _lieu (Exe)
   (let X (eval (cadr Exe))
      (nond
         ((symb? X) $Nil)
         ((sym? (val (tail X))) $Nil)
         (NIL
            (let Nm (name (& (val (tail X)) -9))
               (setq Nm (add Nm Nm))
               (cond
                  (@@  # Dirty
                     (setq Nm (add Nm Nm))
                     (if @@ $Nil X) )  # Deleted
                  (T
                     (setq Nm (add Nm Nm))
                     (if @@ X $Nil) ) ) ) ) ) ) )  # Loaded

# (lock ['sym]) -> cnt | NIL
(de _lock (Exe)
   (if
      (if (nil? (eval (cadr Exe)))
         (tryLock (val $DbFiles) 0 0)  # Use first dbFile
         (let X (needSymb Exe @)
            (unless (sym? (val (tail (needSymb Exe X))))
               (extErr Exe X) )
            (let
               (Nm (name (& (val (tail X)) -9))
                  F (objFile Nm)
                  N (objId Nm) )
               (when (>= F (val $DBs))
                  (dbfErr Exe) )
               (let Db: (dbFile (ofs (val $DbFiles) (* F (dbFile T))))
                  (tryLock (Db:) (* N (i64 (Db: siz))) 1) ) ) ) )
      (cnt (i64 @))
      $Nil ) )

(local) (db dbFetch dbTouch dbZap)

(de void db (Exe Sym Nm)
   (save Sym)
   (let F (objFile Nm)  # Get file number
      (if (>= F (val $DBs))
         (let Ext (val $Ext)  # Non-local file
            (if
               (or
                  (atom Ext)  # First offset
                  (> (i32 (int (caar @))) (inc 'F)) )  # too big
               (dbfErr Exe)
               (while  # Find DB extension
                  (and
                     (pair (cdr Ext))
                     (>= F (i32 (int (caar @)))) )
                  (shift Ext) )
               (let
                  (V (push NIL $Nil ZERO Sym)  # [car cdr name arg]
                     E (push NIL V ZERO (cdar Ext)) )  # [car cdr name fun]
                  (set V (ofs V 3)  E (ofs E 3))
                  (let X (evList E)
                     (set Sym (++ X))  # Set value
                     (if (atom X)
                        (set (tail Sym) Nm)  # Set status/name
                        (set (tail Sym) (sym X))  # Set property list
                        (while (pair (cdr X))  # Find end
                           (setq X @) )
                        (set 2 X Nm) ) ) ) ) )  # Set status/name
         # Local file
         (set $DbFile
            (ofs (val $DbFiles) (* F (dbFile T))) )
         (rdLockDb)  # Lock for reading
         (let Blk (rdBlock (shl (objId Nm) 6))  # Read first block
            (unless (== 1 (& (val Blk) BLKTAG))  # ID-Block
               (err Exe Sym ($ "Bad ID") null) ) )
         (set
            $GetBin (fun (i32) getBlock)
            $Extn 0 )
         (set Sym (binRead))  # Read symbol value
         (if (nil? (binRead))  # First property key
            (set (tail Sym) Nm)  # Set status/name
            (set (tail Sym)  # Set tail
               (sym (setq Nm (cons @ Nm))) )
            (unless (t? (binRead))  # First property value
               (set Nm (cons @ (val Nm))) )  # Cons with key
            (until (nil? (binRead))  # Next property key
               (set 2 Nm (cons @ (cdr Nm)))
               (shift Nm)
               (unless (t? (binRead))  # Next property value
                  (set Nm (cons @ (val Nm))) ) ) )  # Cons with key
         (unLockDb 1) ) ) )  # Unlock

(de void dbFetch (Exe Sym)
   (let Nm (val (tail Sym))
      (when
         (and
            (num? Nm)  # No properties
            (prog (setq Nm (add Nm Nm)) (not @@))  # Not dirty
            (prog (setq Nm (add Nm Nm)) (not @@)) )  # Not loaded
         (set (tail Sym) (setq Nm (shr 1 Nm 2)))  # Set "loaded"
         (tailcall (db Exe Sym Nm)) ) ) )

(de void dbTouch (Exe Sym)
   (let (Q (tail Sym)  Nm (val Q))
      (unless (num? Nm)  # Has properties
         (setq Nm (any (& Nm -9)))  # Clear 'extern' tag
         (loop
            (setq Q (ofs Nm 1))  # Skip property
            (? (num? (setq Nm (val Q)))) ) )  # Find name
      (setq Nm (add Nm Nm))
      (unless @@  # Not yet dirty
         (setq Nm (add Nm Nm))
         (set Q (setq Nm (shr 2 Nm 2)))  # Set "dirty"
         (unless @@  # Not loaded
            (tailcall (db Exe Sym Nm)) ) ) ) )

# (touch 'sym) -> sym
(de _touch (Exe)
   (let X (eval (cadr Exe))
      (when (and (symb? X) (sym? (val (tail X))))
         (dbTouch Exe X) )
      X ) )

(de void dbZap (Sym)
   (let Tail (val (tail Sym))  # Get tail
      (unless (num? Tail)  # Any properties
         (setq Tail (& Tail -9))  # Clear 'extern' tag
         (loop
            (? (num? (shift Tail))) )  # Find name
         (setq Tail (sym Tail)) )  # Set 'extern' tag
      (set (tail Sym) (shr 3 (shl Tail 2) 2))  # Set "deleted"
      (set Sym $Nil) ) )  # Clear value

# (commit ['any] [exe1] [exe2]) -> T
(de _commit (Exe)
         $Nil )

# (mark 'sym|0 [NIL | T | 0]) -> flg
(de _mark (Exe)
   (let (X (cdr Exe)  Y (eval (++ X)))
      (if (== Y ZERO)  # Clear all marks
         (let (Db (val $DbFiles)  C (val $DBs))  # Iterate DB files
            (while (ge0 (dec 'C))
               (let Db: (dbFile Db)
                  (Db: mrks 0)  # Set mark vector size to zero
                  (free (Db: mark))  # Free mark bit vector
                  (Db: mark null) )  # and set to null
               (setq Db (ofs Db (dbFile T))) )
            $Nil )
         (unless (sym? (val (tail (needSymb Exe Y))))
            (extErr Exe Y) )
         (let
            (Nm (name (& (val (tail Y)) -9))
               F (objFile Nm)
               N (objId Nm) )
            (if (>= F (val $DBs))
               $T  # Non-local file
               (let
                  (Flg (eval (car X))  # Second arg
                     Db: (dbFile (ofs (val $DbFiles) (* F (dbFile T))))
                     P (Db: mark)  # Mark bit vector
                     I (shr N 3) )  # Byte index
                  (when (>= I (Db: mrks))  # Greater or equal to mark vector size
                     (let J (inc I)
                        (memset
                           (ofs
                              (setq P (Db: mark (alloc P J)))  # Increase mark bit vector
                              (Db: mrks) )
                           0  # Clear new area
                           (- J (Db: mrks)) )
                        (Db: mrks J) ) )  # New mark vector size
                  (setq
                     P (ofs P I)  # Byte position in bit vector
                     N (i8 (shl 1 (& N 7))) )  # Bit position
                  (let B (val P)  # Old value
                     (cond
                        ((& B N)  # Bit is set
                           (when (== ZERO Flg)
                              (set P (& B (x| N -1))) )  # Clear mark
                           $T )  # Return T
                        (T  # Bit is not set
                           (when (== $T Flg)
                              (set P (| B N)) )  # Set mark
                           $Nil ) ) ) ) ) ) ) ) )  # Return NIL

# (free 'cnt) -> (sym . lst)
(de _free (Exe)
   (let
      (X (cdr Exe)
         F (dec (i32 (evCnt Exe X)))
         Buf (b8 (* BLK 2)) )
      (when (>= F (val $DBs))
         (dbfErr Exe) )
      (set $DbFile
         (ofs (val $DbFiles) (* F (dbFile T))) )
      (rdLockDb)  # Lock for reading
      (blkPeek 0 Buf (* 2 BLK))  # Read 'free' and 'next' from block zero
      (set $BlkLink (getAdr Buf))  # free' as next block
      (let
         (Y
            (cons  # CAR of result list
               (extern  # 'next' symbol
                  (extNm F (shr (getAdr (ofs Buf BLK)) 6)) )
               $Nil )
            R (save Y) )
         (while (val $BlkLink)  # Collect free list
            (setq Y
               (set 2 Y
                  (cons (extern (extNm F (shr @ 6))) $Nil) ) )
            (rdBlock @) )
         (unLockDb 1)  # Unlock
         R ) ) )

# (dbck ['cnt] 'flg) -> any
(de _dbck (Exe)
   (let
      (X (cdr Exe)
         Y (eval (car X))
         Jnl (val $DbJnl)
         Buf (b8 (* BLK 2))
         Cnt BLKSIZE
         Syms 0
         Blks 0 )
      (if (cnt? Y)
         (let F (dec (i32 (int Y)))
            (when (>= F (val $DBs))
               (dbfErr Exe) )
            (set $DbFile
               (ofs (val $DbFiles) (* F (dbFile T))) )
            (setq Y (eval (cadr X))) )  # Use first dbFile
         (set $DbFile (val $DbFiles)) )
      (set $Protect (inc (val $Protect)))
      (wrLockDb)
      (when Jnl
         (lockJnl)  # Write lock journal
         (set $DbJnl null) )  # Disable Journal
      (blkPeek 0 Buf (* 2 BLK))  # Read 'free' and 'next' from block zero
      (set $BlkLink (getAdr Buf))  # free' as next block
      (let Next (getAdr (ofs Buf BLK))  # Get 'next'
         (while (val $BlkLink)  # Check free list
            (let Blk (rdBlock @)
               (set Blk (| (val Blk) BLKTAG)) )  # Mark free list
            (when (> (inc 'Cnt BLKSIZE) Next)
               (setq Y (mkStr ($ "Circular free list")))
               (goto 9) )
            (wrBlock) )
         (set $DbJnl Jnl)  # Restore Journal
         (let P BLKSIZE
            (until (== P Next)  # Check all chains
               (let Blk (rdBlock P)
                  (case (& (val Blk) BLKTAG)
                     (0  # Free block
                        (inc 'Cnt BLKSIZE)
                        (memcpy Blk Buf BLK)
                        (wrBlock)
                        (setAdr P Buf)
                        (blkPoke 0 Buf BLK) )
                     (1  # ID-block of symbol
                        (inc 'Syms)
                        (let I (i8 2)
                           (loop  # Check chains
                              (inc 'Blks)
                              (inc 'Cnt BLKSIZE)
                              (? (=0 (val $BlkLink)))
                              (unless
                                 (== I
                                    (& (val (rdBlock @)) BLKTAG) )
                                 (setq Y (mkStr ($ "Bad chain")))
                                 (goto 9) )
                              (when (> BLKTAG I)
                                 (inc 'I) ) ) ) ) ) )
               (inc 'P BLKSIZE) ) )
         (set $BlkLink (getAdr Buf))
         (set $DbJnl null)  # Disable Journal
         (while (val $BlkLink)  # Unmark free list
            (let Blk (rdBlock @)
               (when (& (val Blk) BLKTAG)
                  (set Blk (& (val Blk) BLKMASK))
                  (wrBlock) ) ) )
         (nond
            ((== Cnt Next)
               (setq Y (mkStr ($ "Bad count"))) )
            ((nil? Y)
               (setq Y (cons (cnt Blks) (cnt Syms))) ) ) )
      (: 9
         (when (set $DbJnl Jnl)
            (unLockJnl) )
         (unLockDb 1)  # Unlock
         (set $Protect (dec (val $Protect)))
         Y ) ) )
