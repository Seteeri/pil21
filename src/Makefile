# 24dec20 Software Lab. Alexander Burger

#.SILENT:

CC = clang
PIL = pil  # pil
ASM = opt -O0 # llvm-as
MAIN = -march=aarch64 -mcpu=cortex-a72 -mattr=+strict-align #-mattr=+a72
OS = $(shell uname)
CPU = $(shell uname -m)

BIN = ../bin
LIB = ../lib

INC = lib/llvm.l vers.l defs.l glob.l dec.l
SRC = main.l gc.l big.l sym.l io.l db.l apply.l flow.l subr.l

all: $(BIN)/picolisp

# llc -march=ARCH -mattr=help
# -march=arm64 -mcpu=cortex-a72 -mattr=+a72
# -relocation-model=pic

#  --stack-alignment=<uint>                                             - Override default stack alignment
#  --stack-size-section                                                 - Emit a section containing stack size metadata
#  --stack-symbol-ordering                                              - Order local stack symbols.
#  --stackrealign                                                       - Force align the stack to the minimum alignment

# Base system
$(BIN)/picolisp: picolisp.bc
	llc $(MAIN) picolisp.bc  -o picolisp.s

picolisp.bc: base.bc
	llvm-link -o picolisp.bc base.bc

base.bc: base.ll
	$(ASM) -o base.bc base.ll

base.ll: $(INC) $(SRC)
	$(PIL) lib/llvm.l main.l -bye > base.ll

# Clean up
clean:
	rm -f *.ll *.bc *.s
