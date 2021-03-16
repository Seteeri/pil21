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

## Sync src/lib.c 'gSignal' and src/glob.l '$Signal'
(local) (SIGHUP SIGINT SIGUSR1 SIGUSR2 SIGPIPE SIGALRM SIGTERM SIGCHLD SIGCONT
SIGSTOP SIGTSTP SIGTTIN SIGTTOU SIGWINCH SIGIO)

(equ
   SIGHUP    1
   SIGINT    2
   SIGUSR1   3
   SIGUSR2   4
   SIGPIPE   5
   SIGALRM   6
   SIGTERM   7
   SIGCHLD   8
   SIGCONT   9
   SIGSTOP  10
   SIGTSTP  11
   SIGTTIN  12
   SIGTTOU  13
   SIGWINCH 14
   SIGIO    15 )

## Sync src/lib.c 'gErrno'
(local) (ENOENT EINTR EBADF EAGAIN EACCES EPIPE ECONNRESET)

(equ
   ENOENT     1      # No such file or directory
   EINTR      2      # Interrupted system call
   EBADF      3      # Bad file number
   EAGAIN     4      # Try again
   EACCES     5      # Permission denied
   EPIPE      6      # Broken pipe
   ECONNRESET 7 )    # Connection reset by peer
   
   
(local) 
(BASE-PERI     
 AUX-ENABLE    
 AUX-MU-IO     
 AUX-MU-IER    
 AUX-MU-IIR    
 AUX-MU-LCR    
 AUX-MU-MCR    
 AUX-MU-LSR    
 AUX-MU-MSR    
 AUX-MU-SCRATCH
 AUX-MU-CNTL   
 AUX-MU-STAT   
 AUX-MU-BAUD)
 
(equ
  BASE-PERI      (hex "FE000000") #(hex "3F000000")
  
  AUX-ENABLE     (+ BASE-PERI (hex "00215004"))
  AUX-MU-IO      (+ BASE-PERI (hex "00215040"))
  AUX-MU-IER     (+ BASE-PERI (hex "00215044"))
  AUX-MU-IIR     (+ BASE-PERI (hex "00215048"))
  AUX-MU-LCR     (+ BASE-PERI (hex "0021504C"))
  AUX-MU-MCR     (+ BASE-PERI (hex "00215050"))
  AUX-MU-LSR     (+ BASE-PERI (hex "00215054"))
  AUX-MU-MSR     (+ BASE-PERI (hex "00215058"))
  AUX-MU-SCRATCH (+ BASE-PERI (hex "0021505C"))
  AUX-MU-CNTL    (+ BASE-PERI (hex "00215060"))
  AUX-MU-STAT    (+ BASE-PERI (hex "00215064"))
  AUX-MU-BAUD    (+ BASE-PERI (hex "00215068")))

  
(local) 
(UART-DR 
 UART-FR 
 UART-TXE
 UART-RXF
 UART-TXF
 UART-RXE
 UART-BUS
 UART-DCD
 UART-DSR
 UART-CTS)
 
(equ
  UART-DR        (+ BASE-PERI (hex "00201000"))
  UART-FR        (+ BASE-PERI (hex "00201018"))
  UART-TXE       (>> -7 1)
  UART-RXF       (>> -6 1)
  UART-TXF       (>> -5 1)
  UART-RXE       (>> -4 1)
  UART-BUS       (>> -3 1)
  UART-DCD       (>> -2 1)
  UART-DSR       (>> -1 1)
  UART-CTS       (>> -0 1))
  
  
(local) 
(GICD-CTL       
 GICD-TYPE-R    
 GICD-I-ID      
 GICD-I-GROUP   
 GICD-IS-ENAB   
 GICD-IC-ENAB   
 GICD-IS-PEND   
 GICD-IC-PEND   
 GICD-IS-ACT    
 GICD-IC-ACT    
 GICD-I-PRIO    
 GICD-I-TGTS    
 GICD-I-CFG     
 GICD-PPI-S     
 GICD-SPI-S     
 GICD-SGI       
 GICD-C-PEND-SGI
 GICD-S-PEND-SGI
 GICD-PID-4     
 GICD-PID-5     
 GICD-PID-6     
 GICD-PID-7     
 GICD-PID-0     
 GICD-PID-1     
 GICD-PID-2     
 GICD-PID-3     
 GICD-CID-0     
 GICD-CID-1     
 GICD-CID-2     
 GICD-CID-3     
 GICC-CTL   
 GICC-PM    
 GICC-BP    
 GICC-IA    
 GICC-EOI   
 GICC-RP    
 GICC-HPPI  
 GICC-ABP   
 GICC-AIA   
 GICC-AEOI  
 GICC-AHPPI 
 GICC-AP0   
 GICC-NS-AP0
 GICC-IID   
 GICC-DI)
 
