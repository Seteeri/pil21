# 28sep20 Software Lab. Alexander Burger

(symbols '(llvm))

# Constants
(local) (HEAP CELLS STACK TOP BUFSIZ DB1)

(equ
   HEAP (*/ 1024 1024 8)      # Heap size (number of pointers)
   CELLS (/ HEAP 2)           # Number of cells in a heap (65536)
   STACK (* 64 1024)          # Default coroutine stack size (64 kB)
   TOP (hex "110000")         # Character top
   BUFSIZ 4096                # I/O buffer size
   DB1 (hex "1A")             # Name of '{1}'
   292MY (dec (** 2 63)) )    # 292 million years

# PLIO Tokens
(local) (NIX BEG DOT END NUMBER INTERN TRANSIENT EXTERN)

(equ
   NIX 0        # NIL
   BEG 1        # Begin list
   DOT 2        # Dotted pair
   END 3        # End list
   NUMBER 0     # Number
   INTERN 1     # Internal symbol
   TRANSIENT 2  # Transient symbol
   EXTERN 3 )   # External symbol

# DB-I/O
(local) (BLK BLKSIZE BLKMASK BLKTAG)

(equ
   BLK 6        # Block address size
   BLKSIZE 64   # DB block unit size
   BLKMASK -64  # Block address mask
   BLKTAG 63 )  # Block tag mask

(local)
(BASE-PERI)
(equ #(hex "3F000000")
  BASE-PERI      (hex "FE000000"))

(local)
(AUX-IRQ
 AUX-ENABLES
 AUX-MU-IO-REG
 AUX-MU-IER-REG
 AUX-MU-IIR-REG
 AUX-MU-LCR-REG
 AUX-MU-MCR-REG
 AUX-MU-LSR-REG
 AUX-MU-MSR-REG
 AUX-MU-SCRATCH
 AUX-MU-CNTL-REG
 AUX-MU-STAT-REG
 AUX-MU-BAUD-REG
 AUX-SPI1-CNTL0-REG
 AUX-SPI1-CNTL1-REG
 AUX-SPI1-STAT-REG
 AUX-SPI1-PEEK-REG
 AUX-SPI1-IO-REG
 AUX-SPI1-IO-REG
 AUX-SPI1-IO-REG
 AUX-SPI1-IO-REG
 AUX-SPI1-TXHOLD-REG
 AUX-SPI1-TXHOLD-REG
 AUX-SPI1-TXHOLD-REG
 AUX-SPI1-TXHOLD-REG
 AUX-SPI2-CNTL0-REG
 AUX-SPI2-CNTL1-REG
 AUX-SPI2-STAT-REG
 AUX-SPI2-PEEK-REG
 AUX-SPI2-IO-REG
 AUX-SPI2-IO-REG
 AUX-SPI2-IO-REG
 AUX-SPI2-IO-REG
 AUX-SPI2-TXHOLD-REG
 AUX-SPI2-TXHOLD-REG
 AUX-SPI2-TXHOLD-REG
 AUX-SPI2-TXHOLD-REG)

(equ
  AUX-IRQ             (+ BASE-PERI (hex "00215000")) # Auxiliary Interrupt status 3
  AUX-ENABLES         (+ BASE-PERI (hex "00215004")) # Auxiliary enables 3
  AUX-MU-IO-REG       (+ BASE-PERI (hex "00215040")) # Mini UART I/O Data 8
  AUX-MU-IER-REG      (+ BASE-PERI (hex "00215044")) # Mini UART Interrupt Enable 8
  AUX-MU-IIR-REG      (+ BASE-PERI (hex "00215048")) # Mini UART Interrupt Identify 8
  AUX-MU-LCR-REG      (+ BASE-PERI (hex "0021504C")) # Mini UART Line Control 8
  AUX-MU-MCR-REG      (+ BASE-PERI (hex "00215050")) # Mini UART Modem Control 8
  AUX-MU-LSR-REG      (+ BASE-PERI (hex "00215054")) # Mini UART Line Status 8
  AUX-MU-MSR-REG      (+ BASE-PERI (hex "00215058")) # Mini UART Modem Status 8
  AUX-MU-SCRATCH      (+ BASE-PERI (hex "0021505C")) # Mini UART Scratch 8
  AUX-MU-CNTL-REG     (+ BASE-PERI (hex "00215060")) # Mini UART Extra Control 8
  AUX-MU-STAT-REG     (+ BASE-PERI (hex "00215064")) # Mini UART Extra Status 32
  AUX-MU-BAUD-REG     (+ BASE-PERI (hex "00215068")) # Mini UART Baudrate 16
  AUX-SPI1-CNTL0-REG  (+ BASE-PERI (hex "00215080")) # SPI 1 Control register 0 32
  AUX-SPI1-CNTL1-REG  (+ BASE-PERI (hex "00215084")) # SPI 1 Control register 1 8
  AUX-SPI1-STAT-REG   (+ BASE-PERI (hex "00215088")) # SPI 1 Status 32
  AUX-SPI1-PEEK-REG   (+ BASE-PERI (hex "0021508C")) # SPI 1 Peek 16
  AUX-SPI1-IO-REG     (+ BASE-PERI (hex "002150A0")) # SPI 1 Data 32
  AUX-SPI1-IO-REG     (+ BASE-PERI (hex "002150A4")) # SPI 1 Data 32
  AUX-SPI1-IO-REG     (+ BASE-PERI (hex "002150A8")) # SPI 1 Data 32
  AUX-SPI1-IO-REG     (+ BASE-PERI (hex "002150AC")) # SPI 1 Data 32
  AUX-SPI1-TXHOLD-REG (+ BASE-PERI (hex "002150B0")) # SPI 1 Extended Data 32
  AUX-SPI1-TXHOLD-REG (+ BASE-PERI (hex "002150B4")) # SPI 1 Extended Data 32
  AUX-SPI1-TXHOLD-REG (+ BASE-PERI (hex "002150B8")) # SPI 1 Extended Data 32
  AUX-SPI1-TXHOLD-REG (+ BASE-PERI (hex "002150BC")) # SPI 1 Extended Data 32
  AUX-SPI2-CNTL0-REG  (+ BASE-PERI (hex "002150C0")) # SPI 2 Control register 0 32
  AUX-SPI2-CNTL1-REG  (+ BASE-PERI (hex "002150C4")) # SPI 2 Control register 1 8
  AUX-SPI2-STAT-REG   (+ BASE-PERI (hex "002150C8")) # SPI 2 Status 32
  AUX-SPI2-PEEK-REG   (+ BASE-PERI (hex "002150CC")) # SPI 2 Peek 16
  AUX-SPI2-IO-REG     (+ BASE-PERI (hex "002150E0")) # SPI 2 Data 32
  AUX-SPI2-IO-REG     (+ BASE-PERI (hex "002150E4")) # SPI 2 Data 32
  AUX-SPI2-IO-REG     (+ BASE-PERI (hex "002150E8")) # SPI 2 Data 32
  AUX-SPI2-IO-REG     (+ BASE-PERI (hex "002150EC")) # SPI 2 Data 32
  AUX-SPI2-TXHOLD-REG (+ BASE-PERI (hex "002150F0")) # SPI 2 Extended Data 32
  AUX-SPI2-TXHOLD-REG (+ BASE-PERI (hex "002150F4")) # SPI 2 Extended Data 32
  AUX-SPI2-TXHOLD-REG (+ BASE-PERI (hex "002150F8")) # SPI 2 Extended Data 32
  AUX-SPI2-TXHOLD-REG (+ BASE-PERI (hex "002150FC")) # SPI 2 Extended Data 32
)


(local)
(BASE-GIC
 DIST-CTLR
 DIST-TYPER
 DIST-IIDR
 DIST-IGROUPR
 DIST-ISENABLER
 DIST-ICENABLER
 DIST-ISPENDR
 DIST-ICPENDR
 DIST-ISACTIVER
 DIST-ICACTIVER
 DIST-IPRIORITYR
 DIST-ITARGETSR
 DIST-ICFGR
 DIST-PPISR
 DIST-SPISR
 DIST-SGIR
 DIST-CPENDSGIR
 DIST-SPENDSGIR
 DIST-PIDR4
 DIST-PIDR5
 DIST-PIDR6
 DIST-PIDR7
 DIST-PIDR0
 DIST-PIDR1
 DIST-PIDR2
 DIST-PIDR3
 DIST-CIDR0
 DIST-CIDR1
 DIST-CIDR2
 DIST-CIDR3

 CPUI-CTLR
 CPUI-PMR
 CPUI-BPR
 CPUI-IAR
 CPUI-EOIR
 CPUI-RPR
 CPUI-HPPIR
 CPUI-ABPR
 CPUI-AIAR
 CPUI-AEOIR
 CPUI-AHPPIR
 CPUI-APR0
 CPUI-NSAPR0
 CPUI-IIDR
 CPUI-DIR)

  # DIST-CTLR       (+ (hex "FF840000") (hex "1000"))
(equ
  BASE-GIC        (+ BASE-PERI (hex "1840000"))
  DIST-CTLR       (+ BASE-GIC  (hex "1000"))
  DIST-TYPER      (+ BASE-GIC  (hex "1004"))
  DIST-IIDR       (+ BASE-GIC  (hex "1008"))
  DIST-IGROUPR    (+ BASE-GIC  (hex "1080"))
  DIST-ISENABLER  (+ BASE-GIC  (hex "1100"))
  DIST-ICENABLER  (+ BASE-GIC  (hex "1180"))
  DIST-ISPENDR    (+ BASE-GIC  (hex "1200"))
  DIST-ICPENDR    (+ BASE-GIC  (hex "1280"))
  DIST-ISACTIVER  (+ BASE-GIC  (hex "1300"))
  DIST-ICACTIVER  (+ BASE-GIC  (hex "1380"))
  DIST-IPRIORITYR (+ BASE-GIC  (hex "1400"))
  DIST-ITARGETSR  (+ BASE-GIC  (hex "1800"))
  DIST-ICFGR      (+ BASE-GIC  (hex "1C00"))
  DIST-PPISR      (+ BASE-GIC  (hex "1D00"))
  DIST-SPISR      (+ BASE-GIC  (hex "1D04"))
  DIST-SGIR       (+ BASE-GIC  (hex "1F00"))
  DIST-CPENDSGIR  (+ BASE-GIC  (hex "1F10"))
  DIST-SPENDSGIR  (+ BASE-GIC  (hex "1F20"))
  DIST-PIDR4      (+ BASE-GIC  (hex "1FD0"))
  DIST-PIDR5      (+ BASE-GIC  (hex "1FD4"))
  DIST-PIDR6      (+ BASE-GIC  (hex "1FD8"))
  DIST-PIDR7      (+ BASE-GIC  (hex "1FDC"))
  DIST-PIDR0      (+ BASE-GIC  (hex "1FE0"))
  DIST-PIDR1      (+ BASE-GIC  (hex "1FE4"))
  DIST-PIDR2      (+ BASE-GIC  (hex "1FE8"))
  DIST-PIDR3      (+ BASE-GIC  (hex "1FEC"))
  DIST-CIDR0      (+ BASE-GIC  (hex "1FF0"))
  DIST-CIDR1      (+ BASE-GIC  (hex "1FF4"))
  DIST-CIDR2      (+ BASE-GIC  (hex "1FF8"))
  DIST-CIDR3      (+ BASE-GIC  (hex "1FEC"))

  CPUI-CTLR       (+ BASE-GIC  (hex "2000"))
  CPUI-PMR        (+ BASE-GIC  (hex "2004"))
  CPUI-BPR        (+ BASE-GIC  (hex "2008"))
  CPUI-IAR        (+ BASE-GIC  (hex "200C"))
  CPUI-EOIR       (+ BASE-GIC  (hex "2010"))
  CPUI-RPR        (+ BASE-GIC  (hex "2014"))
  CPUI-HPPIR      (+ BASE-GIC  (hex "2018"))
  CPUI-ABPR       (+ BASE-GIC  (hex "201C"))
  CPUI-AIAR       (+ BASE-GIC  (hex "2020"))
  CPUI-AEOIR      (+ BASE-GIC  (hex "2024"))
  CPUI-AHPPIR     (+ BASE-GIC  (hex "2028"))
  CPUI-APR0       (+ BASE-GIC  (hex "20D0"))
  CPUI-NSAPR0     (+ BASE-GIC  (hex "20E0"))
  CPUI-IIDR       (+ BASE-GIC  (hex "20FC"))
  CPUI-DIR        (+ BASE-GIC  (hex "3000")))


(local)
(UART-TXE
 UART-RXF
 UART-TXF
 UART-RXE
 UART-BUS
 UART-DCD
 UART-DSR
 UART-CTS)

(equ
  UART-TXE       (>> -7 1)
  UART-RXF       (>> -6 1)
  UART-TXF       (>> -5 1)
  UART-RXE       (>> -4 1)
  UART-BUS       (>> -3 1)
  UART-DCD       (>> -2 1)
  UART-DSR       (>> -1 1)
  UART-CTS       (>> -0 1))

# UART0: 0x7E20 1000
# UART2: 0x7E20 1400
# UART3: 0x7E20 1600
# UART4: 0x7E20 1800
# UART5: 0x7E20 1A00

#UART-DR        (+ BASE-PERI (hex "00201000"))
#UART-FR        (+ BASE-PERI (hex "00201018"))

(local)
(BASE-UART0
 UART0-DR
 UART0-RSRECR
 UART0-FR
 UART0-ILPR
 UART0-IBRD
 UART0-FBRD
 UART0-LCRH
 UART0-CR
 UART0-IFLS
 UART0-IMSC
 UART0-RIS
 UART0-MIS
 UART0-ICR
 UART0-DMACR
 UART0-ITCR
 UART0-ITIP
 UART0-ITOP
 UART0-TDR

 UART2-DR
 UART2-RSRECR
 UART2-FR
 UART2-ILPR
 UART2-IBRD
 UART2-FBRD
 UART2-LCRH
 UART2-CR
 UART2-IFLS
 UART2-IMSC
 UART2-RIS
 UART2-MIS
 UART2-ICR
 UART2-DMACR
 UART2-ITCR
 UART2-ITIP
 UART2-ITOP
 UART2-TDR

 UART3-DR
 UART3-RSRECR
 UART3-FR
 UART3-ILPR
 UART3-IBRD
 UART3-FBRD
 UART3-LCRH
 UART3-CR
 UART3-IFLS
 UART3-IMSC
 UART3-RIS
 UART3-MIS
 UART3-ICR
 UART3-DMACR
 UART3-ITCR
 UART3-ITIP
 UART3-ITOP
 UART3-TDR

 UART4-DR
 UART4-RSRECR
 UART4-FR
 UART4-ILPR
 UART4-IBRD
 UART4-FBRD
 UART4-LCRH
 UART4-CR
 UART4-IFLS
 UART4-IMSC
 UART4-RIS
 UART4-MIS
 UART4-ICR
 UART4-DMACR
 UART4-ITCR
 UART4-ITIP
 UART4-ITOP
 UART4-TDR

 UART5-DR
 UART5-RSRECR
 UART5-FR
 UART5-ILPR
 UART5-IBRD
 UART5-FBRD
 UART5-LCRH
 UART5-CR
 UART5-IFLS
 UART5-IMSC
 UART5-RIS
 UART5-MIS
 UART5-ICR
 UART5-DMACR
 UART5-ITCR
 UART5-ITIP
 UART5-ITOP
 UART5-TDR)

(equ
  BASE-UART0   (+ BASE-PERI (hex "00200000"))

  UART0-DR     (+ BASE-UART0 (hex "1000")) # Data Register 32
  UART0-RSRECR (+ BASE-UART0 (hex "1004")) # 32
  UART0-FR     (+ BASE-UART0 (hex "1018")) # Flag register 32
  UART0-ILPR   (+ BASE-UART0 (hex "1020")) # not in use 32
  UART0-IBRD   (+ BASE-UART0 (hex "1024")) # Integer Baud rate divisor 32
  UART0-FBRD   (+ BASE-UART0 (hex "1028")) # Fractional Baud rate divisor 32
  UART0-LCRH   (+ BASE-UART0 (hex "102C")) # Line Control register 32
  UART0-CR     (+ BASE-UART0 (hex "1030")) # Control register 32
  UART0-IFLS   (+ BASE-UART0 (hex "1034")) # Interrupt FIFO Level Select Register 32
  UART0-IMSC   (+ BASE-UART0 (hex "1038")) # Interrupt Mask Set Clear Register 32
  UART0-RIS    (+ BASE-UART0 (hex "103C")) # Raw Interrupt Status Register 32
  UART0-MIS    (+ BASE-UART0 (hex "1040")) # Masked Interrupt Status Register 32
  UART0-ICR    (+ BASE-UART0 (hex "1044")) # Interrupt Clear Register 32
  UART0-DMACR  (+ BASE-UART0 (hex "1048")) # DMA Control Register 32
  UART0-ITCR   (+ BASE-UART0 (hex "1080")) # Test Control register 32
  UART0-ITIP   (+ BASE-UART0 (hex "1084")) # Integration test input reg 32
  UART0-ITOP   (+ BASE-UART0 (hex "1088")) # Integration test output reg 32
  UART0-TDR    (+ BASE-UART0 (hex "108C")) # Test Data reg 32

  UART2-DR     (+ BASE-UART0 (hex "1400")) # Data Register 32
  UART2-RSRECR (+ BASE-UART0 (hex "1404")) # 32
  UART2-FR     (+ BASE-UART0 (hex "1418")) # Flag register 32
  UART2-ILPR   (+ BASE-UART0 (hex "1420")) # not in use 32
  UART2-IBRD   (+ BASE-UART0 (hex "1424")) # Integer Baud rate divisor 32
  UART2-FBRD   (+ BASE-UART0 (hex "1428")) # Fractional Baud rate divisor 32
  UART2-LCRH   (+ BASE-UART0 (hex "142C")) # Line Control register 32
  UART2-CR     (+ BASE-UART0 (hex "1430")) # Control register 32
  UART2-IFLS   (+ BASE-UART0 (hex "1434")) # Interrupt FIFO Level Select Register 32
  UART2-IMSC   (+ BASE-UART0 (hex "1438")) # Interrupt Mask Set Clear Register 32
  UART2-RIS    (+ BASE-UART0 (hex "143C")) # Raw Interrupt Status Register 32
  UART2-MIS    (+ BASE-UART0 (hex "1440")) # Masked Interrupt Status Register 32
  UART2-ICR    (+ BASE-UART0 (hex "1444")) # Interrupt Clear Register 32
  UART2-DMACR  (+ BASE-UART0 (hex "1448")) # DMA Control Register 32
  UART2-ITCR   (+ BASE-UART0 (hex "1480")) # Test Control register 32
  UART2-ITIP   (+ BASE-UART0 (hex "1484")) # Integration test input reg 32
  UART2-ITOP   (+ BASE-UART0 (hex "1488")) # Integration test output reg 32
  UART2-TDR    (+ BASE-UART0 (hex "148C")) # Test Data reg 32

  UART3-DR     (+ BASE-UART0 (hex "1600")) # Data Register 32
  UART3-RSRECR (+ BASE-UART0 (hex "1604")) # 32
  UART3-FR     (+ BASE-UART0 (hex "1618")) # Flag register 32
  UART3-ILPR   (+ BASE-UART0 (hex "1620")) # not in use 32
  UART3-IBRD   (+ BASE-UART0 (hex "1624")) # Integer Baud rate divisor 32
  UART3-FBRD   (+ BASE-UART0 (hex "1628")) # Fractional Baud rate divisor 32
  UART3-LCRH   (+ BASE-UART0 (hex "162C")) # Line Control register 32
  UART3-CR     (+ BASE-UART0 (hex "1630")) # Control register 32
  UART3-IFLS   (+ BASE-UART0 (hex "1634")) # Interrupt FIFO Level Select Register 32
  UART3-IMSC   (+ BASE-UART0 (hex "1638")) # Interrupt Mask Set Clear Register 32
  UART3-RIS    (+ BASE-UART0 (hex "163C")) # Raw Interrupt Status Register 32
  UART3-MIS    (+ BASE-UART0 (hex "1640")) # Masked Interrupt Status Register 32
  UART3-ICR    (+ BASE-UART0 (hex "1644")) # Interrupt Clear Register 32
  UART3-DMACR  (+ BASE-UART0 (hex "1648")) # DMA Control Register 32
  UART3-ITCR   (+ BASE-UART0 (hex "1680")) # Test Control register 32
  UART3-ITIP   (+ BASE-UART0 (hex "1684")) # Integration test input reg 32
  UART3-ITOP   (+ BASE-UART0 (hex "1688")) # Integration test output reg 32
  UART3-TDR    (+ BASE-UART0 (hex "168C")) # Test Data reg 32

  UART4-DR     (+ BASE-UART0 (hex "1800")) # Data Register 32
  UART4-RSRECR (+ BASE-UART0 (hex "1804")) # 32
  UART4-FR     (+ BASE-UART0 (hex "1818")) # Flag register 32
  UART4-ILPR   (+ BASE-UART0 (hex "1820")) # not in use 32
  UART4-IBRD   (+ BASE-UART0 (hex "1824")) # Integer Baud rate divisor 32
  UART4-FBRD   (+ BASE-UART0 (hex "1828")) # Fractional Baud rate divisor 32
  UART4-LCRH   (+ BASE-UART0 (hex "182C")) # Line Control register 32
  UART4-CR     (+ BASE-UART0 (hex "1830")) # Control register 32
  UART4-IFLS   (+ BASE-UART0 (hex "1834")) # Interrupt FIFO Level Select Register 32
  UART4-IMSC   (+ BASE-UART0 (hex "1838")) # Interrupt Mask Set Clear Register 32
  UART4-RIS    (+ BASE-UART0 (hex "183C")) # Raw Interrupt Status Register 32
  UART4-MIS    (+ BASE-UART0 (hex "1840")) # Masked Interrupt Status Register 32
  UART4-ICR    (+ BASE-UART0 (hex "1844")) # Interrupt Clear Register 32
  UART4-DMACR  (+ BASE-UART0 (hex "1848")) # DMA Control Register 32
  UART4-ITCR   (+ BASE-UART0 (hex "1880")) # Test Control register 32
  UART4-ITIP   (+ BASE-UART0 (hex "1884")) # Integration test input reg 32
  UART4-ITOP   (+ BASE-UART0 (hex "1888")) # Integration test output reg 32
  UART4-TDR    (+ BASE-UART0 (hex "188C")) # Test Data reg 32

  UART5-DR     (+ BASE-UART0 (hex "1A00")) # Data Register 32
  UART5-RSRECR (+ BASE-UART0 (hex "1A04")) # 32
  UART5-FR     (+ BASE-UART0 (hex "1A18")) # Flag register 32
  UART5-ILPR   (+ BASE-UART0 (hex "1A20")) # not in use 32
  UART5-IBRD   (+ BASE-UART0 (hex "1A24")) # Integer Baud rate divisor 32
  UART5-FBRD   (+ BASE-UART0 (hex "1A28")) # Fractional Baud rate divisor 32
  UART5-LCRH   (+ BASE-UART0 (hex "1A2C")) # Line Control register 32
  UART5-CR     (+ BASE-UART0 (hex "1A30")) # Control register 32
  UART5-IFLS   (+ BASE-UART0 (hex "1A34")) # Interrupt FIFO Level Select Register 32
  UART5-IMSC   (+ BASE-UART0 (hex "1A38")) # Interrupt Mask Set Clear Register 32
  UART5-RIS    (+ BASE-UART0 (hex "1A3C")) # Raw Interrupt Status Register 32
  UART5-MIS    (+ BASE-UART0 (hex "1A40")) # Masked Interrupt Status Register 32
  UART5-ICR    (+ BASE-UART0 (hex "1A44")) # Interrupt Clear Register 32
  UART5-DMACR  (+ BASE-UART0 (hex "1A48")) # DMA Control Register 32
  UART5-ITCR   (+ BASE-UART0 (hex "1A80")) # Test Control register 32
  UART5-ITIP   (+ BASE-UART0 (hex "1A84")) # Integration test input reg 32
  UART5-ITOP   (+ BASE-UART0 (hex "1A88")) # Integration test output reg 32
  UART5-TDR    (+ BASE-UART0 (hex "1A8C")) # Test Data reg 32
)



(local)
(IRQ-CORE-N-HP-TIMER
 IRQ-CORE-N-V-TIMER
 IRQ-LEGACY-FIQn
 IRQ-CORE-N-PS-TIMER
 IRQ-CORE-N-PNS-TIMER
 IRQ-LEGACY-IRQn


 IRQ-MAILBOX-0
 IRQ-MAILBOX-1
 IRQ-MAILBOX-2
 IRQ-MAILBOX-3
 IRQ-MAILBOX-4
 IRQ-MAILBOX-5
 IRQ-MAILBOX-6
 IRQ-MAILBOX-7
 IRQ-MAILBOX-8
 IRQ-MAILBOX-9
 IRQ-MAILBOX-10
 IRQ-MAILBOX-11
 IRQ-MAILBOX-12
 IRQ-MAILBOX-13
 IRQ-MAILBOX-14
 IRQ-MAILBOX-15


 IRQ-CORE-0-PMU
 IRQ-CORE-1-PMU
 IRQ-CORE-2-PMU
 IRQ-CORE-3-PMU
 IRQ-AXIERR
 IRQ-LOCAL-TIMER


 IRQ-TIMER
 IRQ-MAILBOX
 IRQ-DOORBELL-0
 IRQ-DOORBELL-1
 IRQ-VPU0-HALTED
 IRQ-VPU1-HALTED
 IRQ-ARM-ADDRESS-ERROR
 IRQ-ARM-AXI-ERROR
 IRQ-SOFTWARE-INTERRUPT-0
 IRQ-SOFTWARE-INTERRUPT-1
 IRQ-SOFTWARE-INTERRUPT-2
 IRQ-SOFTWARE-INTERRUPT-3
 IRQ-SOFTWARE-INTERRUPT-4
 IRQ-SOFTWARE-INTERRUPT-5
 IRQ-SOFTWARE-INTERRUPT-6
 IRQ-SOFTWARE-INTERRUPT-7


 IRQ-TIMER-0
 IRQ-TIMER-1
 IRQ-TIMER-2
 IRQ-TIMER-3
 IRQ-H264-0
 IRQ-H264-1
 IRQ-H264-2
 IRQ-JPEG
 IRQ-ISP
 IRQ-USB
 IRQ-V3D
 IRQ-TRANSPOSER
 IRQ-MULTICORE-SYNC-0
 IRQ-MULTICORE-SYNC-1
 IRQ-MULTICORE-SYNC-2
 IRQ-MULTICORE-SYNC-3
 IRQ-DMA-0
 IRQ-DMA-1
 IRQ-DMA-2
 IRQ-DMA-3
 IRQ-DMA-4
 IRQ-DMA-5
 IRQ-DMA-6
 IRQ-DMA-7&8
 IRQ-DMA-9&10
 IRQ-DMA-11
 IRQ-DMA-12
 IRQ-DMA-13
 IRQ-DMA-14
 IRQ-AUX
 IRQ-ARM
 IRQ-DMA-15
 IRQ-HDMI-CEC
 IRQ-HVS
 IRQ-RPIVID
 IRQ-SDC
 IRQ-DSI-0
 IRQ-PIXEL-VALVE-2
 IRQ-CAMERA-0
 IRQ-CAMERA-1
 IRQ-HDMI-0
 IRQ-HDMI-1
 IRQ-PIXEL-VALVE-3
 IRQ-SPI/BSC-SLAVE
 IRQ-DSI-1
 IRQ-PIXEL-VALVE-0
 IRQ-PIXEL-VALVE-1&4
 IRQ-CPR
 IRQ-SMI
 IRQ-GPIO-0
 IRQ-GPIO-1
 IRQ-GPIO-2
 IRQ-GPIO-3
 IRQ-I2C-ALL
 IRQ-SPI-ALL
 IRQ-PCM/I2S
 IRQ-SDHOST
 IRQ-PL011-UART-ALL
 IRQ-ETH-PCIe-L2-ALL
 IRQ-VEC
 IRQ-CPG
 IRQ-RNG
 IRQ-EMMC&2
 IRQ-ETH-PCIe-SECURE


 IRQ-AVS
 IRQ-PCIE-0-INTA
 IRQ-PCIE-0-INTB
 IRQ-PCIE-0-INTC
 IRQ-PCIE-0-INTD
 IRQ-PCIE-0-MSI
 IRQ-GENET-0-A
 IRQ-GENET-0-B
 IRQ-USB0-XHCI-0)

(equ
  # PPI : [0,31]   (banked)
  #   SGI : [0,15] (banked)
  # SPI : [32,1019]
  IRQ-CORE-N-HP-TIMER      26  # hypervisor timer
  IRQ-CORE-N-V-TIMER       27  # virtual timer
  IRQ-LEGACY-FIQn          28
  IRQ-CORE-N-PS-TIMER      29  # secure physical
  IRQ-CORE-N-PNS-TIMER     30  # non-secure physical
  IRQ-LEGACY-IRQn          31


  IRQ-MAILBOX-0            32
  IRQ-MAILBOX-1            33
  IRQ-MAILBOX-2            34
  IRQ-MAILBOX-3            35
  IRQ-MAILBOX-4            36
  IRQ-MAILBOX-5            37
  IRQ-MAILBOX-6            38
  IRQ-MAILBOX-7            39
  IRQ-MAILBOX-8            40
  IRQ-MAILBOX-9            41
  IRQ-MAILBOX-10           42
  IRQ-MAILBOX-11           43
  IRQ-MAILBOX-12           44
  IRQ-MAILBOX-13           45
  IRQ-MAILBOX-14           46
  IRQ-MAILBOX-15           47


  IRQ-CORE-0-PMU           48
  IRQ-CORE-1-PMU           48
  IRQ-CORE-2-PMU           48
  IRQ-CORE-3-PMU           48
  IRQ-AXIERR               52
  IRQ-LOCAL-TIMER          53


  IRQ-TIMER                64
  IRQ-MAILBOX              65
  IRQ-DOORBELL-0           66
  IRQ-DOORBELL-1           67
  IRQ-VPU0-HALTED          68
  IRQ-VPU1-HALTED          69
  IRQ-ARM-ADDRESS-ERROR    70
  IRQ-ARM-AXI-ERROR        71
  IRQ-SOFTWARE-INTERRUPT-0 72
  IRQ-SOFTWARE-INTERRUPT-1 73
  IRQ-SOFTWARE-INTERRUPT-2 74
  IRQ-SOFTWARE-INTERRUPT-3 75
  IRQ-SOFTWARE-INTERRUPT-4 76
  IRQ-SOFTWARE-INTERRUPT-5 77
  IRQ-SOFTWARE-INTERRUPT-6 78
  IRQ-SOFTWARE-INTERRUPT-7 79


  IRQ-TIMER-0              96
  IRQ-TIMER-1              97
  IRQ-TIMER-2              98
  IRQ-TIMER-3              99
  IRQ-H264-0               100
  IRQ-H264-1               101
  IRQ-H264-2               102
  IRQ-JPEG                 103
  IRQ-ISP                  104
  IRQ-USB                  105
  IRQ-V3D                  106
  IRQ-TRANSPOSER           107
  IRQ-MULTICORE-SYNC-0     108
  IRQ-MULTICORE-SYNC-1     109
  IRQ-MULTICORE-SYNC-2     110
  IRQ-MULTICORE-SYNC-3     111
  IRQ-DMA-0                112
  IRQ-DMA-1                113
  IRQ-DMA-2                114
  IRQ-DMA-3                115
  IRQ-DMA-4                116
  IRQ-DMA-5                117
  IRQ-DMA-6                118
  IRQ-DMA-7&8              119
  IRQ-DMA-9&10             120
  IRQ-DMA-11               121
  IRQ-DMA-12               122
  IRQ-DMA-13               123
  IRQ-DMA-14               124
  IRQ-AUX                  125 # UART1 + SPI1/2, Figure 6. Peripheral IRQ OR-ing
  IRQ-ARM                  126
  IRQ-DMA-15               127
  IRQ-HDMI-CEC             128
  IRQ-HVS                  129
  IRQ-RPIVID               130
  IRQ-SDC                  131
  IRQ-DSI-0                132
  IRQ-PIXEL-VALVE-2        133
  IRQ-CAMERA-0             134
  IRQ-CAMERA-1             135
  IRQ-HDMI-0               136
  IRQ-HDMI-1               137
  IRQ-PIXEL-VALVE-3        138
  IRQ-SPI/BSC-SLAVE        139
  IRQ-DSI-1                140
  IRQ-PIXEL-VALVE-0        141
  IRQ-PIXEL-VALVE-1&4      142
  IRQ-CPR                  143
  IRQ-SMI                  144
  IRQ-GPIO-0               145
  IRQ-GPIO-1               146
  IRQ-GPIO-2               147
  IRQ-GPIO-3               148
  IRQ-I2C-ALL              149 # [0-6], Figure 6. Peripheral IRQ OR-ing
  IRQ-SPI-ALL              150 # [0-7], Figure 6. Peripheral IRQ OR-ing
  IRQ-PCM/I2S              151
  IRQ-SDHOST               152
  IRQ-PL011-UART-ALL       153 # UART5/4/3/2/0, Figure 6. Peripheral IRQ OR-ing
  IRQ-ETH-PCIe-L2-ALL      154
  IRQ-VEC                  155
  IRQ-CPG                  156
  IRQ-RNG                  157
  IRQ-EMMC&2               158
  IRQ-ETH-PCIe-SECURE      159


  IRQ-AVS                  (+ 160 9)  # ...216
  IRQ-PCIE-0-INTA          (+ 160 15)
  IRQ-PCIE-0-INTB          (+ 160 16)
  IRQ-PCIE-0-INTC          (+ 160 17)
  IRQ-PCIE-0-INTD          (+ 160 18)
  IRQ-PCIE-0-MSI           (+ 160 20)
  IRQ-GENET-0-A            (+ 160 29)
  IRQ-GENET-0-B            (+ 160 30)
  IRQ-USB0-XHCI-0          (+ 160 48)

  IRQ-MAX   1024)
