# 23oct20 Software Lab. Alexander Burger

(symbols '(llvm))

(local) (dbfErr dbRdErr dbWrErr jnlErr dbSyncErr)

(de NIL dbfErr (Exe)
   (err Exe 0 ($ "Bad DB file") null) )

(de NIL dbRdErr ()
   (err 0 0 ($ "DB read: <ERRNO>") null) )

(de NIL dbWrErr ()
   (err 0 0 ($ "DB write: <ERRNO>") null) )

(de NIL jnlErr (Exe)
   (err Exe 0 ($ "Bad Journal") null) )

(de NIL dbSyncErr (Exe)
   (err Exe 0 ($ "DB fsync error: <ERRNO>") null) )

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

(de void rdLockDb () (outString ($ "rdLockDb\n")))

(de void wrLockDb () (outString ($ "wrLockDb\n")))

(de void unLockDb ((i64 . Len)) (outString ($ "unLockDb\n")))

(de i32 tryLock ((i8* . DbFile) (i64 . N) (i64 . Len)) (outString ($ "tryLock\n")) 0)

(de void lockJnl () (outString ($ "lockJnl\n")))

(de void unLockJnl () (outString ($ "unLockJnl\n")))

(local) (blkPeek rdBlock blkPoke wrBlock logBlock)

(de void blkPeek ((i64 . Pos) (i8* . Buf) (i32 . Siz)) (outString ($ "blkPeek\n")))

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

(de void blkPoke ((i64 . Pos) (i8* . Buf) (i32 . Siz)) (outString ($ "blkPoke\n")))

(de void wrBlock () (outString ($ "wrBlock\n")))

(de void logBlock () (outString ($ "logBlock\n")))

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
         (memset2 P 0 (i64 Siz))  # Init new block
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
(de _extQ (Exe) $Nil)

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
(de _rollback (Exe))

# (extern 'sym) -> sym | NIL
(de _extern (Exe))

(local) (ignLog transaction fsyncDB restore truncLog)

(de void ignLog () (outString ($ "ignLog\n")))

# Test for existing transaction
(de i1 transaction () (outString ($ "transaction\n")) 0)

(de void fsyncDB (Exe) (outString ($ "fsyncDB\n")))

(de void restore (Exe) (outString ($ "restore\n")))

(de void truncLog (Exe) (outString ($ "truncLog\n")))

# (pool ['sym1 ['lst] ['sym2] ['sym3]]) -> T
(de _pool (Exe))

# (pool2 'sym . prg) -> any
(de _pool2 (Exe))

# (journal ['T] 'any ..) -> T
(de _journal (Exe))

# (id 'num ['num]) -> sym
# (id 'sym [NIL]) -> num
# (id 'sym T) -> (num . num)
(de _id (Exe))

# (blk 'fd 'cnt 'siz ['fd2]) -> lst
# (blk 'fd 0) -> (cnt . siz)
(de _blk (Exe))
# (seq 'cnt|sym1) -> sym | NIL
(de _seq (Exe))

# (lieu 'any) -> sym | NIL
(de _lieu (Exe))

# (lock ['sym]) -> cnt | NIL
(de _lock (Exe))

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
(de _touch (Exe))

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
(de _commit (Exe))

# (mark 'sym|0 [NIL | T | 0]) -> flg
(de _mark (Exe))

# (free 'cnt) -> (sym . lst)
(de _free (Exe))

# (dbck ['cnt] 'flg) -> any
(de _dbck (Exe))