(equ 
  GICD-CTL        (+ (hex "FF840000") (hex "1000"))
  GICD-TYPE-R     (+ (hex "FF840000") (hex "1004"))
  GICD-I-ID       (+ (hex "FF840000") (hex "1008"))
  GICD-I-GROUP    (+ (hex "FF840000") (hex "1080"))
  GICD-IS-ENAB    (+ (hex "FF840000") (hex "1100"))
  GICD-IC-ENAB    (+ (hex "FF840000") (hex "1180")) 
  GICD-IS-PEND    (+ (hex "FF840000") (hex "1200"))
  GICD-IC-PEND    (+ (hex "FF840000") (hex "1280"))
  GICD-IS-ACT     (+ (hex "FF840000") (hex "1300"))
  GICD-IC-ACT     (+ (hex "FF840000") (hex "1380"))
  GICD-I-PRIO     (+ (hex "FF840000") (hex "1400"))
  GICD-I-TGTS     (+ (hex "FF840000") (hex "1800"))
  GICD-I-CFG      (+ (hex "FF840000") (hex "1C00"))
  GICD-PPI-S      (+ (hex "FF840000") (hex "1D00"))   
  GICD-SPI-S      (+ (hex "FF840000") (hex "1D04"))
  GICD-SGI        (+ (hex "FF840000") (hex "1F00"))
  GICD-C-PEND-SGI (+ (hex "FF840000") (hex "1F10"))
  GICD-S-PEND-SGI (+ (hex "FF840000") (hex "1F20")) 
  GICD-PID-4      (+ (hex "FF840000") (hex "1FD0"))
  GICD-PID-5      (+ (hex "FF840000") (hex "1FD4"))
  GICD-PID-6      (+ (hex "FF840000") (hex "1FD8"))
  GICD-PID-7      (+ (hex "FF840000") (hex "1FDC"))   
  GICD-PID-0      (+ (hex "FF840000") (hex "1FE0"))
  GICD-PID-1      (+ (hex "FF840000") (hex "1FE4"))
  GICD-PID-2      (+ (hex "FF840000") (hex "1FE8"))
  GICD-PID-3      (+ (hex "FF840000") (hex "1FEC"))
  GICD-CID-0      (+ (hex "FF840000") (hex "1FF0"))   
  GICD-CID-1      (+ (hex "FF840000") (hex "1FF4"))
  GICD-CID-2      (+ (hex "FF840000") (hex "1FF8"))
  GICD-CID-3      (+ (hex "FF840000") (hex "1FEC"))
  
  GICC-CTL    (+ (hex "FF840000") (hex "2000"))
  GICC-PM     (+ (hex "FF840000") (hex "2004"))
  GICC-BP     (+ (hex "FF840000") (hex "2008"))
  GICC-IA     (+ (hex "FF840000") (hex "200C"))
  GICC-EOI    (+ (hex "FF840000") (hex "2010"))
  GICC-RP     (+ (hex "FF840000") (hex "2014"))  
  GICC-HPPI   (+ (hex "FF840000") (hex "2018"))
  GICC-ABP    (+ (hex "FF840000") (hex "201C"))  
  GICC-AIA    (+ (hex "FF840000") (hex "2020"))
  GICC-AEOI   (+ (hex "FF840000") (hex "2024"))  
  GICC-AHPPI  (+ (hex "FF840000") (hex "2028"))
  GICC-AP0    (+ (hex "FF840000") (hex "20D0"))  
  GICC-NS-AP0 (+ (hex "FF840000") (hex "20E0"))    
  GICC-IID    (+ (hex "FF840000") (hex "20FC"))
  GICC-DI     (+ (hex "FF840000") (hex "3000")))

  
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
