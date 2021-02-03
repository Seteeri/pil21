# 24dec20 Software Lab. Alexander Burger

#.SILENT:

CC = clang
PIL = pil  # pil
ASM = opt -O3 # llvm-as
MAIN = -march=arm64 #-mcpu=cortex-a72 -mattr=+a72
OS = $(shell uname)
CPU = $(shell uname -m)

BIN = ../bin
LIB = ../lib

INC = lib/llvm.l vers.l defs.l glob.l dec.l
SRC = main.l gc.l big.l sym.l io.l db.l apply.l flow.l subr.l

all: $(BIN)/picolisp

# llc -march=ARCH -mattr=help
# -march=arm64 -mcpu=cortex-a72 -mattr=+a72

# Base system
$(BIN)/picolisp: picolisp.bc
	llc -march=aarch64 picolisp.bc -relocation-model=pic -o picolisp.s

picolisp.bc: base.bc
	llvm-link -o picolisp.bc base.bc

base.bc: base.ll
	$(ASM) -o base.bc base.ll

base.ll: $(INC) $(SRC)
	$(PIL) lib/llvm.l main.l -bye > base.ll

# Clean up
clean:
	rm -f *.ll *.bc *.s
