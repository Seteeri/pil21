# 14dec20 Software Lab. Alexander Burger

(symbols '(llvm))

(var $Heap  i64 0)                        # Heap start address
(var $Limit i64 0)                        # Heap limit

(var $Heaps 0)                         # Heap list
(var $Avail 0)                         # Avail list
(var $Extern 0)                        # External symbol tree
(var $ExtCnt i64 1)                    # External symbol count
(var $ExtSkip i64 0)                   # External tree skip
(var $StkSize i64 STACK)               # Coroutine stack segment size
(var $StkLimit i8* null)               # Stack limit: StackN-Size+4096

(var $Stdin i8* null)                  # Stdin frame
(var $Stdout i8* null)                 # Stdout frame
(var $ReplPrmt i8* null)               # REPL console prompt
(var $ContPrmt i8* null)               # REPL continue prompt
(var $Ret 0)                           # Secondary return value

(var $OutFiles i8** null)              # Output files
(var $OutFile i8* null)                # Output file

(var $Chr i32 0)                       # Single-char look ahead
(var $Put (void i8) null)              # Character output function
(var $Get (i32) null)                  # Character input function
(var $PutBin (void i8) null)           # Binary output function
(var $GetBin (i32) null)               # Binary input function
(var $SeedL i64 0)                     # Random seed low
(var $SeedH i64 0)                     # Random seed high
(var $USec i64 0)                      # Startup microseconds
(var $Ptr i8* null)                    # Byte buffer pointer
(var $End i8* null)                    # Buffer end pointer
(var $BufX i8* null)                   # Exchange buffer
(var $PtrX i8* null)                   # Exchange buffer pointer
(var $EndX i8* null)                   # Exchange end pointer
(var $ExtN i32 0)                      # External symbol offset
(var $Extn i32 0)
(var $StrP i64* null)                  # String status
(var $GcCount i64 CELLS)               # Collector count

# Database
(var $DbFiles i8* null)                # DB files
(var $DbFile i8* null)                 # DB file
(var $DBs i32 0)                       # Number of DB files
(var $MaxBlkSize i32 0)                # Maximum block size
(var $DbBlock i8* null)                # Block buffer
(var $BlkIndex i64 0)                  # Block index
(var $BlkLink i64 0)                   # Next block
(var $BlkPtr i8* null)                 # Block byte buffer pointer
(var $BlkEnd i8* null)                 # Block buffer end pointer
(var $DbJnl i8* null)                  # Journal file
(var $DbLog i8* null)                  # Transaction log file

# Jmp -> 176
(var $JmpBufSize i64 256)              # IHI0055B_aapcs64.pdf:
                                       # 5.1.1, 5.1.2 callee saved registers
#(var $QuitRst i8 0)
(array $QuitRst i8
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0)

# Interrupts
# GIC-400 max intr id = 1023
(array $Signal i32
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0
   0)

# Symbol Table
(symTab
   ($Nil "NIL" $Nil)          # NIL symbol
   (NIL $Nil 0)               # CDR of NIL as empty list
   ($Tilde "~" $Tilde)        # Tilde symbol
   ($PicoT $Nil $Nil 0)       # Pico trees
   ($Pico $Tilde $PicoT 0)    # Initial namespace
   ($pico "pico" $Pico)
   ($Pico1 $pico $Nil 0)
   ($PrivT $Nil $Nil 0)       # Private trees
   ($Priv $Tilde $PrivT 0)    # Private namespace
   ($priv "priv" $Priv)
   ($DB "*DB" 0)              # Database root constant
   ($Meth "meth" __meth)
   ($Quote "quote" _quote)
   ($T "T" $T)  ### Sync src/pico.h 'T' (17*2+1) ###
   ($N "N" $Nil)
   ($C "C" $Nil)
   ($S "S" $Nil)
   ($B "B" $Nil)
   ($I "I" $Nil)
   ($P "P" $Nil)
   ($W "W" $Nil)
   ($Db1 0 $Nil)              # Database root symbol '{1}'
   ($Solo "*Solo" ZERO)
   ($At "@" $Nil)
   ($At2 "@@" $Nil)
   ($At3 "@@@" $Nil)
   ($This "This" $Nil)
   ($Prompt "*Prompt" $Nil)
   ($Zap "*Zap" $Nil)
   ($Ext "*Ext" $Nil)
   ($Scl "*Scl" ZERO)
   ($Class "*Class" $Nil)
   ($Run "*Run" $Nil)
   ($Up "\^" $Nil)
   ($Err "*Err" $Nil)
   ($Msg "*Msg" $Nil)
   ($Uni "*Uni" $Nil)
   ($Dbg "*Dbg" $Nil)
   # Platform/Board/Sys
   ($Kern  "*Kern"  $Nil)
   ($MBox  "*MBox"  $Nil)
   ($IntID "*IntID" $Nil)
   ($Int   "*Int"   $Nil)
   ($Peri  "*Peri"  $Nil)
   ($Gic   "*Gic"   $Nil)
   ($Irq   "*Irq"   $Nil)
   ($Aux   "*Aux"   $Nil)
   ($Uart  "*Uart"  $Nil)
   ($Putc  "*Putc"  $Nil)
   ($Ch    "*Ch"    $Nil)
   ($Getc  "*Getc"  $Nil)
   ($Complete "complete" $Nil)
   # Garbage collection
   (NIL "gc" _gc)
   # Arithmetics
   (NIL "format" _format)
   (NIL "+" _add)
   (NIL "-" _sub)
   (NIL "inc" _inc)
   (NIL "dec" _dec)
   (NIL "*" _mul)
   (NIL "*/" _mulDiv)
   (NIL "/" _div)
   ($rem "%" _rem)
   (NIL ">>" _shr)
   (NIL "lt0" _lt0)
   (NIL "le0" _le0)
   (NIL "ge0" _ge0)
   (NIL "gt0" _gt0)
   (NIL "abs" _abs)
   (NIL "bit?"_bitQ)
   (NIL "&" _bitAnd)
   (NIL "|" _bitOr)
   (NIL "x|" _bitXor)
   (NIL "sqrt" _sqrt)
   (NIL "seed" _seed)
   (NIL "hash" _hash)
   (NIL "rand" _rand)
   # Symbol functions
   (NIL "name" _name)
   (NIL "nsp" _nsp)
   (NIL "sp?" _spQ)
   (NIL "pat?" _patQ)
   (NIL "fun?" _funQ)
   (NIL "getd" _getd)
   (NIL "all" _all)
   (NIL "symbols" _symbols)
   (NIL "intern" _intern)
   (NIL "box?" _boxQ)
   (NIL "str?" _strQ)
   (NIL "zap" _zap)
   (NIL "chop" _chop)
   (NIL "pack" _pack)
   (NIL "glue" _glue)
   (NIL "text" _text)
   (NIL "pre?" _preQ)
   (NIL "sub?" _subQ)
   (NIL "val" _val)
   (NIL "set" _set)
   (NIL "setq" _setq)
   (NIL "swap" _swap)
   (NIL "xchg" _xchg)
   (NIL "on" _on)
   (NIL "off" _off)
   (NIL "onOff" _onOff)
   (NIL "zero" _zero)
   (NIL "one" _one)
   (NIL "default" _default)
   (NIL "push" _push)
   (NIL "push1" _push1)
   (NIL "push1q" _push1q)
   (NIL "pop" _pop)
   (NIL "++" _popq)
   (NIL "cut" _cut)
   (NIL "del" _del)
   (NIL "queue" _queue)
   (NIL "fifo" _fifo)
   (NIL "idx" _idx)
   (NIL "lup" _lup)
   (NIL "put" _put)
   (NIL "get" _get)
   (NIL "prop" _prop)
   (NIL ";" _semicol)
   (NIL "=:" _setCol)
   (NIL ":" _col)
   (NIL "::" _propCol)
   (NIL "putl" _putl)
   (NIL "getl" _getl)
   (NIL "wipe" _wipe)
   (NIL "meta" _meta)
   (NIL "low?" _lowQ)
   (NIL "upp?" _uppQ)
   (NIL "lowc" _lowc)
   (NIL "uppc" _uppc)
   (NIL "fold" _fold)
   # Input/Output
   (NIL "read" _read)
   (NIL "key" _key)
   (NIL "peek" _peek)
   (NIL "char" _char)
   (NIL "skip" _skip)
   (NIL "eol" _eol)
   (NIL "eof" _eof)
   (NIL "from" _from)
   (NIL "till" _till)
   (NIL "line" _line)
   (NIL "echo" _echo)
   (NIL "prin" _prin)
   (NIL "prinl" _prinl)
   (NIL "space" _space)
   (NIL "print" _print)
   (NIL "printsp" _printsp)
   (NIL "println" _println)
   (NIL "ext" _ext)
   (NIL "plio" _plio)
   (NIL "rd" _rd)
   (NIL "pr" _pr)
   (NIL "wr" _wr)
   (NIL "any" _any)
   (NIL "sym" _sym)
   (NIL "str" _str)
   # Database
   #
   # Mapping
   (NIL "apply" _apply)
   (NIL "pass" _pass)
   (NIL "maps" _maps)
   (NIL "map" _map)
   (NIL "mapc" _mapc)
   (NIL "maplist" _maplist)
   (NIL "mapcar" _mapcar)
   (NIL "mapcon" _mapcon)
   (NIL "mapcan" _mapcan)
   (NIL "filter" _filter)
   (NIL "extract" _extract)
   (NIL "seek" _seek)
   (NIL "find" _find)
   (NIL "pick" _pick)
   (NIL "fully" _fully)
   (NIL "cnt" _cnt)
   (NIL "sum" _sum)
   (NIL "maxi" _maxi)
   (NIL "mini" _mini)
   (NIL "fish" _fish)
   (NIL "by" _by)
   # Control flow
   (NIL "as" _as)
   (NIL "lit" _lit)
   (NIL "eval" _eval)
   (NIL "run" _run)
   (NIL "def" _def)
   (NIL "de" _de)
   (NIL "dm" _dm)
   (NIL "box" _box)
   (NIL "new" _new)
   (NIL "type" _type)
   (NIL "isa" _isa)
   (NIL "method" _method)
   (NIL "send" _send)
   (NIL "try" _try)
   (NIL "super" _super)
   (NIL "extra" _extra)
   (NIL "and" _and)
   (NIL "or" _or)
   (NIL "nand" _nand)
   (NIL "nor" _nor)
   (NIL "xor" _xor)
   (NIL "bool" _bool)
   (NIL "not" _not)
   (NIL "nil" _nil)
   (NIL "t" _t)
   (NIL "prog" _prog)
   (NIL "prog1" _prog1)
   (NIL "prog2" _prog2)
   (NIL "if" _if)
   (NIL "ifn" _ifn)
   (NIL "if2" _if2)
   (NIL "when" _when)
   (NIL "unless" _unless)
   (NIL "cond" _cond)
   (NIL "nond" _nond)
   (NIL "case" _case)
   (NIL "casq" _casq)
   (NIL "state" _state)
   (NIL "while" _while)
   (NIL "until" _until)
   (NIL "at" _at)
   (NIL "do" _do)
   (NIL "loop" _loop)
   (NIL "for" _for)
   (NIL "with" _with)
   (NIL "bind" _bind)
   (NIL "job" _job)
   (NIL "let" _let)
   (NIL "let?" _letQ)
   (NIL "use" _use)
   (NIL "buf" _buf)
   (NIL "catch" _catch)
   (NIL "throw" _throw)
   (NIL "finally" _finally)
   (NIL "co" _co)
   (NIL "yield" _yield)
   #(NIL "!" _break) # implement in kern
   #(NIL "e" _e)
   #(NIL "$" _trace)
   # List processing
   (NIL "car" _car)
   (NIL "cdr" _cdr)
   (NIL "caar" _caar)
   (NIL "cadr" _cadr)
   (NIL "cdar" _cdar)
   (NIL "cddr" _cddr)
   (NIL "caaar" _caaar)
   (NIL "caadr" _caadr)
   (NIL "cadar" _cadar)
   (NIL "caddr" _caddr)
   (NIL "cdaar" _cdaar)
   (NIL "cdadr" _cdadr)
   (NIL "cddar" _cddar)
   (NIL "cdddr" _cdddr)
   (NIL "caaaar" _caaaar)
   (NIL "caaadr" _caaadr)
   (NIL "caadar" _caadar)
   (NIL "caaddr" _caaddr)
   (NIL "cadaar" _cadaar)
   (NIL "cadadr" _cadadr)
   (NIL "caddar" _caddar)
   (NIL "cadddr" _cadddr)
   (NIL "cdaaar" _cdaaar)
   (NIL "cdaadr" _cdaadr)
   (NIL "cdadar" _cdadar)
   (NIL "cdaddr" _cdaddr)
   (NIL "cddaar" _cddaar)
   (NIL "cddadr" _cddadr)
   (NIL "cdddar" _cdddar)
   (NIL "cddddr" _cddddr)
   (NIL "nth" _nth)
   (NIL "con" _con)
   (NIL "cons" _cons)
   (NIL "conc" _conc)
   (NIL "circ" _circ)
   (NIL "rot" _rot)
   (NIL "list" _list)
   (NIL "need" _need)
   (NIL "range" _range)
   (NIL "full" _full)
   (NIL "make" _make)
   (NIL "made" _made)
   (NIL "chain" _chain)
   (NIL "link" _link)
   (NIL "yoke" _yoke)
   (NIL "copy" _copy)
   (NIL "mix" _mix)
   (NIL "append" _append)
   (NIL "delete" _delete)
   (NIL "delq" _delq)
   (NIL "replace" _replace)
   (NIL "insert" _insert)
   (NIL "remove" _remove)
   (NIL "place" _place)
   (NIL "strip" _strip)
   (NIL "split" _split)
   (NIL "reverse" _reverse)
   (NIL "flip" _flip)
   (NIL "trim" _trim)
   (NIL "clip" _clip)
   (NIL "head" _head)
   (NIL "tail" _tail)
   (NIL "stem" _stem)
   (NIL "fin" _fin)
   (NIL "last" _last)
   (NIL "==" _eq)
   (NIL "n==" _neq)
   (NIL "=" _equal)
   (NIL "<>" _nequal)
   (NIL "=0" _eq0)
   (NIL "=1" _eq1)
   (NIL "=T" _eqT)
   (NIL "n0" _neq0)
   (NIL "nT" _neqT)
   (NIL "<" _lt)
   (NIL "<=" _le)
   (NIL ">" _gt)
   (NIL ">=" _ge)
   (NIL "max" _max)
   (NIL "min" _min)
   (NIL "atom" _atom)
   (NIL "pair" _pair)
   (NIL "circ?" _circQ)
   (NIL "lst?" _lstQ)
   (NIL "num?" _numQ)
   (NIL "sym?" _symQ)
   (NIL "flg?" _flgQ)
   (NIL "member" _member)
   (NIL "memq" _memq)
   (NIL "mmeq" _mmeq)
   (NIL "sect" _sect)
   (NIL "diff" _diff)
   (NIL "index" _index)
   (NIL "offset" _offset)
   (NIL "prior" _prior)
   (NIL "length" _length)
   (NIL "size" _size)
   (NIL "bytes" _bytes)
   (NIL "assoc" _assoc)
   (NIL "rassoc" _rassoc)
   (NIL "asoq" _asoq)
   (NIL "rank" _rank)
   (NIL "match" _match)
   (NIL "fill" _fill)
   (NIL "prove" _prove)
   (NIL "->" _arrow)
   (NIL "unify" _unify)
   (NIL "group" _group)
   (NIL "sort" _sort)
   # System functions
   (NIL "protect" _protect)
   (NIL "heap" _heap)
   (NIL "stack" _stack)
   (NIL "byte" _byte)
   (NIL "ptr32" _ptr32)
   (NIL "ptr64" _ptr64)
   (NIL "env" _env)
   (NIL "usec" _usec)
   (NIL "quit" _quit)
   (NIL "args" _args)
   (NIL "next" _next)
   (NIL "arg" _arg)
   (NIL "rest" _rest)
   (NIL "adr" _adr)
   (NIL "trail" _trail)
   (NIL "up" _up)
   # Platform/Board
   (NIL "kern"      _kern)
   (NIL "isb"       _isb)
   (NIL "wfi"       _wfi)
   (NIL "wfe"       _wfe)
   (NIL "daif"      _daif)
   (NIL "daif2"     _daif2)
   (NIL "cnt-frq"   _cnt-frq)
   (NIL "cntv-ctl"  _cntv-ctl)
   (NIL "cntv-cval" _cntv-cval)
   (NIL "cntv-tval" _cntv-tval)
   (NIL "cntvct"    _cntvct)
   (NIL "cntp-ctl"  _cntp-ctl)
   (NIL "cntp-cval" _cntp-cval)
   (NIL "cntp-tval" _cntp-tval)
   (NIL "cntpct"    _cntpct)
   ($LastSym "version" _version) )

# GC relevant data
(local) (gcData)

(table gcData
   ($Transient $Nil)    # Short transient names
   (NIL $Nil)           # Long transient names
   ($Alarm $Nil)        # Alarm handler
   ($Sigio $Nil)        # Sigio handler
   ($Lisp $Nil)         # Lisp callbacks: tag+fun
   (NIL $Nil)
   (NIL $Nil)           # 2
   (NIL $Nil)
   (NIL $Nil)           # 3
   (NIL $Nil)
   (NIL $Nil)           # 4
   (NIL $Nil)
   (NIL $Nil)           # 5
   (NIL $Nil)
   (NIL $Nil)           # 6
   (NIL $Nil)
   (NIL $Nil)           # 7
   (NIL $Nil)
   (NIL $Nil)           # 8
   (NIL $Nil)
   (NIL $Nil)           # 9
   (NIL $Nil)
   (NIL $Nil)           # 10
   (NIL $Nil)
   (NIL $Nil)           # 11
   (NIL $Nil)
   (NIL $Nil)           # 12
   (NIL $Nil)
   (NIL $Nil)           # 13
   (NIL $Nil)
   (NIL $Nil)           # 14
   (NIL $Nil)
   (NIL $Nil)           # 15
   (NIL $Nil)
   (NIL $Nil)           # 16
   (NIL $Nil)
   (NIL $Nil)           # 17
   (NIL $Nil)
   (NIL $Nil)           # 18
   (NIL $Nil)
   (NIL $Nil)           # 19
   (NIL $Nil)
   (NIL $Nil)           # 20
   (NIL $Nil)
   (NIL $Nil)           # 21
   (NIL $Nil)
   (NIL $Nil)           # 22
   (NIL $Nil)
   (NIL $Nil)           # 23
   (NIL $Nil)
   (NIL $Nil)           # 24
   ($LispEnd $Nil) )

# Environment
(local) env

(table env
   ($Link 0)                     # Link register
   ($Bind 0)                     # Bind frames
   ($Break 0)                    # Breakpoint
   ($Catch i8* null)             # Catch frames
   ($Current i8* null)           # Current coroutine
   ($Coroutines i8* null)        # Coroutines
   ($InFrames i8* null)          # Input frames
   ($OutFrames i8* null)         # Output frames
   ($ErrFrames i8* null)         # Error frames
   ($CtlFrames i8* null)         # Control frames
   ($Parser i64* null)           # String parser
   ($Intern $Pico1)              # Current namespaces of internal symbols
   ($Next $Nil)                  # Next vararg
   ($Typ 0)                      # Method type
   ($Key 0)                      # Method key
   ($Make 0)                     # 'make' environment
   ($Yoke 0)
   ($Protect i32 0)              # Signal protection
   ($Trace i32 0) )              # Trace level

# Temporary cell
(array $Cell any
   $Nil
   $Nil )

# Version number
(table $Version
   ($Y (short (pico~car *Version)))
   ($M (short (pico~cadr *Version)))
   ($D (short (pico~caddr *Version))) )

# 'T' in PLIO format
(array $TBuf i8
   (+ INTERN 4)
   (char "T") )

# Booleans
(var $Repl  i1 NO)               # REPL flag
(var $PRepl i1 NO)               # Parent REPL
(var $Jam   i1 NO)               # Error jam
(var $InBye i1 NO)               # Exit status

# Strings
(str $Empty "")
(str $Delim " \t\n\r\"'(),[]`{}~")
(str $Kerns
"
(prinl \"No Kernel\")
T
")

# Sys Structs
