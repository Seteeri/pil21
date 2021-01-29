# 24dec20 Software Lab. Alexander Burger

#.SILENT:

CC = clang
PIL = pil  # pil
ASM = opt -O3  # llvm-as
MAIN = -rdynamic -lc -lm
OS = $(shell uname)
CPU = $(shell uname -m)

BIN = ../bin
LIB = ../lib

INC = lib/llvm.l vers.l defs.l glob.l dec.l
SRC = main.l gc.l big.l sym.l io.l db.l apply.l flow.l subr.l

all: $(BIN)/picolisp

# Base system
$(BIN)/picolisp: picolisp.bc
	mkdir -p $(BIN) $(LIB)
	llc picolisp.bc -relocation-model=pic -o picolisp.s
	$(CC) picolisp.s -o $(BIN)/picolisp $(MAIN)

picolisp.bc: base.bc
	llvm-link -o picolisp.bc base.bc

base.bc: base.ll
	$(ASM) -o base.bc base.ll

base.ll: $(INC) $(SRC)
	$(PIL) lib/llvm.l main.l -bye > base.ll

# Clean up
clean:
	rm -f *.ll *.bc *.s
