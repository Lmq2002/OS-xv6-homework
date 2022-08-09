
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0ac78793          	addi	a5,a5,172 # 80006110 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f0e78793          	addi	a5,a5,-242 # 80000fbc <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	4a2080e7          	jalr	1186(ra) # 800025c0 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	b88080e7          	jalr	-1144(ra) # 80000d0e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00002097          	auipc	ra,0x2
    800001ba:	942080e7          	jalr	-1726(ra) # 80001af8 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	142080e7          	jalr	322(ra) # 80002308 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	368080e7          	jalr	872(ra) # 8000256a <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	ba4080e7          	jalr	-1116(ra) # 80000dc2 <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	b8e080e7          	jalr	-1138(ra) # 80000dc2 <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	a48080e7          	jalr	-1464(ra) # 80000d0e <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	332080e7          	jalr	818(ra) # 80002616 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	ace080e7          	jalr	-1330(ra) # 80000dc2 <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	056080e7          	jalr	86(ra) # 8000248e <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00001097          	auipc	ra,0x1
    8000045e:	824080e7          	jalr	-2012(ra) # 80000c7e <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	00020797          	auipc	a5,0x20
    8000046e:	a3678793          	addi	a5,a5,-1482 # 8001fea0 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b8250513          	addi	a0,a0,-1150 # 800080e0 <digits+0xa0>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	71c080e7          	jalr	1820(ra) # 80000d0e <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	66c080e7          	jalr	1644(ra) # 80000dc2 <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	502080e7          	jalr	1282(ra) # 80000c7e <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	4ac080e7          	jalr	1196(ra) # 80000c7e <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	4d4080e7          	jalr	1236(ra) # 80000cc2 <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	542080e7          	jalr	1346(ra) # 80000d62 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	bfc080e7          	jalr	-1028(ra) # 8000248e <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	438080e7          	jalr	1080(ra) # 80000d0e <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	9ea080e7          	jalr	-1558(ra) # 80002308 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	468080e7          	jalr	1128(ra) # 80000dc2 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	348080e7          	jalr	840(ra) # 80000d0e <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	3ea080e7          	jalr	1002(ra) # 80000dc2 <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
*/

//释放pa块
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  //新的空闲链表
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebbd                	bnez	a5,80000a70 <kfree+0x86>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00023797          	auipc	a5,0x23
    80000a02:	60278793          	addi	a5,a5,1538 # 80024000 <end>
    80000a06:	06f56563          	bltu	a0,a5,80000a70 <kfree+0x86>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	06f57163          	bgeu	a0,a5,80000a70 <kfree+0x86>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	3f4080e7          	jalr	1012(ra) # 80000e0a <memset>

  r = (struct run*)pa;

  //获取当前内核id
  push_off();
    80000a1e:	00000097          	auipc	ra,0x0
    80000a22:	2a4080e7          	jalr	676(ra) # 80000cc2 <push_off>
  int currentid=cpuid();
    80000a26:	00001097          	auipc	ra,0x1
    80000a2a:	0a6080e7          	jalr	166(ra) # 80001acc <cpuid>
    80000a2e:	892a                	mv	s2,a0
  pop_off();
    80000a30:	00000097          	auipc	ra,0x0
    80000a34:	332080e7          	jalr	818(ra) # 80000d62 <pop_off>

  acquire(&kmems[currentid].lock);
    80000a38:	00591513          	slli	a0,s2,0x5
    80000a3c:	00011917          	auipc	s2,0x11
    80000a40:	84490913          	addi	s2,s2,-1980 # 80011280 <kmems>
    80000a44:	992a                	add	s2,s2,a0
    80000a46:	854a                	mv	a0,s2
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2c6080e7          	jalr	710(ra) # 80000d0e <acquire>
  r->next = kmems[currentid].freelist;
    80000a50:	01893783          	ld	a5,24(s2)
    80000a54:	e09c                	sd	a5,0(s1)
  kmems[currentid].freelist = r;
    80000a56:	00993c23          	sd	s1,24(s2)
  release(&kmems[currentid].lock);
    80000a5a:	854a                	mv	a0,s2
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	366080e7          	jalr	870(ra) # 80000dc2 <release>

}
    80000a64:	60e2                	ld	ra,24(sp)
    80000a66:	6442                	ld	s0,16(sp)
    80000a68:	64a2                	ld	s1,8(sp)
    80000a6a:	6902                	ld	s2,0(sp)
    80000a6c:	6105                	addi	sp,sp,32
    80000a6e:	8082                	ret
    panic("kfree");
    80000a70:	00007517          	auipc	a0,0x7
    80000a74:	5f050513          	addi	a0,a0,1520 # 80008060 <digits+0x20>
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	ab8080e7          	jalr	-1352(ra) # 80000530 <panic>

0000000080000a80 <freerange>:
{
    80000a80:	7179                	addi	sp,sp,-48
    80000a82:	f406                	sd	ra,40(sp)
    80000a84:	f022                	sd	s0,32(sp)
    80000a86:	ec26                	sd	s1,24(sp)
    80000a88:	e84a                	sd	s2,16(sp)
    80000a8a:	e44e                	sd	s3,8(sp)
    80000a8c:	e052                	sd	s4,0(sp)
    80000a8e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a90:	6785                	lui	a5,0x1
    80000a92:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a96:	94aa                	add	s1,s1,a0
    80000a98:	757d                	lui	a0,0xfffff
    80000a9a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9c:	94be                	add	s1,s1,a5
    80000a9e:	0095ee63          	bltu	a1,s1,80000aba <freerange+0x3a>
    80000aa2:	892e                	mv	s2,a1
    kfree(p);
    80000aa4:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa6:	6985                	lui	s3,0x1
    kfree(p);
    80000aa8:	01448533          	add	a0,s1,s4
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	f3e080e7          	jalr	-194(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe9979e3          	bgeu	s2,s1,80000aa8 <freerange+0x28>
}
    80000aba:	70a2                	ld	ra,40(sp)
    80000abc:	7402                	ld	s0,32(sp)
    80000abe:	64e2                	ld	s1,24(sp)
    80000ac0:	6942                	ld	s2,16(sp)
    80000ac2:	69a2                	ld	s3,8(sp)
    80000ac4:	6a02                	ld	s4,0(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	7179                	addi	sp,sp,-48
    80000acc:	f406                	sd	ra,40(sp)
    80000ace:	f022                	sd	s0,32(sp)
    80000ad0:	ec26                	sd	s1,24(sp)
    80000ad2:	e84a                	sd	s2,16(sp)
    80000ad4:	e44e                	sd	s3,8(sp)
    80000ad6:	1800                	addi	s0,sp,48
  for(int i=0;i<NCPU;i++)
    80000ad8:	00010497          	auipc	s1,0x10
    80000adc:	7a848493          	addi	s1,s1,1960 # 80011280 <kmems>
    80000ae0:	00011997          	auipc	s3,0x11
    80000ae4:	8a098993          	addi	s3,s3,-1888 # 80011380 <pid_lock>
    initlock(&kmems[i].lock,"kmem");
    80000ae8:	00007917          	auipc	s2,0x7
    80000aec:	58090913          	addi	s2,s2,1408 # 80008068 <digits+0x28>
    80000af0:	85ca                	mv	a1,s2
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	18a080e7          	jalr	394(ra) # 80000c7e <initlock>
  for(int i=0;i<NCPU;i++)
    80000afc:	02048493          	addi	s1,s1,32
    80000b00:	ff3498e3          	bne	s1,s3,80000af0 <kinit+0x26>
  freerange(end,(void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00023517          	auipc	a0,0x23
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80024000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f70080e7          	jalr	-144(ra) # 80000a80 <freerange>
}
    80000b18:	70a2                	ld	ra,40(sp)
    80000b1a:	7402                	ld	s0,32(sp)
    80000b1c:	64e2                	ld	s1,24(sp)
    80000b1e:	6942                	ld	s2,16(sp)
    80000b20:	69a2                	ld	s3,8(sp)
    80000b22:	6145                	addi	sp,sp,48
    80000b24:	8082                	ret

0000000080000b26 <popr>:
  return (void*)r;
}

struct run *
popr(int id)
{
    80000b26:	1141                	addi	sp,sp,-16
    80000b28:	e422                	sd	s0,8(sp)
    80000b2a:	0800                	addi	s0,sp,16
    80000b2c:	87aa                	mv	a5,a0
  struct run *r;
  r =kmems[id].freelist;
    80000b2e:	00551693          	slli	a3,a0,0x5
    80000b32:	00010717          	auipc	a4,0x10
    80000b36:	74e70713          	addi	a4,a4,1870 # 80011280 <kmems>
    80000b3a:	9736                	add	a4,a4,a3
    80000b3c:	6f08                	ld	a0,24(a4)
  if(r)
    80000b3e:	c909                	beqz	a0,80000b50 <popr+0x2a>
    kmems[id].freelist=r->next;
    80000b40:	6114                	ld	a3,0(a0)
    80000b42:	0796                	slli	a5,a5,0x5
    80000b44:	00010717          	auipc	a4,0x10
    80000b48:	73c70713          	addi	a4,a4,1852 # 80011280 <kmems>
    80000b4c:	97ba                	add	a5,a5,a4
    80000b4e:	ef94                	sd	a3,24(a5)
  return r;
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <pushr>:

void 
pushr(int id, struct run *r)
{
  if(r){
    80000b56:	c999                	beqz	a1,80000b6c <pushr+0x16>
    r->next=kmems[id].freelist;
    80000b58:	0516                	slli	a0,a0,0x5
    80000b5a:	00010797          	auipc	a5,0x10
    80000b5e:	72678793          	addi	a5,a5,1830 # 80011280 <kmems>
    80000b62:	953e                	add	a0,a0,a5
    80000b64:	6d1c                	ld	a5,24(a0)
    80000b66:	e19c                	sd	a5,0(a1)
    kmems[id].freelist = r;
    80000b68:	ed0c                	sd	a1,24(a0)
    80000b6a:	8082                	ret
{
    80000b6c:	1141                	addi	sp,sp,-16
    80000b6e:	e406                	sd	ra,8(sp)
    80000b70:	e022                	sd	s0,0(sp)
    80000b72:	0800                	addi	s0,sp,16
  }
  else{
    panic("cannot push null run");
    80000b74:	00007517          	auipc	a0,0x7
    80000b78:	4fc50513          	addi	a0,a0,1276 # 80008070 <digits+0x30>
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	9b4080e7          	jalr	-1612(ra) # 80000530 <panic>

0000000080000b84 <kalloc>:
{
    80000b84:	7179                	addi	sp,sp,-48
    80000b86:	f406                	sd	ra,40(sp)
    80000b88:	f022                	sd	s0,32(sp)
    80000b8a:	ec26                	sd	s1,24(sp)
    80000b8c:	e84a                	sd	s2,16(sp)
    80000b8e:	e44e                	sd	s3,8(sp)
    80000b90:	e052                	sd	s4,0(sp)
    80000b92:	1800                	addi	s0,sp,48
  push_off();
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	12e080e7          	jalr	302(ra) # 80000cc2 <push_off>
  int currentid = cpuid();
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	f30080e7          	jalr	-208(ra) # 80001acc <cpuid>
    80000ba4:	892a                	mv	s2,a0
  pop_off();
    80000ba6:	00000097          	auipc	ra,0x0
    80000baa:	1bc080e7          	jalr	444(ra) # 80000d62 <pop_off>
  acquire(&kmems[currentid].lock);
    80000bae:	00591793          	slli	a5,s2,0x5
    80000bb2:	00010a17          	auipc	s4,0x10
    80000bb6:	6cea0a13          	addi	s4,s4,1742 # 80011280 <kmems>
    80000bba:	9a3e                	add	s4,s4,a5
    80000bbc:	8552                	mv	a0,s4
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	150080e7          	jalr	336(ra) # 80000d0e <acquire>
  r = popr(currentid);//返回值为原列表
    80000bc6:	854a                	mv	a0,s2
    80000bc8:	00000097          	auipc	ra,0x0
    80000bcc:	f5e080e7          	jalr	-162(ra) # 80000b26 <popr>
    80000bd0:	89aa                	mv	s3,a0
  if(!r)//原列表是空的
    80000bd2:	c515                	beqz	a0,80000bfe <kalloc+0x7a>
  release(&kmems[currentid].lock);
    80000bd4:	8552                	mv	a0,s4
    80000bd6:	00000097          	auipc	ra,0x0
    80000bda:	1ec080e7          	jalr	492(ra) # 80000dc2 <release>
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bde:	6605                	lui	a2,0x1
    80000be0:	4595                	li	a1,5
    80000be2:	854e                	mv	a0,s3
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	226080e7          	jalr	550(ra) # 80000e0a <memset>
}
    80000bec:	854e                	mv	a0,s3
    80000bee:	70a2                	ld	ra,40(sp)
    80000bf0:	7402                	ld	s0,32(sp)
    80000bf2:	64e2                	ld	s1,24(sp)
    80000bf4:	6942                	ld	s2,16(sp)
    80000bf6:	69a2                	ld	s3,8(sp)
    80000bf8:	6a02                	ld	s4,0(sp)
    80000bfa:	6145                	addi	sp,sp,48
    80000bfc:	8082                	ret
    80000bfe:	00010797          	auipc	a5,0x10
    80000c02:	68278793          	addi	a5,a5,1666 # 80011280 <kmems>
    for(int id=0;id<NCPU;id++)
    80000c06:	4481                	li	s1,0
    80000c08:	46a1                	li	a3,8
    80000c0a:	a031                	j	80000c16 <kalloc+0x92>
    80000c0c:	2485                	addiw	s1,s1,1
    80000c0e:	02078793          	addi	a5,a5,32
    80000c12:	06d48063          	beq	s1,a3,80000c72 <kalloc+0xee>
      if(id==currentid)continue;
    80000c16:	fe990be3          	beq	s2,s1,80000c0c <kalloc+0x88>
      if(kmems[id].freelist)//有空闲块
    80000c1a:	6f98                	ld	a4,24(a5)
    80000c1c:	db65                	beqz	a4,80000c0c <kalloc+0x88>
        acquire(&kmems[id].lock);
    80000c1e:	00549793          	slli	a5,s1,0x5
    80000c22:	00010997          	auipc	s3,0x10
    80000c26:	65e98993          	addi	s3,s3,1630 # 80011280 <kmems>
    80000c2a:	99be                	add	s3,s3,a5
    80000c2c:	854e                	mv	a0,s3
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	0e0080e7          	jalr	224(ra) # 80000d0e <acquire>
        r=popr(id);
    80000c36:	8526                	mv	a0,s1
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	eee080e7          	jalr	-274(ra) # 80000b26 <popr>
    80000c40:	85aa                	mv	a1,a0
        pushr(currentid,r);
    80000c42:	854a                	mv	a0,s2
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	f12080e7          	jalr	-238(ra) # 80000b56 <pushr>
        release(&kmems[id].lock);
    80000c4c:	854e                	mv	a0,s3
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	174080e7          	jalr	372(ra) # 80000dc2 <release>
    r=popr(currentid);
    80000c56:	854a                	mv	a0,s2
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	ece080e7          	jalr	-306(ra) # 80000b26 <popr>
    80000c60:	89aa                	mv	s3,a0
  release(&kmems[currentid].lock);
    80000c62:	8552                	mv	a0,s4
    80000c64:	00000097          	auipc	ra,0x0
    80000c68:	15e080e7          	jalr	350(ra) # 80000dc2 <release>
  if(r)
    80000c6c:	f80980e3          	beqz	s3,80000bec <kalloc+0x68>
    80000c70:	b7bd                	j	80000bde <kalloc+0x5a>
  release(&kmems[currentid].lock);
    80000c72:	8552                	mv	a0,s4
    80000c74:	00000097          	auipc	ra,0x0
    80000c78:	14e080e7          	jalr	334(ra) # 80000dc2 <release>
  if(r)
    80000c7c:	bf85                	j	80000bec <kalloc+0x68>

0000000080000c7e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c7e:	1141                	addi	sp,sp,-16
    80000c80:	e422                	sd	s0,8(sp)
    80000c82:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c84:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c86:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c8a:	00053823          	sd	zero,16(a0)
}
    80000c8e:	6422                	ld	s0,8(sp)
    80000c90:	0141                	addi	sp,sp,16
    80000c92:	8082                	ret

0000000080000c94 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c94:	411c                	lw	a5,0(a0)
    80000c96:	e399                	bnez	a5,80000c9c <holding+0x8>
    80000c98:	4501                	li	a0,0
  return r;
}
    80000c9a:	8082                	ret
{
    80000c9c:	1101                	addi	sp,sp,-32
    80000c9e:	ec06                	sd	ra,24(sp)
    80000ca0:	e822                	sd	s0,16(sp)
    80000ca2:	e426                	sd	s1,8(sp)
    80000ca4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ca6:	6904                	ld	s1,16(a0)
    80000ca8:	00001097          	auipc	ra,0x1
    80000cac:	e34080e7          	jalr	-460(ra) # 80001adc <mycpu>
    80000cb0:	40a48533          	sub	a0,s1,a0
    80000cb4:	00153513          	seqz	a0,a0
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret

0000000080000cc2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cc2:	1101                	addi	sp,sp,-32
    80000cc4:	ec06                	sd	ra,24(sp)
    80000cc6:	e822                	sd	s0,16(sp)
    80000cc8:	e426                	sd	s1,8(sp)
    80000cca:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ccc:	100024f3          	csrr	s1,sstatus
    80000cd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cda:	00001097          	auipc	ra,0x1
    80000cde:	e02080e7          	jalr	-510(ra) # 80001adc <mycpu>
    80000ce2:	5d3c                	lw	a5,120(a0)
    80000ce4:	cf89                	beqz	a5,80000cfe <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ce6:	00001097          	auipc	ra,0x1
    80000cea:	df6080e7          	jalr	-522(ra) # 80001adc <mycpu>
    80000cee:	5d3c                	lw	a5,120(a0)
    80000cf0:	2785                	addiw	a5,a5,1
    80000cf2:	dd3c                	sw	a5,120(a0)
}
    80000cf4:	60e2                	ld	ra,24(sp)
    80000cf6:	6442                	ld	s0,16(sp)
    80000cf8:	64a2                	ld	s1,8(sp)
    80000cfa:	6105                	addi	sp,sp,32
    80000cfc:	8082                	ret
    mycpu()->intena = old;
    80000cfe:	00001097          	auipc	ra,0x1
    80000d02:	dde080e7          	jalr	-546(ra) # 80001adc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d06:	8085                	srli	s1,s1,0x1
    80000d08:	8885                	andi	s1,s1,1
    80000d0a:	dd64                	sw	s1,124(a0)
    80000d0c:	bfe9                	j	80000ce6 <push_off+0x24>

0000000080000d0e <acquire>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	fa8080e7          	jalr	-88(ra) # 80000cc2 <push_off>
  if(holding(lk))
    80000d22:	8526                	mv	a0,s1
    80000d24:	00000097          	auipc	ra,0x0
    80000d28:	f70080e7          	jalr	-144(ra) # 80000c94 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2c:	4705                	li	a4,1
  if(holding(lk))
    80000d2e:	e115                	bnez	a0,80000d52 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d30:	87ba                	mv	a5,a4
    80000d32:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d36:	2781                	sext.w	a5,a5
    80000d38:	ffe5                	bnez	a5,80000d30 <acquire+0x22>
  __sync_synchronize();
    80000d3a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d3e:	00001097          	auipc	ra,0x1
    80000d42:	d9e080e7          	jalr	-610(ra) # 80001adc <mycpu>
    80000d46:	e888                	sd	a0,16(s1)
}
    80000d48:	60e2                	ld	ra,24(sp)
    80000d4a:	6442                	ld	s0,16(sp)
    80000d4c:	64a2                	ld	s1,8(sp)
    80000d4e:	6105                	addi	sp,sp,32
    80000d50:	8082                	ret
    panic("acquire");
    80000d52:	00007517          	auipc	a0,0x7
    80000d56:	33650513          	addi	a0,a0,822 # 80008088 <digits+0x48>
    80000d5a:	fffff097          	auipc	ra,0xfffff
    80000d5e:	7d6080e7          	jalr	2006(ra) # 80000530 <panic>

0000000080000d62 <pop_off>:

void
pop_off(void)
{
    80000d62:	1141                	addi	sp,sp,-16
    80000d64:	e406                	sd	ra,8(sp)
    80000d66:	e022                	sd	s0,0(sp)
    80000d68:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d6a:	00001097          	auipc	ra,0x1
    80000d6e:	d72080e7          	jalr	-654(ra) # 80001adc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d76:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d78:	e78d                	bnez	a5,80000da2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d7a:	5d3c                	lw	a5,120(a0)
    80000d7c:	02f05b63          	blez	a5,80000db2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d80:	37fd                	addiw	a5,a5,-1
    80000d82:	0007871b          	sext.w	a4,a5
    80000d86:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d88:	eb09                	bnez	a4,80000d9a <pop_off+0x38>
    80000d8a:	5d7c                	lw	a5,124(a0)
    80000d8c:	c799                	beqz	a5,80000d9a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d96:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    panic("pop_off - interruptible");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	2ee50513          	addi	a0,a0,750 # 80008090 <digits+0x50>
    80000daa:	fffff097          	auipc	ra,0xfffff
    80000dae:	786080e7          	jalr	1926(ra) # 80000530 <panic>
    panic("pop_off");
    80000db2:	00007517          	auipc	a0,0x7
    80000db6:	2f650513          	addi	a0,a0,758 # 800080a8 <digits+0x68>
    80000dba:	fffff097          	auipc	ra,0xfffff
    80000dbe:	776080e7          	jalr	1910(ra) # 80000530 <panic>

0000000080000dc2 <release>:
{
    80000dc2:	1101                	addi	sp,sp,-32
    80000dc4:	ec06                	sd	ra,24(sp)
    80000dc6:	e822                	sd	s0,16(sp)
    80000dc8:	e426                	sd	s1,8(sp)
    80000dca:	1000                	addi	s0,sp,32
    80000dcc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dce:	00000097          	auipc	ra,0x0
    80000dd2:	ec6080e7          	jalr	-314(ra) # 80000c94 <holding>
    80000dd6:	c115                	beqz	a0,80000dfa <release+0x38>
  lk->cpu = 0;
    80000dd8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ddc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de0:	0f50000f          	fence	iorw,ow
    80000de4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de8:	00000097          	auipc	ra,0x0
    80000dec:	f7a080e7          	jalr	-134(ra) # 80000d62 <pop_off>
}
    80000df0:	60e2                	ld	ra,24(sp)
    80000df2:	6442                	ld	s0,16(sp)
    80000df4:	64a2                	ld	s1,8(sp)
    80000df6:	6105                	addi	sp,sp,32
    80000df8:	8082                	ret
    panic("release");
    80000dfa:	00007517          	auipc	a0,0x7
    80000dfe:	2b650513          	addi	a0,a0,694 # 800080b0 <digits+0x70>
    80000e02:	fffff097          	auipc	ra,0xfffff
    80000e06:	72e080e7          	jalr	1838(ra) # 80000530 <panic>

0000000080000e0a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e0a:	1141                	addi	sp,sp,-16
    80000e0c:	e422                	sd	s0,8(sp)
    80000e0e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e10:	ce09                	beqz	a2,80000e2a <memset+0x20>
    80000e12:	87aa                	mv	a5,a0
    80000e14:	fff6071b          	addiw	a4,a2,-1
    80000e18:	1702                	slli	a4,a4,0x20
    80000e1a:	9301                	srli	a4,a4,0x20
    80000e1c:	0705                	addi	a4,a4,1
    80000e1e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e20:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fee79de3          	bne	a5,a4,80000e20 <memset+0x16>
  }
  return dst;
}
    80000e2a:	6422                	ld	s0,8(sp)
    80000e2c:	0141                	addi	sp,sp,16
    80000e2e:	8082                	ret

0000000080000e30 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e30:	1141                	addi	sp,sp,-16
    80000e32:	e422                	sd	s0,8(sp)
    80000e34:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e36:	ca05                	beqz	a2,80000e66 <memcmp+0x36>
    80000e38:	fff6069b          	addiw	a3,a2,-1
    80000e3c:	1682                	slli	a3,a3,0x20
    80000e3e:	9281                	srli	a3,a3,0x20
    80000e40:	0685                	addi	a3,a3,1
    80000e42:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e44:	00054783          	lbu	a5,0(a0)
    80000e48:	0005c703          	lbu	a4,0(a1)
    80000e4c:	00e79863          	bne	a5,a4,80000e5c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e50:	0505                	addi	a0,a0,1
    80000e52:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e54:	fed518e3          	bne	a0,a3,80000e44 <memcmp+0x14>
  }

  return 0;
    80000e58:	4501                	li	a0,0
    80000e5a:	a019                	j	80000e60 <memcmp+0x30>
      return *s1 - *s2;
    80000e5c:	40e7853b          	subw	a0,a5,a4
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret
  return 0;
    80000e66:	4501                	li	a0,0
    80000e68:	bfe5                	j	80000e60 <memcmp+0x30>

0000000080000e6a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e70:	00a5f963          	bgeu	a1,a0,80000e82 <memmove+0x18>
    80000e74:	02061713          	slli	a4,a2,0x20
    80000e78:	9301                	srli	a4,a4,0x20
    80000e7a:	00e587b3          	add	a5,a1,a4
    80000e7e:	02f56563          	bltu	a0,a5,80000ea8 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e82:	fff6069b          	addiw	a3,a2,-1
    80000e86:	ce11                	beqz	a2,80000ea2 <memmove+0x38>
    80000e88:	1682                	slli	a3,a3,0x20
    80000e8a:	9281                	srli	a3,a3,0x20
    80000e8c:	0685                	addi	a3,a3,1
    80000e8e:	96ae                	add	a3,a3,a1
    80000e90:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e92:	0585                	addi	a1,a1,1
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fff5c703          	lbu	a4,-1(a1)
    80000e9a:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e9e:	fed59ae3          	bne	a1,a3,80000e92 <memmove+0x28>

  return dst;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret
    d += n;
    80000ea8:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000eaa:	fff6069b          	addiw	a3,a2,-1
    80000eae:	da75                	beqz	a2,80000ea2 <memmove+0x38>
    80000eb0:	02069613          	slli	a2,a3,0x20
    80000eb4:	9201                	srli	a2,a2,0x20
    80000eb6:	fff64613          	not	a2,a2
    80000eba:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000ebc:	17fd                	addi	a5,a5,-1
    80000ebe:	177d                	addi	a4,a4,-1
    80000ec0:	0007c683          	lbu	a3,0(a5)
    80000ec4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000ec8:	fec79ae3          	bne	a5,a2,80000ebc <memmove+0x52>
    80000ecc:	bfd9                	j	80000ea2 <memmove+0x38>

0000000080000ece <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ece:	1141                	addi	sp,sp,-16
    80000ed0:	e406                	sd	ra,8(sp)
    80000ed2:	e022                	sd	s0,0(sp)
    80000ed4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	f94080e7          	jalr	-108(ra) # 80000e6a <memmove>
}
    80000ede:	60a2                	ld	ra,8(sp)
    80000ee0:	6402                	ld	s0,0(sp)
    80000ee2:	0141                	addi	sp,sp,16
    80000ee4:	8082                	ret

0000000080000ee6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ee6:	1141                	addi	sp,sp,-16
    80000ee8:	e422                	sd	s0,8(sp)
    80000eea:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eec:	ce11                	beqz	a2,80000f08 <strncmp+0x22>
    80000eee:	00054783          	lbu	a5,0(a0)
    80000ef2:	cf89                	beqz	a5,80000f0c <strncmp+0x26>
    80000ef4:	0005c703          	lbu	a4,0(a1)
    80000ef8:	00f71a63          	bne	a4,a5,80000f0c <strncmp+0x26>
    n--, p++, q++;
    80000efc:	367d                	addiw	a2,a2,-1
    80000efe:	0505                	addi	a0,a0,1
    80000f00:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f02:	f675                	bnez	a2,80000eee <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f04:	4501                	li	a0,0
    80000f06:	a809                	j	80000f18 <strncmp+0x32>
    80000f08:	4501                	li	a0,0
    80000f0a:	a039                	j	80000f18 <strncmp+0x32>
  if(n == 0)
    80000f0c:	ca09                	beqz	a2,80000f1e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f0e:	00054503          	lbu	a0,0(a0)
    80000f12:	0005c783          	lbu	a5,0(a1)
    80000f16:	9d1d                	subw	a0,a0,a5
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret
    return 0;
    80000f1e:	4501                	li	a0,0
    80000f20:	bfe5                	j	80000f18 <strncmp+0x32>

0000000080000f22 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f22:	1141                	addi	sp,sp,-16
    80000f24:	e422                	sd	s0,8(sp)
    80000f26:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f28:	872a                	mv	a4,a0
    80000f2a:	8832                	mv	a6,a2
    80000f2c:	367d                	addiw	a2,a2,-1
    80000f2e:	01005963          	blez	a6,80000f40 <strncpy+0x1e>
    80000f32:	0705                	addi	a4,a4,1
    80000f34:	0005c783          	lbu	a5,0(a1)
    80000f38:	fef70fa3          	sb	a5,-1(a4)
    80000f3c:	0585                	addi	a1,a1,1
    80000f3e:	f7f5                	bnez	a5,80000f2a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f40:	00c05d63          	blez	a2,80000f5a <strncpy+0x38>
    80000f44:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f46:	0685                	addi	a3,a3,1
    80000f48:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f4c:	fff6c793          	not	a5,a3
    80000f50:	9fb9                	addw	a5,a5,a4
    80000f52:	010787bb          	addw	a5,a5,a6
    80000f56:	fef048e3          	bgtz	a5,80000f46 <strncpy+0x24>
  return os;
}
    80000f5a:	6422                	ld	s0,8(sp)
    80000f5c:	0141                	addi	sp,sp,16
    80000f5e:	8082                	ret

0000000080000f60 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f60:	1141                	addi	sp,sp,-16
    80000f62:	e422                	sd	s0,8(sp)
    80000f64:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f66:	02c05363          	blez	a2,80000f8c <safestrcpy+0x2c>
    80000f6a:	fff6069b          	addiw	a3,a2,-1
    80000f6e:	1682                	slli	a3,a3,0x20
    80000f70:	9281                	srli	a3,a3,0x20
    80000f72:	96ae                	add	a3,a3,a1
    80000f74:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f76:	00d58963          	beq	a1,a3,80000f88 <safestrcpy+0x28>
    80000f7a:	0585                	addi	a1,a1,1
    80000f7c:	0785                	addi	a5,a5,1
    80000f7e:	fff5c703          	lbu	a4,-1(a1)
    80000f82:	fee78fa3          	sb	a4,-1(a5)
    80000f86:	fb65                	bnez	a4,80000f76 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f88:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f8c:	6422                	ld	s0,8(sp)
    80000f8e:	0141                	addi	sp,sp,16
    80000f90:	8082                	ret

0000000080000f92 <strlen>:

int
strlen(const char *s)
{
    80000f92:	1141                	addi	sp,sp,-16
    80000f94:	e422                	sd	s0,8(sp)
    80000f96:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f98:	00054783          	lbu	a5,0(a0)
    80000f9c:	cf91                	beqz	a5,80000fb8 <strlen+0x26>
    80000f9e:	0505                	addi	a0,a0,1
    80000fa0:	87aa                	mv	a5,a0
    80000fa2:	4685                	li	a3,1
    80000fa4:	9e89                	subw	a3,a3,a0
    80000fa6:	00f6853b          	addw	a0,a3,a5
    80000faa:	0785                	addi	a5,a5,1
    80000fac:	fff7c703          	lbu	a4,-1(a5)
    80000fb0:	fb7d                	bnez	a4,80000fa6 <strlen+0x14>
    ;
  return n;
}
    80000fb2:	6422                	ld	s0,8(sp)
    80000fb4:	0141                	addi	sp,sp,16
    80000fb6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fb8:	4501                	li	a0,0
    80000fba:	bfe5                	j	80000fb2 <strlen+0x20>

0000000080000fbc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e406                	sd	ra,8(sp)
    80000fc0:	e022                	sd	s0,0(sp)
    80000fc2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	b08080e7          	jalr	-1272(ra) # 80001acc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fcc:	00008717          	auipc	a4,0x8
    80000fd0:	04c70713          	addi	a4,a4,76 # 80009018 <started>
  if(cpuid() == 0){
    80000fd4:	c139                	beqz	a0,8000101a <main+0x5e>
    while(started == 0)
    80000fd6:	431c                	lw	a5,0(a4)
    80000fd8:	2781                	sext.w	a5,a5
    80000fda:	dff5                	beqz	a5,80000fd6 <main+0x1a>
      ;
    __sync_synchronize();
    80000fdc:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	aec080e7          	jalr	-1300(ra) # 80001acc <cpuid>
    80000fe8:	85aa                	mv	a1,a0
    80000fea:	00007517          	auipc	a0,0x7
    80000fee:	0e650513          	addi	a0,a0,230 # 800080d0 <digits+0x90>
    80000ff2:	fffff097          	auipc	ra,0xfffff
    80000ff6:	588080e7          	jalr	1416(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	0d8080e7          	jalr	216(ra) # 800010d2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001002:	00001097          	auipc	ra,0x1
    80001006:	754080e7          	jalr	1876(ra) # 80002756 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000100a:	00005097          	auipc	ra,0x5
    8000100e:	146080e7          	jalr	326(ra) # 80006150 <plicinithart>
  }

  scheduler();        
    80001012:	00001097          	auipc	ra,0x1
    80001016:	016080e7          	jalr	22(ra) # 80002028 <scheduler>
    consoleinit();
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	428080e7          	jalr	1064(ra) # 80000442 <consoleinit>
    printfinit();
    80001022:	fffff097          	auipc	ra,0xfffff
    80001026:	73e080e7          	jalr	1854(ra) # 80000760 <printfinit>
    printf("\n");
    8000102a:	00007517          	auipc	a0,0x7
    8000102e:	0b650513          	addi	a0,a0,182 # 800080e0 <digits+0xa0>
    80001032:	fffff097          	auipc	ra,0xfffff
    80001036:	548080e7          	jalr	1352(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    8000103a:	00007517          	auipc	a0,0x7
    8000103e:	07e50513          	addi	a0,a0,126 # 800080b8 <digits+0x78>
    80001042:	fffff097          	auipc	ra,0xfffff
    80001046:	538080e7          	jalr	1336(ra) # 8000057a <printf>
    printf("\n");
    8000104a:	00007517          	auipc	a0,0x7
    8000104e:	09650513          	addi	a0,a0,150 # 800080e0 <digits+0xa0>
    80001052:	fffff097          	auipc	ra,0xfffff
    80001056:	528080e7          	jalr	1320(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	a70080e7          	jalr	-1424(ra) # 80000aca <kinit>
    kvminit();       // create kernel page table
    80001062:	00000097          	auipc	ra,0x0
    80001066:	310080e7          	jalr	784(ra) # 80001372 <kvminit>
    kvminithart();   // turn on paging
    8000106a:	00000097          	auipc	ra,0x0
    8000106e:	068080e7          	jalr	104(ra) # 800010d2 <kvminithart>
    procinit();      // process table
    80001072:	00001097          	auipc	ra,0x1
    80001076:	9c2080e7          	jalr	-1598(ra) # 80001a34 <procinit>
    trapinit();      // trap vectors
    8000107a:	00001097          	auipc	ra,0x1
    8000107e:	6b4080e7          	jalr	1716(ra) # 8000272e <trapinit>
    trapinithart();  // install kernel trap vector
    80001082:	00001097          	auipc	ra,0x1
    80001086:	6d4080e7          	jalr	1748(ra) # 80002756 <trapinithart>
    plicinit();      // set up interrupt controller
    8000108a:	00005097          	auipc	ra,0x5
    8000108e:	0b0080e7          	jalr	176(ra) # 8000613a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001092:	00005097          	auipc	ra,0x5
    80001096:	0be080e7          	jalr	190(ra) # 80006150 <plicinithart>
    binit();         // buffer cache
    8000109a:	00002097          	auipc	ra,0x2
    8000109e:	e22080e7          	jalr	-478(ra) # 80002ebc <binit>
    iinit();         // inode cache
    800010a2:	00002097          	auipc	ra,0x2
    800010a6:	6e6080e7          	jalr	1766(ra) # 80003788 <iinit>
    fileinit();      // file table
    800010aa:	00003097          	auipc	ra,0x3
    800010ae:	69a080e7          	jalr	1690(ra) # 80004744 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010b2:	00005097          	auipc	ra,0x5
    800010b6:	1c0080e7          	jalr	448(ra) # 80006272 <virtio_disk_init>
    userinit();      // first user process
    800010ba:	00001097          	auipc	ra,0x1
    800010be:	d08080e7          	jalr	-760(ra) # 80001dc2 <userinit>
    __sync_synchronize();
    800010c2:	0ff0000f          	fence
    started = 1;
    800010c6:	4785                	li	a5,1
    800010c8:	00008717          	auipc	a4,0x8
    800010cc:	f4f72823          	sw	a5,-176(a4) # 80009018 <started>
    800010d0:	b789                	j	80001012 <main+0x56>

00000000800010d2 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010d2:	1141                	addi	sp,sp,-16
    800010d4:	e422                	sd	s0,8(sp)
    800010d6:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010d8:	00008797          	auipc	a5,0x8
    800010dc:	f487b783          	ld	a5,-184(a5) # 80009020 <kernel_pagetable>
    800010e0:	83b1                	srli	a5,a5,0xc
    800010e2:	577d                	li	a4,-1
    800010e4:	177e                	slli	a4,a4,0x3f
    800010e6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010e8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ec:	12000073          	sfence.vma
  sfence_vma();
}
    800010f0:	6422                	ld	s0,8(sp)
    800010f2:	0141                	addi	sp,sp,16
    800010f4:	8082                	ret

00000000800010f6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010f6:	7139                	addi	sp,sp,-64
    800010f8:	fc06                	sd	ra,56(sp)
    800010fa:	f822                	sd	s0,48(sp)
    800010fc:	f426                	sd	s1,40(sp)
    800010fe:	f04a                	sd	s2,32(sp)
    80001100:	ec4e                	sd	s3,24(sp)
    80001102:	e852                	sd	s4,16(sp)
    80001104:	e456                	sd	s5,8(sp)
    80001106:	e05a                	sd	s6,0(sp)
    80001108:	0080                	addi	s0,sp,64
    8000110a:	84aa                	mv	s1,a0
    8000110c:	89ae                	mv	s3,a1
    8000110e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001110:	57fd                	li	a5,-1
    80001112:	83e9                	srli	a5,a5,0x1a
    80001114:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001116:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001118:	04b7f263          	bgeu	a5,a1,8000115c <walk+0x66>
    panic("walk");
    8000111c:	00007517          	auipc	a0,0x7
    80001120:	fcc50513          	addi	a0,a0,-52 # 800080e8 <digits+0xa8>
    80001124:	fffff097          	auipc	ra,0xfffff
    80001128:	40c080e7          	jalr	1036(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000112c:	060a8663          	beqz	s5,80001198 <walk+0xa2>
    80001130:	00000097          	auipc	ra,0x0
    80001134:	a54080e7          	jalr	-1452(ra) # 80000b84 <kalloc>
    80001138:	84aa                	mv	s1,a0
    8000113a:	c529                	beqz	a0,80001184 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000113c:	6605                	lui	a2,0x1
    8000113e:	4581                	li	a1,0
    80001140:	00000097          	auipc	ra,0x0
    80001144:	cca080e7          	jalr	-822(ra) # 80000e0a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001148:	00c4d793          	srli	a5,s1,0xc
    8000114c:	07aa                	slli	a5,a5,0xa
    8000114e:	0017e793          	ori	a5,a5,1
    80001152:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001156:	3a5d                	addiw	s4,s4,-9
    80001158:	036a0063          	beq	s4,s6,80001178 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000115c:	0149d933          	srl	s2,s3,s4
    80001160:	1ff97913          	andi	s2,s2,511
    80001164:	090e                	slli	s2,s2,0x3
    80001166:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001168:	00093483          	ld	s1,0(s2)
    8000116c:	0014f793          	andi	a5,s1,1
    80001170:	dfd5                	beqz	a5,8000112c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001172:	80a9                	srli	s1,s1,0xa
    80001174:	04b2                	slli	s1,s1,0xc
    80001176:	b7c5                	j	80001156 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001178:	00c9d513          	srli	a0,s3,0xc
    8000117c:	1ff57513          	andi	a0,a0,511
    80001180:	050e                	slli	a0,a0,0x3
    80001182:	9526                	add	a0,a0,s1
}
    80001184:	70e2                	ld	ra,56(sp)
    80001186:	7442                	ld	s0,48(sp)
    80001188:	74a2                	ld	s1,40(sp)
    8000118a:	7902                	ld	s2,32(sp)
    8000118c:	69e2                	ld	s3,24(sp)
    8000118e:	6a42                	ld	s4,16(sp)
    80001190:	6aa2                	ld	s5,8(sp)
    80001192:	6b02                	ld	s6,0(sp)
    80001194:	6121                	addi	sp,sp,64
    80001196:	8082                	ret
        return 0;
    80001198:	4501                	li	a0,0
    8000119a:	b7ed                	j	80001184 <walk+0x8e>

000000008000119c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000119c:	57fd                	li	a5,-1
    8000119e:	83e9                	srli	a5,a5,0x1a
    800011a0:	00b7f463          	bgeu	a5,a1,800011a8 <walkaddr+0xc>
    return 0;
    800011a4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011a6:	8082                	ret
{
    800011a8:	1141                	addi	sp,sp,-16
    800011aa:	e406                	sd	ra,8(sp)
    800011ac:	e022                	sd	s0,0(sp)
    800011ae:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011b0:	4601                	li	a2,0
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	f44080e7          	jalr	-188(ra) # 800010f6 <walk>
  if(pte == 0)
    800011ba:	c105                	beqz	a0,800011da <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011bc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011be:	0117f693          	andi	a3,a5,17
    800011c2:	4745                	li	a4,17
    return 0;
    800011c4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011c6:	00e68663          	beq	a3,a4,800011d2 <walkaddr+0x36>
}
    800011ca:	60a2                	ld	ra,8(sp)
    800011cc:	6402                	ld	s0,0(sp)
    800011ce:	0141                	addi	sp,sp,16
    800011d0:	8082                	ret
  pa = PTE2PA(*pte);
    800011d2:	00a7d513          	srli	a0,a5,0xa
    800011d6:	0532                	slli	a0,a0,0xc
  return pa;
    800011d8:	bfcd                	j	800011ca <walkaddr+0x2e>
    return 0;
    800011da:	4501                	li	a0,0
    800011dc:	b7fd                	j	800011ca <walkaddr+0x2e>

00000000800011de <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011de:	715d                	addi	sp,sp,-80
    800011e0:	e486                	sd	ra,72(sp)
    800011e2:	e0a2                	sd	s0,64(sp)
    800011e4:	fc26                	sd	s1,56(sp)
    800011e6:	f84a                	sd	s2,48(sp)
    800011e8:	f44e                	sd	s3,40(sp)
    800011ea:	f052                	sd	s4,32(sp)
    800011ec:	ec56                	sd	s5,24(sp)
    800011ee:	e85a                	sd	s6,16(sp)
    800011f0:	e45e                	sd	s7,8(sp)
    800011f2:	0880                	addi	s0,sp,80
    800011f4:	8aaa                	mv	s5,a0
    800011f6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011f8:	777d                	lui	a4,0xfffff
    800011fa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011fe:	167d                	addi	a2,a2,-1
    80001200:	00b609b3          	add	s3,a2,a1
    80001204:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001208:	893e                	mv	s2,a5
    8000120a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000120e:	6b85                	lui	s7,0x1
    80001210:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001214:	4605                	li	a2,1
    80001216:	85ca                	mv	a1,s2
    80001218:	8556                	mv	a0,s5
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	edc080e7          	jalr	-292(ra) # 800010f6 <walk>
    80001222:	c51d                	beqz	a0,80001250 <mappages+0x72>
    if(*pte & PTE_V)
    80001224:	611c                	ld	a5,0(a0)
    80001226:	8b85                	andi	a5,a5,1
    80001228:	ef81                	bnez	a5,80001240 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000122a:	80b1                	srli	s1,s1,0xc
    8000122c:	04aa                	slli	s1,s1,0xa
    8000122e:	0164e4b3          	or	s1,s1,s6
    80001232:	0014e493          	ori	s1,s1,1
    80001236:	e104                	sd	s1,0(a0)
    if(a == last)
    80001238:	03390863          	beq	s2,s3,80001268 <mappages+0x8a>
    a += PGSIZE;
    8000123c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000123e:	bfc9                	j	80001210 <mappages+0x32>
      panic("remap");
    80001240:	00007517          	auipc	a0,0x7
    80001244:	eb050513          	addi	a0,a0,-336 # 800080f0 <digits+0xb0>
    80001248:	fffff097          	auipc	ra,0xfffff
    8000124c:	2e8080e7          	jalr	744(ra) # 80000530 <panic>
      return -1;
    80001250:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001252:	60a6                	ld	ra,72(sp)
    80001254:	6406                	ld	s0,64(sp)
    80001256:	74e2                	ld	s1,56(sp)
    80001258:	7942                	ld	s2,48(sp)
    8000125a:	79a2                	ld	s3,40(sp)
    8000125c:	7a02                	ld	s4,32(sp)
    8000125e:	6ae2                	ld	s5,24(sp)
    80001260:	6b42                	ld	s6,16(sp)
    80001262:	6ba2                	ld	s7,8(sp)
    80001264:	6161                	addi	sp,sp,80
    80001266:	8082                	ret
  return 0;
    80001268:	4501                	li	a0,0
    8000126a:	b7e5                	j	80001252 <mappages+0x74>

000000008000126c <kvmmap>:
{
    8000126c:	1141                	addi	sp,sp,-16
    8000126e:	e406                	sd	ra,8(sp)
    80001270:	e022                	sd	s0,0(sp)
    80001272:	0800                	addi	s0,sp,16
    80001274:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001276:	86b2                	mv	a3,a2
    80001278:	863e                	mv	a2,a5
    8000127a:	00000097          	auipc	ra,0x0
    8000127e:	f64080e7          	jalr	-156(ra) # 800011de <mappages>
    80001282:	e509                	bnez	a0,8000128c <kvmmap+0x20>
}
    80001284:	60a2                	ld	ra,8(sp)
    80001286:	6402                	ld	s0,0(sp)
    80001288:	0141                	addi	sp,sp,16
    8000128a:	8082                	ret
    panic("kvmmap");
    8000128c:	00007517          	auipc	a0,0x7
    80001290:	e6c50513          	addi	a0,a0,-404 # 800080f8 <digits+0xb8>
    80001294:	fffff097          	auipc	ra,0xfffff
    80001298:	29c080e7          	jalr	668(ra) # 80000530 <panic>

000000008000129c <kvmmake>:
{
    8000129c:	1101                	addi	sp,sp,-32
    8000129e:	ec06                	sd	ra,24(sp)
    800012a0:	e822                	sd	s0,16(sp)
    800012a2:	e426                	sd	s1,8(sp)
    800012a4:	e04a                	sd	s2,0(sp)
    800012a6:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	8dc080e7          	jalr	-1828(ra) # 80000b84 <kalloc>
    800012b0:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012b2:	6605                	lui	a2,0x1
    800012b4:	4581                	li	a1,0
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	b54080e7          	jalr	-1196(ra) # 80000e0a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012be:	4719                	li	a4,6
    800012c0:	6685                	lui	a3,0x1
    800012c2:	10000637          	lui	a2,0x10000
    800012c6:	100005b7          	lui	a1,0x10000
    800012ca:	8526                	mv	a0,s1
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	fa0080e7          	jalr	-96(ra) # 8000126c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012d4:	4719                	li	a4,6
    800012d6:	6685                	lui	a3,0x1
    800012d8:	10001637          	lui	a2,0x10001
    800012dc:	100015b7          	lui	a1,0x10001
    800012e0:	8526                	mv	a0,s1
    800012e2:	00000097          	auipc	ra,0x0
    800012e6:	f8a080e7          	jalr	-118(ra) # 8000126c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ea:	4719                	li	a4,6
    800012ec:	004006b7          	lui	a3,0x400
    800012f0:	0c000637          	lui	a2,0xc000
    800012f4:	0c0005b7          	lui	a1,0xc000
    800012f8:	8526                	mv	a0,s1
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f72080e7          	jalr	-142(ra) # 8000126c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001302:	00007917          	auipc	s2,0x7
    80001306:	cfe90913          	addi	s2,s2,-770 # 80008000 <etext>
    8000130a:	4729                	li	a4,10
    8000130c:	80007697          	auipc	a3,0x80007
    80001310:	cf468693          	addi	a3,a3,-780 # 8000 <_entry-0x7fff8000>
    80001314:	4605                	li	a2,1
    80001316:	067e                	slli	a2,a2,0x1f
    80001318:	85b2                	mv	a1,a2
    8000131a:	8526                	mv	a0,s1
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	f50080e7          	jalr	-176(ra) # 8000126c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001324:	4719                	li	a4,6
    80001326:	46c5                	li	a3,17
    80001328:	06ee                	slli	a3,a3,0x1b
    8000132a:	412686b3          	sub	a3,a3,s2
    8000132e:	864a                	mv	a2,s2
    80001330:	85ca                	mv	a1,s2
    80001332:	8526                	mv	a0,s1
    80001334:	00000097          	auipc	ra,0x0
    80001338:	f38080e7          	jalr	-200(ra) # 8000126c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000133c:	4729                	li	a4,10
    8000133e:	6685                	lui	a3,0x1
    80001340:	00006617          	auipc	a2,0x6
    80001344:	cc060613          	addi	a2,a2,-832 # 80007000 <_trampoline>
    80001348:	040005b7          	lui	a1,0x4000
    8000134c:	15fd                	addi	a1,a1,-1
    8000134e:	05b2                	slli	a1,a1,0xc
    80001350:	8526                	mv	a0,s1
    80001352:	00000097          	auipc	ra,0x0
    80001356:	f1a080e7          	jalr	-230(ra) # 8000126c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000135a:	8526                	mv	a0,s1
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	642080e7          	jalr	1602(ra) # 8000199e <proc_mapstacks>
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6902                	ld	s2,0(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <kvminit>:
{
    80001372:	1141                	addi	sp,sp,-16
    80001374:	e406                	sd	ra,8(sp)
    80001376:	e022                	sd	s0,0(sp)
    80001378:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	f22080e7          	jalr	-222(ra) # 8000129c <kvmmake>
    80001382:	00008797          	auipc	a5,0x8
    80001386:	c8a7bf23          	sd	a0,-866(a5) # 80009020 <kernel_pagetable>
}
    8000138a:	60a2                	ld	ra,8(sp)
    8000138c:	6402                	ld	s0,0(sp)
    8000138e:	0141                	addi	sp,sp,16
    80001390:	8082                	ret

0000000080001392 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001392:	715d                	addi	sp,sp,-80
    80001394:	e486                	sd	ra,72(sp)
    80001396:	e0a2                	sd	s0,64(sp)
    80001398:	fc26                	sd	s1,56(sp)
    8000139a:	f84a                	sd	s2,48(sp)
    8000139c:	f44e                	sd	s3,40(sp)
    8000139e:	f052                	sd	s4,32(sp)
    800013a0:	ec56                	sd	s5,24(sp)
    800013a2:	e85a                	sd	s6,16(sp)
    800013a4:	e45e                	sd	s7,8(sp)
    800013a6:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013a8:	03459793          	slli	a5,a1,0x34
    800013ac:	e795                	bnez	a5,800013d8 <uvmunmap+0x46>
    800013ae:	8a2a                	mv	s4,a0
    800013b0:	892e                	mv	s2,a1
    800013b2:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b4:	0632                	slli	a2,a2,0xc
    800013b6:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ba:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013bc:	6b05                	lui	s6,0x1
    800013be:	0735e863          	bltu	a1,s3,8000142e <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013c2:	60a6                	ld	ra,72(sp)
    800013c4:	6406                	ld	s0,64(sp)
    800013c6:	74e2                	ld	s1,56(sp)
    800013c8:	7942                	ld	s2,48(sp)
    800013ca:	79a2                	ld	s3,40(sp)
    800013cc:	7a02                	ld	s4,32(sp)
    800013ce:	6ae2                	ld	s5,24(sp)
    800013d0:	6b42                	ld	s6,16(sp)
    800013d2:	6ba2                	ld	s7,8(sp)
    800013d4:	6161                	addi	sp,sp,80
    800013d6:	8082                	ret
    panic("uvmunmap: not aligned");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d2850513          	addi	a0,a0,-728 # 80008100 <digits+0xc0>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	150080e7          	jalr	336(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800013e8:	00007517          	auipc	a0,0x7
    800013ec:	d3050513          	addi	a0,a0,-720 # 80008118 <digits+0xd8>
    800013f0:	fffff097          	auipc	ra,0xfffff
    800013f4:	140080e7          	jalr	320(ra) # 80000530 <panic>
      panic("uvmunmap: not mapped");
    800013f8:	00007517          	auipc	a0,0x7
    800013fc:	d3050513          	addi	a0,a0,-720 # 80008128 <digits+0xe8>
    80001400:	fffff097          	auipc	ra,0xfffff
    80001404:	130080e7          	jalr	304(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    80001408:	00007517          	auipc	a0,0x7
    8000140c:	d3850513          	addi	a0,a0,-712 # 80008140 <digits+0x100>
    80001410:	fffff097          	auipc	ra,0xfffff
    80001414:	120080e7          	jalr	288(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    80001418:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000141a:	0532                	slli	a0,a0,0xc
    8000141c:	fffff097          	auipc	ra,0xfffff
    80001420:	5ce080e7          	jalr	1486(ra) # 800009ea <kfree>
    *pte = 0;
    80001424:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001428:	995a                	add	s2,s2,s6
    8000142a:	f9397ce3          	bgeu	s2,s3,800013c2 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000142e:	4601                	li	a2,0
    80001430:	85ca                	mv	a1,s2
    80001432:	8552                	mv	a0,s4
    80001434:	00000097          	auipc	ra,0x0
    80001438:	cc2080e7          	jalr	-830(ra) # 800010f6 <walk>
    8000143c:	84aa                	mv	s1,a0
    8000143e:	d54d                	beqz	a0,800013e8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001440:	6108                	ld	a0,0(a0)
    80001442:	00157793          	andi	a5,a0,1
    80001446:	dbcd                	beqz	a5,800013f8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001448:	3ff57793          	andi	a5,a0,1023
    8000144c:	fb778ee3          	beq	a5,s7,80001408 <uvmunmap+0x76>
    if(do_free){
    80001450:	fc0a8ae3          	beqz	s5,80001424 <uvmunmap+0x92>
    80001454:	b7d1                	j	80001418 <uvmunmap+0x86>

0000000080001456 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001456:	1101                	addi	sp,sp,-32
    80001458:	ec06                	sd	ra,24(sp)
    8000145a:	e822                	sd	s0,16(sp)
    8000145c:	e426                	sd	s1,8(sp)
    8000145e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	724080e7          	jalr	1828(ra) # 80000b84 <kalloc>
    80001468:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000146a:	c519                	beqz	a0,80001478 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000146c:	6605                	lui	a2,0x1
    8000146e:	4581                	li	a1,0
    80001470:	00000097          	auipc	ra,0x0
    80001474:	99a080e7          	jalr	-1638(ra) # 80000e0a <memset>
  return pagetable;
}
    80001478:	8526                	mv	a0,s1
    8000147a:	60e2                	ld	ra,24(sp)
    8000147c:	6442                	ld	s0,16(sp)
    8000147e:	64a2                	ld	s1,8(sp)
    80001480:	6105                	addi	sp,sp,32
    80001482:	8082                	ret

0000000080001484 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001484:	7179                	addi	sp,sp,-48
    80001486:	f406                	sd	ra,40(sp)
    80001488:	f022                	sd	s0,32(sp)
    8000148a:	ec26                	sd	s1,24(sp)
    8000148c:	e84a                	sd	s2,16(sp)
    8000148e:	e44e                	sd	s3,8(sp)
    80001490:	e052                	sd	s4,0(sp)
    80001492:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001494:	6785                	lui	a5,0x1
    80001496:	04f67863          	bgeu	a2,a5,800014e6 <uvminit+0x62>
    8000149a:	8a2a                	mv	s4,a0
    8000149c:	89ae                	mv	s3,a1
    8000149e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	6e4080e7          	jalr	1764(ra) # 80000b84 <kalloc>
    800014a8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014aa:	6605                	lui	a2,0x1
    800014ac:	4581                	li	a1,0
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	95c080e7          	jalr	-1700(ra) # 80000e0a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014b6:	4779                	li	a4,30
    800014b8:	86ca                	mv	a3,s2
    800014ba:	6605                	lui	a2,0x1
    800014bc:	4581                	li	a1,0
    800014be:	8552                	mv	a0,s4
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	d1e080e7          	jalr	-738(ra) # 800011de <mappages>
  memmove(mem, src, sz);
    800014c8:	8626                	mv	a2,s1
    800014ca:	85ce                	mv	a1,s3
    800014cc:	854a                	mv	a0,s2
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	99c080e7          	jalr	-1636(ra) # 80000e6a <memmove>
}
    800014d6:	70a2                	ld	ra,40(sp)
    800014d8:	7402                	ld	s0,32(sp)
    800014da:	64e2                	ld	s1,24(sp)
    800014dc:	6942                	ld	s2,16(sp)
    800014de:	69a2                	ld	s3,8(sp)
    800014e0:	6a02                	ld	s4,0(sp)
    800014e2:	6145                	addi	sp,sp,48
    800014e4:	8082                	ret
    panic("inituvm: more than a page");
    800014e6:	00007517          	auipc	a0,0x7
    800014ea:	c7250513          	addi	a0,a0,-910 # 80008158 <digits+0x118>
    800014ee:	fffff097          	auipc	ra,0xfffff
    800014f2:	042080e7          	jalr	66(ra) # 80000530 <panic>

00000000800014f6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014f6:	1101                	addi	sp,sp,-32
    800014f8:	ec06                	sd	ra,24(sp)
    800014fa:	e822                	sd	s0,16(sp)
    800014fc:	e426                	sd	s1,8(sp)
    800014fe:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001500:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001502:	00b67d63          	bgeu	a2,a1,8000151c <uvmdealloc+0x26>
    80001506:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001508:	6785                	lui	a5,0x1
    8000150a:	17fd                	addi	a5,a5,-1
    8000150c:	00f60733          	add	a4,a2,a5
    80001510:	767d                	lui	a2,0xfffff
    80001512:	8f71                	and	a4,a4,a2
    80001514:	97ae                	add	a5,a5,a1
    80001516:	8ff1                	and	a5,a5,a2
    80001518:	00f76863          	bltu	a4,a5,80001528 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000151c:	8526                	mv	a0,s1
    8000151e:	60e2                	ld	ra,24(sp)
    80001520:	6442                	ld	s0,16(sp)
    80001522:	64a2                	ld	s1,8(sp)
    80001524:	6105                	addi	sp,sp,32
    80001526:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001528:	8f99                	sub	a5,a5,a4
    8000152a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000152c:	4685                	li	a3,1
    8000152e:	0007861b          	sext.w	a2,a5
    80001532:	85ba                	mv	a1,a4
    80001534:	00000097          	auipc	ra,0x0
    80001538:	e5e080e7          	jalr	-418(ra) # 80001392 <uvmunmap>
    8000153c:	b7c5                	j	8000151c <uvmdealloc+0x26>

000000008000153e <uvmalloc>:
  if(newsz < oldsz)
    8000153e:	0ab66163          	bltu	a2,a1,800015e0 <uvmalloc+0xa2>
{
    80001542:	7139                	addi	sp,sp,-64
    80001544:	fc06                	sd	ra,56(sp)
    80001546:	f822                	sd	s0,48(sp)
    80001548:	f426                	sd	s1,40(sp)
    8000154a:	f04a                	sd	s2,32(sp)
    8000154c:	ec4e                	sd	s3,24(sp)
    8000154e:	e852                	sd	s4,16(sp)
    80001550:	e456                	sd	s5,8(sp)
    80001552:	0080                	addi	s0,sp,64
    80001554:	8aaa                	mv	s5,a0
    80001556:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001558:	6985                	lui	s3,0x1
    8000155a:	19fd                	addi	s3,s3,-1
    8000155c:	95ce                	add	a1,a1,s3
    8000155e:	79fd                	lui	s3,0xfffff
    80001560:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001564:	08c9f063          	bgeu	s3,a2,800015e4 <uvmalloc+0xa6>
    80001568:	894e                	mv	s2,s3
    mem = kalloc();
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	61a080e7          	jalr	1562(ra) # 80000b84 <kalloc>
    80001572:	84aa                	mv	s1,a0
    if(mem == 0){
    80001574:	c51d                	beqz	a0,800015a2 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001576:	6605                	lui	a2,0x1
    80001578:	4581                	li	a1,0
    8000157a:	00000097          	auipc	ra,0x0
    8000157e:	890080e7          	jalr	-1904(ra) # 80000e0a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001582:	4779                	li	a4,30
    80001584:	86a6                	mv	a3,s1
    80001586:	6605                	lui	a2,0x1
    80001588:	85ca                	mv	a1,s2
    8000158a:	8556                	mv	a0,s5
    8000158c:	00000097          	auipc	ra,0x0
    80001590:	c52080e7          	jalr	-942(ra) # 800011de <mappages>
    80001594:	e905                	bnez	a0,800015c4 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001596:	6785                	lui	a5,0x1
    80001598:	993e                	add	s2,s2,a5
    8000159a:	fd4968e3          	bltu	s2,s4,8000156a <uvmalloc+0x2c>
  return newsz;
    8000159e:	8552                	mv	a0,s4
    800015a0:	a809                	j	800015b2 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015a2:	864e                	mv	a2,s3
    800015a4:	85ca                	mv	a1,s2
    800015a6:	8556                	mv	a0,s5
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	f4e080e7          	jalr	-178(ra) # 800014f6 <uvmdealloc>
      return 0;
    800015b0:	4501                	li	a0,0
}
    800015b2:	70e2                	ld	ra,56(sp)
    800015b4:	7442                	ld	s0,48(sp)
    800015b6:	74a2                	ld	s1,40(sp)
    800015b8:	7902                	ld	s2,32(sp)
    800015ba:	69e2                	ld	s3,24(sp)
    800015bc:	6a42                	ld	s4,16(sp)
    800015be:	6aa2                	ld	s5,8(sp)
    800015c0:	6121                	addi	sp,sp,64
    800015c2:	8082                	ret
      kfree(mem);
    800015c4:	8526                	mv	a0,s1
    800015c6:	fffff097          	auipc	ra,0xfffff
    800015ca:	424080e7          	jalr	1060(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015ce:	864e                	mv	a2,s3
    800015d0:	85ca                	mv	a1,s2
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	f22080e7          	jalr	-222(ra) # 800014f6 <uvmdealloc>
      return 0;
    800015dc:	4501                	li	a0,0
    800015de:	bfd1                	j	800015b2 <uvmalloc+0x74>
    return oldsz;
    800015e0:	852e                	mv	a0,a1
}
    800015e2:	8082                	ret
  return newsz;
    800015e4:	8532                	mv	a0,a2
    800015e6:	b7f1                	j	800015b2 <uvmalloc+0x74>

00000000800015e8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015e8:	7179                	addi	sp,sp,-48
    800015ea:	f406                	sd	ra,40(sp)
    800015ec:	f022                	sd	s0,32(sp)
    800015ee:	ec26                	sd	s1,24(sp)
    800015f0:	e84a                	sd	s2,16(sp)
    800015f2:	e44e                	sd	s3,8(sp)
    800015f4:	e052                	sd	s4,0(sp)
    800015f6:	1800                	addi	s0,sp,48
    800015f8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015fa:	84aa                	mv	s1,a0
    800015fc:	6905                	lui	s2,0x1
    800015fe:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001600:	4985                	li	s3,1
    80001602:	a821                	j	8000161a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001604:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001606:	0532                	slli	a0,a0,0xc
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	fe0080e7          	jalr	-32(ra) # 800015e8 <freewalk>
      pagetable[i] = 0;
    80001610:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001614:	04a1                	addi	s1,s1,8
    80001616:	03248163          	beq	s1,s2,80001638 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000161a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000161c:	00f57793          	andi	a5,a0,15
    80001620:	ff3782e3          	beq	a5,s3,80001604 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001624:	8905                	andi	a0,a0,1
    80001626:	d57d                	beqz	a0,80001614 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001628:	00007517          	auipc	a0,0x7
    8000162c:	b5050513          	addi	a0,a0,-1200 # 80008178 <digits+0x138>
    80001630:	fffff097          	auipc	ra,0xfffff
    80001634:	f00080e7          	jalr	-256(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    80001638:	8552                	mv	a0,s4
    8000163a:	fffff097          	auipc	ra,0xfffff
    8000163e:	3b0080e7          	jalr	944(ra) # 800009ea <kfree>
}
    80001642:	70a2                	ld	ra,40(sp)
    80001644:	7402                	ld	s0,32(sp)
    80001646:	64e2                	ld	s1,24(sp)
    80001648:	6942                	ld	s2,16(sp)
    8000164a:	69a2                	ld	s3,8(sp)
    8000164c:	6a02                	ld	s4,0(sp)
    8000164e:	6145                	addi	sp,sp,48
    80001650:	8082                	ret

0000000080001652 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001652:	1101                	addi	sp,sp,-32
    80001654:	ec06                	sd	ra,24(sp)
    80001656:	e822                	sd	s0,16(sp)
    80001658:	e426                	sd	s1,8(sp)
    8000165a:	1000                	addi	s0,sp,32
    8000165c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000165e:	e999                	bnez	a1,80001674 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001660:	8526                	mv	a0,s1
    80001662:	00000097          	auipc	ra,0x0
    80001666:	f86080e7          	jalr	-122(ra) # 800015e8 <freewalk>
}
    8000166a:	60e2                	ld	ra,24(sp)
    8000166c:	6442                	ld	s0,16(sp)
    8000166e:	64a2                	ld	s1,8(sp)
    80001670:	6105                	addi	sp,sp,32
    80001672:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001674:	6605                	lui	a2,0x1
    80001676:	167d                	addi	a2,a2,-1
    80001678:	962e                	add	a2,a2,a1
    8000167a:	4685                	li	a3,1
    8000167c:	8231                	srli	a2,a2,0xc
    8000167e:	4581                	li	a1,0
    80001680:	00000097          	auipc	ra,0x0
    80001684:	d12080e7          	jalr	-750(ra) # 80001392 <uvmunmap>
    80001688:	bfe1                	j	80001660 <uvmfree+0xe>

000000008000168a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000168a:	c679                	beqz	a2,80001758 <uvmcopy+0xce>
{
    8000168c:	715d                	addi	sp,sp,-80
    8000168e:	e486                	sd	ra,72(sp)
    80001690:	e0a2                	sd	s0,64(sp)
    80001692:	fc26                	sd	s1,56(sp)
    80001694:	f84a                	sd	s2,48(sp)
    80001696:	f44e                	sd	s3,40(sp)
    80001698:	f052                	sd	s4,32(sp)
    8000169a:	ec56                	sd	s5,24(sp)
    8000169c:	e85a                	sd	s6,16(sp)
    8000169e:	e45e                	sd	s7,8(sp)
    800016a0:	0880                	addi	s0,sp,80
    800016a2:	8b2a                	mv	s6,a0
    800016a4:	8aae                	mv	s5,a1
    800016a6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016a8:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016aa:	4601                	li	a2,0
    800016ac:	85ce                	mv	a1,s3
    800016ae:	855a                	mv	a0,s6
    800016b0:	00000097          	auipc	ra,0x0
    800016b4:	a46080e7          	jalr	-1466(ra) # 800010f6 <walk>
    800016b8:	c531                	beqz	a0,80001704 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016ba:	6118                	ld	a4,0(a0)
    800016bc:	00177793          	andi	a5,a4,1
    800016c0:	cbb1                	beqz	a5,80001714 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016c2:	00a75593          	srli	a1,a4,0xa
    800016c6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016ca:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016ce:	fffff097          	auipc	ra,0xfffff
    800016d2:	4b6080e7          	jalr	1206(ra) # 80000b84 <kalloc>
    800016d6:	892a                	mv	s2,a0
    800016d8:	c939                	beqz	a0,8000172e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016da:	6605                	lui	a2,0x1
    800016dc:	85de                	mv	a1,s7
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	78c080e7          	jalr	1932(ra) # 80000e6a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016e6:	8726                	mv	a4,s1
    800016e8:	86ca                	mv	a3,s2
    800016ea:	6605                	lui	a2,0x1
    800016ec:	85ce                	mv	a1,s3
    800016ee:	8556                	mv	a0,s5
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	aee080e7          	jalr	-1298(ra) # 800011de <mappages>
    800016f8:	e515                	bnez	a0,80001724 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016fa:	6785                	lui	a5,0x1
    800016fc:	99be                	add	s3,s3,a5
    800016fe:	fb49e6e3          	bltu	s3,s4,800016aa <uvmcopy+0x20>
    80001702:	a081                	j	80001742 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001704:	00007517          	auipc	a0,0x7
    80001708:	a8450513          	addi	a0,a0,-1404 # 80008188 <digits+0x148>
    8000170c:	fffff097          	auipc	ra,0xfffff
    80001710:	e24080e7          	jalr	-476(ra) # 80000530 <panic>
      panic("uvmcopy: page not present");
    80001714:	00007517          	auipc	a0,0x7
    80001718:	a9450513          	addi	a0,a0,-1388 # 800081a8 <digits+0x168>
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	e14080e7          	jalr	-492(ra) # 80000530 <panic>
      kfree(mem);
    80001724:	854a                	mv	a0,s2
    80001726:	fffff097          	auipc	ra,0xfffff
    8000172a:	2c4080e7          	jalr	708(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000172e:	4685                	li	a3,1
    80001730:	00c9d613          	srli	a2,s3,0xc
    80001734:	4581                	li	a1,0
    80001736:	8556                	mv	a0,s5
    80001738:	00000097          	auipc	ra,0x0
    8000173c:	c5a080e7          	jalr	-934(ra) # 80001392 <uvmunmap>
  return -1;
    80001740:	557d                	li	a0,-1
}
    80001742:	60a6                	ld	ra,72(sp)
    80001744:	6406                	ld	s0,64(sp)
    80001746:	74e2                	ld	s1,56(sp)
    80001748:	7942                	ld	s2,48(sp)
    8000174a:	79a2                	ld	s3,40(sp)
    8000174c:	7a02                	ld	s4,32(sp)
    8000174e:	6ae2                	ld	s5,24(sp)
    80001750:	6b42                	ld	s6,16(sp)
    80001752:	6ba2                	ld	s7,8(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret
  return 0;
    80001758:	4501                	li	a0,0
}
    8000175a:	8082                	ret

000000008000175c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000175c:	1141                	addi	sp,sp,-16
    8000175e:	e406                	sd	ra,8(sp)
    80001760:	e022                	sd	s0,0(sp)
    80001762:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001764:	4601                	li	a2,0
    80001766:	00000097          	auipc	ra,0x0
    8000176a:	990080e7          	jalr	-1648(ra) # 800010f6 <walk>
  if(pte == 0)
    8000176e:	c901                	beqz	a0,8000177e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001770:	611c                	ld	a5,0(a0)
    80001772:	9bbd                	andi	a5,a5,-17
    80001774:	e11c                	sd	a5,0(a0)
}
    80001776:	60a2                	ld	ra,8(sp)
    80001778:	6402                	ld	s0,0(sp)
    8000177a:	0141                	addi	sp,sp,16
    8000177c:	8082                	ret
    panic("uvmclear");
    8000177e:	00007517          	auipc	a0,0x7
    80001782:	a4a50513          	addi	a0,a0,-1462 # 800081c8 <digits+0x188>
    80001786:	fffff097          	auipc	ra,0xfffff
    8000178a:	daa080e7          	jalr	-598(ra) # 80000530 <panic>

000000008000178e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000178e:	c6bd                	beqz	a3,800017fc <copyout+0x6e>
{
    80001790:	715d                	addi	sp,sp,-80
    80001792:	e486                	sd	ra,72(sp)
    80001794:	e0a2                	sd	s0,64(sp)
    80001796:	fc26                	sd	s1,56(sp)
    80001798:	f84a                	sd	s2,48(sp)
    8000179a:	f44e                	sd	s3,40(sp)
    8000179c:	f052                	sd	s4,32(sp)
    8000179e:	ec56                	sd	s5,24(sp)
    800017a0:	e85a                	sd	s6,16(sp)
    800017a2:	e45e                	sd	s7,8(sp)
    800017a4:	e062                	sd	s8,0(sp)
    800017a6:	0880                	addi	s0,sp,80
    800017a8:	8b2a                	mv	s6,a0
    800017aa:	8c2e                	mv	s8,a1
    800017ac:	8a32                	mv	s4,a2
    800017ae:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017b0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017b2:	6a85                	lui	s5,0x1
    800017b4:	a015                	j	800017d8 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017b6:	9562                	add	a0,a0,s8
    800017b8:	0004861b          	sext.w	a2,s1
    800017bc:	85d2                	mv	a1,s4
    800017be:	41250533          	sub	a0,a0,s2
    800017c2:	fffff097          	auipc	ra,0xfffff
    800017c6:	6a8080e7          	jalr	1704(ra) # 80000e6a <memmove>

    len -= n;
    800017ca:	409989b3          	sub	s3,s3,s1
    src += n;
    800017ce:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017d0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017d4:	02098263          	beqz	s3,800017f8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017d8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017dc:	85ca                	mv	a1,s2
    800017de:	855a                	mv	a0,s6
    800017e0:	00000097          	auipc	ra,0x0
    800017e4:	9bc080e7          	jalr	-1604(ra) # 8000119c <walkaddr>
    if(pa0 == 0)
    800017e8:	cd01                	beqz	a0,80001800 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017ea:	418904b3          	sub	s1,s2,s8
    800017ee:	94d6                	add	s1,s1,s5
    if(n > len)
    800017f0:	fc99f3e3          	bgeu	s3,s1,800017b6 <copyout+0x28>
    800017f4:	84ce                	mv	s1,s3
    800017f6:	b7c1                	j	800017b6 <copyout+0x28>
  }
  return 0;
    800017f8:	4501                	li	a0,0
    800017fa:	a021                	j	80001802 <copyout+0x74>
    800017fc:	4501                	li	a0,0
}
    800017fe:	8082                	ret
      return -1;
    80001800:	557d                	li	a0,-1
}
    80001802:	60a6                	ld	ra,72(sp)
    80001804:	6406                	ld	s0,64(sp)
    80001806:	74e2                	ld	s1,56(sp)
    80001808:	7942                	ld	s2,48(sp)
    8000180a:	79a2                	ld	s3,40(sp)
    8000180c:	7a02                	ld	s4,32(sp)
    8000180e:	6ae2                	ld	s5,24(sp)
    80001810:	6b42                	ld	s6,16(sp)
    80001812:	6ba2                	ld	s7,8(sp)
    80001814:	6c02                	ld	s8,0(sp)
    80001816:	6161                	addi	sp,sp,80
    80001818:	8082                	ret

000000008000181a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000181a:	c6bd                	beqz	a3,80001888 <copyin+0x6e>
{
    8000181c:	715d                	addi	sp,sp,-80
    8000181e:	e486                	sd	ra,72(sp)
    80001820:	e0a2                	sd	s0,64(sp)
    80001822:	fc26                	sd	s1,56(sp)
    80001824:	f84a                	sd	s2,48(sp)
    80001826:	f44e                	sd	s3,40(sp)
    80001828:	f052                	sd	s4,32(sp)
    8000182a:	ec56                	sd	s5,24(sp)
    8000182c:	e85a                	sd	s6,16(sp)
    8000182e:	e45e                	sd	s7,8(sp)
    80001830:	e062                	sd	s8,0(sp)
    80001832:	0880                	addi	s0,sp,80
    80001834:	8b2a                	mv	s6,a0
    80001836:	8a2e                	mv	s4,a1
    80001838:	8c32                	mv	s8,a2
    8000183a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000183c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000183e:	6a85                	lui	s5,0x1
    80001840:	a015                	j	80001864 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001842:	9562                	add	a0,a0,s8
    80001844:	0004861b          	sext.w	a2,s1
    80001848:	412505b3          	sub	a1,a0,s2
    8000184c:	8552                	mv	a0,s4
    8000184e:	fffff097          	auipc	ra,0xfffff
    80001852:	61c080e7          	jalr	1564(ra) # 80000e6a <memmove>

    len -= n;
    80001856:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000185a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000185c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001860:	02098263          	beqz	s3,80001884 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001864:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001868:	85ca                	mv	a1,s2
    8000186a:	855a                	mv	a0,s6
    8000186c:	00000097          	auipc	ra,0x0
    80001870:	930080e7          	jalr	-1744(ra) # 8000119c <walkaddr>
    if(pa0 == 0)
    80001874:	cd01                	beqz	a0,8000188c <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001876:	418904b3          	sub	s1,s2,s8
    8000187a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000187c:	fc99f3e3          	bgeu	s3,s1,80001842 <copyin+0x28>
    80001880:	84ce                	mv	s1,s3
    80001882:	b7c1                	j	80001842 <copyin+0x28>
  }
  return 0;
    80001884:	4501                	li	a0,0
    80001886:	a021                	j	8000188e <copyin+0x74>
    80001888:	4501                	li	a0,0
}
    8000188a:	8082                	ret
      return -1;
    8000188c:	557d                	li	a0,-1
}
    8000188e:	60a6                	ld	ra,72(sp)
    80001890:	6406                	ld	s0,64(sp)
    80001892:	74e2                	ld	s1,56(sp)
    80001894:	7942                	ld	s2,48(sp)
    80001896:	79a2                	ld	s3,40(sp)
    80001898:	7a02                	ld	s4,32(sp)
    8000189a:	6ae2                	ld	s5,24(sp)
    8000189c:	6b42                	ld	s6,16(sp)
    8000189e:	6ba2                	ld	s7,8(sp)
    800018a0:	6c02                	ld	s8,0(sp)
    800018a2:	6161                	addi	sp,sp,80
    800018a4:	8082                	ret

00000000800018a6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018a6:	c6c5                	beqz	a3,8000194e <copyinstr+0xa8>
{
    800018a8:	715d                	addi	sp,sp,-80
    800018aa:	e486                	sd	ra,72(sp)
    800018ac:	e0a2                	sd	s0,64(sp)
    800018ae:	fc26                	sd	s1,56(sp)
    800018b0:	f84a                	sd	s2,48(sp)
    800018b2:	f44e                	sd	s3,40(sp)
    800018b4:	f052                	sd	s4,32(sp)
    800018b6:	ec56                	sd	s5,24(sp)
    800018b8:	e85a                	sd	s6,16(sp)
    800018ba:	e45e                	sd	s7,8(sp)
    800018bc:	0880                	addi	s0,sp,80
    800018be:	8a2a                	mv	s4,a0
    800018c0:	8b2e                	mv	s6,a1
    800018c2:	8bb2                	mv	s7,a2
    800018c4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018c6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018c8:	6985                	lui	s3,0x1
    800018ca:	a035                	j	800018f6 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018cc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018d0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018d2:	0017b793          	seqz	a5,a5
    800018d6:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018da:	60a6                	ld	ra,72(sp)
    800018dc:	6406                	ld	s0,64(sp)
    800018de:	74e2                	ld	s1,56(sp)
    800018e0:	7942                	ld	s2,48(sp)
    800018e2:	79a2                	ld	s3,40(sp)
    800018e4:	7a02                	ld	s4,32(sp)
    800018e6:	6ae2                	ld	s5,24(sp)
    800018e8:	6b42                	ld	s6,16(sp)
    800018ea:	6ba2                	ld	s7,8(sp)
    800018ec:	6161                	addi	sp,sp,80
    800018ee:	8082                	ret
    srcva = va0 + PGSIZE;
    800018f0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018f4:	c8a9                	beqz	s1,80001946 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018f6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018fa:	85ca                	mv	a1,s2
    800018fc:	8552                	mv	a0,s4
    800018fe:	00000097          	auipc	ra,0x0
    80001902:	89e080e7          	jalr	-1890(ra) # 8000119c <walkaddr>
    if(pa0 == 0)
    80001906:	c131                	beqz	a0,8000194a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001908:	41790833          	sub	a6,s2,s7
    8000190c:	984e                	add	a6,a6,s3
    if(n > max)
    8000190e:	0104f363          	bgeu	s1,a6,80001914 <copyinstr+0x6e>
    80001912:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001914:	955e                	add	a0,a0,s7
    80001916:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000191a:	fc080be3          	beqz	a6,800018f0 <copyinstr+0x4a>
    8000191e:	985a                	add	a6,a6,s6
    80001920:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001922:	41650633          	sub	a2,a0,s6
    80001926:	14fd                	addi	s1,s1,-1
    80001928:	9b26                	add	s6,s6,s1
    8000192a:	00f60733          	add	a4,a2,a5
    8000192e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdb000>
    80001932:	df49                	beqz	a4,800018cc <copyinstr+0x26>
        *dst = *p;
    80001934:	00e78023          	sb	a4,0(a5)
      --max;
    80001938:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000193c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000193e:	ff0796e3          	bne	a5,a6,8000192a <copyinstr+0x84>
      dst++;
    80001942:	8b42                	mv	s6,a6
    80001944:	b775                	j	800018f0 <copyinstr+0x4a>
    80001946:	4781                	li	a5,0
    80001948:	b769                	j	800018d2 <copyinstr+0x2c>
      return -1;
    8000194a:	557d                	li	a0,-1
    8000194c:	b779                	j	800018da <copyinstr+0x34>
  int got_null = 0;
    8000194e:	4781                	li	a5,0
  if(got_null){
    80001950:	0017b793          	seqz	a5,a5
    80001954:	40f00533          	neg	a0,a5
}
    80001958:	8082                	ret

000000008000195a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000195a:	1101                	addi	sp,sp,-32
    8000195c:	ec06                	sd	ra,24(sp)
    8000195e:	e822                	sd	s0,16(sp)
    80001960:	e426                	sd	s1,8(sp)
    80001962:	1000                	addi	s0,sp,32
    80001964:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	32e080e7          	jalr	814(ra) # 80000c94 <holding>
    8000196e:	c909                	beqz	a0,80001980 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001970:	749c                	ld	a5,40(s1)
    80001972:	00978f63          	beq	a5,s1,80001990 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001976:	60e2                	ld	ra,24(sp)
    80001978:	6442                	ld	s0,16(sp)
    8000197a:	64a2                	ld	s1,8(sp)
    8000197c:	6105                	addi	sp,sp,32
    8000197e:	8082                	ret
    panic("wakeup1");
    80001980:	00007517          	auipc	a0,0x7
    80001984:	85850513          	addi	a0,a0,-1960 # 800081d8 <digits+0x198>
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	ba8080e7          	jalr	-1112(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001990:	4c98                	lw	a4,24(s1)
    80001992:	4785                	li	a5,1
    80001994:	fef711e3          	bne	a4,a5,80001976 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001998:	4789                	li	a5,2
    8000199a:	cc9c                	sw	a5,24(s1)
}
    8000199c:	bfe9                	j	80001976 <wakeup1+0x1c>

000000008000199e <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000199e:	7139                	addi	sp,sp,-64
    800019a0:	fc06                	sd	ra,56(sp)
    800019a2:	f822                	sd	s0,48(sp)
    800019a4:	f426                	sd	s1,40(sp)
    800019a6:	f04a                	sd	s2,32(sp)
    800019a8:	ec4e                	sd	s3,24(sp)
    800019aa:	e852                	sd	s4,16(sp)
    800019ac:	e456                	sd	s5,8(sp)
    800019ae:	e05a                	sd	s6,0(sp)
    800019b0:	0080                	addi	s0,sp,64
    800019b2:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b4:	00010497          	auipc	s1,0x10
    800019b8:	de448493          	addi	s1,s1,-540 # 80011798 <proc>
    uint64 va = KSTACK((int) (p - proc));
    800019bc:	8b26                	mv	s6,s1
    800019be:	00006a97          	auipc	s5,0x6
    800019c2:	642a8a93          	addi	s5,s5,1602 # 80008000 <etext>
    800019c6:	04000937          	lui	s2,0x4000
    800019ca:	197d                	addi	s2,s2,-1
    800019cc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ce:	00011a17          	auipc	s4,0x11
    800019d2:	bdaa0a13          	addi	s4,s4,-1062 # 800125a8 <tickslock>
    char *pa = kalloc();
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	1ae080e7          	jalr	430(ra) # 80000b84 <kalloc>
    800019de:	862a                	mv	a2,a0
    if(pa == 0)
    800019e0:	c131                	beqz	a0,80001a24 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019e2:	416485b3          	sub	a1,s1,s6
    800019e6:	858d                	srai	a1,a1,0x3
    800019e8:	000ab783          	ld	a5,0(s5)
    800019ec:	02f585b3          	mul	a1,a1,a5
    800019f0:	2585                	addiw	a1,a1,1
    800019f2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019f6:	4719                	li	a4,6
    800019f8:	6685                	lui	a3,0x1
    800019fa:	40b905b3          	sub	a1,s2,a1
    800019fe:	854e                	mv	a0,s3
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	86c080e7          	jalr	-1940(ra) # 8000126c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a08:	16848493          	addi	s1,s1,360
    80001a0c:	fd4495e3          	bne	s1,s4,800019d6 <proc_mapstacks+0x38>
}
    80001a10:	70e2                	ld	ra,56(sp)
    80001a12:	7442                	ld	s0,48(sp)
    80001a14:	74a2                	ld	s1,40(sp)
    80001a16:	7902                	ld	s2,32(sp)
    80001a18:	69e2                	ld	s3,24(sp)
    80001a1a:	6a42                	ld	s4,16(sp)
    80001a1c:	6aa2                	ld	s5,8(sp)
    80001a1e:	6b02                	ld	s6,0(sp)
    80001a20:	6121                	addi	sp,sp,64
    80001a22:	8082                	ret
      panic("kalloc");
    80001a24:	00006517          	auipc	a0,0x6
    80001a28:	7bc50513          	addi	a0,a0,1980 # 800081e0 <digits+0x1a0>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	b04080e7          	jalr	-1276(ra) # 80000530 <panic>

0000000080001a34 <procinit>:
{
    80001a34:	7139                	addi	sp,sp,-64
    80001a36:	fc06                	sd	ra,56(sp)
    80001a38:	f822                	sd	s0,48(sp)
    80001a3a:	f426                	sd	s1,40(sp)
    80001a3c:	f04a                	sd	s2,32(sp)
    80001a3e:	ec4e                	sd	s3,24(sp)
    80001a40:	e852                	sd	s4,16(sp)
    80001a42:	e456                	sd	s5,8(sp)
    80001a44:	e05a                	sd	s6,0(sp)
    80001a46:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001a48:	00006597          	auipc	a1,0x6
    80001a4c:	7a058593          	addi	a1,a1,1952 # 800081e8 <digits+0x1a8>
    80001a50:	00010517          	auipc	a0,0x10
    80001a54:	93050513          	addi	a0,a0,-1744 # 80011380 <pid_lock>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	226080e7          	jalr	550(ra) # 80000c7e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a60:	00010497          	auipc	s1,0x10
    80001a64:	d3848493          	addi	s1,s1,-712 # 80011798 <proc>
      initlock(&p->lock, "proc");
    80001a68:	00006b17          	auipc	s6,0x6
    80001a6c:	788b0b13          	addi	s6,s6,1928 # 800081f0 <digits+0x1b0>
      p->kstack = KSTACK((int) (p - proc));
    80001a70:	8aa6                	mv	s5,s1
    80001a72:	00006a17          	auipc	s4,0x6
    80001a76:	58ea0a13          	addi	s4,s4,1422 # 80008000 <etext>
    80001a7a:	04000937          	lui	s2,0x4000
    80001a7e:	197d                	addi	s2,s2,-1
    80001a80:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a82:	00011997          	auipc	s3,0x11
    80001a86:	b2698993          	addi	s3,s3,-1242 # 800125a8 <tickslock>
      initlock(&p->lock, "proc");
    80001a8a:	85da                	mv	a1,s6
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	1f0080e7          	jalr	496(ra) # 80000c7e <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a96:	415487b3          	sub	a5,s1,s5
    80001a9a:	878d                	srai	a5,a5,0x3
    80001a9c:	000a3703          	ld	a4,0(s4)
    80001aa0:	02e787b3          	mul	a5,a5,a4
    80001aa4:	2785                	addiw	a5,a5,1
    80001aa6:	00d7979b          	slliw	a5,a5,0xd
    80001aaa:	40f907b3          	sub	a5,s2,a5
    80001aae:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab0:	16848493          	addi	s1,s1,360
    80001ab4:	fd349be3          	bne	s1,s3,80001a8a <procinit+0x56>
}
    80001ab8:	70e2                	ld	ra,56(sp)
    80001aba:	7442                	ld	s0,48(sp)
    80001abc:	74a2                	ld	s1,40(sp)
    80001abe:	7902                	ld	s2,32(sp)
    80001ac0:	69e2                	ld	s3,24(sp)
    80001ac2:	6a42                	ld	s4,16(sp)
    80001ac4:	6aa2                	ld	s5,8(sp)
    80001ac6:	6b02                	ld	s6,0(sp)
    80001ac8:	6121                	addi	sp,sp,64
    80001aca:	8082                	ret

0000000080001acc <cpuid>:
{
    80001acc:	1141                	addi	sp,sp,-16
    80001ace:	e422                	sd	s0,8(sp)
    80001ad0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ad2:	8512                	mv	a0,tp
}
    80001ad4:	2501                	sext.w	a0,a0
    80001ad6:	6422                	ld	s0,8(sp)
    80001ad8:	0141                	addi	sp,sp,16
    80001ada:	8082                	ret

0000000080001adc <mycpu>:
mycpu(void) {
    80001adc:	1141                	addi	sp,sp,-16
    80001ade:	e422                	sd	s0,8(sp)
    80001ae0:	0800                	addi	s0,sp,16
    80001ae2:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ae4:	2781                	sext.w	a5,a5
    80001ae6:	079e                	slli	a5,a5,0x7
}
    80001ae8:	00010517          	auipc	a0,0x10
    80001aec:	8b050513          	addi	a0,a0,-1872 # 80011398 <cpus>
    80001af0:	953e                	add	a0,a0,a5
    80001af2:	6422                	ld	s0,8(sp)
    80001af4:	0141                	addi	sp,sp,16
    80001af6:	8082                	ret

0000000080001af8 <myproc>:
myproc(void) {
    80001af8:	1101                	addi	sp,sp,-32
    80001afa:	ec06                	sd	ra,24(sp)
    80001afc:	e822                	sd	s0,16(sp)
    80001afe:	e426                	sd	s1,8(sp)
    80001b00:	1000                	addi	s0,sp,32
  push_off();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	1c0080e7          	jalr	448(ra) # 80000cc2 <push_off>
    80001b0a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b0c:	2781                	sext.w	a5,a5
    80001b0e:	079e                	slli	a5,a5,0x7
    80001b10:	00010717          	auipc	a4,0x10
    80001b14:	87070713          	addi	a4,a4,-1936 # 80011380 <pid_lock>
    80001b18:	97ba                	add	a5,a5,a4
    80001b1a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	246080e7          	jalr	582(ra) # 80000d62 <pop_off>
}
    80001b24:	8526                	mv	a0,s1
    80001b26:	60e2                	ld	ra,24(sp)
    80001b28:	6442                	ld	s0,16(sp)
    80001b2a:	64a2                	ld	s1,8(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <forkret>:
{
    80001b30:	1141                	addi	sp,sp,-16
    80001b32:	e406                	sd	ra,8(sp)
    80001b34:	e022                	sd	s0,0(sp)
    80001b36:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b38:	00000097          	auipc	ra,0x0
    80001b3c:	fc0080e7          	jalr	-64(ra) # 80001af8 <myproc>
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	282080e7          	jalr	642(ra) # 80000dc2 <release>
  if (first) {
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	cf87a783          	lw	a5,-776(a5) # 80008840 <first.1670>
    80001b50:	eb89                	bnez	a5,80001b62 <forkret+0x32>
  usertrapret();
    80001b52:	00001097          	auipc	ra,0x1
    80001b56:	c1c080e7          	jalr	-996(ra) # 8000276e <usertrapret>
}
    80001b5a:	60a2                	ld	ra,8(sp)
    80001b5c:	6402                	ld	s0,0(sp)
    80001b5e:	0141                	addi	sp,sp,16
    80001b60:	8082                	ret
    first = 0;
    80001b62:	00007797          	auipc	a5,0x7
    80001b66:	cc07af23          	sw	zero,-802(a5) # 80008840 <first.1670>
    fsinit(ROOTDEV);
    80001b6a:	4505                	li	a0,1
    80001b6c:	00002097          	auipc	ra,0x2
    80001b70:	b9c080e7          	jalr	-1124(ra) # 80003708 <fsinit>
    80001b74:	bff9                	j	80001b52 <forkret+0x22>

0000000080001b76 <allocpid>:
allocpid() {
    80001b76:	1101                	addi	sp,sp,-32
    80001b78:	ec06                	sd	ra,24(sp)
    80001b7a:	e822                	sd	s0,16(sp)
    80001b7c:	e426                	sd	s1,8(sp)
    80001b7e:	e04a                	sd	s2,0(sp)
    80001b80:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b82:	0000f917          	auipc	s2,0xf
    80001b86:	7fe90913          	addi	s2,s2,2046 # 80011380 <pid_lock>
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	182080e7          	jalr	386(ra) # 80000d0e <acquire>
  pid = nextpid;
    80001b94:	00007797          	auipc	a5,0x7
    80001b98:	cb078793          	addi	a5,a5,-848 # 80008844 <nextpid>
    80001b9c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b9e:	0014871b          	addiw	a4,s1,1
    80001ba2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ba4:	854a                	mv	a0,s2
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	21c080e7          	jalr	540(ra) # 80000dc2 <release>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <proc_pagetable>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
    80001bc8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	88c080e7          	jalr	-1908(ra) # 80001456 <uvmcreate>
    80001bd2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bd4:	c121                	beqz	a0,80001c14 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bd6:	4729                	li	a4,10
    80001bd8:	00005697          	auipc	a3,0x5
    80001bdc:	42868693          	addi	a3,a3,1064 # 80007000 <_trampoline>
    80001be0:	6605                	lui	a2,0x1
    80001be2:	040005b7          	lui	a1,0x4000
    80001be6:	15fd                	addi	a1,a1,-1
    80001be8:	05b2                	slli	a1,a1,0xc
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	5f4080e7          	jalr	1524(ra) # 800011de <mappages>
    80001bf2:	02054863          	bltz	a0,80001c22 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bf6:	4719                	li	a4,6
    80001bf8:	05893683          	ld	a3,88(s2)
    80001bfc:	6605                	lui	a2,0x1
    80001bfe:	020005b7          	lui	a1,0x2000
    80001c02:	15fd                	addi	a1,a1,-1
    80001c04:	05b6                	slli	a1,a1,0xd
    80001c06:	8526                	mv	a0,s1
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	5d6080e7          	jalr	1494(ra) # 800011de <mappages>
    80001c10:	02054163          	bltz	a0,80001c32 <proc_pagetable+0x76>
}
    80001c14:	8526                	mv	a0,s1
    80001c16:	60e2                	ld	ra,24(sp)
    80001c18:	6442                	ld	s0,16(sp)
    80001c1a:	64a2                	ld	s1,8(sp)
    80001c1c:	6902                	ld	s2,0(sp)
    80001c1e:	6105                	addi	sp,sp,32
    80001c20:	8082                	ret
    uvmfree(pagetable, 0);
    80001c22:	4581                	li	a1,0
    80001c24:	8526                	mv	a0,s1
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	a2c080e7          	jalr	-1492(ra) # 80001652 <uvmfree>
    return 0;
    80001c2e:	4481                	li	s1,0
    80001c30:	b7d5                	j	80001c14 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c32:	4681                	li	a3,0
    80001c34:	4605                	li	a2,1
    80001c36:	040005b7          	lui	a1,0x4000
    80001c3a:	15fd                	addi	a1,a1,-1
    80001c3c:	05b2                	slli	a1,a1,0xc
    80001c3e:	8526                	mv	a0,s1
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	752080e7          	jalr	1874(ra) # 80001392 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c48:	4581                	li	a1,0
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	a06080e7          	jalr	-1530(ra) # 80001652 <uvmfree>
    return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	bf7d                	j	80001c14 <proc_pagetable+0x58>

0000000080001c58 <proc_freepagetable>:
{
    80001c58:	1101                	addi	sp,sp,-32
    80001c5a:	ec06                	sd	ra,24(sp)
    80001c5c:	e822                	sd	s0,16(sp)
    80001c5e:	e426                	sd	s1,8(sp)
    80001c60:	e04a                	sd	s2,0(sp)
    80001c62:	1000                	addi	s0,sp,32
    80001c64:	84aa                	mv	s1,a0
    80001c66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c68:	4681                	li	a3,0
    80001c6a:	4605                	li	a2,1
    80001c6c:	040005b7          	lui	a1,0x4000
    80001c70:	15fd                	addi	a1,a1,-1
    80001c72:	05b2                	slli	a1,a1,0xc
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	71e080e7          	jalr	1822(ra) # 80001392 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c7c:	4681                	li	a3,0
    80001c7e:	4605                	li	a2,1
    80001c80:	020005b7          	lui	a1,0x2000
    80001c84:	15fd                	addi	a1,a1,-1
    80001c86:	05b6                	slli	a1,a1,0xd
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	708080e7          	jalr	1800(ra) # 80001392 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c92:	85ca                	mv	a1,s2
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	9bc080e7          	jalr	-1604(ra) # 80001652 <uvmfree>
}
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	addi	sp,sp,32
    80001ca8:	8082                	ret

0000000080001caa <freeproc>:
{
    80001caa:	1101                	addi	sp,sp,-32
    80001cac:	ec06                	sd	ra,24(sp)
    80001cae:	e822                	sd	s0,16(sp)
    80001cb0:	e426                	sd	s1,8(sp)
    80001cb2:	1000                	addi	s0,sp,32
    80001cb4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cb6:	6d28                	ld	a0,88(a0)
    80001cb8:	c509                	beqz	a0,80001cc2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	d30080e7          	jalr	-720(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001cc2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cc6:	68a8                	ld	a0,80(s1)
    80001cc8:	c511                	beqz	a0,80001cd4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cca:	64ac                	ld	a1,72(s1)
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	f8c080e7          	jalr	-116(ra) # 80001c58 <proc_freepagetable>
  p->pagetable = 0;
    80001cd4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cd8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cdc:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001ce0:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001ce4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ce8:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cec:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cf0:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cf4:	0004ac23          	sw	zero,24(s1)
}
    80001cf8:	60e2                	ld	ra,24(sp)
    80001cfa:	6442                	ld	s0,16(sp)
    80001cfc:	64a2                	ld	s1,8(sp)
    80001cfe:	6105                	addi	sp,sp,32
    80001d00:	8082                	ret

0000000080001d02 <allocproc>:
{
    80001d02:	1101                	addi	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	e04a                	sd	s2,0(sp)
    80001d0c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0e:	00010497          	auipc	s1,0x10
    80001d12:	a8a48493          	addi	s1,s1,-1398 # 80011798 <proc>
    80001d16:	00011917          	auipc	s2,0x11
    80001d1a:	89290913          	addi	s2,s2,-1902 # 800125a8 <tickslock>
    acquire(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	fee080e7          	jalr	-18(ra) # 80000d0e <acquire>
    if(p->state == UNUSED) {
    80001d28:	4c9c                	lw	a5,24(s1)
    80001d2a:	c395                	beqz	a5,80001d4e <allocproc+0x4c>
      release(&p->lock);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	094080e7          	jalr	148(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d36:	16848493          	addi	s1,s1,360
    80001d3a:	ff2492e3          	bne	s1,s2,80001d1e <allocproc+0x1c>
  return 0;
    80001d3e:	4481                	li	s1,0
}
    80001d40:	8526                	mv	a0,s1
    80001d42:	60e2                	ld	ra,24(sp)
    80001d44:	6442                	ld	s0,16(sp)
    80001d46:	64a2                	ld	s1,8(sp)
    80001d48:	6902                	ld	s2,0(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret
  p->pid = allocpid();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	e28080e7          	jalr	-472(ra) # 80001b76 <allocpid>
    80001d56:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	e2c080e7          	jalr	-468(ra) # 80000b84 <kalloc>
    80001d60:	892a                	mv	s2,a0
    80001d62:	eca8                	sd	a0,88(s1)
    80001d64:	cd05                	beqz	a0,80001d9c <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d66:	8526                	mv	a0,s1
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	e54080e7          	jalr	-428(ra) # 80001bbc <proc_pagetable>
    80001d70:	892a                	mv	s2,a0
    80001d72:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d74:	c91d                	beqz	a0,80001daa <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d76:	07000613          	li	a2,112
    80001d7a:	4581                	li	a1,0
    80001d7c:	06048513          	addi	a0,s1,96
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	08a080e7          	jalr	138(ra) # 80000e0a <memset>
  p->context.ra = (uint64)forkret;
    80001d88:	00000797          	auipc	a5,0x0
    80001d8c:	da878793          	addi	a5,a5,-600 # 80001b30 <forkret>
    80001d90:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d92:	60bc                	ld	a5,64(s1)
    80001d94:	6705                	lui	a4,0x1
    80001d96:	97ba                	add	a5,a5,a4
    80001d98:	f4bc                	sd	a5,104(s1)
  return p;
    80001d9a:	b75d                	j	80001d40 <allocproc+0x3e>
    release(&p->lock);
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	024080e7          	jalr	36(ra) # 80000dc2 <release>
    return 0;
    80001da6:	84ca                	mv	s1,s2
    80001da8:	bf61                	j	80001d40 <allocproc+0x3e>
    freeproc(p);
    80001daa:	8526                	mv	a0,s1
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	efe080e7          	jalr	-258(ra) # 80001caa <freeproc>
    release(&p->lock);
    80001db4:	8526                	mv	a0,s1
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	00c080e7          	jalr	12(ra) # 80000dc2 <release>
    return 0;
    80001dbe:	84ca                	mv	s1,s2
    80001dc0:	b741                	j	80001d40 <allocproc+0x3e>

0000000080001dc2 <userinit>:
{
    80001dc2:	1101                	addi	sp,sp,-32
    80001dc4:	ec06                	sd	ra,24(sp)
    80001dc6:	e822                	sd	s0,16(sp)
    80001dc8:	e426                	sd	s1,8(sp)
    80001dca:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	f36080e7          	jalr	-202(ra) # 80001d02 <allocproc>
    80001dd4:	84aa                	mv	s1,a0
  initproc = p;
    80001dd6:	00007797          	auipc	a5,0x7
    80001dda:	24a7b923          	sd	a0,594(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dde:	03400613          	li	a2,52
    80001de2:	00007597          	auipc	a1,0x7
    80001de6:	a6e58593          	addi	a1,a1,-1426 # 80008850 <initcode>
    80001dea:	6928                	ld	a0,80(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	698080e7          	jalr	1688(ra) # 80001484 <uvminit>
  p->sz = PGSIZE;
    80001df4:	6785                	lui	a5,0x1
    80001df6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001df8:	6cb8                	ld	a4,88(s1)
    80001dfa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dfe:	6cb8                	ld	a4,88(s1)
    80001e00:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e02:	4641                	li	a2,16
    80001e04:	00006597          	auipc	a1,0x6
    80001e08:	3f458593          	addi	a1,a1,1012 # 800081f8 <digits+0x1b8>
    80001e0c:	15848513          	addi	a0,s1,344
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	150080e7          	jalr	336(ra) # 80000f60 <safestrcpy>
  p->cwd = namei("/");
    80001e18:	00006517          	auipc	a0,0x6
    80001e1c:	3f050513          	addi	a0,a0,1008 # 80008208 <digits+0x1c8>
    80001e20:	00002097          	auipc	ra,0x2
    80001e24:	318080e7          	jalr	792(ra) # 80004138 <namei>
    80001e28:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e2c:	4789                	li	a5,2
    80001e2e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	f90080e7          	jalr	-112(ra) # 80000dc2 <release>
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6105                	addi	sp,sp,32
    80001e42:	8082                	ret

0000000080001e44 <growproc>:
{
    80001e44:	1101                	addi	sp,sp,-32
    80001e46:	ec06                	sd	ra,24(sp)
    80001e48:	e822                	sd	s0,16(sp)
    80001e4a:	e426                	sd	s1,8(sp)
    80001e4c:	e04a                	sd	s2,0(sp)
    80001e4e:	1000                	addi	s0,sp,32
    80001e50:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	ca6080e7          	jalr	-858(ra) # 80001af8 <myproc>
    80001e5a:	892a                	mv	s2,a0
  sz = p->sz;
    80001e5c:	652c                	ld	a1,72(a0)
    80001e5e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e62:	00904f63          	bgtz	s1,80001e80 <growproc+0x3c>
  } else if(n < 0){
    80001e66:	0204cc63          	bltz	s1,80001e9e <growproc+0x5a>
  p->sz = sz;
    80001e6a:	1602                	slli	a2,a2,0x20
    80001e6c:	9201                	srli	a2,a2,0x20
    80001e6e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e72:	4501                	li	a0,0
}
    80001e74:	60e2                	ld	ra,24(sp)
    80001e76:	6442                	ld	s0,16(sp)
    80001e78:	64a2                	ld	s1,8(sp)
    80001e7a:	6902                	ld	s2,0(sp)
    80001e7c:	6105                	addi	sp,sp,32
    80001e7e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e80:	9e25                	addw	a2,a2,s1
    80001e82:	1602                	slli	a2,a2,0x20
    80001e84:	9201                	srli	a2,a2,0x20
    80001e86:	1582                	slli	a1,a1,0x20
    80001e88:	9181                	srli	a1,a1,0x20
    80001e8a:	6928                	ld	a0,80(a0)
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	6b2080e7          	jalr	1714(ra) # 8000153e <uvmalloc>
    80001e94:	0005061b          	sext.w	a2,a0
    80001e98:	fa69                	bnez	a2,80001e6a <growproc+0x26>
      return -1;
    80001e9a:	557d                	li	a0,-1
    80001e9c:	bfe1                	j	80001e74 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e9e:	9e25                	addw	a2,a2,s1
    80001ea0:	1602                	slli	a2,a2,0x20
    80001ea2:	9201                	srli	a2,a2,0x20
    80001ea4:	1582                	slli	a1,a1,0x20
    80001ea6:	9181                	srli	a1,a1,0x20
    80001ea8:	6928                	ld	a0,80(a0)
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	64c080e7          	jalr	1612(ra) # 800014f6 <uvmdealloc>
    80001eb2:	0005061b          	sext.w	a2,a0
    80001eb6:	bf55                	j	80001e6a <growproc+0x26>

0000000080001eb8 <fork>:
{
    80001eb8:	7179                	addi	sp,sp,-48
    80001eba:	f406                	sd	ra,40(sp)
    80001ebc:	f022                	sd	s0,32(sp)
    80001ebe:	ec26                	sd	s1,24(sp)
    80001ec0:	e84a                	sd	s2,16(sp)
    80001ec2:	e44e                	sd	s3,8(sp)
    80001ec4:	e052                	sd	s4,0(sp)
    80001ec6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	c30080e7          	jalr	-976(ra) # 80001af8 <myproc>
    80001ed0:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	e30080e7          	jalr	-464(ra) # 80001d02 <allocproc>
    80001eda:	c175                	beqz	a0,80001fbe <fork+0x106>
    80001edc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ede:	04893603          	ld	a2,72(s2)
    80001ee2:	692c                	ld	a1,80(a0)
    80001ee4:	05093503          	ld	a0,80(s2)
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	7a2080e7          	jalr	1954(ra) # 8000168a <uvmcopy>
    80001ef0:	04054863          	bltz	a0,80001f40 <fork+0x88>
  np->sz = p->sz;
    80001ef4:	04893783          	ld	a5,72(s2)
    80001ef8:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80001efc:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f00:	05893683          	ld	a3,88(s2)
    80001f04:	87b6                	mv	a5,a3
    80001f06:	0589b703          	ld	a4,88(s3)
    80001f0a:	12068693          	addi	a3,a3,288
    80001f0e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f12:	6788                	ld	a0,8(a5)
    80001f14:	6b8c                	ld	a1,16(a5)
    80001f16:	6f90                	ld	a2,24(a5)
    80001f18:	01073023          	sd	a6,0(a4)
    80001f1c:	e708                	sd	a0,8(a4)
    80001f1e:	eb0c                	sd	a1,16(a4)
    80001f20:	ef10                	sd	a2,24(a4)
    80001f22:	02078793          	addi	a5,a5,32
    80001f26:	02070713          	addi	a4,a4,32
    80001f2a:	fed792e3          	bne	a5,a3,80001f0e <fork+0x56>
  np->trapframe->a0 = 0;
    80001f2e:	0589b783          	ld	a5,88(s3)
    80001f32:	0607b823          	sd	zero,112(a5)
    80001f36:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f3a:	15000a13          	li	s4,336
    80001f3e:	a03d                	j	80001f6c <fork+0xb4>
    freeproc(np);
    80001f40:	854e                	mv	a0,s3
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	d68080e7          	jalr	-664(ra) # 80001caa <freeproc>
    release(&np->lock);
    80001f4a:	854e                	mv	a0,s3
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	e76080e7          	jalr	-394(ra) # 80000dc2 <release>
    return -1;
    80001f54:	54fd                	li	s1,-1
    80001f56:	a899                	j	80001fac <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f58:	00003097          	auipc	ra,0x3
    80001f5c:	87e080e7          	jalr	-1922(ra) # 800047d6 <filedup>
    80001f60:	009987b3          	add	a5,s3,s1
    80001f64:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f66:	04a1                	addi	s1,s1,8
    80001f68:	01448763          	beq	s1,s4,80001f76 <fork+0xbe>
    if(p->ofile[i])
    80001f6c:	009907b3          	add	a5,s2,s1
    80001f70:	6388                	ld	a0,0(a5)
    80001f72:	f17d                	bnez	a0,80001f58 <fork+0xa0>
    80001f74:	bfcd                	j	80001f66 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f76:	15093503          	ld	a0,336(s2)
    80001f7a:	00002097          	auipc	ra,0x2
    80001f7e:	9c8080e7          	jalr	-1592(ra) # 80003942 <idup>
    80001f82:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f86:	4641                	li	a2,16
    80001f88:	15890593          	addi	a1,s2,344
    80001f8c:	15898513          	addi	a0,s3,344
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	fd0080e7          	jalr	-48(ra) # 80000f60 <safestrcpy>
  pid = np->pid;
    80001f98:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f9c:	4789                	li	a5,2
    80001f9e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fa2:	854e                	mv	a0,s3
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	e1e080e7          	jalr	-482(ra) # 80000dc2 <release>
}
    80001fac:	8526                	mv	a0,s1
    80001fae:	70a2                	ld	ra,40(sp)
    80001fb0:	7402                	ld	s0,32(sp)
    80001fb2:	64e2                	ld	s1,24(sp)
    80001fb4:	6942                	ld	s2,16(sp)
    80001fb6:	69a2                	ld	s3,8(sp)
    80001fb8:	6a02                	ld	s4,0(sp)
    80001fba:	6145                	addi	sp,sp,48
    80001fbc:	8082                	ret
    return -1;
    80001fbe:	54fd                	li	s1,-1
    80001fc0:	b7f5                	j	80001fac <fork+0xf4>

0000000080001fc2 <reparent>:
{
    80001fc2:	7179                	addi	sp,sp,-48
    80001fc4:	f406                	sd	ra,40(sp)
    80001fc6:	f022                	sd	s0,32(sp)
    80001fc8:	ec26                	sd	s1,24(sp)
    80001fca:	e84a                	sd	s2,16(sp)
    80001fcc:	e44e                	sd	s3,8(sp)
    80001fce:	e052                	sd	s4,0(sp)
    80001fd0:	1800                	addi	s0,sp,48
    80001fd2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fd4:	0000f497          	auipc	s1,0xf
    80001fd8:	7c448493          	addi	s1,s1,1988 # 80011798 <proc>
      pp->parent = initproc;
    80001fdc:	00007a17          	auipc	s4,0x7
    80001fe0:	04ca0a13          	addi	s4,s4,76 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fe4:	00010997          	auipc	s3,0x10
    80001fe8:	5c498993          	addi	s3,s3,1476 # 800125a8 <tickslock>
    80001fec:	a029                	j	80001ff6 <reparent+0x34>
    80001fee:	16848493          	addi	s1,s1,360
    80001ff2:	03348363          	beq	s1,s3,80002018 <reparent+0x56>
    if(pp->parent == p){
    80001ff6:	709c                	ld	a5,32(s1)
    80001ff8:	ff279be3          	bne	a5,s2,80001fee <reparent+0x2c>
      acquire(&pp->lock);
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	d10080e7          	jalr	-752(ra) # 80000d0e <acquire>
      pp->parent = initproc;
    80002006:	000a3783          	ld	a5,0(s4)
    8000200a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000200c:	8526                	mv	a0,s1
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	db4080e7          	jalr	-588(ra) # 80000dc2 <release>
    80002016:	bfe1                	j	80001fee <reparent+0x2c>
}
    80002018:	70a2                	ld	ra,40(sp)
    8000201a:	7402                	ld	s0,32(sp)
    8000201c:	64e2                	ld	s1,24(sp)
    8000201e:	6942                	ld	s2,16(sp)
    80002020:	69a2                	ld	s3,8(sp)
    80002022:	6a02                	ld	s4,0(sp)
    80002024:	6145                	addi	sp,sp,48
    80002026:	8082                	ret

0000000080002028 <scheduler>:
{
    80002028:	711d                	addi	sp,sp,-96
    8000202a:	ec86                	sd	ra,88(sp)
    8000202c:	e8a2                	sd	s0,80(sp)
    8000202e:	e4a6                	sd	s1,72(sp)
    80002030:	e0ca                	sd	s2,64(sp)
    80002032:	fc4e                	sd	s3,56(sp)
    80002034:	f852                	sd	s4,48(sp)
    80002036:	f456                	sd	s5,40(sp)
    80002038:	f05a                	sd	s6,32(sp)
    8000203a:	ec5e                	sd	s7,24(sp)
    8000203c:	e862                	sd	s8,16(sp)
    8000203e:	e466                	sd	s9,8(sp)
    80002040:	1080                	addi	s0,sp,96
    80002042:	8792                	mv	a5,tp
  int id = r_tp();
    80002044:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002046:	00779b93          	slli	s7,a5,0x7
    8000204a:	0000f717          	auipc	a4,0xf
    8000204e:	33670713          	addi	a4,a4,822 # 80011380 <pid_lock>
    80002052:	975e                	add	a4,a4,s7
    80002054:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002058:	0000f717          	auipc	a4,0xf
    8000205c:	34870713          	addi	a4,a4,840 # 800113a0 <cpus+0x8>
    80002060:	9bba                	add	s7,s7,a4
      if(p->state == RUNNABLE) {
    80002062:	4a89                	li	s5,2
        c->proc = p;
    80002064:	079e                	slli	a5,a5,0x7
    80002066:	0000fb17          	auipc	s6,0xf
    8000206a:	31ab0b13          	addi	s6,s6,794 # 80011380 <pid_lock>
    8000206e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002070:	00010a17          	auipc	s4,0x10
    80002074:	538a0a13          	addi	s4,s4,1336 # 800125a8 <tickslock>
    int nproc = 0;
    80002078:	4c01                	li	s8,0
    8000207a:	a8a1                	j	800020d2 <scheduler+0xaa>
        p->state = RUNNING;
    8000207c:	0194ac23          	sw	s9,24(s1)
        c->proc = p;
    80002080:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002084:	06048593          	addi	a1,s1,96
    80002088:	855e                	mv	a0,s7
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	63a080e7          	jalr	1594(ra) # 800026c4 <swtch>
        c->proc = 0;
    80002092:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	d2a080e7          	jalr	-726(ra) # 80000dc2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020a0:	16848493          	addi	s1,s1,360
    800020a4:	01448d63          	beq	s1,s4,800020be <scheduler+0x96>
      acquire(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	c64080e7          	jalr	-924(ra) # 80000d0e <acquire>
      if(p->state != UNUSED) {
    800020b2:	4c9c                	lw	a5,24(s1)
    800020b4:	d3ed                	beqz	a5,80002096 <scheduler+0x6e>
        nproc++;
    800020b6:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800020b8:	fd579fe3          	bne	a5,s5,80002096 <scheduler+0x6e>
    800020bc:	b7c1                	j	8000207c <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800020be:	013aca63          	blt	s5,s3,800020d2 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ca:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020ce:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020da:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800020de:	89e2                	mv	s3,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    800020e0:	0000f497          	auipc	s1,0xf
    800020e4:	6b848493          	addi	s1,s1,1720 # 80011798 <proc>
        p->state = RUNNING;
    800020e8:	4c8d                	li	s9,3
    800020ea:	bf7d                	j	800020a8 <scheduler+0x80>

00000000800020ec <sched>:
{
    800020ec:	7179                	addi	sp,sp,-48
    800020ee:	f406                	sd	ra,40(sp)
    800020f0:	f022                	sd	s0,32(sp)
    800020f2:	ec26                	sd	s1,24(sp)
    800020f4:	e84a                	sd	s2,16(sp)
    800020f6:	e44e                	sd	s3,8(sp)
    800020f8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	9fe080e7          	jalr	-1538(ra) # 80001af8 <myproc>
    80002102:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b90080e7          	jalr	-1136(ra) # 80000c94 <holding>
    8000210c:	c93d                	beqz	a0,80002182 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000210e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	0000f717          	auipc	a4,0xf
    80002118:	26c70713          	addi	a4,a4,620 # 80011380 <pid_lock>
    8000211c:	97ba                	add	a5,a5,a4
    8000211e:	0907a703          	lw	a4,144(a5)
    80002122:	4785                	li	a5,1
    80002124:	06f71763          	bne	a4,a5,80002192 <sched+0xa6>
  if(p->state == RUNNING)
    80002128:	4c98                	lw	a4,24(s1)
    8000212a:	478d                	li	a5,3
    8000212c:	06f70b63          	beq	a4,a5,800021a2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002130:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002134:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002136:	efb5                	bnez	a5,800021b2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002138:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000213a:	0000f917          	auipc	s2,0xf
    8000213e:	24690913          	addi	s2,s2,582 # 80011380 <pid_lock>
    80002142:	2781                	sext.w	a5,a5
    80002144:	079e                	slli	a5,a5,0x7
    80002146:	97ca                	add	a5,a5,s2
    80002148:	0947a983          	lw	s3,148(a5)
    8000214c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000214e:	2781                	sext.w	a5,a5
    80002150:	079e                	slli	a5,a5,0x7
    80002152:	0000f597          	auipc	a1,0xf
    80002156:	24e58593          	addi	a1,a1,590 # 800113a0 <cpus+0x8>
    8000215a:	95be                	add	a1,a1,a5
    8000215c:	06048513          	addi	a0,s1,96
    80002160:	00000097          	auipc	ra,0x0
    80002164:	564080e7          	jalr	1380(ra) # 800026c4 <swtch>
    80002168:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000216a:	2781                	sext.w	a5,a5
    8000216c:	079e                	slli	a5,a5,0x7
    8000216e:	97ca                	add	a5,a5,s2
    80002170:	0937aa23          	sw	s3,148(a5)
}
    80002174:	70a2                	ld	ra,40(sp)
    80002176:	7402                	ld	s0,32(sp)
    80002178:	64e2                	ld	s1,24(sp)
    8000217a:	6942                	ld	s2,16(sp)
    8000217c:	69a2                	ld	s3,8(sp)
    8000217e:	6145                	addi	sp,sp,48
    80002180:	8082                	ret
    panic("sched p->lock");
    80002182:	00006517          	auipc	a0,0x6
    80002186:	08e50513          	addi	a0,a0,142 # 80008210 <digits+0x1d0>
    8000218a:	ffffe097          	auipc	ra,0xffffe
    8000218e:	3a6080e7          	jalr	934(ra) # 80000530 <panic>
    panic("sched locks");
    80002192:	00006517          	auipc	a0,0x6
    80002196:	08e50513          	addi	a0,a0,142 # 80008220 <digits+0x1e0>
    8000219a:	ffffe097          	auipc	ra,0xffffe
    8000219e:	396080e7          	jalr	918(ra) # 80000530 <panic>
    panic("sched running");
    800021a2:	00006517          	auipc	a0,0x6
    800021a6:	08e50513          	addi	a0,a0,142 # 80008230 <digits+0x1f0>
    800021aa:	ffffe097          	auipc	ra,0xffffe
    800021ae:	386080e7          	jalr	902(ra) # 80000530 <panic>
    panic("sched interruptible");
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	08e50513          	addi	a0,a0,142 # 80008240 <digits+0x200>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	376080e7          	jalr	886(ra) # 80000530 <panic>

00000000800021c2 <exit>:
{
    800021c2:	7179                	addi	sp,sp,-48
    800021c4:	f406                	sd	ra,40(sp)
    800021c6:	f022                	sd	s0,32(sp)
    800021c8:	ec26                	sd	s1,24(sp)
    800021ca:	e84a                	sd	s2,16(sp)
    800021cc:	e44e                	sd	s3,8(sp)
    800021ce:	e052                	sd	s4,0(sp)
    800021d0:	1800                	addi	s0,sp,48
    800021d2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	924080e7          	jalr	-1756(ra) # 80001af8 <myproc>
    800021dc:	89aa                	mv	s3,a0
  if(p == initproc)
    800021de:	00007797          	auipc	a5,0x7
    800021e2:	e4a7b783          	ld	a5,-438(a5) # 80009028 <initproc>
    800021e6:	0d050493          	addi	s1,a0,208
    800021ea:	15050913          	addi	s2,a0,336
    800021ee:	02a79363          	bne	a5,a0,80002214 <exit+0x52>
    panic("init exiting");
    800021f2:	00006517          	auipc	a0,0x6
    800021f6:	06650513          	addi	a0,a0,102 # 80008258 <digits+0x218>
    800021fa:	ffffe097          	auipc	ra,0xffffe
    800021fe:	336080e7          	jalr	822(ra) # 80000530 <panic>
      fileclose(f);
    80002202:	00002097          	auipc	ra,0x2
    80002206:	626080e7          	jalr	1574(ra) # 80004828 <fileclose>
      p->ofile[fd] = 0;
    8000220a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000220e:	04a1                	addi	s1,s1,8
    80002210:	01248563          	beq	s1,s2,8000221a <exit+0x58>
    if(p->ofile[fd]){
    80002214:	6088                	ld	a0,0(s1)
    80002216:	f575                	bnez	a0,80002202 <exit+0x40>
    80002218:	bfdd                	j	8000220e <exit+0x4c>
  begin_op();
    8000221a:	00002097          	auipc	ra,0x2
    8000221e:	13a080e7          	jalr	314(ra) # 80004354 <begin_op>
  iput(p->cwd);
    80002222:	1509b503          	ld	a0,336(s3)
    80002226:	00002097          	auipc	ra,0x2
    8000222a:	914080e7          	jalr	-1772(ra) # 80003b3a <iput>
  end_op();
    8000222e:	00002097          	auipc	ra,0x2
    80002232:	1a6080e7          	jalr	422(ra) # 800043d4 <end_op>
  p->cwd = 0;
    80002236:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000223a:	00007497          	auipc	s1,0x7
    8000223e:	dee48493          	addi	s1,s1,-530 # 80009028 <initproc>
    80002242:	6088                	ld	a0,0(s1)
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	aca080e7          	jalr	-1334(ra) # 80000d0e <acquire>
  wakeup1(initproc);
    8000224c:	6088                	ld	a0,0(s1)
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	70c080e7          	jalr	1804(ra) # 8000195a <wakeup1>
  release(&initproc->lock);
    80002256:	6088                	ld	a0,0(s1)
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	b6a080e7          	jalr	-1174(ra) # 80000dc2 <release>
  acquire(&p->lock);
    80002260:	854e                	mv	a0,s3
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	aac080e7          	jalr	-1364(ra) # 80000d0e <acquire>
  struct proc *original_parent = p->parent;
    8000226a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000226e:	854e                	mv	a0,s3
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	b52080e7          	jalr	-1198(ra) # 80000dc2 <release>
  acquire(&original_parent->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	a94080e7          	jalr	-1388(ra) # 80000d0e <acquire>
  acquire(&p->lock);
    80002282:	854e                	mv	a0,s3
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a8a080e7          	jalr	-1398(ra) # 80000d0e <acquire>
  reparent(p);
    8000228c:	854e                	mv	a0,s3
    8000228e:	00000097          	auipc	ra,0x0
    80002292:	d34080e7          	jalr	-716(ra) # 80001fc2 <reparent>
  wakeup1(original_parent);
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	6c2080e7          	jalr	1730(ra) # 8000195a <wakeup1>
  p->xstate = status;
    800022a0:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800022a4:	4791                	li	a5,4
    800022a6:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800022aa:	8526                	mv	a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	b16080e7          	jalr	-1258(ra) # 80000dc2 <release>
  sched();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	e38080e7          	jalr	-456(ra) # 800020ec <sched>
  panic("zombie exit");
    800022bc:	00006517          	auipc	a0,0x6
    800022c0:	fac50513          	addi	a0,a0,-84 # 80008268 <digits+0x228>
    800022c4:	ffffe097          	auipc	ra,0xffffe
    800022c8:	26c080e7          	jalr	620(ra) # 80000530 <panic>

00000000800022cc <yield>:
{
    800022cc:	1101                	addi	sp,sp,-32
    800022ce:	ec06                	sd	ra,24(sp)
    800022d0:	e822                	sd	s0,16(sp)
    800022d2:	e426                	sd	s1,8(sp)
    800022d4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	822080e7          	jalr	-2014(ra) # 80001af8 <myproc>
    800022de:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	a2e080e7          	jalr	-1490(ra) # 80000d0e <acquire>
  p->state = RUNNABLE;
    800022e8:	4789                	li	a5,2
    800022ea:	cc9c                	sw	a5,24(s1)
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	e00080e7          	jalr	-512(ra) # 800020ec <sched>
  release(&p->lock);
    800022f4:	8526                	mv	a0,s1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	acc080e7          	jalr	-1332(ra) # 80000dc2 <release>
}
    800022fe:	60e2                	ld	ra,24(sp)
    80002300:	6442                	ld	s0,16(sp)
    80002302:	64a2                	ld	s1,8(sp)
    80002304:	6105                	addi	sp,sp,32
    80002306:	8082                	ret

0000000080002308 <sleep>:
{
    80002308:	7179                	addi	sp,sp,-48
    8000230a:	f406                	sd	ra,40(sp)
    8000230c:	f022                	sd	s0,32(sp)
    8000230e:	ec26                	sd	s1,24(sp)
    80002310:	e84a                	sd	s2,16(sp)
    80002312:	e44e                	sd	s3,8(sp)
    80002314:	1800                	addi	s0,sp,48
    80002316:	89aa                	mv	s3,a0
    80002318:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	7de080e7          	jalr	2014(ra) # 80001af8 <myproc>
    80002322:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002324:	05250663          	beq	a0,s2,80002370 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	9e6080e7          	jalr	-1562(ra) # 80000d0e <acquire>
    release(lk);
    80002330:	854a                	mv	a0,s2
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	a90080e7          	jalr	-1392(ra) # 80000dc2 <release>
  p->chan = chan;
    8000233a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000233e:	4785                	li	a5,1
    80002340:	cc9c                	sw	a5,24(s1)
  sched();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	daa080e7          	jalr	-598(ra) # 800020ec <sched>
  p->chan = 0;
    8000234a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	a72080e7          	jalr	-1422(ra) # 80000dc2 <release>
    acquire(lk);
    80002358:	854a                	mv	a0,s2
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	9b4080e7          	jalr	-1612(ra) # 80000d0e <acquire>
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret
  p->chan = chan;
    80002370:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002374:	4785                	li	a5,1
    80002376:	cd1c                	sw	a5,24(a0)
  sched();
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	d74080e7          	jalr	-652(ra) # 800020ec <sched>
  p->chan = 0;
    80002380:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002384:	bff9                	j	80002362 <sleep+0x5a>

0000000080002386 <wait>:
{
    80002386:	715d                	addi	sp,sp,-80
    80002388:	e486                	sd	ra,72(sp)
    8000238a:	e0a2                	sd	s0,64(sp)
    8000238c:	fc26                	sd	s1,56(sp)
    8000238e:	f84a                	sd	s2,48(sp)
    80002390:	f44e                	sd	s3,40(sp)
    80002392:	f052                	sd	s4,32(sp)
    80002394:	ec56                	sd	s5,24(sp)
    80002396:	e85a                	sd	s6,16(sp)
    80002398:	e45e                	sd	s7,8(sp)
    8000239a:	e062                	sd	s8,0(sp)
    8000239c:	0880                	addi	s0,sp,80
    8000239e:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	758080e7          	jalr	1880(ra) # 80001af8 <myproc>
    800023a8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800023aa:	8c2a                	mv	s8,a0
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	962080e7          	jalr	-1694(ra) # 80000d0e <acquire>
    havekids = 0;
    800023b4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023b6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800023b8:	00010997          	auipc	s3,0x10
    800023bc:	1f098993          	addi	s3,s3,496 # 800125a8 <tickslock>
        havekids = 1;
    800023c0:	4b05                	li	s6,1
    havekids = 0;
    800023c2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023c4:	0000f497          	auipc	s1,0xf
    800023c8:	3d448493          	addi	s1,s1,980 # 80011798 <proc>
    800023cc:	a08d                	j	8000242e <wait+0xa8>
          pid = np->pid;
    800023ce:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023d2:	000a8e63          	beqz	s5,800023ee <wait+0x68>
    800023d6:	4691                	li	a3,4
    800023d8:	03448613          	addi	a2,s1,52
    800023dc:	85d6                	mv	a1,s5
    800023de:	05093503          	ld	a0,80(s2)
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	3ac080e7          	jalr	940(ra) # 8000178e <copyout>
    800023ea:	02054263          	bltz	a0,8000240e <wait+0x88>
          freeproc(np);
    800023ee:	8526                	mv	a0,s1
    800023f0:	00000097          	auipc	ra,0x0
    800023f4:	8ba080e7          	jalr	-1862(ra) # 80001caa <freeproc>
          release(&np->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	9c8080e7          	jalr	-1592(ra) # 80000dc2 <release>
          release(&p->lock);
    80002402:	854a                	mv	a0,s2
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	9be080e7          	jalr	-1602(ra) # 80000dc2 <release>
          return pid;
    8000240c:	a8a9                	j	80002466 <wait+0xe0>
            release(&np->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	9b2080e7          	jalr	-1614(ra) # 80000dc2 <release>
            release(&p->lock);
    80002418:	854a                	mv	a0,s2
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	9a8080e7          	jalr	-1624(ra) # 80000dc2 <release>
            return -1;
    80002422:	59fd                	li	s3,-1
    80002424:	a089                	j	80002466 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002426:	16848493          	addi	s1,s1,360
    8000242a:	03348463          	beq	s1,s3,80002452 <wait+0xcc>
      if(np->parent == p){
    8000242e:	709c                	ld	a5,32(s1)
    80002430:	ff279be3          	bne	a5,s2,80002426 <wait+0xa0>
        acquire(&np->lock);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	8d8080e7          	jalr	-1832(ra) # 80000d0e <acquire>
        if(np->state == ZOMBIE){
    8000243e:	4c9c                	lw	a5,24(s1)
    80002440:	f94787e3          	beq	a5,s4,800023ce <wait+0x48>
        release(&np->lock);
    80002444:	8526                	mv	a0,s1
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	97c080e7          	jalr	-1668(ra) # 80000dc2 <release>
        havekids = 1;
    8000244e:	875a                	mv	a4,s6
    80002450:	bfd9                	j	80002426 <wait+0xa0>
    if(!havekids || p->killed){
    80002452:	c701                	beqz	a4,8000245a <wait+0xd4>
    80002454:	03092783          	lw	a5,48(s2)
    80002458:	c785                	beqz	a5,80002480 <wait+0xfa>
      release(&p->lock);
    8000245a:	854a                	mv	a0,s2
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	966080e7          	jalr	-1690(ra) # 80000dc2 <release>
      return -1;
    80002464:	59fd                	li	s3,-1
}
    80002466:	854e                	mv	a0,s3
    80002468:	60a6                	ld	ra,72(sp)
    8000246a:	6406                	ld	s0,64(sp)
    8000246c:	74e2                	ld	s1,56(sp)
    8000246e:	7942                	ld	s2,48(sp)
    80002470:	79a2                	ld	s3,40(sp)
    80002472:	7a02                	ld	s4,32(sp)
    80002474:	6ae2                	ld	s5,24(sp)
    80002476:	6b42                	ld	s6,16(sp)
    80002478:	6ba2                	ld	s7,8(sp)
    8000247a:	6c02                	ld	s8,0(sp)
    8000247c:	6161                	addi	sp,sp,80
    8000247e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002480:	85e2                	mv	a1,s8
    80002482:	854a                	mv	a0,s2
    80002484:	00000097          	auipc	ra,0x0
    80002488:	e84080e7          	jalr	-380(ra) # 80002308 <sleep>
    havekids = 0;
    8000248c:	bf1d                	j	800023c2 <wait+0x3c>

000000008000248e <wakeup>:
{
    8000248e:	7139                	addi	sp,sp,-64
    80002490:	fc06                	sd	ra,56(sp)
    80002492:	f822                	sd	s0,48(sp)
    80002494:	f426                	sd	s1,40(sp)
    80002496:	f04a                	sd	s2,32(sp)
    80002498:	ec4e                	sd	s3,24(sp)
    8000249a:	e852                	sd	s4,16(sp)
    8000249c:	e456                	sd	s5,8(sp)
    8000249e:	0080                	addi	s0,sp,64
    800024a0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a2:	0000f497          	auipc	s1,0xf
    800024a6:	2f648493          	addi	s1,s1,758 # 80011798 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800024aa:	4985                	li	s3,1
      p->state = RUNNABLE;
    800024ac:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ae:	00010917          	auipc	s2,0x10
    800024b2:	0fa90913          	addi	s2,s2,250 # 800125a8 <tickslock>
    800024b6:	a821                	j	800024ce <wakeup+0x40>
      p->state = RUNNABLE;
    800024b8:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	904080e7          	jalr	-1788(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c6:	16848493          	addi	s1,s1,360
    800024ca:	01248e63          	beq	s1,s2,800024e6 <wakeup+0x58>
    acquire(&p->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	83e080e7          	jalr	-1986(ra) # 80000d0e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024d8:	4c9c                	lw	a5,24(s1)
    800024da:	ff3791e3          	bne	a5,s3,800024bc <wakeup+0x2e>
    800024de:	749c                	ld	a5,40(s1)
    800024e0:	fd479ee3          	bne	a5,s4,800024bc <wakeup+0x2e>
    800024e4:	bfd1                	j	800024b8 <wakeup+0x2a>
}
    800024e6:	70e2                	ld	ra,56(sp)
    800024e8:	7442                	ld	s0,48(sp)
    800024ea:	74a2                	ld	s1,40(sp)
    800024ec:	7902                	ld	s2,32(sp)
    800024ee:	69e2                	ld	s3,24(sp)
    800024f0:	6a42                	ld	s4,16(sp)
    800024f2:	6aa2                	ld	s5,8(sp)
    800024f4:	6121                	addi	sp,sp,64
    800024f6:	8082                	ret

00000000800024f8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	1800                	addi	s0,sp,48
    80002506:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002508:	0000f497          	auipc	s1,0xf
    8000250c:	29048493          	addi	s1,s1,656 # 80011798 <proc>
    80002510:	00010997          	auipc	s3,0x10
    80002514:	09898993          	addi	s3,s3,152 # 800125a8 <tickslock>
    acquire(&p->lock);
    80002518:	8526                	mv	a0,s1
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	7f4080e7          	jalr	2036(ra) # 80000d0e <acquire>
    if(p->pid == pid){
    80002522:	5c9c                	lw	a5,56(s1)
    80002524:	03278363          	beq	a5,s2,8000254a <kill+0x52>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	898080e7          	jalr	-1896(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002532:	16848493          	addi	s1,s1,360
    80002536:	ff3491e3          	bne	s1,s3,80002518 <kill+0x20>
  }
  return -1;
    8000253a:	557d                	li	a0,-1
}
    8000253c:	70a2                	ld	ra,40(sp)
    8000253e:	7402                	ld	s0,32(sp)
    80002540:	64e2                	ld	s1,24(sp)
    80002542:	6942                	ld	s2,16(sp)
    80002544:	69a2                	ld	s3,8(sp)
    80002546:	6145                	addi	sp,sp,48
    80002548:	8082                	ret
      p->killed = 1;
    8000254a:	4785                	li	a5,1
    8000254c:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000254e:	4c98                	lw	a4,24(s1)
    80002550:	4785                	li	a5,1
    80002552:	00f70963          	beq	a4,a5,80002564 <kill+0x6c>
      release(&p->lock);
    80002556:	8526                	mv	a0,s1
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	86a080e7          	jalr	-1942(ra) # 80000dc2 <release>
      return 0;
    80002560:	4501                	li	a0,0
    80002562:	bfe9                	j	8000253c <kill+0x44>
        p->state = RUNNABLE;
    80002564:	4789                	li	a5,2
    80002566:	cc9c                	sw	a5,24(s1)
    80002568:	b7fd                	j	80002556 <kill+0x5e>

000000008000256a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000256a:	7179                	addi	sp,sp,-48
    8000256c:	f406                	sd	ra,40(sp)
    8000256e:	f022                	sd	s0,32(sp)
    80002570:	ec26                	sd	s1,24(sp)
    80002572:	e84a                	sd	s2,16(sp)
    80002574:	e44e                	sd	s3,8(sp)
    80002576:	e052                	sd	s4,0(sp)
    80002578:	1800                	addi	s0,sp,48
    8000257a:	84aa                	mv	s1,a0
    8000257c:	892e                	mv	s2,a1
    8000257e:	89b2                	mv	s3,a2
    80002580:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	576080e7          	jalr	1398(ra) # 80001af8 <myproc>
  if(user_dst){
    8000258a:	c08d                	beqz	s1,800025ac <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000258c:	86d2                	mv	a3,s4
    8000258e:	864e                	mv	a2,s3
    80002590:	85ca                	mv	a1,s2
    80002592:	6928                	ld	a0,80(a0)
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	1fa080e7          	jalr	506(ra) # 8000178e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000259c:	70a2                	ld	ra,40(sp)
    8000259e:	7402                	ld	s0,32(sp)
    800025a0:	64e2                	ld	s1,24(sp)
    800025a2:	6942                	ld	s2,16(sp)
    800025a4:	69a2                	ld	s3,8(sp)
    800025a6:	6a02                	ld	s4,0(sp)
    800025a8:	6145                	addi	sp,sp,48
    800025aa:	8082                	ret
    memmove((char *)dst, src, len);
    800025ac:	000a061b          	sext.w	a2,s4
    800025b0:	85ce                	mv	a1,s3
    800025b2:	854a                	mv	a0,s2
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	8b6080e7          	jalr	-1866(ra) # 80000e6a <memmove>
    return 0;
    800025bc:	8526                	mv	a0,s1
    800025be:	bff9                	j	8000259c <either_copyout+0x32>

00000000800025c0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	e052                	sd	s4,0(sp)
    800025ce:	1800                	addi	s0,sp,48
    800025d0:	892a                	mv	s2,a0
    800025d2:	84ae                	mv	s1,a1
    800025d4:	89b2                	mv	s3,a2
    800025d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	520080e7          	jalr	1312(ra) # 80001af8 <myproc>
  if(user_src){
    800025e0:	c08d                	beqz	s1,80002602 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025e2:	86d2                	mv	a3,s4
    800025e4:	864e                	mv	a2,s3
    800025e6:	85ca                	mv	a1,s2
    800025e8:	6928                	ld	a0,80(a0)
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	230080e7          	jalr	560(ra) # 8000181a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025f2:	70a2                	ld	ra,40(sp)
    800025f4:	7402                	ld	s0,32(sp)
    800025f6:	64e2                	ld	s1,24(sp)
    800025f8:	6942                	ld	s2,16(sp)
    800025fa:	69a2                	ld	s3,8(sp)
    800025fc:	6a02                	ld	s4,0(sp)
    800025fe:	6145                	addi	sp,sp,48
    80002600:	8082                	ret
    memmove(dst, (char*)src, len);
    80002602:	000a061b          	sext.w	a2,s4
    80002606:	85ce                	mv	a1,s3
    80002608:	854a                	mv	a0,s2
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	860080e7          	jalr	-1952(ra) # 80000e6a <memmove>
    return 0;
    80002612:	8526                	mv	a0,s1
    80002614:	bff9                	j	800025f2 <either_copyin+0x32>

0000000080002616 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002616:	715d                	addi	sp,sp,-80
    80002618:	e486                	sd	ra,72(sp)
    8000261a:	e0a2                	sd	s0,64(sp)
    8000261c:	fc26                	sd	s1,56(sp)
    8000261e:	f84a                	sd	s2,48(sp)
    80002620:	f44e                	sd	s3,40(sp)
    80002622:	f052                	sd	s4,32(sp)
    80002624:	ec56                	sd	s5,24(sp)
    80002626:	e85a                	sd	s6,16(sp)
    80002628:	e45e                	sd	s7,8(sp)
    8000262a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000262c:	00006517          	auipc	a0,0x6
    80002630:	ab450513          	addi	a0,a0,-1356 # 800080e0 <digits+0xa0>
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	f46080e7          	jalr	-186(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263c:	0000f497          	auipc	s1,0xf
    80002640:	2b448493          	addi	s1,s1,692 # 800118f0 <proc+0x158>
    80002644:	00010917          	auipc	s2,0x10
    80002648:	0bc90913          	addi	s2,s2,188 # 80012700 <hashTable+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000264e:	00006997          	auipc	s3,0x6
    80002652:	c2a98993          	addi	s3,s3,-982 # 80008278 <digits+0x238>
    printf("%d %s %s", p->pid, state, p->name);
    80002656:	00006a97          	auipc	s5,0x6
    8000265a:	c2aa8a93          	addi	s5,s5,-982 # 80008280 <digits+0x240>
    printf("\n");
    8000265e:	00006a17          	auipc	s4,0x6
    80002662:	a82a0a13          	addi	s4,s4,-1406 # 800080e0 <digits+0xa0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002666:	00006b97          	auipc	s7,0x6
    8000266a:	c52b8b93          	addi	s7,s7,-942 # 800082b8 <states.1710>
    8000266e:	a00d                	j	80002690 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002670:	ee06a583          	lw	a1,-288(a3)
    80002674:	8556                	mv	a0,s5
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	f04080e7          	jalr	-252(ra) # 8000057a <printf>
    printf("\n");
    8000267e:	8552                	mv	a0,s4
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	efa080e7          	jalr	-262(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002688:	16848493          	addi	s1,s1,360
    8000268c:	03248163          	beq	s1,s2,800026ae <procdump+0x98>
    if(p->state == UNUSED)
    80002690:	86a6                	mv	a3,s1
    80002692:	ec04a783          	lw	a5,-320(s1)
    80002696:	dbed                	beqz	a5,80002688 <procdump+0x72>
      state = "???";
    80002698:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000269a:	fcfb6be3          	bltu	s6,a5,80002670 <procdump+0x5a>
    8000269e:	1782                	slli	a5,a5,0x20
    800026a0:	9381                	srli	a5,a5,0x20
    800026a2:	078e                	slli	a5,a5,0x3
    800026a4:	97de                	add	a5,a5,s7
    800026a6:	6390                	ld	a2,0(a5)
    800026a8:	f661                	bnez	a2,80002670 <procdump+0x5a>
      state = "???";
    800026aa:	864e                	mv	a2,s3
    800026ac:	b7d1                	j	80002670 <procdump+0x5a>
  }
}
    800026ae:	60a6                	ld	ra,72(sp)
    800026b0:	6406                	ld	s0,64(sp)
    800026b2:	74e2                	ld	s1,56(sp)
    800026b4:	7942                	ld	s2,48(sp)
    800026b6:	79a2                	ld	s3,40(sp)
    800026b8:	7a02                	ld	s4,32(sp)
    800026ba:	6ae2                	ld	s5,24(sp)
    800026bc:	6b42                	ld	s6,16(sp)
    800026be:	6ba2                	ld	s7,8(sp)
    800026c0:	6161                	addi	sp,sp,80
    800026c2:	8082                	ret

00000000800026c4 <swtch>:
    800026c4:	00153023          	sd	ra,0(a0)
    800026c8:	00253423          	sd	sp,8(a0)
    800026cc:	e900                	sd	s0,16(a0)
    800026ce:	ed04                	sd	s1,24(a0)
    800026d0:	03253023          	sd	s2,32(a0)
    800026d4:	03353423          	sd	s3,40(a0)
    800026d8:	03453823          	sd	s4,48(a0)
    800026dc:	03553c23          	sd	s5,56(a0)
    800026e0:	05653023          	sd	s6,64(a0)
    800026e4:	05753423          	sd	s7,72(a0)
    800026e8:	05853823          	sd	s8,80(a0)
    800026ec:	05953c23          	sd	s9,88(a0)
    800026f0:	07a53023          	sd	s10,96(a0)
    800026f4:	07b53423          	sd	s11,104(a0)
    800026f8:	0005b083          	ld	ra,0(a1)
    800026fc:	0085b103          	ld	sp,8(a1)
    80002700:	6980                	ld	s0,16(a1)
    80002702:	6d84                	ld	s1,24(a1)
    80002704:	0205b903          	ld	s2,32(a1)
    80002708:	0285b983          	ld	s3,40(a1)
    8000270c:	0305ba03          	ld	s4,48(a1)
    80002710:	0385ba83          	ld	s5,56(a1)
    80002714:	0405bb03          	ld	s6,64(a1)
    80002718:	0485bb83          	ld	s7,72(a1)
    8000271c:	0505bc03          	ld	s8,80(a1)
    80002720:	0585bc83          	ld	s9,88(a1)
    80002724:	0605bd03          	ld	s10,96(a1)
    80002728:	0685bd83          	ld	s11,104(a1)
    8000272c:	8082                	ret

000000008000272e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000272e:	1141                	addi	sp,sp,-16
    80002730:	e406                	sd	ra,8(sp)
    80002732:	e022                	sd	s0,0(sp)
    80002734:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002736:	00006597          	auipc	a1,0x6
    8000273a:	baa58593          	addi	a1,a1,-1110 # 800082e0 <states.1710+0x28>
    8000273e:	00010517          	auipc	a0,0x10
    80002742:	e6a50513          	addi	a0,a0,-406 # 800125a8 <tickslock>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	538080e7          	jalr	1336(ra) # 80000c7e <initlock>
}
    8000274e:	60a2                	ld	ra,8(sp)
    80002750:	6402                	ld	s0,0(sp)
    80002752:	0141                	addi	sp,sp,16
    80002754:	8082                	ret

0000000080002756 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002756:	1141                	addi	sp,sp,-16
    80002758:	e422                	sd	s0,8(sp)
    8000275a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000275c:	00004797          	auipc	a5,0x4
    80002760:	92478793          	addi	a5,a5,-1756 # 80006080 <kernelvec>
    80002764:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002768:	6422                	ld	s0,8(sp)
    8000276a:	0141                	addi	sp,sp,16
    8000276c:	8082                	ret

000000008000276e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000276e:	1141                	addi	sp,sp,-16
    80002770:	e406                	sd	ra,8(sp)
    80002772:	e022                	sd	s0,0(sp)
    80002774:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002776:	fffff097          	auipc	ra,0xfffff
    8000277a:	382080e7          	jalr	898(ra) # 80001af8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000277e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002782:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002784:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002788:	00005617          	auipc	a2,0x5
    8000278c:	87860613          	addi	a2,a2,-1928 # 80007000 <_trampoline>
    80002790:	00005697          	auipc	a3,0x5
    80002794:	87068693          	addi	a3,a3,-1936 # 80007000 <_trampoline>
    80002798:	8e91                	sub	a3,a3,a2
    8000279a:	040007b7          	lui	a5,0x4000
    8000279e:	17fd                	addi	a5,a5,-1
    800027a0:	07b2                	slli	a5,a5,0xc
    800027a2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027aa:	180026f3          	csrr	a3,satp
    800027ae:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027b0:	6d38                	ld	a4,88(a0)
    800027b2:	6134                	ld	a3,64(a0)
    800027b4:	6585                	lui	a1,0x1
    800027b6:	96ae                	add	a3,a3,a1
    800027b8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027ba:	6d38                	ld	a4,88(a0)
    800027bc:	00000697          	auipc	a3,0x0
    800027c0:	13868693          	addi	a3,a3,312 # 800028f4 <usertrap>
    800027c4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027c6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027c8:	8692                	mv	a3,tp
    800027ca:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027cc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027d0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027d4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027de:	6f18                	ld	a4,24(a4)
    800027e0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027e4:	692c                	ld	a1,80(a0)
    800027e6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027e8:	00005717          	auipc	a4,0x5
    800027ec:	8a870713          	addi	a4,a4,-1880 # 80007090 <userret>
    800027f0:	8f11                	sub	a4,a4,a2
    800027f2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027f4:	577d                	li	a4,-1
    800027f6:	177e                	slli	a4,a4,0x3f
    800027f8:	8dd9                	or	a1,a1,a4
    800027fa:	02000537          	lui	a0,0x2000
    800027fe:	157d                	addi	a0,a0,-1
    80002800:	0536                	slli	a0,a0,0xd
    80002802:	9782                	jalr	a5
}
    80002804:	60a2                	ld	ra,8(sp)
    80002806:	6402                	ld	s0,0(sp)
    80002808:	0141                	addi	sp,sp,16
    8000280a:	8082                	ret

000000008000280c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000280c:	1101                	addi	sp,sp,-32
    8000280e:	ec06                	sd	ra,24(sp)
    80002810:	e822                	sd	s0,16(sp)
    80002812:	e426                	sd	s1,8(sp)
    80002814:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002816:	00010497          	auipc	s1,0x10
    8000281a:	d9248493          	addi	s1,s1,-622 # 800125a8 <tickslock>
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	4ee080e7          	jalr	1262(ra) # 80000d0e <acquire>
  ticks++;
    80002828:	00007517          	auipc	a0,0x7
    8000282c:	80850513          	addi	a0,a0,-2040 # 80009030 <ticks>
    80002830:	411c                	lw	a5,0(a0)
    80002832:	2785                	addiw	a5,a5,1
    80002834:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	c58080e7          	jalr	-936(ra) # 8000248e <wakeup>
  release(&tickslock);
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	582080e7          	jalr	1410(ra) # 80000dc2 <release>
}
    80002848:	60e2                	ld	ra,24(sp)
    8000284a:	6442                	ld	s0,16(sp)
    8000284c:	64a2                	ld	s1,8(sp)
    8000284e:	6105                	addi	sp,sp,32
    80002850:	8082                	ret

0000000080002852 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002852:	1101                	addi	sp,sp,-32
    80002854:	ec06                	sd	ra,24(sp)
    80002856:	e822                	sd	s0,16(sp)
    80002858:	e426                	sd	s1,8(sp)
    8000285a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000285c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002860:	00074d63          	bltz	a4,8000287a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002864:	57fd                	li	a5,-1
    80002866:	17fe                	slli	a5,a5,0x3f
    80002868:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000286a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000286c:	06f70363          	beq	a4,a5,800028d2 <devintr+0x80>
  }
}
    80002870:	60e2                	ld	ra,24(sp)
    80002872:	6442                	ld	s0,16(sp)
    80002874:	64a2                	ld	s1,8(sp)
    80002876:	6105                	addi	sp,sp,32
    80002878:	8082                	ret
     (scause & 0xff) == 9){
    8000287a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000287e:	46a5                	li	a3,9
    80002880:	fed792e3          	bne	a5,a3,80002864 <devintr+0x12>
    int irq = plic_claim();
    80002884:	00004097          	auipc	ra,0x4
    80002888:	904080e7          	jalr	-1788(ra) # 80006188 <plic_claim>
    8000288c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000288e:	47a9                	li	a5,10
    80002890:	02f50763          	beq	a0,a5,800028be <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002894:	4785                	li	a5,1
    80002896:	02f50963          	beq	a0,a5,800028c8 <devintr+0x76>
    return 1;
    8000289a:	4505                	li	a0,1
    } else if(irq){
    8000289c:	d8f1                	beqz	s1,80002870 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000289e:	85a6                	mv	a1,s1
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	a4850513          	addi	a0,a0,-1464 # 800082e8 <states.1710+0x30>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	cd2080e7          	jalr	-814(ra) # 8000057a <printf>
      plic_complete(irq);
    800028b0:	8526                	mv	a0,s1
    800028b2:	00004097          	auipc	ra,0x4
    800028b6:	8fa080e7          	jalr	-1798(ra) # 800061ac <plic_complete>
    return 1;
    800028ba:	4505                	li	a0,1
    800028bc:	bf55                	j	80002870 <devintr+0x1e>
      uartintr();
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	0dc080e7          	jalr	220(ra) # 8000099a <uartintr>
    800028c6:	b7ed                	j	800028b0 <devintr+0x5e>
      virtio_disk_intr();
    800028c8:	00004097          	auipc	ra,0x4
    800028cc:	dc4080e7          	jalr	-572(ra) # 8000668c <virtio_disk_intr>
    800028d0:	b7c5                	j	800028b0 <devintr+0x5e>
    if(cpuid() == 0){
    800028d2:	fffff097          	auipc	ra,0xfffff
    800028d6:	1fa080e7          	jalr	506(ra) # 80001acc <cpuid>
    800028da:	c901                	beqz	a0,800028ea <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028dc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028e2:	14479073          	csrw	sip,a5
    return 2;
    800028e6:	4509                	li	a0,2
    800028e8:	b761                	j	80002870 <devintr+0x1e>
      clockintr();
    800028ea:	00000097          	auipc	ra,0x0
    800028ee:	f22080e7          	jalr	-222(ra) # 8000280c <clockintr>
    800028f2:	b7ed                	j	800028dc <devintr+0x8a>

00000000800028f4 <usertrap>:
{
    800028f4:	1101                	addi	sp,sp,-32
    800028f6:	ec06                	sd	ra,24(sp)
    800028f8:	e822                	sd	s0,16(sp)
    800028fa:	e426                	sd	s1,8(sp)
    800028fc:	e04a                	sd	s2,0(sp)
    800028fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002900:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002904:	1007f793          	andi	a5,a5,256
    80002908:	e3ad                	bnez	a5,8000296a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000290a:	00003797          	auipc	a5,0x3
    8000290e:	77678793          	addi	a5,a5,1910 # 80006080 <kernelvec>
    80002912:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002916:	fffff097          	auipc	ra,0xfffff
    8000291a:	1e2080e7          	jalr	482(ra) # 80001af8 <myproc>
    8000291e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002920:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002922:	14102773          	csrr	a4,sepc
    80002926:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000292c:	47a1                	li	a5,8
    8000292e:	04f71c63          	bne	a4,a5,80002986 <usertrap+0x92>
    if(p->killed)
    80002932:	591c                	lw	a5,48(a0)
    80002934:	e3b9                	bnez	a5,8000297a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002936:	6cb8                	ld	a4,88(s1)
    80002938:	6f1c                	ld	a5,24(a4)
    8000293a:	0791                	addi	a5,a5,4
    8000293c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002942:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002946:	10079073          	csrw	sstatus,a5
    syscall();
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	2e0080e7          	jalr	736(ra) # 80002c2a <syscall>
  if(p->killed)
    80002952:	589c                	lw	a5,48(s1)
    80002954:	ebc1                	bnez	a5,800029e4 <usertrap+0xf0>
  usertrapret();
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	e18080e7          	jalr	-488(ra) # 8000276e <usertrapret>
}
    8000295e:	60e2                	ld	ra,24(sp)
    80002960:	6442                	ld	s0,16(sp)
    80002962:	64a2                	ld	s1,8(sp)
    80002964:	6902                	ld	s2,0(sp)
    80002966:	6105                	addi	sp,sp,32
    80002968:	8082                	ret
    panic("usertrap: not from user mode");
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	99e50513          	addi	a0,a0,-1634 # 80008308 <states.1710+0x50>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	bbe080e7          	jalr	-1090(ra) # 80000530 <panic>
      exit(-1);
    8000297a:	557d                	li	a0,-1
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	846080e7          	jalr	-1978(ra) # 800021c2 <exit>
    80002984:	bf4d                	j	80002936 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	ecc080e7          	jalr	-308(ra) # 80002852 <devintr>
    8000298e:	892a                	mv	s2,a0
    80002990:	c501                	beqz	a0,80002998 <usertrap+0xa4>
  if(p->killed)
    80002992:	589c                	lw	a5,48(s1)
    80002994:	c3a1                	beqz	a5,800029d4 <usertrap+0xe0>
    80002996:	a815                	j	800029ca <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002998:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000299c:	5c90                	lw	a2,56(s1)
    8000299e:	00006517          	auipc	a0,0x6
    800029a2:	98a50513          	addi	a0,a0,-1654 # 80008328 <states.1710+0x70>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	bd4080e7          	jalr	-1068(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	9a250513          	addi	a0,a0,-1630 # 80008358 <states.1710+0xa0>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	bbc080e7          	jalr	-1092(ra) # 8000057a <printf>
    p->killed = 1;
    800029c6:	4785                	li	a5,1
    800029c8:	d89c                	sw	a5,48(s1)
    exit(-1);
    800029ca:	557d                	li	a0,-1
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	7f6080e7          	jalr	2038(ra) # 800021c2 <exit>
  if(which_dev == 2)
    800029d4:	4789                	li	a5,2
    800029d6:	f8f910e3          	bne	s2,a5,80002956 <usertrap+0x62>
    yield();
    800029da:	00000097          	auipc	ra,0x0
    800029de:	8f2080e7          	jalr	-1806(ra) # 800022cc <yield>
    800029e2:	bf95                	j	80002956 <usertrap+0x62>
  int which_dev = 0;
    800029e4:	4901                	li	s2,0
    800029e6:	b7d5                	j	800029ca <usertrap+0xd6>

00000000800029e8 <kerneltrap>:
{
    800029e8:	7179                	addi	sp,sp,-48
    800029ea:	f406                	sd	ra,40(sp)
    800029ec:	f022                	sd	s0,32(sp)
    800029ee:	ec26                	sd	s1,24(sp)
    800029f0:	e84a                	sd	s2,16(sp)
    800029f2:	e44e                	sd	s3,8(sp)
    800029f4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a02:	1004f793          	andi	a5,s1,256
    80002a06:	cb85                	beqz	a5,80002a36 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a08:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a0c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a0e:	ef85                	bnez	a5,80002a46 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	e42080e7          	jalr	-446(ra) # 80002852 <devintr>
    80002a18:	cd1d                	beqz	a0,80002a56 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1a:	4789                	li	a5,2
    80002a1c:	06f50a63          	beq	a0,a5,80002a90 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a20:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10049073          	csrw	sstatus,s1
}
    80002a28:	70a2                	ld	ra,40(sp)
    80002a2a:	7402                	ld	s0,32(sp)
    80002a2c:	64e2                	ld	s1,24(sp)
    80002a2e:	6942                	ld	s2,16(sp)
    80002a30:	69a2                	ld	s3,8(sp)
    80002a32:	6145                	addi	sp,sp,48
    80002a34:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	94250513          	addi	a0,a0,-1726 # 80008378 <states.1710+0xc0>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	af2080e7          	jalr	-1294(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	95a50513          	addi	a0,a0,-1702 # 800083a0 <states.1710+0xe8>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	ae2080e7          	jalr	-1310(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002a56:	85ce                	mv	a1,s3
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	96850513          	addi	a0,a0,-1688 # 800083c0 <states.1710+0x108>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	b1a080e7          	jalr	-1254(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a68:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	96050513          	addi	a0,a0,-1696 # 800083d0 <states.1710+0x118>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b02080e7          	jalr	-1278(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	96850513          	addi	a0,a0,-1688 # 800083e8 <states.1710+0x130>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	aa8080e7          	jalr	-1368(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	068080e7          	jalr	104(ra) # 80001af8 <myproc>
    80002a98:	d541                	beqz	a0,80002a20 <kerneltrap+0x38>
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	05e080e7          	jalr	94(ra) # 80001af8 <myproc>
    80002aa2:	4d18                	lw	a4,24(a0)
    80002aa4:	478d                	li	a5,3
    80002aa6:	f6f71de3          	bne	a4,a5,80002a20 <kerneltrap+0x38>
    yield();
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	822080e7          	jalr	-2014(ra) # 800022cc <yield>
    80002ab2:	b7bd                	j	80002a20 <kerneltrap+0x38>

0000000080002ab4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	1000                	addi	s0,sp,32
    80002abe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	038080e7          	jalr	56(ra) # 80001af8 <myproc>
  switch (n) {
    80002ac8:	4795                	li	a5,5
    80002aca:	0497e163          	bltu	a5,s1,80002b0c <argraw+0x58>
    80002ace:	048a                	slli	s1,s1,0x2
    80002ad0:	00006717          	auipc	a4,0x6
    80002ad4:	95070713          	addi	a4,a4,-1712 # 80008420 <states.1710+0x168>
    80002ad8:	94ba                	add	s1,s1,a4
    80002ada:	409c                	lw	a5,0(s1)
    80002adc:	97ba                	add	a5,a5,a4
    80002ade:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ae0:	6d3c                	ld	a5,88(a0)
    80002ae2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret
    return p->trapframe->a1;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	7fa8                	ld	a0,120(a5)
    80002af2:	bfcd                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a2;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	63c8                	ld	a0,128(a5)
    80002af8:	b7f5                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a3;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	67c8                	ld	a0,136(a5)
    80002afe:	b7dd                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a4;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6bc8                	ld	a0,144(a5)
    80002b04:	b7c5                	j	80002ae4 <argraw+0x30>
    return p->trapframe->a5;
    80002b06:	6d3c                	ld	a5,88(a0)
    80002b08:	6fc8                	ld	a0,152(a5)
    80002b0a:	bfe9                	j	80002ae4 <argraw+0x30>
  panic("argraw");
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	8ec50513          	addi	a0,a0,-1812 # 800083f8 <states.1710+0x140>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a1c080e7          	jalr	-1508(ra) # 80000530 <panic>

0000000080002b1c <fetchaddr>:
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	e04a                	sd	s2,0(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84aa                	mv	s1,a0
    80002b2a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	fcc080e7          	jalr	-52(ra) # 80001af8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b34:	653c                	ld	a5,72(a0)
    80002b36:	02f4f863          	bgeu	s1,a5,80002b66 <fetchaddr+0x4a>
    80002b3a:	00848713          	addi	a4,s1,8
    80002b3e:	02e7e663          	bltu	a5,a4,80002b6a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b42:	46a1                	li	a3,8
    80002b44:	8626                	mv	a2,s1
    80002b46:	85ca                	mv	a1,s2
    80002b48:	6928                	ld	a0,80(a0)
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	cd0080e7          	jalr	-816(ra) # 8000181a <copyin>
    80002b52:	00a03533          	snez	a0,a0
    80002b56:	40a00533          	neg	a0,a0
}
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6902                	ld	s2,0(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret
    return -1;
    80002b66:	557d                	li	a0,-1
    80002b68:	bfcd                	j	80002b5a <fetchaddr+0x3e>
    80002b6a:	557d                	li	a0,-1
    80002b6c:	b7fd                	j	80002b5a <fetchaddr+0x3e>

0000000080002b6e <fetchstr>:
{
    80002b6e:	7179                	addi	sp,sp,-48
    80002b70:	f406                	sd	ra,40(sp)
    80002b72:	f022                	sd	s0,32(sp)
    80002b74:	ec26                	sd	s1,24(sp)
    80002b76:	e84a                	sd	s2,16(sp)
    80002b78:	e44e                	sd	s3,8(sp)
    80002b7a:	1800                	addi	s0,sp,48
    80002b7c:	892a                	mv	s2,a0
    80002b7e:	84ae                	mv	s1,a1
    80002b80:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	f76080e7          	jalr	-138(ra) # 80001af8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b8a:	86ce                	mv	a3,s3
    80002b8c:	864a                	mv	a2,s2
    80002b8e:	85a6                	mv	a1,s1
    80002b90:	6928                	ld	a0,80(a0)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	d14080e7          	jalr	-748(ra) # 800018a6 <copyinstr>
  if(err < 0)
    80002b9a:	00054763          	bltz	a0,80002ba8 <fetchstr+0x3a>
  return strlen(buf);
    80002b9e:	8526                	mv	a0,s1
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	3f2080e7          	jalr	1010(ra) # 80000f92 <strlen>
}
    80002ba8:	70a2                	ld	ra,40(sp)
    80002baa:	7402                	ld	s0,32(sp)
    80002bac:	64e2                	ld	s1,24(sp)
    80002bae:	6942                	ld	s2,16(sp)
    80002bb0:	69a2                	ld	s3,8(sp)
    80002bb2:	6145                	addi	sp,sp,48
    80002bb4:	8082                	ret

0000000080002bb6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	1000                	addi	s0,sp,32
    80002bc0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	ef2080e7          	jalr	-270(ra) # 80002ab4 <argraw>
    80002bca:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bcc:	4501                	li	a0,0
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6105                	addi	sp,sp,32
    80002bd6:	8082                	ret

0000000080002bd8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd8:	1101                	addi	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	1000                	addi	s0,sp,32
    80002be2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	ed0080e7          	jalr	-304(ra) # 80002ab4 <argraw>
    80002bec:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bee:	4501                	li	a0,0
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	64a2                	ld	s1,8(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret

0000000080002bfa <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	e04a                	sd	s2,0(sp)
    80002c04:	1000                	addi	s0,sp,32
    80002c06:	84ae                	mv	s1,a1
    80002c08:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	eaa080e7          	jalr	-342(ra) # 80002ab4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c12:	864a                	mv	a2,s2
    80002c14:	85a6                	mv	a1,s1
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	f58080e7          	jalr	-168(ra) # 80002b6e <fetchstr>
}
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6902                	ld	s2,0(sp)
    80002c26:	6105                	addi	sp,sp,32
    80002c28:	8082                	ret

0000000080002c2a <syscall>:
[SYS_symlink] sys_symlink
};

void
syscall(void)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	e04a                	sd	s2,0(sp)
    80002c34:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	ec2080e7          	jalr	-318(ra) # 80001af8 <myproc>
    80002c3e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c40:	05853903          	ld	s2,88(a0)
    80002c44:	0a893783          	ld	a5,168(s2)
    80002c48:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c4c:	37fd                	addiw	a5,a5,-1
    80002c4e:	4759                	li	a4,22
    80002c50:	00f76f63          	bltu	a4,a5,80002c6e <syscall+0x44>
    80002c54:	00369713          	slli	a4,a3,0x3
    80002c58:	00005797          	auipc	a5,0x5
    80002c5c:	7e078793          	addi	a5,a5,2016 # 80008438 <syscalls>
    80002c60:	97ba                	add	a5,a5,a4
    80002c62:	639c                	ld	a5,0(a5)
    80002c64:	c789                	beqz	a5,80002c6e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c66:	9782                	jalr	a5
    80002c68:	06a93823          	sd	a0,112(s2)
    80002c6c:	a839                	j	80002c8a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c6e:	15848613          	addi	a2,s1,344
    80002c72:	5c8c                	lw	a1,56(s1)
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	78c50513          	addi	a0,a0,1932 # 80008400 <states.1710+0x148>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	8fe080e7          	jalr	-1794(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c84:	6cbc                	ld	a5,88(s1)
    80002c86:	577d                	li	a4,-1
    80002c88:	fbb8                	sd	a4,112(a5)
  }
}
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	64a2                	ld	s1,8(sp)
    80002c90:	6902                	ld	s2,0(sp)
    80002c92:	6105                	addi	sp,sp,32
    80002c94:	8082                	ret

0000000080002c96 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c9e:	fec40593          	addi	a1,s0,-20
    80002ca2:	4501                	li	a0,0
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	f12080e7          	jalr	-238(ra) # 80002bb6 <argint>
    return -1;
    80002cac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cae:	00054963          	bltz	a0,80002cc0 <sys_exit+0x2a>
  exit(n);
    80002cb2:	fec42503          	lw	a0,-20(s0)
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	50c080e7          	jalr	1292(ra) # 800021c2 <exit>
  return 0;  // not reached
    80002cbe:	4781                	li	a5,0
}
    80002cc0:	853e                	mv	a0,a5
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret

0000000080002cca <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cca:	1141                	addi	sp,sp,-16
    80002ccc:	e406                	sd	ra,8(sp)
    80002cce:	e022                	sd	s0,0(sp)
    80002cd0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	e26080e7          	jalr	-474(ra) # 80001af8 <myproc>
}
    80002cda:	5d08                	lw	a0,56(a0)
    80002cdc:	60a2                	ld	ra,8(sp)
    80002cde:	6402                	ld	s0,0(sp)
    80002ce0:	0141                	addi	sp,sp,16
    80002ce2:	8082                	ret

0000000080002ce4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ce4:	1141                	addi	sp,sp,-16
    80002ce6:	e406                	sd	ra,8(sp)
    80002ce8:	e022                	sd	s0,0(sp)
    80002cea:	0800                	addi	s0,sp,16
  return fork();
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	1cc080e7          	jalr	460(ra) # 80001eb8 <fork>
}
    80002cf4:	60a2                	ld	ra,8(sp)
    80002cf6:	6402                	ld	s0,0(sp)
    80002cf8:	0141                	addi	sp,sp,16
    80002cfa:	8082                	ret

0000000080002cfc <sys_wait>:

uint64
sys_wait(void)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d04:	fe840593          	addi	a1,s0,-24
    80002d08:	4501                	li	a0,0
    80002d0a:	00000097          	auipc	ra,0x0
    80002d0e:	ece080e7          	jalr	-306(ra) # 80002bd8 <argaddr>
    80002d12:	87aa                	mv	a5,a0
    return -1;
    80002d14:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d16:	0007c863          	bltz	a5,80002d26 <sys_wait+0x2a>
  return wait(p);
    80002d1a:	fe843503          	ld	a0,-24(s0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	668080e7          	jalr	1640(ra) # 80002386 <wait>
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	6105                	addi	sp,sp,32
    80002d2c:	8082                	ret

0000000080002d2e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d2e:	7179                	addi	sp,sp,-48
    80002d30:	f406                	sd	ra,40(sp)
    80002d32:	f022                	sd	s0,32(sp)
    80002d34:	ec26                	sd	s1,24(sp)
    80002d36:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d38:	fdc40593          	addi	a1,s0,-36
    80002d3c:	4501                	li	a0,0
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	e78080e7          	jalr	-392(ra) # 80002bb6 <argint>
    80002d46:	87aa                	mv	a5,a0
    return -1;
    80002d48:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d4a:	0207c063          	bltz	a5,80002d6a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	daa080e7          	jalr	-598(ra) # 80001af8 <myproc>
    80002d56:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d58:	fdc42503          	lw	a0,-36(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	0e8080e7          	jalr	232(ra) # 80001e44 <growproc>
    80002d64:	00054863          	bltz	a0,80002d74 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d68:	8526                	mv	a0,s1
}
    80002d6a:	70a2                	ld	ra,40(sp)
    80002d6c:	7402                	ld	s0,32(sp)
    80002d6e:	64e2                	ld	s1,24(sp)
    80002d70:	6145                	addi	sp,sp,48
    80002d72:	8082                	ret
    return -1;
    80002d74:	557d                	li	a0,-1
    80002d76:	bfd5                	j	80002d6a <sys_sbrk+0x3c>

0000000080002d78 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d78:	7139                	addi	sp,sp,-64
    80002d7a:	fc06                	sd	ra,56(sp)
    80002d7c:	f822                	sd	s0,48(sp)
    80002d7e:	f426                	sd	s1,40(sp)
    80002d80:	f04a                	sd	s2,32(sp)
    80002d82:	ec4e                	sd	s3,24(sp)
    80002d84:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d86:	fcc40593          	addi	a1,s0,-52
    80002d8a:	4501                	li	a0,0
    80002d8c:	00000097          	auipc	ra,0x0
    80002d90:	e2a080e7          	jalr	-470(ra) # 80002bb6 <argint>
    return -1;
    80002d94:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d96:	06054563          	bltz	a0,80002e00 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d9a:	00010517          	auipc	a0,0x10
    80002d9e:	80e50513          	addi	a0,a0,-2034 # 800125a8 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	f6c080e7          	jalr	-148(ra) # 80000d0e <acquire>
  ticks0 = ticks;
    80002daa:	00006917          	auipc	s2,0x6
    80002dae:	28692903          	lw	s2,646(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002db2:	fcc42783          	lw	a5,-52(s0)
    80002db6:	cf85                	beqz	a5,80002dee <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db8:	0000f997          	auipc	s3,0xf
    80002dbc:	7f098993          	addi	s3,s3,2032 # 800125a8 <tickslock>
    80002dc0:	00006497          	auipc	s1,0x6
    80002dc4:	27048493          	addi	s1,s1,624 # 80009030 <ticks>
    if(myproc()->killed){
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	d30080e7          	jalr	-720(ra) # 80001af8 <myproc>
    80002dd0:	591c                	lw	a5,48(a0)
    80002dd2:	ef9d                	bnez	a5,80002e10 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dd4:	85ce                	mv	a1,s3
    80002dd6:	8526                	mv	a0,s1
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	530080e7          	jalr	1328(ra) # 80002308 <sleep>
  while(ticks - ticks0 < n){
    80002de0:	409c                	lw	a5,0(s1)
    80002de2:	412787bb          	subw	a5,a5,s2
    80002de6:	fcc42703          	lw	a4,-52(s0)
    80002dea:	fce7efe3          	bltu	a5,a4,80002dc8 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dee:	0000f517          	auipc	a0,0xf
    80002df2:	7ba50513          	addi	a0,a0,1978 # 800125a8 <tickslock>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	fcc080e7          	jalr	-52(ra) # 80000dc2 <release>
  return 0;
    80002dfe:	4781                	li	a5,0
}
    80002e00:	853e                	mv	a0,a5
    80002e02:	70e2                	ld	ra,56(sp)
    80002e04:	7442                	ld	s0,48(sp)
    80002e06:	74a2                	ld	s1,40(sp)
    80002e08:	7902                	ld	s2,32(sp)
    80002e0a:	69e2                	ld	s3,24(sp)
    80002e0c:	6121                	addi	sp,sp,64
    80002e0e:	8082                	ret
      release(&tickslock);
    80002e10:	0000f517          	auipc	a0,0xf
    80002e14:	79850513          	addi	a0,a0,1944 # 800125a8 <tickslock>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	faa080e7          	jalr	-86(ra) # 80000dc2 <release>
      return -1;
    80002e20:	57fd                	li	a5,-1
    80002e22:	bff9                	j	80002e00 <sys_sleep+0x88>

0000000080002e24 <sys_kill>:

uint64
sys_kill(void)
{
    80002e24:	1101                	addi	sp,sp,-32
    80002e26:	ec06                	sd	ra,24(sp)
    80002e28:	e822                	sd	s0,16(sp)
    80002e2a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e2c:	fec40593          	addi	a1,s0,-20
    80002e30:	4501                	li	a0,0
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	d84080e7          	jalr	-636(ra) # 80002bb6 <argint>
    80002e3a:	87aa                	mv	a5,a0
    return -1;
    80002e3c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e3e:	0007c863          	bltz	a5,80002e4e <sys_kill+0x2a>
  return kill(pid);
    80002e42:	fec42503          	lw	a0,-20(s0)
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	6b2080e7          	jalr	1714(ra) # 800024f8 <kill>
}
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e56:	1101                	addi	sp,sp,-32
    80002e58:	ec06                	sd	ra,24(sp)
    80002e5a:	e822                	sd	s0,16(sp)
    80002e5c:	e426                	sd	s1,8(sp)
    80002e5e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e60:	0000f517          	auipc	a0,0xf
    80002e64:	74850513          	addi	a0,a0,1864 # 800125a8 <tickslock>
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	ea6080e7          	jalr	-346(ra) # 80000d0e <acquire>
  xticks = ticks;
    80002e70:	00006497          	auipc	s1,0x6
    80002e74:	1c04a483          	lw	s1,448(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e78:	0000f517          	auipc	a0,0xf
    80002e7c:	73050513          	addi	a0,a0,1840 # 800125a8 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	f42080e7          	jalr	-190(ra) # 80000dc2 <release>
  return xticks;
}
    80002e88:	02049513          	slli	a0,s1,0x20
    80002e8c:	9101                	srli	a0,a0,0x20
    80002e8e:	60e2                	ld	ra,24(sp)
    80002e90:	6442                	ld	s0,16(sp)
    80002e92:	64a2                	ld	s1,8(sp)
    80002e94:	6105                	addi	sp,sp,32
    80002e96:	8082                	ret

0000000080002e98 <replacebuf>:

static struct bucket hashTable[NBUC];

void
replacebuf(struct buf *lrubuf,uint dev, uint blockno)
{
    80002e98:	1141                	addi	sp,sp,-16
    80002e9a:	e422                	sd	s0,8(sp)
    80002e9c:	0800                	addi	s0,sp,16
  lrubuf->dev = dev;
    80002e9e:	c50c                	sw	a1,8(a0)
  lrubuf->blockno = blockno;
    80002ea0:	c550                	sw	a2,12(a0)
  lrubuf->valid = 0;
    80002ea2:	00052023          	sw	zero,0(a0)
  lrubuf->refcnt = 1;
    80002ea6:	4785                	li	a5,1
    80002ea8:	c13c                	sw	a5,64(a0)
  lrubuf->tick =ticks;
    80002eaa:	00006797          	auipc	a5,0x6
    80002eae:	1867a783          	lw	a5,390(a5) # 80009030 <ticks>
    80002eb2:	44f52c23          	sw	a5,1112(a0)
}
    80002eb6:	6422                	ld	s0,8(sp)
    80002eb8:	0141                	addi	sp,sp,16
    80002eba:	8082                	ret

0000000080002ebc <binit>:

void
binit(void)
{
    80002ebc:	7179                	addi	sp,sp,-48
    80002ebe:	f406                	sd	ra,40(sp)
    80002ec0:	f022                	sd	s0,32(sp)
    80002ec2:	ec26                	sd	s1,24(sp)
    80002ec4:	e84a                	sd	s2,16(sp)
    80002ec6:	e44e                	sd	s3,8(sp)
    80002ec8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eca:	00005597          	auipc	a1,0x5
    80002ece:	62e58593          	addi	a1,a1,1582 # 800084f8 <syscalls+0xc0>
    80002ed2:	00013517          	auipc	a0,0x13
    80002ed6:	10650513          	addi	a0,a0,262 # 80015fd8 <bcache>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	da4080e7          	jalr	-604(ra) # 80000c7e <initlock>

  for(b = bcache.buf; b < bcache.buf+NBUF; b++)
    80002ee2:	00013497          	auipc	s1,0x13
    80002ee6:	11e48493          	addi	s1,s1,286 # 80016000 <bcache+0x28>
    80002eea:	0001b997          	auipc	s3,0x1b
    80002eee:	45698993          	addi	s3,s3,1110 # 8001e340 <sb+0x10>
  {
    initsleeplock(&b->lock, "buffer");
    80002ef2:	00005917          	auipc	s2,0x5
    80002ef6:	60e90913          	addi	s2,s2,1550 # 80008500 <syscalls+0xc8>
    80002efa:	85ca                	mv	a1,s2
    80002efc:	8526                	mv	a0,s1
    80002efe:	00001097          	auipc	ra,0x1
    80002f02:	71c080e7          	jalr	1820(ra) # 8000461a <initsleeplock>
    b->tick = 0;
    80002f06:	4404a423          	sw	zero,1096(s1)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++)
    80002f0a:	46048493          	addi	s1,s1,1120
    80002f0e:	ff3496e3          	bne	s1,s3,80002efa <binit+0x3e>
    80002f12:	0000f497          	auipc	s1,0xf
    80002f16:	6ae48493          	addi	s1,s1,1710 # 800125c0 <hashTable>
    80002f1a:	00013997          	auipc	s3,0x13
    80002f1e:	0be98993          	addi	s3,s3,190 # 80015fd8 <bcache>
  }
  for(int i=0; i<NBUC; i++)
  {
    initlock(&hashTable[i].lock,"bcache.bucket");
    80002f22:	00005917          	auipc	s2,0x5
    80002f26:	5e690913          	addi	s2,s2,1510 # 80008508 <syscalls+0xd0>
    80002f2a:	85ca                	mv	a1,s2
    80002f2c:	8526                	mv	a0,s1
    80002f2e:	ffffe097          	auipc	ra,0xffffe
    80002f32:	d50080e7          	jalr	-688(ra) # 80000c7e <initlock>
    hashTable[i].head.next = 0;
    80002f36:	0604b023          	sd	zero,96(s1)
    hashTable[i].head.prev = 0;
    80002f3a:	0604b423          	sd	zero,104(s1)
  for(int i=0; i<NBUC; i++)
    80002f3e:	47848493          	addi	s1,s1,1144
    80002f42:	ff3494e3          	bne	s1,s3,80002f2a <binit+0x6e>
  }
}
    80002f46:	70a2                	ld	ra,40(sp)
    80002f48:	7402                	ld	s0,32(sp)
    80002f4a:	64e2                	ld	s1,24(sp)
    80002f4c:	6942                	ld	s2,16(sp)
    80002f4e:	69a2                	ld	s3,8(sp)
    80002f50:	6145                	addi	sp,sp,48
    80002f52:	8082                	ret

0000000080002f54 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f54:	715d                	addi	sp,sp,-80
    80002f56:	e486                	sd	ra,72(sp)
    80002f58:	e0a2                	sd	s0,64(sp)
    80002f5a:	fc26                	sd	s1,56(sp)
    80002f5c:	f84a                	sd	s2,48(sp)
    80002f5e:	f44e                	sd	s3,40(sp)
    80002f60:	f052                	sd	s4,32(sp)
    80002f62:	ec56                	sd	s5,24(sp)
    80002f64:	e85a                	sd	s6,16(sp)
    80002f66:	e45e                	sd	s7,8(sp)
    80002f68:	0880                	addi	s0,sp,80
    80002f6a:	8baa                	mv	s7,a0
    80002f6c:	8b2e                	mv	s6,a1
  uint64 hash = blockno%NBUC;
    80002f6e:	4935                	li	s2,13
    80002f70:	0325f93b          	remuw	s2,a1,s2
    80002f74:	1902                	slli	s2,s2,0x20
    80002f76:	02095913          	srli	s2,s2,0x20
  acquire(&hashTable[hash].lock);
    80002f7a:	47800993          	li	s3,1144
    80002f7e:	033909b3          	mul	s3,s2,s3
    80002f82:	0000fa97          	auipc	s5,0xf
    80002f86:	63ea8a93          	addi	s5,s5,1598 # 800125c0 <hashTable>
    80002f8a:	9ace                	add	s5,s5,s3
    80002f8c:	8556                	mv	a0,s5
    80002f8e:	ffffe097          	auipc	ra,0xffffe
    80002f92:	d80080e7          	jalr	-640(ra) # 80000d0e <acquire>
  for(b = hashTable[hash].head.next; b; b = b->next){
    80002f96:	060ab483          	ld	s1,96(s5)
    80002f9a:	e495                	bnez	s1,80002fc6 <bread+0x72>
  acquire(&bcache.lock);
    80002f9c:	00013517          	auipc	a0,0x13
    80002fa0:	03c50513          	addi	a0,a0,60 # 80015fd8 <bcache>
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	d6a080e7          	jalr	-662(ra) # 80000d0e <acquire>
  uint64 mintick = 0;
    80002fac:	4701                	li	a4,0
  struct buf *lrubuf = 0;
    80002fae:	4481                	li	s1,0
  for(b = bcache.buf; b <bcache.buf+NBUF; b++){
    80002fb0:	00013797          	auipc	a5,0x13
    80002fb4:	04078793          	addi	a5,a5,64 # 80015ff0 <bcache+0x18>
    80002fb8:	0001b617          	auipc	a2,0x1b
    80002fbc:	37860613          	addi	a2,a2,888 # 8001e330 <sb>
    80002fc0:	a83d                	j	80002ffe <bread+0xaa>
  for(b = hashTable[hash].head.next; b; b = b->next){
    80002fc2:	64a4                	ld	s1,72(s1)
    80002fc4:	dce1                	beqz	s1,80002f9c <bread+0x48>
    if(b->dev == dev && b->blockno == blockno){
    80002fc6:	449c                	lw	a5,8(s1)
    80002fc8:	ff779de3          	bne	a5,s7,80002fc2 <bread+0x6e>
    80002fcc:	44dc                	lw	a5,12(s1)
    80002fce:	ff679ae3          	bne	a5,s6,80002fc2 <bread+0x6e>
      b->refcnt++;
    80002fd2:	40bc                	lw	a5,64(s1)
    80002fd4:	2785                	addiw	a5,a5,1
    80002fd6:	c0bc                	sw	a5,64(s1)
      release(&hashTable[hash].lock);
    80002fd8:	8556                	mv	a0,s5
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	de8080e7          	jalr	-536(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    80002fe2:	01048513          	addi	a0,s1,16
    80002fe6:	00001097          	auipc	ra,0x1
    80002fea:	66e080e7          	jalr	1646(ra) # 80004654 <acquiresleep>
      return b;
    80002fee:	a8d5                	j	800030e2 <bread+0x18e>
        mintick = b->tick;
    80002ff0:	4587e703          	lwu	a4,1112(a5)
        continue;
    80002ff4:	84be                	mv	s1,a5
  for(b = bcache.buf; b <bcache.buf+NBUF; b++){
    80002ff6:	46078793          	addi	a5,a5,1120
    80002ffa:	00c78c63          	beq	a5,a2,80003012 <bread+0xbe>
    if(b->refcnt == 0) 
    80002ffe:	43b4                	lw	a3,64(a5)
    80003000:	fafd                	bnez	a3,80002ff6 <bread+0xa2>
      if(lrubuf ==0)
    80003002:	d4fd                	beqz	s1,80002ff0 <bread+0x9c>
      if(b->tick<mintick)
    80003004:	4587e683          	lwu	a3,1112(a5)
    80003008:	fee6f7e3          	bgeu	a3,a4,80002ff6 <bread+0xa2>
        mintick = b->tick;
    8000300c:	8736                	mv	a4,a3
      if(b->tick<mintick)
    8000300e:	84be                	mv	s1,a5
    80003010:	b7dd                	j	80002ff6 <bread+0xa2>
  if(lrubuf)
    80003012:	14048f63          	beqz	s1,80003170 <bread+0x21c>
    uint64 oldblockno = lrubuf->blockno;
    80003016:	00c4ea03          	lwu	s4,12(s1)
    if(oldtick == 0)
    8000301a:	4584a783          	lw	a5,1112(s1)
    8000301e:	c3e5                	beqz	a5,800030fe <bread+0x1aa>
      if(hash != oldblockno%NBUC)
    80003020:	47b5                	li	a5,13
    80003022:	02fa7a33          	remu	s4,s4,a5
    80003026:	11490363          	beq	s2,s4,8000312c <bread+0x1d8>
        if(holding(&hashTable[oldblockno%NBUC].lock))
    8000302a:	47800793          	li	a5,1144
    8000302e:	02fa0a33          	mul	s4,s4,a5
    80003032:	0000f797          	auipc	a5,0xf
    80003036:	58e78793          	addi	a5,a5,1422 # 800125c0 <hashTable>
    8000303a:	9a3e                	add	s4,s4,a5
    8000303c:	8552                	mv	a0,s4
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	c56080e7          	jalr	-938(ra) # 80000c94 <holding>
    80003046:	e979                	bnez	a0,8000311c <bread+0x1c8>
        acquire(&hashTable[oldblockno%NBUC].lock);
    80003048:	8552                	mv	a0,s4
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	cc4080e7          	jalr	-828(ra) # 80000d0e <acquire>
  lrubuf->dev = dev;
    80003052:	0174a423          	sw	s7,8(s1)
  lrubuf->blockno = blockno;
    80003056:	0164a623          	sw	s6,12(s1)
  lrubuf->valid = 0;
    8000305a:	0004a023          	sw	zero,0(s1)
  lrubuf->refcnt = 1;
    8000305e:	4785                	li	a5,1
    80003060:	c0bc                	sw	a5,64(s1)
  lrubuf->tick =ticks;
    80003062:	00006797          	auipc	a5,0x6
    80003066:	fce7a783          	lw	a5,-50(a5) # 80009030 <ticks>
    8000306a:	44f4ac23          	sw	a5,1112(s1)
        lrubuf->prev->next = lrubuf->next;
    8000306e:	68b8                	ld	a4,80(s1)
    80003070:	64bc                	ld	a5,72(s1)
    80003072:	e73c                	sd	a5,72(a4)
        if(lrubuf->next)
    80003074:	c399                	beqz	a5,8000307a <bread+0x126>
          lrubuf->next->prev = lrubuf->prev;
    80003076:	68b8                	ld	a4,80(s1)
    80003078:	ebb8                	sd	a4,80(a5)
        release(&hashTable[oldblockno%NBUC].lock);
    8000307a:	8552                	mv	a0,s4
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	d46080e7          	jalr	-698(ra) # 80000dc2 <release>
    lrubuf->next = hashTable[hash].head.next;
    80003084:	0000f717          	auipc	a4,0xf
    80003088:	53c70713          	addi	a4,a4,1340 # 800125c0 <hashTable>
    8000308c:	47800793          	li	a5,1144
    80003090:	02f907b3          	mul	a5,s2,a5
    80003094:	97ba                	add	a5,a5,a4
    80003096:	73bc                	ld	a5,96(a5)
    80003098:	e4bc                	sd	a5,72(s1)
    lrubuf->prev = &hashTable[hash].head;
    8000309a:	09e1                	addi	s3,s3,24
    8000309c:	99ba                	add	s3,s3,a4
    8000309e:	0534b823          	sd	s3,80(s1)
    if(hashTable[hash].head.next)
    800030a2:	c391                	beqz	a5,800030a6 <bread+0x152>
      hashTable[hash].head.next->prev = lrubuf;
    800030a4:	eba4                	sd	s1,80(a5)
    hashTable[hash].head.next = lrubuf;
    800030a6:	47800793          	li	a5,1144
    800030aa:	02f90933          	mul	s2,s2,a5
    800030ae:	0000f797          	auipc	a5,0xf
    800030b2:	51278793          	addi	a5,a5,1298 # 800125c0 <hashTable>
    800030b6:	993e                	add	s2,s2,a5
    800030b8:	06993023          	sd	s1,96(s2)
    release(&bcache.lock);
    800030bc:	00013517          	auipc	a0,0x13
    800030c0:	f1c50513          	addi	a0,a0,-228 # 80015fd8 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	cfe080e7          	jalr	-770(ra) # 80000dc2 <release>
    release(&hashTable[hash].lock);
    800030cc:	8556                	mv	a0,s5
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	cf4080e7          	jalr	-780(ra) # 80000dc2 <release>
    acquiresleep(&lrubuf->lock);
    800030d6:	01048513          	addi	a0,s1,16
    800030da:	00001097          	auipc	ra,0x1
    800030de:	57a080e7          	jalr	1402(ra) # 80004654 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030e2:	409c                	lw	a5,0(s1)
    800030e4:	cfd1                	beqz	a5,80003180 <bread+0x22c>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030e6:	8526                	mv	a0,s1
    800030e8:	60a6                	ld	ra,72(sp)
    800030ea:	6406                	ld	s0,64(sp)
    800030ec:	74e2                	ld	s1,56(sp)
    800030ee:	7942                	ld	s2,48(sp)
    800030f0:	79a2                	ld	s3,40(sp)
    800030f2:	7a02                	ld	s4,32(sp)
    800030f4:	6ae2                	ld	s5,24(sp)
    800030f6:	6b42                	ld	s6,16(sp)
    800030f8:	6ba2                	ld	s7,8(sp)
    800030fa:	6161                	addi	sp,sp,80
    800030fc:	8082                	ret
  lrubuf->dev = dev;
    800030fe:	0174a423          	sw	s7,8(s1)
  lrubuf->blockno = blockno;
    80003102:	0164a623          	sw	s6,12(s1)
  lrubuf->valid = 0;
    80003106:	0004a023          	sw	zero,0(s1)
  lrubuf->refcnt = 1;
    8000310a:	4785                	li	a5,1
    8000310c:	c0bc                	sw	a5,64(s1)
  lrubuf->tick =ticks;
    8000310e:	00006797          	auipc	a5,0x6
    80003112:	f227a783          	lw	a5,-222(a5) # 80009030 <ticks>
    80003116:	44f4ac23          	sw	a5,1112(s1)
}
    8000311a:	b7ad                	j	80003084 <bread+0x130>
          panic("???");
    8000311c:	00005517          	auipc	a0,0x5
    80003120:	15c50513          	addi	a0,a0,348 # 80008278 <digits+0x238>
    80003124:	ffffd097          	auipc	ra,0xffffd
    80003128:	40c080e7          	jalr	1036(ra) # 80000530 <panic>
  lrubuf->dev = dev;
    8000312c:	0174a423          	sw	s7,8(s1)
  lrubuf->blockno = blockno;
    80003130:	0164a623          	sw	s6,12(s1)
  lrubuf->valid = 0;
    80003134:	0004a023          	sw	zero,0(s1)
  lrubuf->refcnt = 1;
    80003138:	4785                	li	a5,1
    8000313a:	c0bc                	sw	a5,64(s1)
  lrubuf->tick =ticks;
    8000313c:	00006797          	auipc	a5,0x6
    80003140:	ef47a783          	lw	a5,-268(a5) # 80009030 <ticks>
    80003144:	44f4ac23          	sw	a5,1112(s1)
        release(&bcache.lock);
    80003148:	00013517          	auipc	a0,0x13
    8000314c:	e9050513          	addi	a0,a0,-368 # 80015fd8 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	c72080e7          	jalr	-910(ra) # 80000dc2 <release>
        release(&hashTable[hash].lock);
    80003158:	8556                	mv	a0,s5
    8000315a:	ffffe097          	auipc	ra,0xffffe
    8000315e:	c68080e7          	jalr	-920(ra) # 80000dc2 <release>
        acquiresleep(&lrubuf->lock);
    80003162:	01048513          	addi	a0,s1,16
    80003166:	00001097          	auipc	ra,0x1
    8000316a:	4ee080e7          	jalr	1262(ra) # 80004654 <acquiresleep>
        return lrubuf;
    8000316e:	bf95                	j	800030e2 <bread+0x18e>
  panic("bget: no buffers");
    80003170:	00005517          	auipc	a0,0x5
    80003174:	3a850513          	addi	a0,a0,936 # 80008518 <syscalls+0xe0>
    80003178:	ffffd097          	auipc	ra,0xffffd
    8000317c:	3b8080e7          	jalr	952(ra) # 80000530 <panic>
    virtio_disk_rw(b, 0);
    80003180:	4581                	li	a1,0
    80003182:	8526                	mv	a0,s1
    80003184:	00003097          	auipc	ra,0x3
    80003188:	232080e7          	jalr	562(ra) # 800063b6 <virtio_disk_rw>
    b->valid = 1;
    8000318c:	4785                	li	a5,1
    8000318e:	c09c                	sw	a5,0(s1)
  return b;
    80003190:	bf99                	j	800030e6 <bread+0x192>

0000000080003192 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000319e:	0541                	addi	a0,a0,16
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	54e080e7          	jalr	1358(ra) # 800046ee <holdingsleep>
    800031a8:	cd01                	beqz	a0,800031c0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031aa:	4585                	li	a1,1
    800031ac:	8526                	mv	a0,s1
    800031ae:	00003097          	auipc	ra,0x3
    800031b2:	208080e7          	jalr	520(ra) # 800063b6 <virtio_disk_rw>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret
    panic("bwrite");
    800031c0:	00005517          	auipc	a0,0x5
    800031c4:	37050513          	addi	a0,a0,880 # 80008530 <syscalls+0xf8>
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	368080e7          	jalr	872(ra) # 80000530 <panic>

00000000800031d0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031d0:	1101                	addi	sp,sp,-32
    800031d2:	ec06                	sd	ra,24(sp)
    800031d4:	e822                	sd	s0,16(sp)
    800031d6:	e426                	sd	s1,8(sp)
    800031d8:	e04a                	sd	s2,0(sp)
    800031da:	1000                	addi	s0,sp,32
    800031dc:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    800031de:	01050493          	addi	s1,a0,16
    800031e2:	8526                	mv	a0,s1
    800031e4:	00001097          	auipc	ra,0x1
    800031e8:	50a080e7          	jalr	1290(ra) # 800046ee <holdingsleep>
    800031ec:	c939                	beqz	a0,80003242 <brelse+0x72>
    panic("brelse");

  releasesleep(&b->lock);
    800031ee:	8526                	mv	a0,s1
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	4ba080e7          	jalr	1210(ra) # 800046aa <releasesleep>

  uint64 hash = b->blockno%NBUC;
    800031f8:	00c92483          	lw	s1,12(s2)
    800031fc:	47b5                	li	a5,13
    800031fe:	02f4f4bb          	remuw	s1,s1,a5
    80003202:	1482                	slli	s1,s1,0x20
    80003204:	9081                	srli	s1,s1,0x20
  acquire(&hashTable[hash].lock);
    80003206:	47800793          	li	a5,1144
    8000320a:	02f484b3          	mul	s1,s1,a5
    8000320e:	0000f797          	auipc	a5,0xf
    80003212:	3b278793          	addi	a5,a5,946 # 800125c0 <hashTable>
    80003216:	94be                	add	s1,s1,a5
    80003218:	8526                	mv	a0,s1
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	af4080e7          	jalr	-1292(ra) # 80000d0e <acquire>
  b->refcnt--;
    80003222:	04092783          	lw	a5,64(s2)
    80003226:	37fd                	addiw	a5,a5,-1
    80003228:	04f92023          	sw	a5,64(s2)
  release(&hashTable[hash].lock);
    8000322c:	8526                	mv	a0,s1
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	b94080e7          	jalr	-1132(ra) # 80000dc2 <release>
}
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	64a2                	ld	s1,8(sp)
    8000323c:	6902                	ld	s2,0(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret
    panic("brelse");
    80003242:	00005517          	auipc	a0,0x5
    80003246:	2f650513          	addi	a0,a0,758 # 80008538 <syscalls+0x100>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	2e6080e7          	jalr	742(ra) # 80000530 <panic>

0000000080003252 <bpin>:

void
bpin(struct buf *b) {
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	e04a                	sd	s2,0(sp)
    8000325c:	1000                	addi	s0,sp,32
    8000325e:	892a                	mv	s2,a0
  uint64 hash = b->blockno%NBUC;
    80003260:	4544                	lw	s1,12(a0)
    80003262:	47b5                	li	a5,13
    80003264:	02f4f4bb          	remuw	s1,s1,a5
    80003268:	1482                	slli	s1,s1,0x20
    8000326a:	9081                	srli	s1,s1,0x20
  acquire(&hashTable[hash].lock);
    8000326c:	47800793          	li	a5,1144
    80003270:	02f484b3          	mul	s1,s1,a5
    80003274:	0000f797          	auipc	a5,0xf
    80003278:	34c78793          	addi	a5,a5,844 # 800125c0 <hashTable>
    8000327c:	94be                	add	s1,s1,a5
    8000327e:	8526                	mv	a0,s1
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	a8e080e7          	jalr	-1394(ra) # 80000d0e <acquire>
  b->refcnt++;
    80003288:	04092783          	lw	a5,64(s2)
    8000328c:	2785                	addiw	a5,a5,1
    8000328e:	04f92023          	sw	a5,64(s2)
  release(&hashTable[hash].lock);
    80003292:	8526                	mv	a0,s1
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	b2e080e7          	jalr	-1234(ra) # 80000dc2 <release>
}
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6902                	ld	s2,0(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret

00000000800032a8 <bunpin>:

void
bunpin(struct buf *b) {
    800032a8:	1101                	addi	sp,sp,-32
    800032aa:	ec06                	sd	ra,24(sp)
    800032ac:	e822                	sd	s0,16(sp)
    800032ae:	e426                	sd	s1,8(sp)
    800032b0:	e04a                	sd	s2,0(sp)
    800032b2:	1000                	addi	s0,sp,32
    800032b4:	892a                	mv	s2,a0
  uint64 hash = b->blockno%NBUC;
    800032b6:	4544                	lw	s1,12(a0)
    800032b8:	47b5                	li	a5,13
    800032ba:	02f4f4bb          	remuw	s1,s1,a5
    800032be:	1482                	slli	s1,s1,0x20
    800032c0:	9081                	srli	s1,s1,0x20
  acquire(&hashTable[hash].lock);
    800032c2:	47800793          	li	a5,1144
    800032c6:	02f484b3          	mul	s1,s1,a5
    800032ca:	0000f797          	auipc	a5,0xf
    800032ce:	2f678793          	addi	a5,a5,758 # 800125c0 <hashTable>
    800032d2:	94be                	add	s1,s1,a5
    800032d4:	8526                	mv	a0,s1
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	a38080e7          	jalr	-1480(ra) # 80000d0e <acquire>
  b->refcnt--;
    800032de:	04092783          	lw	a5,64(s2)
    800032e2:	37fd                	addiw	a5,a5,-1
    800032e4:	04f92023          	sw	a5,64(s2)
  release(&hashTable[hash].lock);
    800032e8:	8526                	mv	a0,s1
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	ad8080e7          	jalr	-1320(ra) # 80000dc2 <release>
}
    800032f2:	60e2                	ld	ra,24(sp)
    800032f4:	6442                	ld	s0,16(sp)
    800032f6:	64a2                	ld	s1,8(sp)
    800032f8:	6902                	ld	s2,0(sp)
    800032fa:	6105                	addi	sp,sp,32
    800032fc:	8082                	ret

00000000800032fe <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	e04a                	sd	s2,0(sp)
    80003308:	1000                	addi	s0,sp,32
    8000330a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000330c:	00d5d59b          	srliw	a1,a1,0xd
    80003310:	0001b797          	auipc	a5,0x1b
    80003314:	03c7a783          	lw	a5,60(a5) # 8001e34c <sb+0x1c>
    80003318:	9dbd                	addw	a1,a1,a5
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	c3a080e7          	jalr	-966(ra) # 80002f54 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003322:	0074f713          	andi	a4,s1,7
    80003326:	4785                	li	a5,1
    80003328:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000332c:	14ce                	slli	s1,s1,0x33
    8000332e:	90d9                	srli	s1,s1,0x36
    80003330:	00950733          	add	a4,a0,s1
    80003334:	05874703          	lbu	a4,88(a4)
    80003338:	00e7f6b3          	and	a3,a5,a4
    8000333c:	c69d                	beqz	a3,8000336a <bfree+0x6c>
    8000333e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003340:	94aa                	add	s1,s1,a0
    80003342:	fff7c793          	not	a5,a5
    80003346:	8ff9                	and	a5,a5,a4
    80003348:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	1e0080e7          	jalr	480(ra) # 8000452c <log_write>
  brelse(bp);
    80003354:	854a                	mv	a0,s2
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	e7a080e7          	jalr	-390(ra) # 800031d0 <brelse>
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	64a2                	ld	s1,8(sp)
    80003364:	6902                	ld	s2,0(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret
    panic("freeing free block");
    8000336a:	00005517          	auipc	a0,0x5
    8000336e:	1d650513          	addi	a0,a0,470 # 80008540 <syscalls+0x108>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	1be080e7          	jalr	446(ra) # 80000530 <panic>

000000008000337a <balloc>:
{
    8000337a:	711d                	addi	sp,sp,-96
    8000337c:	ec86                	sd	ra,88(sp)
    8000337e:	e8a2                	sd	s0,80(sp)
    80003380:	e4a6                	sd	s1,72(sp)
    80003382:	e0ca                	sd	s2,64(sp)
    80003384:	fc4e                	sd	s3,56(sp)
    80003386:	f852                	sd	s4,48(sp)
    80003388:	f456                	sd	s5,40(sp)
    8000338a:	f05a                	sd	s6,32(sp)
    8000338c:	ec5e                	sd	s7,24(sp)
    8000338e:	e862                	sd	s8,16(sp)
    80003390:	e466                	sd	s9,8(sp)
    80003392:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003394:	0001b797          	auipc	a5,0x1b
    80003398:	fa07a783          	lw	a5,-96(a5) # 8001e334 <sb+0x4>
    8000339c:	cbd1                	beqz	a5,80003430 <balloc+0xb6>
    8000339e:	8baa                	mv	s7,a0
    800033a0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033a2:	0001bb17          	auipc	s6,0x1b
    800033a6:	f8eb0b13          	addi	s6,s6,-114 # 8001e330 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033aa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033ac:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ae:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033b0:	6c89                	lui	s9,0x2
    800033b2:	a831                	j	800033ce <balloc+0x54>
    brelse(bp);
    800033b4:	854a                	mv	a0,s2
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	e1a080e7          	jalr	-486(ra) # 800031d0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033be:	015c87bb          	addw	a5,s9,s5
    800033c2:	00078a9b          	sext.w	s5,a5
    800033c6:	004b2703          	lw	a4,4(s6)
    800033ca:	06eaf363          	bgeu	s5,a4,80003430 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033ce:	41fad79b          	sraiw	a5,s5,0x1f
    800033d2:	0137d79b          	srliw	a5,a5,0x13
    800033d6:	015787bb          	addw	a5,a5,s5
    800033da:	40d7d79b          	sraiw	a5,a5,0xd
    800033de:	01cb2583          	lw	a1,28(s6)
    800033e2:	9dbd                	addw	a1,a1,a5
    800033e4:	855e                	mv	a0,s7
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	b6e080e7          	jalr	-1170(ra) # 80002f54 <bread>
    800033ee:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f0:	004b2503          	lw	a0,4(s6)
    800033f4:	000a849b          	sext.w	s1,s5
    800033f8:	8662                	mv	a2,s8
    800033fa:	faa4fde3          	bgeu	s1,a0,800033b4 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033fe:	41f6579b          	sraiw	a5,a2,0x1f
    80003402:	01d7d69b          	srliw	a3,a5,0x1d
    80003406:	00c6873b          	addw	a4,a3,a2
    8000340a:	00777793          	andi	a5,a4,7
    8000340e:	9f95                	subw	a5,a5,a3
    80003410:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003414:	4037571b          	sraiw	a4,a4,0x3
    80003418:	00e906b3          	add	a3,s2,a4
    8000341c:	0586c683          	lbu	a3,88(a3)
    80003420:	00d7f5b3          	and	a1,a5,a3
    80003424:	cd91                	beqz	a1,80003440 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003426:	2605                	addiw	a2,a2,1
    80003428:	2485                	addiw	s1,s1,1
    8000342a:	fd4618e3          	bne	a2,s4,800033fa <balloc+0x80>
    8000342e:	b759                	j	800033b4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003430:	00005517          	auipc	a0,0x5
    80003434:	12850513          	addi	a0,a0,296 # 80008558 <syscalls+0x120>
    80003438:	ffffd097          	auipc	ra,0xffffd
    8000343c:	0f8080e7          	jalr	248(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003440:	974a                	add	a4,a4,s2
    80003442:	8fd5                	or	a5,a5,a3
    80003444:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003448:	854a                	mv	a0,s2
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	0e2080e7          	jalr	226(ra) # 8000452c <log_write>
        brelse(bp);
    80003452:	854a                	mv	a0,s2
    80003454:	00000097          	auipc	ra,0x0
    80003458:	d7c080e7          	jalr	-644(ra) # 800031d0 <brelse>
  bp = bread(dev, bno);
    8000345c:	85a6                	mv	a1,s1
    8000345e:	855e                	mv	a0,s7
    80003460:	00000097          	auipc	ra,0x0
    80003464:	af4080e7          	jalr	-1292(ra) # 80002f54 <bread>
    80003468:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000346a:	40000613          	li	a2,1024
    8000346e:	4581                	li	a1,0
    80003470:	05850513          	addi	a0,a0,88
    80003474:	ffffe097          	auipc	ra,0xffffe
    80003478:	996080e7          	jalr	-1642(ra) # 80000e0a <memset>
  log_write(bp);
    8000347c:	854a                	mv	a0,s2
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	0ae080e7          	jalr	174(ra) # 8000452c <log_write>
  brelse(bp);
    80003486:	854a                	mv	a0,s2
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	d48080e7          	jalr	-696(ra) # 800031d0 <brelse>
}
    80003490:	8526                	mv	a0,s1
    80003492:	60e6                	ld	ra,88(sp)
    80003494:	6446                	ld	s0,80(sp)
    80003496:	64a6                	ld	s1,72(sp)
    80003498:	6906                	ld	s2,64(sp)
    8000349a:	79e2                	ld	s3,56(sp)
    8000349c:	7a42                	ld	s4,48(sp)
    8000349e:	7aa2                	ld	s5,40(sp)
    800034a0:	7b02                	ld	s6,32(sp)
    800034a2:	6be2                	ld	s7,24(sp)
    800034a4:	6c42                	ld	s8,16(sp)
    800034a6:	6ca2                	ld	s9,8(sp)
    800034a8:	6125                	addi	sp,sp,96
    800034aa:	8082                	ret

00000000800034ac <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034ac:	7139                	addi	sp,sp,-64
    800034ae:	fc06                	sd	ra,56(sp)
    800034b0:	f822                	sd	s0,48(sp)
    800034b2:	f426                	sd	s1,40(sp)
    800034b4:	f04a                	sd	s2,32(sp)
    800034b6:	ec4e                	sd	s3,24(sp)
    800034b8:	e852                	sd	s4,16(sp)
    800034ba:	e456                	sd	s5,8(sp)
    800034bc:	0080                	addi	s0,sp,64
    800034be:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034c0:	47a9                	li	a5,10
    800034c2:	08b7fd63          	bgeu	a5,a1,8000355c <bmap+0xb0>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034c6:	ff55849b          	addiw	s1,a1,-11
    800034ca:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034ce:	0ff00793          	li	a5,255
    800034d2:	0ae7f863          	bgeu	a5,a4,80003582 <bmap+0xd6>
      log_write(bp);
    }
    brelse(bp);
    return addr;
  }
  bn -=NINDIRECT;
    800034d6:	ef55849b          	addiw	s1,a1,-267
    800034da:	0004871b          	sext.w	a4,s1

  if(bn<NDINDIRECT)
    800034de:	67c1                	lui	a5,0x10
    800034e0:	14f77e63          	bgeu	a4,a5,8000363c <bmap+0x190>
  {
    //二级链表
    //先看有没有二级块地址
    if((addr=ip->addrs[NDIRECT+1]) == 0)
    800034e4:	08052583          	lw	a1,128(a0)
    800034e8:	10058063          	beqz	a1,800035e8 <bmap+0x13c>
      ip->addrs[NDIRECT+1]=addr = balloc(ip->dev);
    bp = bread(ip->dev,addr);
    800034ec:	0009a503          	lw	a0,0(s3)
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	a64080e7          	jalr	-1436(ra) # 80002f54 <bread>
    800034f8:	892a                	mv	s2,a0
    a = (uint*)bp->data;
    800034fa:	05850a13          	addi	s4,a0,88
    if((addr = a[bn/NINDIRECT]) == 0)//对应块号没有地址
    800034fe:	0084d79b          	srliw	a5,s1,0x8
    80003502:	078a                	slli	a5,a5,0x2
    80003504:	9a3e                	add	s4,s4,a5
    80003506:	000a2a83          	lw	s5,0(s4) # 2000 <_entry-0x7fffe000>
    8000350a:	0e0a8963          	beqz	s5,800035fc <bmap+0x150>
    {
      a[bn/NINDIRECT] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000350e:	854a                	mv	a0,s2
    80003510:	00000097          	auipc	ra,0x0
    80003514:	cc0080e7          	jalr	-832(ra) # 800031d0 <brelse>
    struct buf *bp1 =bread(ip->dev,addr);
    80003518:	85d6                	mv	a1,s5
    8000351a:	0009a503          	lw	a0,0(s3)
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	a36080e7          	jalr	-1482(ra) # 80002f54 <bread>
    80003526:	8a2a                	mv	s4,a0
    a = (uint*)bp1->data;
    80003528:	05850793          	addi	a5,a0,88
    if((addr = a[bn%NINDIRECT]) == 0)
    8000352c:	0ff4f593          	andi	a1,s1,255
    80003530:	058a                	slli	a1,a1,0x2
    80003532:	00b784b3          	add	s1,a5,a1
    80003536:	0004a903          	lw	s2,0(s1)
    8000353a:	0e090163          	beqz	s2,8000361c <bmap+0x170>
    {
       a[bn%NINDIRECT] = addr =balloc(ip->dev);
       log_write(bp1);
    }
    brelse(bp1);
    8000353e:	8552                	mv	a0,s4
    80003540:	00000097          	auipc	ra,0x0
    80003544:	c90080e7          	jalr	-880(ra) # 800031d0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003548:	854a                	mv	a0,s2
    8000354a:	70e2                	ld	ra,56(sp)
    8000354c:	7442                	ld	s0,48(sp)
    8000354e:	74a2                	ld	s1,40(sp)
    80003550:	7902                	ld	s2,32(sp)
    80003552:	69e2                	ld	s3,24(sp)
    80003554:	6a42                	ld	s4,16(sp)
    80003556:	6aa2                	ld	s5,8(sp)
    80003558:	6121                	addi	sp,sp,64
    8000355a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000355c:	02059493          	slli	s1,a1,0x20
    80003560:	9081                	srli	s1,s1,0x20
    80003562:	048a                	slli	s1,s1,0x2
    80003564:	94aa                	add	s1,s1,a0
    80003566:	0504a903          	lw	s2,80(s1)
    8000356a:	fc091fe3          	bnez	s2,80003548 <bmap+0x9c>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000356e:	4108                	lw	a0,0(a0)
    80003570:	00000097          	auipc	ra,0x0
    80003574:	e0a080e7          	jalr	-502(ra) # 8000337a <balloc>
    80003578:	0005091b          	sext.w	s2,a0
    8000357c:	0524a823          	sw	s2,80(s1)
    80003580:	b7e1                	j	80003548 <bmap+0x9c>
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003582:	5d6c                	lw	a1,124(a0)
    80003584:	c985                	beqz	a1,800035b4 <bmap+0x108>
    bp = bread(ip->dev, addr);
    80003586:	0009a503          	lw	a0,0(s3)
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	9ca080e7          	jalr	-1590(ra) # 80002f54 <bread>
    80003592:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003594:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003598:	1482                	slli	s1,s1,0x20
    8000359a:	9081                	srli	s1,s1,0x20
    8000359c:	048a                	slli	s1,s1,0x2
    8000359e:	94be                	add	s1,s1,a5
    800035a0:	0004a903          	lw	s2,0(s1)
    800035a4:	02090263          	beqz	s2,800035c8 <bmap+0x11c>
    brelse(bp);
    800035a8:	8552                	mv	a0,s4
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	c26080e7          	jalr	-986(ra) # 800031d0 <brelse>
    return addr;
    800035b2:	bf59                	j	80003548 <bmap+0x9c>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035b4:	4108                	lw	a0,0(a0)
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	dc4080e7          	jalr	-572(ra) # 8000337a <balloc>
    800035be:	0005059b          	sext.w	a1,a0
    800035c2:	06b9ae23          	sw	a1,124(s3)
    800035c6:	b7c1                	j	80003586 <bmap+0xda>
      a[bn] = addr = balloc(ip->dev);
    800035c8:	0009a503          	lw	a0,0(s3)
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	dae080e7          	jalr	-594(ra) # 8000337a <balloc>
    800035d4:	0005091b          	sext.w	s2,a0
    800035d8:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    800035dc:	8552                	mv	a0,s4
    800035de:	00001097          	auipc	ra,0x1
    800035e2:	f4e080e7          	jalr	-178(ra) # 8000452c <log_write>
    800035e6:	b7c9                	j	800035a8 <bmap+0xfc>
      ip->addrs[NDIRECT+1]=addr = balloc(ip->dev);
    800035e8:	4108                	lw	a0,0(a0)
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	d90080e7          	jalr	-624(ra) # 8000337a <balloc>
    800035f2:	0005059b          	sext.w	a1,a0
    800035f6:	08b9a023          	sw	a1,128(s3)
    800035fa:	bdcd                	j	800034ec <bmap+0x40>
      a[bn/NINDIRECT] = addr = balloc(ip->dev);
    800035fc:	0009a503          	lw	a0,0(s3)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	d7a080e7          	jalr	-646(ra) # 8000337a <balloc>
    80003608:	00050a9b          	sext.w	s5,a0
    8000360c:	015a2023          	sw	s5,0(s4)
      log_write(bp);
    80003610:	854a                	mv	a0,s2
    80003612:	00001097          	auipc	ra,0x1
    80003616:	f1a080e7          	jalr	-230(ra) # 8000452c <log_write>
    8000361a:	bdd5                	j	8000350e <bmap+0x62>
       a[bn%NINDIRECT] = addr =balloc(ip->dev);
    8000361c:	0009a503          	lw	a0,0(s3)
    80003620:	00000097          	auipc	ra,0x0
    80003624:	d5a080e7          	jalr	-678(ra) # 8000337a <balloc>
    80003628:	0005091b          	sext.w	s2,a0
    8000362c:	0124a023          	sw	s2,0(s1)
       log_write(bp1);
    80003630:	8552                	mv	a0,s4
    80003632:	00001097          	auipc	ra,0x1
    80003636:	efa080e7          	jalr	-262(ra) # 8000452c <log_write>
    8000363a:	b711                	j	8000353e <bmap+0x92>
  panic("bmap: out of range");
    8000363c:	00005517          	auipc	a0,0x5
    80003640:	f3450513          	addi	a0,a0,-204 # 80008570 <syscalls+0x138>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	eec080e7          	jalr	-276(ra) # 80000530 <panic>

000000008000364c <iget>:
{
    8000364c:	7179                	addi	sp,sp,-48
    8000364e:	f406                	sd	ra,40(sp)
    80003650:	f022                	sd	s0,32(sp)
    80003652:	ec26                	sd	s1,24(sp)
    80003654:	e84a                	sd	s2,16(sp)
    80003656:	e44e                	sd	s3,8(sp)
    80003658:	e052                	sd	s4,0(sp)
    8000365a:	1800                	addi	s0,sp,48
    8000365c:	89aa                	mv	s3,a0
    8000365e:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003660:	0001b517          	auipc	a0,0x1b
    80003664:	cf050513          	addi	a0,a0,-784 # 8001e350 <icache>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	6a6080e7          	jalr	1702(ra) # 80000d0e <acquire>
  empty = 0;
    80003670:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003672:	0001b497          	auipc	s1,0x1b
    80003676:	cf648493          	addi	s1,s1,-778 # 8001e368 <icache+0x18>
    8000367a:	0001c697          	auipc	a3,0x1c
    8000367e:	77e68693          	addi	a3,a3,1918 # 8001fdf8 <log>
    80003682:	a039                	j	80003690 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003684:	02090b63          	beqz	s2,800036ba <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003688:	08848493          	addi	s1,s1,136
    8000368c:	02d48a63          	beq	s1,a3,800036c0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003690:	449c                	lw	a5,8(s1)
    80003692:	fef059e3          	blez	a5,80003684 <iget+0x38>
    80003696:	4098                	lw	a4,0(s1)
    80003698:	ff3716e3          	bne	a4,s3,80003684 <iget+0x38>
    8000369c:	40d8                	lw	a4,4(s1)
    8000369e:	ff4713e3          	bne	a4,s4,80003684 <iget+0x38>
      ip->ref++;
    800036a2:	2785                	addiw	a5,a5,1
    800036a4:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036a6:	0001b517          	auipc	a0,0x1b
    800036aa:	caa50513          	addi	a0,a0,-854 # 8001e350 <icache>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	714080e7          	jalr	1812(ra) # 80000dc2 <release>
      return ip;
    800036b6:	8926                	mv	s2,s1
    800036b8:	a03d                	j	800036e6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036ba:	f7f9                	bnez	a5,80003688 <iget+0x3c>
    800036bc:	8926                	mv	s2,s1
    800036be:	b7e9                	j	80003688 <iget+0x3c>
  if(empty == 0)
    800036c0:	02090c63          	beqz	s2,800036f8 <iget+0xac>
  ip->dev = dev;
    800036c4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036c8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036cc:	4785                	li	a5,1
    800036ce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036d2:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036d6:	0001b517          	auipc	a0,0x1b
    800036da:	c7a50513          	addi	a0,a0,-902 # 8001e350 <icache>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	6e4080e7          	jalr	1764(ra) # 80000dc2 <release>
}
    800036e6:	854a                	mv	a0,s2
    800036e8:	70a2                	ld	ra,40(sp)
    800036ea:	7402                	ld	s0,32(sp)
    800036ec:	64e2                	ld	s1,24(sp)
    800036ee:	6942                	ld	s2,16(sp)
    800036f0:	69a2                	ld	s3,8(sp)
    800036f2:	6a02                	ld	s4,0(sp)
    800036f4:	6145                	addi	sp,sp,48
    800036f6:	8082                	ret
    panic("iget: no inodes");
    800036f8:	00005517          	auipc	a0,0x5
    800036fc:	e9050513          	addi	a0,a0,-368 # 80008588 <syscalls+0x150>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	e30080e7          	jalr	-464(ra) # 80000530 <panic>

0000000080003708 <fsinit>:
fsinit(int dev) {
    80003708:	7179                	addi	sp,sp,-48
    8000370a:	f406                	sd	ra,40(sp)
    8000370c:	f022                	sd	s0,32(sp)
    8000370e:	ec26                	sd	s1,24(sp)
    80003710:	e84a                	sd	s2,16(sp)
    80003712:	e44e                	sd	s3,8(sp)
    80003714:	1800                	addi	s0,sp,48
    80003716:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003718:	4585                	li	a1,1
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	83a080e7          	jalr	-1990(ra) # 80002f54 <bread>
    80003722:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003724:	0001b997          	auipc	s3,0x1b
    80003728:	c0c98993          	addi	s3,s3,-1012 # 8001e330 <sb>
    8000372c:	02000613          	li	a2,32
    80003730:	05850593          	addi	a1,a0,88
    80003734:	854e                	mv	a0,s3
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	734080e7          	jalr	1844(ra) # 80000e6a <memmove>
  brelse(bp);
    8000373e:	8526                	mv	a0,s1
    80003740:	00000097          	auipc	ra,0x0
    80003744:	a90080e7          	jalr	-1392(ra) # 800031d0 <brelse>
  if(sb.magic != FSMAGIC)
    80003748:	0009a703          	lw	a4,0(s3)
    8000374c:	102037b7          	lui	a5,0x10203
    80003750:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003754:	02f71263          	bne	a4,a5,80003778 <fsinit+0x70>
  initlog(dev, &sb);
    80003758:	0001b597          	auipc	a1,0x1b
    8000375c:	bd858593          	addi	a1,a1,-1064 # 8001e330 <sb>
    80003760:	854a                	mv	a0,s2
    80003762:	00001097          	auipc	ra,0x1
    80003766:	b4e080e7          	jalr	-1202(ra) # 800042b0 <initlog>
}
    8000376a:	70a2                	ld	ra,40(sp)
    8000376c:	7402                	ld	s0,32(sp)
    8000376e:	64e2                	ld	s1,24(sp)
    80003770:	6942                	ld	s2,16(sp)
    80003772:	69a2                	ld	s3,8(sp)
    80003774:	6145                	addi	sp,sp,48
    80003776:	8082                	ret
    panic("invalid file system");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	e2050513          	addi	a0,a0,-480 # 80008598 <syscalls+0x160>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	db0080e7          	jalr	-592(ra) # 80000530 <panic>

0000000080003788 <iinit>:
{
    80003788:	7179                	addi	sp,sp,-48
    8000378a:	f406                	sd	ra,40(sp)
    8000378c:	f022                	sd	s0,32(sp)
    8000378e:	ec26                	sd	s1,24(sp)
    80003790:	e84a                	sd	s2,16(sp)
    80003792:	e44e                	sd	s3,8(sp)
    80003794:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003796:	00005597          	auipc	a1,0x5
    8000379a:	e1a58593          	addi	a1,a1,-486 # 800085b0 <syscalls+0x178>
    8000379e:	0001b517          	auipc	a0,0x1b
    800037a2:	bb250513          	addi	a0,a0,-1102 # 8001e350 <icache>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	4d8080e7          	jalr	1240(ra) # 80000c7e <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ae:	0001b497          	auipc	s1,0x1b
    800037b2:	bca48493          	addi	s1,s1,-1078 # 8001e378 <icache+0x28>
    800037b6:	0001c997          	auipc	s3,0x1c
    800037ba:	65298993          	addi	s3,s3,1618 # 8001fe08 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037be:	00005917          	auipc	s2,0x5
    800037c2:	dfa90913          	addi	s2,s2,-518 # 800085b8 <syscalls+0x180>
    800037c6:	85ca                	mv	a1,s2
    800037c8:	8526                	mv	a0,s1
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	e50080e7          	jalr	-432(ra) # 8000461a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037d2:	08848493          	addi	s1,s1,136
    800037d6:	ff3498e3          	bne	s1,s3,800037c6 <iinit+0x3e>
}
    800037da:	70a2                	ld	ra,40(sp)
    800037dc:	7402                	ld	s0,32(sp)
    800037de:	64e2                	ld	s1,24(sp)
    800037e0:	6942                	ld	s2,16(sp)
    800037e2:	69a2                	ld	s3,8(sp)
    800037e4:	6145                	addi	sp,sp,48
    800037e6:	8082                	ret

00000000800037e8 <ialloc>:
{
    800037e8:	715d                	addi	sp,sp,-80
    800037ea:	e486                	sd	ra,72(sp)
    800037ec:	e0a2                	sd	s0,64(sp)
    800037ee:	fc26                	sd	s1,56(sp)
    800037f0:	f84a                	sd	s2,48(sp)
    800037f2:	f44e                	sd	s3,40(sp)
    800037f4:	f052                	sd	s4,32(sp)
    800037f6:	ec56                	sd	s5,24(sp)
    800037f8:	e85a                	sd	s6,16(sp)
    800037fa:	e45e                	sd	s7,8(sp)
    800037fc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037fe:	0001b717          	auipc	a4,0x1b
    80003802:	b3e72703          	lw	a4,-1218(a4) # 8001e33c <sb+0xc>
    80003806:	4785                	li	a5,1
    80003808:	04e7fa63          	bgeu	a5,a4,8000385c <ialloc+0x74>
    8000380c:	8aaa                	mv	s5,a0
    8000380e:	8bae                	mv	s7,a1
    80003810:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003812:	0001ba17          	auipc	s4,0x1b
    80003816:	b1ea0a13          	addi	s4,s4,-1250 # 8001e330 <sb>
    8000381a:	00048b1b          	sext.w	s6,s1
    8000381e:	0044d593          	srli	a1,s1,0x4
    80003822:	018a2783          	lw	a5,24(s4)
    80003826:	9dbd                	addw	a1,a1,a5
    80003828:	8556                	mv	a0,s5
    8000382a:	fffff097          	auipc	ra,0xfffff
    8000382e:	72a080e7          	jalr	1834(ra) # 80002f54 <bread>
    80003832:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003834:	05850993          	addi	s3,a0,88
    80003838:	00f4f793          	andi	a5,s1,15
    8000383c:	079a                	slli	a5,a5,0x6
    8000383e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003840:	00099783          	lh	a5,0(s3)
    80003844:	c785                	beqz	a5,8000386c <ialloc+0x84>
    brelse(bp);
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	98a080e7          	jalr	-1654(ra) # 800031d0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000384e:	0485                	addi	s1,s1,1
    80003850:	00ca2703          	lw	a4,12(s4)
    80003854:	0004879b          	sext.w	a5,s1
    80003858:	fce7e1e3          	bltu	a5,a4,8000381a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000385c:	00005517          	auipc	a0,0x5
    80003860:	d6450513          	addi	a0,a0,-668 # 800085c0 <syscalls+0x188>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	ccc080e7          	jalr	-820(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    8000386c:	04000613          	li	a2,64
    80003870:	4581                	li	a1,0
    80003872:	854e                	mv	a0,s3
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	596080e7          	jalr	1430(ra) # 80000e0a <memset>
      dip->type = type;
    8000387c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003880:	854a                	mv	a0,s2
    80003882:	00001097          	auipc	ra,0x1
    80003886:	caa080e7          	jalr	-854(ra) # 8000452c <log_write>
      brelse(bp);
    8000388a:	854a                	mv	a0,s2
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	944080e7          	jalr	-1724(ra) # 800031d0 <brelse>
      return iget(dev, inum);
    80003894:	85da                	mv	a1,s6
    80003896:	8556                	mv	a0,s5
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	db4080e7          	jalr	-588(ra) # 8000364c <iget>
}
    800038a0:	60a6                	ld	ra,72(sp)
    800038a2:	6406                	ld	s0,64(sp)
    800038a4:	74e2                	ld	s1,56(sp)
    800038a6:	7942                	ld	s2,48(sp)
    800038a8:	79a2                	ld	s3,40(sp)
    800038aa:	7a02                	ld	s4,32(sp)
    800038ac:	6ae2                	ld	s5,24(sp)
    800038ae:	6b42                	ld	s6,16(sp)
    800038b0:	6ba2                	ld	s7,8(sp)
    800038b2:	6161                	addi	sp,sp,80
    800038b4:	8082                	ret

00000000800038b6 <iupdate>:
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	e04a                	sd	s2,0(sp)
    800038c0:	1000                	addi	s0,sp,32
    800038c2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c4:	415c                	lw	a5,4(a0)
    800038c6:	0047d79b          	srliw	a5,a5,0x4
    800038ca:	0001b597          	auipc	a1,0x1b
    800038ce:	a7e5a583          	lw	a1,-1410(a1) # 8001e348 <sb+0x18>
    800038d2:	9dbd                	addw	a1,a1,a5
    800038d4:	4108                	lw	a0,0(a0)
    800038d6:	fffff097          	auipc	ra,0xfffff
    800038da:	67e080e7          	jalr	1662(ra) # 80002f54 <bread>
    800038de:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e0:	05850793          	addi	a5,a0,88
    800038e4:	40c8                	lw	a0,4(s1)
    800038e6:	893d                	andi	a0,a0,15
    800038e8:	051a                	slli	a0,a0,0x6
    800038ea:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038ec:	04449703          	lh	a4,68(s1)
    800038f0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038f4:	04649703          	lh	a4,70(s1)
    800038f8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038fc:	04849703          	lh	a4,72(s1)
    80003900:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003904:	04a49703          	lh	a4,74(s1)
    80003908:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000390c:	44f8                	lw	a4,76(s1)
    8000390e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003910:	03400613          	li	a2,52
    80003914:	05048593          	addi	a1,s1,80
    80003918:	0531                	addi	a0,a0,12
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	550080e7          	jalr	1360(ra) # 80000e6a <memmove>
  log_write(bp);
    80003922:	854a                	mv	a0,s2
    80003924:	00001097          	auipc	ra,0x1
    80003928:	c08080e7          	jalr	-1016(ra) # 8000452c <log_write>
  brelse(bp);
    8000392c:	854a                	mv	a0,s2
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	8a2080e7          	jalr	-1886(ra) # 800031d0 <brelse>
}
    80003936:	60e2                	ld	ra,24(sp)
    80003938:	6442                	ld	s0,16(sp)
    8000393a:	64a2                	ld	s1,8(sp)
    8000393c:	6902                	ld	s2,0(sp)
    8000393e:	6105                	addi	sp,sp,32
    80003940:	8082                	ret

0000000080003942 <idup>:
{
    80003942:	1101                	addi	sp,sp,-32
    80003944:	ec06                	sd	ra,24(sp)
    80003946:	e822                	sd	s0,16(sp)
    80003948:	e426                	sd	s1,8(sp)
    8000394a:	1000                	addi	s0,sp,32
    8000394c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000394e:	0001b517          	auipc	a0,0x1b
    80003952:	a0250513          	addi	a0,a0,-1534 # 8001e350 <icache>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	3b8080e7          	jalr	952(ra) # 80000d0e <acquire>
  ip->ref++;
    8000395e:	449c                	lw	a5,8(s1)
    80003960:	2785                	addiw	a5,a5,1
    80003962:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003964:	0001b517          	auipc	a0,0x1b
    80003968:	9ec50513          	addi	a0,a0,-1556 # 8001e350 <icache>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	456080e7          	jalr	1110(ra) # 80000dc2 <release>
}
    80003974:	8526                	mv	a0,s1
    80003976:	60e2                	ld	ra,24(sp)
    80003978:	6442                	ld	s0,16(sp)
    8000397a:	64a2                	ld	s1,8(sp)
    8000397c:	6105                	addi	sp,sp,32
    8000397e:	8082                	ret

0000000080003980 <ilock>:
{
    80003980:	1101                	addi	sp,sp,-32
    80003982:	ec06                	sd	ra,24(sp)
    80003984:	e822                	sd	s0,16(sp)
    80003986:	e426                	sd	s1,8(sp)
    80003988:	e04a                	sd	s2,0(sp)
    8000398a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000398c:	c115                	beqz	a0,800039b0 <ilock+0x30>
    8000398e:	84aa                	mv	s1,a0
    80003990:	451c                	lw	a5,8(a0)
    80003992:	00f05f63          	blez	a5,800039b0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003996:	0541                	addi	a0,a0,16
    80003998:	00001097          	auipc	ra,0x1
    8000399c:	cbc080e7          	jalr	-836(ra) # 80004654 <acquiresleep>
  if(ip->valid == 0){
    800039a0:	40bc                	lw	a5,64(s1)
    800039a2:	cf99                	beqz	a5,800039c0 <ilock+0x40>
}
    800039a4:	60e2                	ld	ra,24(sp)
    800039a6:	6442                	ld	s0,16(sp)
    800039a8:	64a2                	ld	s1,8(sp)
    800039aa:	6902                	ld	s2,0(sp)
    800039ac:	6105                	addi	sp,sp,32
    800039ae:	8082                	ret
    panic("ilock");
    800039b0:	00005517          	auipc	a0,0x5
    800039b4:	c2850513          	addi	a0,a0,-984 # 800085d8 <syscalls+0x1a0>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	b78080e7          	jalr	-1160(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c0:	40dc                	lw	a5,4(s1)
    800039c2:	0047d79b          	srliw	a5,a5,0x4
    800039c6:	0001b597          	auipc	a1,0x1b
    800039ca:	9825a583          	lw	a1,-1662(a1) # 8001e348 <sb+0x18>
    800039ce:	9dbd                	addw	a1,a1,a5
    800039d0:	4088                	lw	a0,0(s1)
    800039d2:	fffff097          	auipc	ra,0xfffff
    800039d6:	582080e7          	jalr	1410(ra) # 80002f54 <bread>
    800039da:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039dc:	05850593          	addi	a1,a0,88
    800039e0:	40dc                	lw	a5,4(s1)
    800039e2:	8bbd                	andi	a5,a5,15
    800039e4:	079a                	slli	a5,a5,0x6
    800039e6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039e8:	00059783          	lh	a5,0(a1)
    800039ec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039f0:	00259783          	lh	a5,2(a1)
    800039f4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039f8:	00459783          	lh	a5,4(a1)
    800039fc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a00:	00659783          	lh	a5,6(a1)
    80003a04:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a08:	459c                	lw	a5,8(a1)
    80003a0a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a0c:	03400613          	li	a2,52
    80003a10:	05b1                	addi	a1,a1,12
    80003a12:	05048513          	addi	a0,s1,80
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	454080e7          	jalr	1108(ra) # 80000e6a <memmove>
    brelse(bp);
    80003a1e:	854a                	mv	a0,s2
    80003a20:	fffff097          	auipc	ra,0xfffff
    80003a24:	7b0080e7          	jalr	1968(ra) # 800031d0 <brelse>
    ip->valid = 1;
    80003a28:	4785                	li	a5,1
    80003a2a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a2c:	04449783          	lh	a5,68(s1)
    80003a30:	fbb5                	bnez	a5,800039a4 <ilock+0x24>
      panic("ilock: no type");
    80003a32:	00005517          	auipc	a0,0x5
    80003a36:	bae50513          	addi	a0,a0,-1106 # 800085e0 <syscalls+0x1a8>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	af6080e7          	jalr	-1290(ra) # 80000530 <panic>

0000000080003a42 <iunlock>:
{
    80003a42:	1101                	addi	sp,sp,-32
    80003a44:	ec06                	sd	ra,24(sp)
    80003a46:	e822                	sd	s0,16(sp)
    80003a48:	e426                	sd	s1,8(sp)
    80003a4a:	e04a                	sd	s2,0(sp)
    80003a4c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a4e:	c905                	beqz	a0,80003a7e <iunlock+0x3c>
    80003a50:	84aa                	mv	s1,a0
    80003a52:	01050913          	addi	s2,a0,16
    80003a56:	854a                	mv	a0,s2
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	c96080e7          	jalr	-874(ra) # 800046ee <holdingsleep>
    80003a60:	cd19                	beqz	a0,80003a7e <iunlock+0x3c>
    80003a62:	449c                	lw	a5,8(s1)
    80003a64:	00f05d63          	blez	a5,80003a7e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a68:	854a                	mv	a0,s2
    80003a6a:	00001097          	auipc	ra,0x1
    80003a6e:	c40080e7          	jalr	-960(ra) # 800046aa <releasesleep>
}
    80003a72:	60e2                	ld	ra,24(sp)
    80003a74:	6442                	ld	s0,16(sp)
    80003a76:	64a2                	ld	s1,8(sp)
    80003a78:	6902                	ld	s2,0(sp)
    80003a7a:	6105                	addi	sp,sp,32
    80003a7c:	8082                	ret
    panic("iunlock");
    80003a7e:	00005517          	auipc	a0,0x5
    80003a82:	b7250513          	addi	a0,a0,-1166 # 800085f0 <syscalls+0x1b8>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	aaa080e7          	jalr	-1366(ra) # 80000530 <panic>

0000000080003a8e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a8e:	7179                	addi	sp,sp,-48
    80003a90:	f406                	sd	ra,40(sp)
    80003a92:	f022                	sd	s0,32(sp)
    80003a94:	ec26                	sd	s1,24(sp)
    80003a96:	e84a                	sd	s2,16(sp)
    80003a98:	e44e                	sd	s3,8(sp)
    80003a9a:	e052                	sd	s4,0(sp)
    80003a9c:	1800                	addi	s0,sp,48
    80003a9e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;
  //*bp1, *a1
  for(i = 0; i < NDIRECT; i++){
    80003aa0:	05050493          	addi	s1,a0,80
    80003aa4:	07c50913          	addi	s2,a0,124
    80003aa8:	a821                	j	80003ac0 <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    80003aaa:	0009a503          	lw	a0,0(s3)
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	850080e7          	jalr	-1968(ra) # 800032fe <bfree>
      ip->addrs[i] = 0;
    80003ab6:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    80003aba:	0491                	addi	s1,s1,4
    80003abc:	01248563          	beq	s1,s2,80003ac6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ac0:	408c                	lw	a1,0(s1)
    80003ac2:	dde5                	beqz	a1,80003aba <itrunc+0x2c>
    80003ac4:	b7dd                	j	80003aaa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ac6:	07c9a583          	lw	a1,124(s3)
    80003aca:	e185                	bnez	a1,80003aea <itrunc+0x5c>
  //   brelse(bp);
  //   bfree(ip->dev,ip->addrs[NDIRECT+1]);
  //   ip->addrs[NDIRECT+1]=0;
  // }

  ip->size = 0;
    80003acc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ad0:	854e                	mv	a0,s3
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	de4080e7          	jalr	-540(ra) # 800038b6 <iupdate>
}
    80003ada:	70a2                	ld	ra,40(sp)
    80003adc:	7402                	ld	s0,32(sp)
    80003ade:	64e2                	ld	s1,24(sp)
    80003ae0:	6942                	ld	s2,16(sp)
    80003ae2:	69a2                	ld	s3,8(sp)
    80003ae4:	6a02                	ld	s4,0(sp)
    80003ae6:	6145                	addi	sp,sp,48
    80003ae8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aea:	0009a503          	lw	a0,0(s3)
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	466080e7          	jalr	1126(ra) # 80002f54 <bread>
    80003af6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003af8:	05850493          	addi	s1,a0,88
    80003afc:	45850913          	addi	s2,a0,1112
    80003b00:	a811                	j	80003b14 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b02:	0009a503          	lw	a0,0(s3)
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	7f8080e7          	jalr	2040(ra) # 800032fe <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b0e:	0491                	addi	s1,s1,4
    80003b10:	01248563          	beq	s1,s2,80003b1a <itrunc+0x8c>
      if(a[j])
    80003b14:	408c                	lw	a1,0(s1)
    80003b16:	dde5                	beqz	a1,80003b0e <itrunc+0x80>
    80003b18:	b7ed                	j	80003b02 <itrunc+0x74>
    brelse(bp);
    80003b1a:	8552                	mv	a0,s4
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	6b4080e7          	jalr	1716(ra) # 800031d0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b24:	07c9a583          	lw	a1,124(s3)
    80003b28:	0009a503          	lw	a0,0(s3)
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	7d2080e7          	jalr	2002(ra) # 800032fe <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b34:	0609ae23          	sw	zero,124(s3)
    80003b38:	bf51                	j	80003acc <itrunc+0x3e>

0000000080003b3a <iput>:
{
    80003b3a:	1101                	addi	sp,sp,-32
    80003b3c:	ec06                	sd	ra,24(sp)
    80003b3e:	e822                	sd	s0,16(sp)
    80003b40:	e426                	sd	s1,8(sp)
    80003b42:	e04a                	sd	s2,0(sp)
    80003b44:	1000                	addi	s0,sp,32
    80003b46:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b48:	0001b517          	auipc	a0,0x1b
    80003b4c:	80850513          	addi	a0,a0,-2040 # 8001e350 <icache>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	1be080e7          	jalr	446(ra) # 80000d0e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b58:	4498                	lw	a4,8(s1)
    80003b5a:	4785                	li	a5,1
    80003b5c:	02f70363          	beq	a4,a5,80003b82 <iput+0x48>
  ip->ref--;
    80003b60:	449c                	lw	a5,8(s1)
    80003b62:	37fd                	addiw	a5,a5,-1
    80003b64:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b66:	0001a517          	auipc	a0,0x1a
    80003b6a:	7ea50513          	addi	a0,a0,2026 # 8001e350 <icache>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	254080e7          	jalr	596(ra) # 80000dc2 <release>
}
    80003b76:	60e2                	ld	ra,24(sp)
    80003b78:	6442                	ld	s0,16(sp)
    80003b7a:	64a2                	ld	s1,8(sp)
    80003b7c:	6902                	ld	s2,0(sp)
    80003b7e:	6105                	addi	sp,sp,32
    80003b80:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b82:	40bc                	lw	a5,64(s1)
    80003b84:	dff1                	beqz	a5,80003b60 <iput+0x26>
    80003b86:	04a49783          	lh	a5,74(s1)
    80003b8a:	fbf9                	bnez	a5,80003b60 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b8c:	01048913          	addi	s2,s1,16
    80003b90:	854a                	mv	a0,s2
    80003b92:	00001097          	auipc	ra,0x1
    80003b96:	ac2080e7          	jalr	-1342(ra) # 80004654 <acquiresleep>
    release(&icache.lock);
    80003b9a:	0001a517          	auipc	a0,0x1a
    80003b9e:	7b650513          	addi	a0,a0,1974 # 8001e350 <icache>
    80003ba2:	ffffd097          	auipc	ra,0xffffd
    80003ba6:	220080e7          	jalr	544(ra) # 80000dc2 <release>
    itrunc(ip);
    80003baa:	8526                	mv	a0,s1
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	ee2080e7          	jalr	-286(ra) # 80003a8e <itrunc>
    ip->type = 0;
    80003bb4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bb8:	8526                	mv	a0,s1
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	cfc080e7          	jalr	-772(ra) # 800038b6 <iupdate>
    ip->valid = 0;
    80003bc2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	00001097          	auipc	ra,0x1
    80003bcc:	ae2080e7          	jalr	-1310(ra) # 800046aa <releasesleep>
    acquire(&icache.lock);
    80003bd0:	0001a517          	auipc	a0,0x1a
    80003bd4:	78050513          	addi	a0,a0,1920 # 8001e350 <icache>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	136080e7          	jalr	310(ra) # 80000d0e <acquire>
    80003be0:	b741                	j	80003b60 <iput+0x26>

0000000080003be2 <iunlockput>:
{
    80003be2:	1101                	addi	sp,sp,-32
    80003be4:	ec06                	sd	ra,24(sp)
    80003be6:	e822                	sd	s0,16(sp)
    80003be8:	e426                	sd	s1,8(sp)
    80003bea:	1000                	addi	s0,sp,32
    80003bec:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	e54080e7          	jalr	-428(ra) # 80003a42 <iunlock>
  iput(ip);
    80003bf6:	8526                	mv	a0,s1
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	f42080e7          	jalr	-190(ra) # 80003b3a <iput>
}
    80003c00:	60e2                	ld	ra,24(sp)
    80003c02:	6442                	ld	s0,16(sp)
    80003c04:	64a2                	ld	s1,8(sp)
    80003c06:	6105                	addi	sp,sp,32
    80003c08:	8082                	ret

0000000080003c0a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c0a:	1141                	addi	sp,sp,-16
    80003c0c:	e422                	sd	s0,8(sp)
    80003c0e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c10:	411c                	lw	a5,0(a0)
    80003c12:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c14:	415c                	lw	a5,4(a0)
    80003c16:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c18:	04451783          	lh	a5,68(a0)
    80003c1c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c20:	04a51783          	lh	a5,74(a0)
    80003c24:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c28:	04c56783          	lwu	a5,76(a0)
    80003c2c:	e99c                	sd	a5,16(a1)
}
    80003c2e:	6422                	ld	s0,8(sp)
    80003c30:	0141                	addi	sp,sp,16
    80003c32:	8082                	ret

0000000080003c34 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c34:	457c                	lw	a5,76(a0)
    80003c36:	0ed7e963          	bltu	a5,a3,80003d28 <readi+0xf4>
{
    80003c3a:	7159                	addi	sp,sp,-112
    80003c3c:	f486                	sd	ra,104(sp)
    80003c3e:	f0a2                	sd	s0,96(sp)
    80003c40:	eca6                	sd	s1,88(sp)
    80003c42:	e8ca                	sd	s2,80(sp)
    80003c44:	e4ce                	sd	s3,72(sp)
    80003c46:	e0d2                	sd	s4,64(sp)
    80003c48:	fc56                	sd	s5,56(sp)
    80003c4a:	f85a                	sd	s6,48(sp)
    80003c4c:	f45e                	sd	s7,40(sp)
    80003c4e:	f062                	sd	s8,32(sp)
    80003c50:	ec66                	sd	s9,24(sp)
    80003c52:	e86a                	sd	s10,16(sp)
    80003c54:	e46e                	sd	s11,8(sp)
    80003c56:	1880                	addi	s0,sp,112
    80003c58:	8baa                	mv	s7,a0
    80003c5a:	8c2e                	mv	s8,a1
    80003c5c:	8ab2                	mv	s5,a2
    80003c5e:	84b6                	mv	s1,a3
    80003c60:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c62:	9f35                	addw	a4,a4,a3
    return 0;
    80003c64:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c66:	0ad76063          	bltu	a4,a3,80003d06 <readi+0xd2>
  if(off + n > ip->size)
    80003c6a:	00e7f463          	bgeu	a5,a4,80003c72 <readi+0x3e>
    n = ip->size - off;
    80003c6e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c72:	0a0b0963          	beqz	s6,80003d24 <readi+0xf0>
    80003c76:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c78:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c7c:	5cfd                	li	s9,-1
    80003c7e:	a82d                	j	80003cb8 <readi+0x84>
    80003c80:	020a1d93          	slli	s11,s4,0x20
    80003c84:	020ddd93          	srli	s11,s11,0x20
    80003c88:	05890613          	addi	a2,s2,88
    80003c8c:	86ee                	mv	a3,s11
    80003c8e:	963a                	add	a2,a2,a4
    80003c90:	85d6                	mv	a1,s5
    80003c92:	8562                	mv	a0,s8
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	8d6080e7          	jalr	-1834(ra) # 8000256a <either_copyout>
    80003c9c:	05950d63          	beq	a0,s9,80003cf6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ca0:	854a                	mv	a0,s2
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	52e080e7          	jalr	1326(ra) # 800031d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003caa:	013a09bb          	addw	s3,s4,s3
    80003cae:	009a04bb          	addw	s1,s4,s1
    80003cb2:	9aee                	add	s5,s5,s11
    80003cb4:	0569f763          	bgeu	s3,s6,80003d02 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cb8:	000ba903          	lw	s2,0(s7)
    80003cbc:	00a4d59b          	srliw	a1,s1,0xa
    80003cc0:	855e                	mv	a0,s7
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	7ea080e7          	jalr	2026(ra) # 800034ac <bmap>
    80003cca:	0005059b          	sext.w	a1,a0
    80003cce:	854a                	mv	a0,s2
    80003cd0:	fffff097          	auipc	ra,0xfffff
    80003cd4:	284080e7          	jalr	644(ra) # 80002f54 <bread>
    80003cd8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cda:	3ff4f713          	andi	a4,s1,1023
    80003cde:	40ed07bb          	subw	a5,s10,a4
    80003ce2:	413b06bb          	subw	a3,s6,s3
    80003ce6:	8a3e                	mv	s4,a5
    80003ce8:	2781                	sext.w	a5,a5
    80003cea:	0006861b          	sext.w	a2,a3
    80003cee:	f8f679e3          	bgeu	a2,a5,80003c80 <readi+0x4c>
    80003cf2:	8a36                	mv	s4,a3
    80003cf4:	b771                	j	80003c80 <readi+0x4c>
      brelse(bp);
    80003cf6:	854a                	mv	a0,s2
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	4d8080e7          	jalr	1240(ra) # 800031d0 <brelse>
      tot = -1;
    80003d00:	59fd                	li	s3,-1
  }
  return tot;
    80003d02:	0009851b          	sext.w	a0,s3
}
    80003d06:	70a6                	ld	ra,104(sp)
    80003d08:	7406                	ld	s0,96(sp)
    80003d0a:	64e6                	ld	s1,88(sp)
    80003d0c:	6946                	ld	s2,80(sp)
    80003d0e:	69a6                	ld	s3,72(sp)
    80003d10:	6a06                	ld	s4,64(sp)
    80003d12:	7ae2                	ld	s5,56(sp)
    80003d14:	7b42                	ld	s6,48(sp)
    80003d16:	7ba2                	ld	s7,40(sp)
    80003d18:	7c02                	ld	s8,32(sp)
    80003d1a:	6ce2                	ld	s9,24(sp)
    80003d1c:	6d42                	ld	s10,16(sp)
    80003d1e:	6da2                	ld	s11,8(sp)
    80003d20:	6165                	addi	sp,sp,112
    80003d22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d24:	89da                	mv	s3,s6
    80003d26:	bff1                	j	80003d02 <readi+0xce>
    return 0;
    80003d28:	4501                	li	a0,0
}
    80003d2a:	8082                	ret

0000000080003d2c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d2c:	457c                	lw	a5,76(a0)
    80003d2e:	10d7e963          	bltu	a5,a3,80003e40 <writei+0x114>
{
    80003d32:	7159                	addi	sp,sp,-112
    80003d34:	f486                	sd	ra,104(sp)
    80003d36:	f0a2                	sd	s0,96(sp)
    80003d38:	eca6                	sd	s1,88(sp)
    80003d3a:	e8ca                	sd	s2,80(sp)
    80003d3c:	e4ce                	sd	s3,72(sp)
    80003d3e:	e0d2                	sd	s4,64(sp)
    80003d40:	fc56                	sd	s5,56(sp)
    80003d42:	f85a                	sd	s6,48(sp)
    80003d44:	f45e                	sd	s7,40(sp)
    80003d46:	f062                	sd	s8,32(sp)
    80003d48:	ec66                	sd	s9,24(sp)
    80003d4a:	e86a                	sd	s10,16(sp)
    80003d4c:	e46e                	sd	s11,8(sp)
    80003d4e:	1880                	addi	s0,sp,112
    80003d50:	8b2a                	mv	s6,a0
    80003d52:	8c2e                	mv	s8,a1
    80003d54:	8ab2                	mv	s5,a2
    80003d56:	8936                	mv	s2,a3
    80003d58:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d5a:	9f35                	addw	a4,a4,a3
    80003d5c:	0ed76463          	bltu	a4,a3,80003e44 <writei+0x118>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d60:	040437b7          	lui	a5,0x4043
    80003d64:	c0078793          	addi	a5,a5,-1024 # 4042c00 <_entry-0x7bfbd400>
    80003d68:	0ee7e063          	bltu	a5,a4,80003e48 <writei+0x11c>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d6c:	0c0b8863          	beqz	s7,80003e3c <writei+0x110>
    80003d70:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d72:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d76:	5cfd                	li	s9,-1
    80003d78:	a091                	j	80003dbc <writei+0x90>
    80003d7a:	02099d93          	slli	s11,s3,0x20
    80003d7e:	020ddd93          	srli	s11,s11,0x20
    80003d82:	05848513          	addi	a0,s1,88
    80003d86:	86ee                	mv	a3,s11
    80003d88:	8656                	mv	a2,s5
    80003d8a:	85e2                	mv	a1,s8
    80003d8c:	953a                	add	a0,a0,a4
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	832080e7          	jalr	-1998(ra) # 800025c0 <either_copyin>
    80003d96:	07950263          	beq	a0,s9,80003dfa <writei+0xce>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	790080e7          	jalr	1936(ra) # 8000452c <log_write>
    brelse(bp);
    80003da4:	8526                	mv	a0,s1
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	42a080e7          	jalr	1066(ra) # 800031d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dae:	01498a3b          	addw	s4,s3,s4
    80003db2:	0129893b          	addw	s2,s3,s2
    80003db6:	9aee                	add	s5,s5,s11
    80003db8:	057a7663          	bgeu	s4,s7,80003e04 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dbc:	000b2483          	lw	s1,0(s6)
    80003dc0:	00a9559b          	srliw	a1,s2,0xa
    80003dc4:	855a                	mv	a0,s6
    80003dc6:	fffff097          	auipc	ra,0xfffff
    80003dca:	6e6080e7          	jalr	1766(ra) # 800034ac <bmap>
    80003dce:	0005059b          	sext.w	a1,a0
    80003dd2:	8526                	mv	a0,s1
    80003dd4:	fffff097          	auipc	ra,0xfffff
    80003dd8:	180080e7          	jalr	384(ra) # 80002f54 <bread>
    80003ddc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dde:	3ff97713          	andi	a4,s2,1023
    80003de2:	40ed07bb          	subw	a5,s10,a4
    80003de6:	414b86bb          	subw	a3,s7,s4
    80003dea:	89be                	mv	s3,a5
    80003dec:	2781                	sext.w	a5,a5
    80003dee:	0006861b          	sext.w	a2,a3
    80003df2:	f8f674e3          	bgeu	a2,a5,80003d7a <writei+0x4e>
    80003df6:	89b6                	mv	s3,a3
    80003df8:	b749                	j	80003d7a <writei+0x4e>
      brelse(bp);
    80003dfa:	8526                	mv	a0,s1
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	3d4080e7          	jalr	980(ra) # 800031d0 <brelse>
  }

  if(off > ip->size)
    80003e04:	04cb2783          	lw	a5,76(s6)
    80003e08:	0127f463          	bgeu	a5,s2,80003e10 <writei+0xe4>
    ip->size = off;
    80003e0c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e10:	855a                	mv	a0,s6
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	aa4080e7          	jalr	-1372(ra) # 800038b6 <iupdate>

  return tot;
    80003e1a:	000a051b          	sext.w	a0,s4
}
    80003e1e:	70a6                	ld	ra,104(sp)
    80003e20:	7406                	ld	s0,96(sp)
    80003e22:	64e6                	ld	s1,88(sp)
    80003e24:	6946                	ld	s2,80(sp)
    80003e26:	69a6                	ld	s3,72(sp)
    80003e28:	6a06                	ld	s4,64(sp)
    80003e2a:	7ae2                	ld	s5,56(sp)
    80003e2c:	7b42                	ld	s6,48(sp)
    80003e2e:	7ba2                	ld	s7,40(sp)
    80003e30:	7c02                	ld	s8,32(sp)
    80003e32:	6ce2                	ld	s9,24(sp)
    80003e34:	6d42                	ld	s10,16(sp)
    80003e36:	6da2                	ld	s11,8(sp)
    80003e38:	6165                	addi	sp,sp,112
    80003e3a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e3c:	8a5e                	mv	s4,s7
    80003e3e:	bfc9                	j	80003e10 <writei+0xe4>
    return -1;
    80003e40:	557d                	li	a0,-1
}
    80003e42:	8082                	ret
    return -1;
    80003e44:	557d                	li	a0,-1
    80003e46:	bfe1                	j	80003e1e <writei+0xf2>
    return -1;
    80003e48:	557d                	li	a0,-1
    80003e4a:	bfd1                	j	80003e1e <writei+0xf2>

0000000080003e4c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e4c:	1141                	addi	sp,sp,-16
    80003e4e:	e406                	sd	ra,8(sp)
    80003e50:	e022                	sd	s0,0(sp)
    80003e52:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e54:	4639                	li	a2,14
    80003e56:	ffffd097          	auipc	ra,0xffffd
    80003e5a:	090080e7          	jalr	144(ra) # 80000ee6 <strncmp>
}
    80003e5e:	60a2                	ld	ra,8(sp)
    80003e60:	6402                	ld	s0,0(sp)
    80003e62:	0141                	addi	sp,sp,16
    80003e64:	8082                	ret

0000000080003e66 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e66:	7139                	addi	sp,sp,-64
    80003e68:	fc06                	sd	ra,56(sp)
    80003e6a:	f822                	sd	s0,48(sp)
    80003e6c:	f426                	sd	s1,40(sp)
    80003e6e:	f04a                	sd	s2,32(sp)
    80003e70:	ec4e                	sd	s3,24(sp)
    80003e72:	e852                	sd	s4,16(sp)
    80003e74:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e76:	04451703          	lh	a4,68(a0)
    80003e7a:	4785                	li	a5,1
    80003e7c:	00f71a63          	bne	a4,a5,80003e90 <dirlookup+0x2a>
    80003e80:	892a                	mv	s2,a0
    80003e82:	89ae                	mv	s3,a1
    80003e84:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e86:	457c                	lw	a5,76(a0)
    80003e88:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e8a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8c:	e79d                	bnez	a5,80003eba <dirlookup+0x54>
    80003e8e:	a8a5                	j	80003f06 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e90:	00004517          	auipc	a0,0x4
    80003e94:	76850513          	addi	a0,a0,1896 # 800085f8 <syscalls+0x1c0>
    80003e98:	ffffc097          	auipc	ra,0xffffc
    80003e9c:	698080e7          	jalr	1688(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003ea0:	00004517          	auipc	a0,0x4
    80003ea4:	77050513          	addi	a0,a0,1904 # 80008610 <syscalls+0x1d8>
    80003ea8:	ffffc097          	auipc	ra,0xffffc
    80003eac:	688080e7          	jalr	1672(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	24c1                	addiw	s1,s1,16
    80003eb2:	04c92783          	lw	a5,76(s2)
    80003eb6:	04f4f763          	bgeu	s1,a5,80003f04 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eba:	4741                	li	a4,16
    80003ebc:	86a6                	mv	a3,s1
    80003ebe:	fc040613          	addi	a2,s0,-64
    80003ec2:	4581                	li	a1,0
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	d6e080e7          	jalr	-658(ra) # 80003c34 <readi>
    80003ece:	47c1                	li	a5,16
    80003ed0:	fcf518e3          	bne	a0,a5,80003ea0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ed4:	fc045783          	lhu	a5,-64(s0)
    80003ed8:	dfe1                	beqz	a5,80003eb0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eda:	fc240593          	addi	a1,s0,-62
    80003ede:	854e                	mv	a0,s3
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	f6c080e7          	jalr	-148(ra) # 80003e4c <namecmp>
    80003ee8:	f561                	bnez	a0,80003eb0 <dirlookup+0x4a>
      if(poff)
    80003eea:	000a0463          	beqz	s4,80003ef2 <dirlookup+0x8c>
        *poff = off;
    80003eee:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ef2:	fc045583          	lhu	a1,-64(s0)
    80003ef6:	00092503          	lw	a0,0(s2)
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	752080e7          	jalr	1874(ra) # 8000364c <iget>
    80003f02:	a011                	j	80003f06 <dirlookup+0xa0>
  return 0;
    80003f04:	4501                	li	a0,0
}
    80003f06:	70e2                	ld	ra,56(sp)
    80003f08:	7442                	ld	s0,48(sp)
    80003f0a:	74a2                	ld	s1,40(sp)
    80003f0c:	7902                	ld	s2,32(sp)
    80003f0e:	69e2                	ld	s3,24(sp)
    80003f10:	6a42                	ld	s4,16(sp)
    80003f12:	6121                	addi	sp,sp,64
    80003f14:	8082                	ret

0000000080003f16 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f16:	711d                	addi	sp,sp,-96
    80003f18:	ec86                	sd	ra,88(sp)
    80003f1a:	e8a2                	sd	s0,80(sp)
    80003f1c:	e4a6                	sd	s1,72(sp)
    80003f1e:	e0ca                	sd	s2,64(sp)
    80003f20:	fc4e                	sd	s3,56(sp)
    80003f22:	f852                	sd	s4,48(sp)
    80003f24:	f456                	sd	s5,40(sp)
    80003f26:	f05a                	sd	s6,32(sp)
    80003f28:	ec5e                	sd	s7,24(sp)
    80003f2a:	e862                	sd	s8,16(sp)
    80003f2c:	e466                	sd	s9,8(sp)
    80003f2e:	1080                	addi	s0,sp,96
    80003f30:	84aa                	mv	s1,a0
    80003f32:	8b2e                	mv	s6,a1
    80003f34:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f36:	00054703          	lbu	a4,0(a0)
    80003f3a:	02f00793          	li	a5,47
    80003f3e:	02f70363          	beq	a4,a5,80003f64 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f42:	ffffe097          	auipc	ra,0xffffe
    80003f46:	bb6080e7          	jalr	-1098(ra) # 80001af8 <myproc>
    80003f4a:	15053503          	ld	a0,336(a0)
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	9f4080e7          	jalr	-1548(ra) # 80003942 <idup>
    80003f56:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f58:	02f00913          	li	s2,47
  len = path - s;
    80003f5c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f5e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f60:	4c05                	li	s8,1
    80003f62:	a865                	j	8000401a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f64:	4585                	li	a1,1
    80003f66:	4505                	li	a0,1
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	6e4080e7          	jalr	1764(ra) # 8000364c <iget>
    80003f70:	89aa                	mv	s3,a0
    80003f72:	b7dd                	j	80003f58 <namex+0x42>
      iunlockput(ip);
    80003f74:	854e                	mv	a0,s3
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	c6c080e7          	jalr	-916(ra) # 80003be2 <iunlockput>
      return 0;
    80003f7e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f80:	854e                	mv	a0,s3
    80003f82:	60e6                	ld	ra,88(sp)
    80003f84:	6446                	ld	s0,80(sp)
    80003f86:	64a6                	ld	s1,72(sp)
    80003f88:	6906                	ld	s2,64(sp)
    80003f8a:	79e2                	ld	s3,56(sp)
    80003f8c:	7a42                	ld	s4,48(sp)
    80003f8e:	7aa2                	ld	s5,40(sp)
    80003f90:	7b02                	ld	s6,32(sp)
    80003f92:	6be2                	ld	s7,24(sp)
    80003f94:	6c42                	ld	s8,16(sp)
    80003f96:	6ca2                	ld	s9,8(sp)
    80003f98:	6125                	addi	sp,sp,96
    80003f9a:	8082                	ret
      iunlock(ip);
    80003f9c:	854e                	mv	a0,s3
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	aa4080e7          	jalr	-1372(ra) # 80003a42 <iunlock>
      return ip;
    80003fa6:	bfe9                	j	80003f80 <namex+0x6a>
      iunlockput(ip);
    80003fa8:	854e                	mv	a0,s3
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	c38080e7          	jalr	-968(ra) # 80003be2 <iunlockput>
      return 0;
    80003fb2:	89d2                	mv	s3,s4
    80003fb4:	b7f1                	j	80003f80 <namex+0x6a>
  len = path - s;
    80003fb6:	40b48633          	sub	a2,s1,a1
    80003fba:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fbe:	094cd463          	bge	s9,s4,80004046 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fc2:	4639                	li	a2,14
    80003fc4:	8556                	mv	a0,s5
    80003fc6:	ffffd097          	auipc	ra,0xffffd
    80003fca:	ea4080e7          	jalr	-348(ra) # 80000e6a <memmove>
  while(*path == '/')
    80003fce:	0004c783          	lbu	a5,0(s1)
    80003fd2:	01279763          	bne	a5,s2,80003fe0 <namex+0xca>
    path++;
    80003fd6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd8:	0004c783          	lbu	a5,0(s1)
    80003fdc:	ff278de3          	beq	a5,s2,80003fd6 <namex+0xc0>
    ilock(ip);
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	99e080e7          	jalr	-1634(ra) # 80003980 <ilock>
    if(ip->type != T_DIR){
    80003fea:	04499783          	lh	a5,68(s3)
    80003fee:	f98793e3          	bne	a5,s8,80003f74 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ff2:	000b0563          	beqz	s6,80003ffc <namex+0xe6>
    80003ff6:	0004c783          	lbu	a5,0(s1)
    80003ffa:	d3cd                	beqz	a5,80003f9c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ffc:	865e                	mv	a2,s7
    80003ffe:	85d6                	mv	a1,s5
    80004000:	854e                	mv	a0,s3
    80004002:	00000097          	auipc	ra,0x0
    80004006:	e64080e7          	jalr	-412(ra) # 80003e66 <dirlookup>
    8000400a:	8a2a                	mv	s4,a0
    8000400c:	dd51                	beqz	a0,80003fa8 <namex+0x92>
    iunlockput(ip);
    8000400e:	854e                	mv	a0,s3
    80004010:	00000097          	auipc	ra,0x0
    80004014:	bd2080e7          	jalr	-1070(ra) # 80003be2 <iunlockput>
    ip = next;
    80004018:	89d2                	mv	s3,s4
  while(*path == '/')
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	05279763          	bne	a5,s2,8000406c <namex+0x156>
    path++;
    80004022:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004024:	0004c783          	lbu	a5,0(s1)
    80004028:	ff278de3          	beq	a5,s2,80004022 <namex+0x10c>
  if(*path == 0)
    8000402c:	c79d                	beqz	a5,8000405a <namex+0x144>
    path++;
    8000402e:	85a6                	mv	a1,s1
  len = path - s;
    80004030:	8a5e                	mv	s4,s7
    80004032:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004034:	01278963          	beq	a5,s2,80004046 <namex+0x130>
    80004038:	dfbd                	beqz	a5,80003fb6 <namex+0xa0>
    path++;
    8000403a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000403c:	0004c783          	lbu	a5,0(s1)
    80004040:	ff279ce3          	bne	a5,s2,80004038 <namex+0x122>
    80004044:	bf8d                	j	80003fb6 <namex+0xa0>
    memmove(name, s, len);
    80004046:	2601                	sext.w	a2,a2
    80004048:	8556                	mv	a0,s5
    8000404a:	ffffd097          	auipc	ra,0xffffd
    8000404e:	e20080e7          	jalr	-480(ra) # 80000e6a <memmove>
    name[len] = 0;
    80004052:	9a56                	add	s4,s4,s5
    80004054:	000a0023          	sb	zero,0(s4)
    80004058:	bf9d                	j	80003fce <namex+0xb8>
  if(nameiparent){
    8000405a:	f20b03e3          	beqz	s6,80003f80 <namex+0x6a>
    iput(ip);
    8000405e:	854e                	mv	a0,s3
    80004060:	00000097          	auipc	ra,0x0
    80004064:	ada080e7          	jalr	-1318(ra) # 80003b3a <iput>
    return 0;
    80004068:	4981                	li	s3,0
    8000406a:	bf19                	j	80003f80 <namex+0x6a>
  if(*path == 0)
    8000406c:	d7fd                	beqz	a5,8000405a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000406e:	0004c783          	lbu	a5,0(s1)
    80004072:	85a6                	mv	a1,s1
    80004074:	b7d1                	j	80004038 <namex+0x122>

0000000080004076 <dirlink>:
{
    80004076:	7139                	addi	sp,sp,-64
    80004078:	fc06                	sd	ra,56(sp)
    8000407a:	f822                	sd	s0,48(sp)
    8000407c:	f426                	sd	s1,40(sp)
    8000407e:	f04a                	sd	s2,32(sp)
    80004080:	ec4e                	sd	s3,24(sp)
    80004082:	e852                	sd	s4,16(sp)
    80004084:	0080                	addi	s0,sp,64
    80004086:	892a                	mv	s2,a0
    80004088:	8a2e                	mv	s4,a1
    8000408a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000408c:	4601                	li	a2,0
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	dd8080e7          	jalr	-552(ra) # 80003e66 <dirlookup>
    80004096:	e93d                	bnez	a0,8000410c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004098:	04c92483          	lw	s1,76(s2)
    8000409c:	c49d                	beqz	s1,800040ca <dirlink+0x54>
    8000409e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a0:	4741                	li	a4,16
    800040a2:	86a6                	mv	a3,s1
    800040a4:	fc040613          	addi	a2,s0,-64
    800040a8:	4581                	li	a1,0
    800040aa:	854a                	mv	a0,s2
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	b88080e7          	jalr	-1144(ra) # 80003c34 <readi>
    800040b4:	47c1                	li	a5,16
    800040b6:	06f51163          	bne	a0,a5,80004118 <dirlink+0xa2>
    if(de.inum == 0)
    800040ba:	fc045783          	lhu	a5,-64(s0)
    800040be:	c791                	beqz	a5,800040ca <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c0:	24c1                	addiw	s1,s1,16
    800040c2:	04c92783          	lw	a5,76(s2)
    800040c6:	fcf4ede3          	bltu	s1,a5,800040a0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040ca:	4639                	li	a2,14
    800040cc:	85d2                	mv	a1,s4
    800040ce:	fc240513          	addi	a0,s0,-62
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	e50080e7          	jalr	-432(ra) # 80000f22 <strncpy>
  de.inum = inum;
    800040da:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040de:	4741                	li	a4,16
    800040e0:	86a6                	mv	a3,s1
    800040e2:	fc040613          	addi	a2,s0,-64
    800040e6:	4581                	li	a1,0
    800040e8:	854a                	mv	a0,s2
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	c42080e7          	jalr	-958(ra) # 80003d2c <writei>
    800040f2:	872a                	mv	a4,a0
    800040f4:	47c1                	li	a5,16
  return 0;
    800040f6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f8:	02f71863          	bne	a4,a5,80004128 <dirlink+0xb2>
}
    800040fc:	70e2                	ld	ra,56(sp)
    800040fe:	7442                	ld	s0,48(sp)
    80004100:	74a2                	ld	s1,40(sp)
    80004102:	7902                	ld	s2,32(sp)
    80004104:	69e2                	ld	s3,24(sp)
    80004106:	6a42                	ld	s4,16(sp)
    80004108:	6121                	addi	sp,sp,64
    8000410a:	8082                	ret
    iput(ip);
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	a2e080e7          	jalr	-1490(ra) # 80003b3a <iput>
    return -1;
    80004114:	557d                	li	a0,-1
    80004116:	b7dd                	j	800040fc <dirlink+0x86>
      panic("dirlink read");
    80004118:	00004517          	auipc	a0,0x4
    8000411c:	50850513          	addi	a0,a0,1288 # 80008620 <syscalls+0x1e8>
    80004120:	ffffc097          	auipc	ra,0xffffc
    80004124:	410080e7          	jalr	1040(ra) # 80000530 <panic>
    panic("dirlink");
    80004128:	00004517          	auipc	a0,0x4
    8000412c:	60850513          	addi	a0,a0,1544 # 80008730 <syscalls+0x2f8>
    80004130:	ffffc097          	auipc	ra,0xffffc
    80004134:	400080e7          	jalr	1024(ra) # 80000530 <panic>

0000000080004138 <namei>:

struct inode*
namei(char *path)
{
    80004138:	1101                	addi	sp,sp,-32
    8000413a:	ec06                	sd	ra,24(sp)
    8000413c:	e822                	sd	s0,16(sp)
    8000413e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004140:	fe040613          	addi	a2,s0,-32
    80004144:	4581                	li	a1,0
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	dd0080e7          	jalr	-560(ra) # 80003f16 <namex>
}
    8000414e:	60e2                	ld	ra,24(sp)
    80004150:	6442                	ld	s0,16(sp)
    80004152:	6105                	addi	sp,sp,32
    80004154:	8082                	ret

0000000080004156 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004156:	1141                	addi	sp,sp,-16
    80004158:	e406                	sd	ra,8(sp)
    8000415a:	e022                	sd	s0,0(sp)
    8000415c:	0800                	addi	s0,sp,16
    8000415e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004160:	4585                	li	a1,1
    80004162:	00000097          	auipc	ra,0x0
    80004166:	db4080e7          	jalr	-588(ra) # 80003f16 <namex>
}
    8000416a:	60a2                	ld	ra,8(sp)
    8000416c:	6402                	ld	s0,0(sp)
    8000416e:	0141                	addi	sp,sp,16
    80004170:	8082                	ret

0000000080004172 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004172:	1101                	addi	sp,sp,-32
    80004174:	ec06                	sd	ra,24(sp)
    80004176:	e822                	sd	s0,16(sp)
    80004178:	e426                	sd	s1,8(sp)
    8000417a:	e04a                	sd	s2,0(sp)
    8000417c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000417e:	0001c917          	auipc	s2,0x1c
    80004182:	c7a90913          	addi	s2,s2,-902 # 8001fdf8 <log>
    80004186:	01892583          	lw	a1,24(s2)
    8000418a:	02892503          	lw	a0,40(s2)
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	dc6080e7          	jalr	-570(ra) # 80002f54 <bread>
    80004196:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004198:	02c92683          	lw	a3,44(s2)
    8000419c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000419e:	02d05763          	blez	a3,800041cc <write_head+0x5a>
    800041a2:	0001c797          	auipc	a5,0x1c
    800041a6:	c8678793          	addi	a5,a5,-890 # 8001fe28 <log+0x30>
    800041aa:	05c50713          	addi	a4,a0,92
    800041ae:	36fd                	addiw	a3,a3,-1
    800041b0:	1682                	slli	a3,a3,0x20
    800041b2:	9281                	srli	a3,a3,0x20
    800041b4:	068a                	slli	a3,a3,0x2
    800041b6:	0001c617          	auipc	a2,0x1c
    800041ba:	c7660613          	addi	a2,a2,-906 # 8001fe2c <log+0x34>
    800041be:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041c0:	4390                	lw	a2,0(a5)
    800041c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c4:	0791                	addi	a5,a5,4
    800041c6:	0711                	addi	a4,a4,4
    800041c8:	fed79ce3          	bne	a5,a3,800041c0 <write_head+0x4e>
  }
  bwrite(buf);
    800041cc:	8526                	mv	a0,s1
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	fc4080e7          	jalr	-60(ra) # 80003192 <bwrite>
  brelse(buf);
    800041d6:	8526                	mv	a0,s1
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	ff8080e7          	jalr	-8(ra) # 800031d0 <brelse>
}
    800041e0:	60e2                	ld	ra,24(sp)
    800041e2:	6442                	ld	s0,16(sp)
    800041e4:	64a2                	ld	s1,8(sp)
    800041e6:	6902                	ld	s2,0(sp)
    800041e8:	6105                	addi	sp,sp,32
    800041ea:	8082                	ret

00000000800041ec <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	0001c797          	auipc	a5,0x1c
    800041f0:	c387a783          	lw	a5,-968(a5) # 8001fe24 <log+0x2c>
    800041f4:	0af05d63          	blez	a5,800042ae <install_trans+0xc2>
{
    800041f8:	7139                	addi	sp,sp,-64
    800041fa:	fc06                	sd	ra,56(sp)
    800041fc:	f822                	sd	s0,48(sp)
    800041fe:	f426                	sd	s1,40(sp)
    80004200:	f04a                	sd	s2,32(sp)
    80004202:	ec4e                	sd	s3,24(sp)
    80004204:	e852                	sd	s4,16(sp)
    80004206:	e456                	sd	s5,8(sp)
    80004208:	e05a                	sd	s6,0(sp)
    8000420a:	0080                	addi	s0,sp,64
    8000420c:	8b2a                	mv	s6,a0
    8000420e:	0001ca97          	auipc	s5,0x1c
    80004212:	c1aa8a93          	addi	s5,s5,-998 # 8001fe28 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004216:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004218:	0001c997          	auipc	s3,0x1c
    8000421c:	be098993          	addi	s3,s3,-1056 # 8001fdf8 <log>
    80004220:	a035                	j	8000424c <install_trans+0x60>
      bunpin(dbuf);
    80004222:	8526                	mv	a0,s1
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	084080e7          	jalr	132(ra) # 800032a8 <bunpin>
    brelse(lbuf);
    8000422c:	854a                	mv	a0,s2
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	fa2080e7          	jalr	-94(ra) # 800031d0 <brelse>
    brelse(dbuf);
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	f98080e7          	jalr	-104(ra) # 800031d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004240:	2a05                	addiw	s4,s4,1
    80004242:	0a91                	addi	s5,s5,4
    80004244:	02c9a783          	lw	a5,44(s3)
    80004248:	04fa5963          	bge	s4,a5,8000429a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000424c:	0189a583          	lw	a1,24(s3)
    80004250:	014585bb          	addw	a1,a1,s4
    80004254:	2585                	addiw	a1,a1,1
    80004256:	0289a503          	lw	a0,40(s3)
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	cfa080e7          	jalr	-774(ra) # 80002f54 <bread>
    80004262:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004264:	000aa583          	lw	a1,0(s5)
    80004268:	0289a503          	lw	a0,40(s3)
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	ce8080e7          	jalr	-792(ra) # 80002f54 <bread>
    80004274:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004276:	40000613          	li	a2,1024
    8000427a:	05890593          	addi	a1,s2,88
    8000427e:	05850513          	addi	a0,a0,88
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	be8080e7          	jalr	-1048(ra) # 80000e6a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000428a:	8526                	mv	a0,s1
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	f06080e7          	jalr	-250(ra) # 80003192 <bwrite>
    if(recovering == 0)
    80004294:	f80b1ce3          	bnez	s6,8000422c <install_trans+0x40>
    80004298:	b769                	j	80004222 <install_trans+0x36>
}
    8000429a:	70e2                	ld	ra,56(sp)
    8000429c:	7442                	ld	s0,48(sp)
    8000429e:	74a2                	ld	s1,40(sp)
    800042a0:	7902                	ld	s2,32(sp)
    800042a2:	69e2                	ld	s3,24(sp)
    800042a4:	6a42                	ld	s4,16(sp)
    800042a6:	6aa2                	ld	s5,8(sp)
    800042a8:	6b02                	ld	s6,0(sp)
    800042aa:	6121                	addi	sp,sp,64
    800042ac:	8082                	ret
    800042ae:	8082                	ret

00000000800042b0 <initlog>:
{
    800042b0:	7179                	addi	sp,sp,-48
    800042b2:	f406                	sd	ra,40(sp)
    800042b4:	f022                	sd	s0,32(sp)
    800042b6:	ec26                	sd	s1,24(sp)
    800042b8:	e84a                	sd	s2,16(sp)
    800042ba:	e44e                	sd	s3,8(sp)
    800042bc:	1800                	addi	s0,sp,48
    800042be:	892a                	mv	s2,a0
    800042c0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042c2:	0001c497          	auipc	s1,0x1c
    800042c6:	b3648493          	addi	s1,s1,-1226 # 8001fdf8 <log>
    800042ca:	00004597          	auipc	a1,0x4
    800042ce:	36658593          	addi	a1,a1,870 # 80008630 <syscalls+0x1f8>
    800042d2:	8526                	mv	a0,s1
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	9aa080e7          	jalr	-1622(ra) # 80000c7e <initlock>
  log.start = sb->logstart;
    800042dc:	0149a583          	lw	a1,20(s3)
    800042e0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042e2:	0109a783          	lw	a5,16(s3)
    800042e6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042e8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042ec:	854a                	mv	a0,s2
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	c66080e7          	jalr	-922(ra) # 80002f54 <bread>
  log.lh.n = lh->n;
    800042f6:	4d3c                	lw	a5,88(a0)
    800042f8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042fa:	02f05563          	blez	a5,80004324 <initlog+0x74>
    800042fe:	05c50713          	addi	a4,a0,92
    80004302:	0001c697          	auipc	a3,0x1c
    80004306:	b2668693          	addi	a3,a3,-1242 # 8001fe28 <log+0x30>
    8000430a:	37fd                	addiw	a5,a5,-1
    8000430c:	1782                	slli	a5,a5,0x20
    8000430e:	9381                	srli	a5,a5,0x20
    80004310:	078a                	slli	a5,a5,0x2
    80004312:	06050613          	addi	a2,a0,96
    80004316:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004318:	4310                	lw	a2,0(a4)
    8000431a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000431c:	0711                	addi	a4,a4,4
    8000431e:	0691                	addi	a3,a3,4
    80004320:	fef71ce3          	bne	a4,a5,80004318 <initlog+0x68>
  brelse(buf);
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	eac080e7          	jalr	-340(ra) # 800031d0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000432c:	4505                	li	a0,1
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	ebe080e7          	jalr	-322(ra) # 800041ec <install_trans>
  log.lh.n = 0;
    80004336:	0001c797          	auipc	a5,0x1c
    8000433a:	ae07a723          	sw	zero,-1298(a5) # 8001fe24 <log+0x2c>
  write_head(); // clear the log
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	e34080e7          	jalr	-460(ra) # 80004172 <write_head>
}
    80004346:	70a2                	ld	ra,40(sp)
    80004348:	7402                	ld	s0,32(sp)
    8000434a:	64e2                	ld	s1,24(sp)
    8000434c:	6942                	ld	s2,16(sp)
    8000434e:	69a2                	ld	s3,8(sp)
    80004350:	6145                	addi	sp,sp,48
    80004352:	8082                	ret

0000000080004354 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004354:	1101                	addi	sp,sp,-32
    80004356:	ec06                	sd	ra,24(sp)
    80004358:	e822                	sd	s0,16(sp)
    8000435a:	e426                	sd	s1,8(sp)
    8000435c:	e04a                	sd	s2,0(sp)
    8000435e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004360:	0001c517          	auipc	a0,0x1c
    80004364:	a9850513          	addi	a0,a0,-1384 # 8001fdf8 <log>
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	9a6080e7          	jalr	-1626(ra) # 80000d0e <acquire>
  while(1){
    if(log.committing){
    80004370:	0001c497          	auipc	s1,0x1c
    80004374:	a8848493          	addi	s1,s1,-1400 # 8001fdf8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004378:	4979                	li	s2,30
    8000437a:	a039                	j	80004388 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000437c:	85a6                	mv	a1,s1
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffe097          	auipc	ra,0xffffe
    80004384:	f88080e7          	jalr	-120(ra) # 80002308 <sleep>
    if(log.committing){
    80004388:	50dc                	lw	a5,36(s1)
    8000438a:	fbed                	bnez	a5,8000437c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000438c:	509c                	lw	a5,32(s1)
    8000438e:	0017871b          	addiw	a4,a5,1
    80004392:	0007069b          	sext.w	a3,a4
    80004396:	0027179b          	slliw	a5,a4,0x2
    8000439a:	9fb9                	addw	a5,a5,a4
    8000439c:	0017979b          	slliw	a5,a5,0x1
    800043a0:	54d8                	lw	a4,44(s1)
    800043a2:	9fb9                	addw	a5,a5,a4
    800043a4:	00f95963          	bge	s2,a5,800043b6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043a8:	85a6                	mv	a1,s1
    800043aa:	8526                	mv	a0,s1
    800043ac:	ffffe097          	auipc	ra,0xffffe
    800043b0:	f5c080e7          	jalr	-164(ra) # 80002308 <sleep>
    800043b4:	bfd1                	j	80004388 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043b6:	0001c517          	auipc	a0,0x1c
    800043ba:	a4250513          	addi	a0,a0,-1470 # 8001fdf8 <log>
    800043be:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	a02080e7          	jalr	-1534(ra) # 80000dc2 <release>
      break;
    }
  }
}
    800043c8:	60e2                	ld	ra,24(sp)
    800043ca:	6442                	ld	s0,16(sp)
    800043cc:	64a2                	ld	s1,8(sp)
    800043ce:	6902                	ld	s2,0(sp)
    800043d0:	6105                	addi	sp,sp,32
    800043d2:	8082                	ret

00000000800043d4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043d4:	7139                	addi	sp,sp,-64
    800043d6:	fc06                	sd	ra,56(sp)
    800043d8:	f822                	sd	s0,48(sp)
    800043da:	f426                	sd	s1,40(sp)
    800043dc:	f04a                	sd	s2,32(sp)
    800043de:	ec4e                	sd	s3,24(sp)
    800043e0:	e852                	sd	s4,16(sp)
    800043e2:	e456                	sd	s5,8(sp)
    800043e4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043e6:	0001c497          	auipc	s1,0x1c
    800043ea:	a1248493          	addi	s1,s1,-1518 # 8001fdf8 <log>
    800043ee:	8526                	mv	a0,s1
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	91e080e7          	jalr	-1762(ra) # 80000d0e <acquire>
  log.outstanding -= 1;
    800043f8:	509c                	lw	a5,32(s1)
    800043fa:	37fd                	addiw	a5,a5,-1
    800043fc:	0007891b          	sext.w	s2,a5
    80004400:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004402:	50dc                	lw	a5,36(s1)
    80004404:	efb9                	bnez	a5,80004462 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004406:	06091663          	bnez	s2,80004472 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000440a:	0001c497          	auipc	s1,0x1c
    8000440e:	9ee48493          	addi	s1,s1,-1554 # 8001fdf8 <log>
    80004412:	4785                	li	a5,1
    80004414:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004416:	8526                	mv	a0,s1
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	9aa080e7          	jalr	-1622(ra) # 80000dc2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004420:	54dc                	lw	a5,44(s1)
    80004422:	06f04763          	bgtz	a5,80004490 <end_op+0xbc>
    acquire(&log.lock);
    80004426:	0001c497          	auipc	s1,0x1c
    8000442a:	9d248493          	addi	s1,s1,-1582 # 8001fdf8 <log>
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffd097          	auipc	ra,0xffffd
    80004434:	8de080e7          	jalr	-1826(ra) # 80000d0e <acquire>
    log.committing = 0;
    80004438:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000443c:	8526                	mv	a0,s1
    8000443e:	ffffe097          	auipc	ra,0xffffe
    80004442:	050080e7          	jalr	80(ra) # 8000248e <wakeup>
    release(&log.lock);
    80004446:	8526                	mv	a0,s1
    80004448:	ffffd097          	auipc	ra,0xffffd
    8000444c:	97a080e7          	jalr	-1670(ra) # 80000dc2 <release>
}
    80004450:	70e2                	ld	ra,56(sp)
    80004452:	7442                	ld	s0,48(sp)
    80004454:	74a2                	ld	s1,40(sp)
    80004456:	7902                	ld	s2,32(sp)
    80004458:	69e2                	ld	s3,24(sp)
    8000445a:	6a42                	ld	s4,16(sp)
    8000445c:	6aa2                	ld	s5,8(sp)
    8000445e:	6121                	addi	sp,sp,64
    80004460:	8082                	ret
    panic("log.committing");
    80004462:	00004517          	auipc	a0,0x4
    80004466:	1d650513          	addi	a0,a0,470 # 80008638 <syscalls+0x200>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	0c6080e7          	jalr	198(ra) # 80000530 <panic>
    wakeup(&log);
    80004472:	0001c497          	auipc	s1,0x1c
    80004476:	98648493          	addi	s1,s1,-1658 # 8001fdf8 <log>
    8000447a:	8526                	mv	a0,s1
    8000447c:	ffffe097          	auipc	ra,0xffffe
    80004480:	012080e7          	jalr	18(ra) # 8000248e <wakeup>
  release(&log.lock);
    80004484:	8526                	mv	a0,s1
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	93c080e7          	jalr	-1732(ra) # 80000dc2 <release>
  if(do_commit){
    8000448e:	b7c9                	j	80004450 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004490:	0001ca97          	auipc	s5,0x1c
    80004494:	998a8a93          	addi	s5,s5,-1640 # 8001fe28 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004498:	0001ca17          	auipc	s4,0x1c
    8000449c:	960a0a13          	addi	s4,s4,-1696 # 8001fdf8 <log>
    800044a0:	018a2583          	lw	a1,24(s4)
    800044a4:	012585bb          	addw	a1,a1,s2
    800044a8:	2585                	addiw	a1,a1,1
    800044aa:	028a2503          	lw	a0,40(s4)
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	aa6080e7          	jalr	-1370(ra) # 80002f54 <bread>
    800044b6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044b8:	000aa583          	lw	a1,0(s5)
    800044bc:	028a2503          	lw	a0,40(s4)
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	a94080e7          	jalr	-1388(ra) # 80002f54 <bread>
    800044c8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044ca:	40000613          	li	a2,1024
    800044ce:	05850593          	addi	a1,a0,88
    800044d2:	05848513          	addi	a0,s1,88
    800044d6:	ffffd097          	auipc	ra,0xffffd
    800044da:	994080e7          	jalr	-1644(ra) # 80000e6a <memmove>
    bwrite(to);  // write the log
    800044de:	8526                	mv	a0,s1
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	cb2080e7          	jalr	-846(ra) # 80003192 <bwrite>
    brelse(from);
    800044e8:	854e                	mv	a0,s3
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	ce6080e7          	jalr	-794(ra) # 800031d0 <brelse>
    brelse(to);
    800044f2:	8526                	mv	a0,s1
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	cdc080e7          	jalr	-804(ra) # 800031d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fc:	2905                	addiw	s2,s2,1
    800044fe:	0a91                	addi	s5,s5,4
    80004500:	02ca2783          	lw	a5,44(s4)
    80004504:	f8f94ee3          	blt	s2,a5,800044a0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	c6a080e7          	jalr	-918(ra) # 80004172 <write_head>
    install_trans(0); // Now install writes to home locations
    80004510:	4501                	li	a0,0
    80004512:	00000097          	auipc	ra,0x0
    80004516:	cda080e7          	jalr	-806(ra) # 800041ec <install_trans>
    log.lh.n = 0;
    8000451a:	0001c797          	auipc	a5,0x1c
    8000451e:	9007a523          	sw	zero,-1782(a5) # 8001fe24 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004522:	00000097          	auipc	ra,0x0
    80004526:	c50080e7          	jalr	-944(ra) # 80004172 <write_head>
    8000452a:	bdf5                	j	80004426 <end_op+0x52>

000000008000452c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000452c:	1101                	addi	sp,sp,-32
    8000452e:	ec06                	sd	ra,24(sp)
    80004530:	e822                	sd	s0,16(sp)
    80004532:	e426                	sd	s1,8(sp)
    80004534:	e04a                	sd	s2,0(sp)
    80004536:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004538:	0001c717          	auipc	a4,0x1c
    8000453c:	8ec72703          	lw	a4,-1812(a4) # 8001fe24 <log+0x2c>
    80004540:	47f5                	li	a5,29
    80004542:	08e7c063          	blt	a5,a4,800045c2 <log_write+0x96>
    80004546:	84aa                	mv	s1,a0
    80004548:	0001c797          	auipc	a5,0x1c
    8000454c:	8cc7a783          	lw	a5,-1844(a5) # 8001fe14 <log+0x1c>
    80004550:	37fd                	addiw	a5,a5,-1
    80004552:	06f75863          	bge	a4,a5,800045c2 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004556:	0001c797          	auipc	a5,0x1c
    8000455a:	8c27a783          	lw	a5,-1854(a5) # 8001fe18 <log+0x20>
    8000455e:	06f05a63          	blez	a5,800045d2 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004562:	0001c917          	auipc	s2,0x1c
    80004566:	89690913          	addi	s2,s2,-1898 # 8001fdf8 <log>
    8000456a:	854a                	mv	a0,s2
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	7a2080e7          	jalr	1954(ra) # 80000d0e <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004574:	02c92603          	lw	a2,44(s2)
    80004578:	06c05563          	blez	a2,800045e2 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000457c:	44cc                	lw	a1,12(s1)
    8000457e:	0001c717          	auipc	a4,0x1c
    80004582:	8aa70713          	addi	a4,a4,-1878 # 8001fe28 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004586:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004588:	4314                	lw	a3,0(a4)
    8000458a:	04b68d63          	beq	a3,a1,800045e4 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000458e:	2785                	addiw	a5,a5,1
    80004590:	0711                	addi	a4,a4,4
    80004592:	fec79be3          	bne	a5,a2,80004588 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004596:	0621                	addi	a2,a2,8
    80004598:	060a                	slli	a2,a2,0x2
    8000459a:	0001c797          	auipc	a5,0x1c
    8000459e:	85e78793          	addi	a5,a5,-1954 # 8001fdf8 <log>
    800045a2:	963e                	add	a2,a2,a5
    800045a4:	44dc                	lw	a5,12(s1)
    800045a6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045a8:	8526                	mv	a0,s1
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	ca8080e7          	jalr	-856(ra) # 80003252 <bpin>
    log.lh.n++;
    800045b2:	0001c717          	auipc	a4,0x1c
    800045b6:	84670713          	addi	a4,a4,-1978 # 8001fdf8 <log>
    800045ba:	575c                	lw	a5,44(a4)
    800045bc:	2785                	addiw	a5,a5,1
    800045be:	d75c                	sw	a5,44(a4)
    800045c0:	a83d                	j	800045fe <log_write+0xd2>
    panic("too big a transaction");
    800045c2:	00004517          	auipc	a0,0x4
    800045c6:	08650513          	addi	a0,a0,134 # 80008648 <syscalls+0x210>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	f66080e7          	jalr	-154(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    800045d2:	00004517          	auipc	a0,0x4
    800045d6:	08e50513          	addi	a0,a0,142 # 80008660 <syscalls+0x228>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	f56080e7          	jalr	-170(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045e2:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045e4:	00878713          	addi	a4,a5,8
    800045e8:	00271693          	slli	a3,a4,0x2
    800045ec:	0001c717          	auipc	a4,0x1c
    800045f0:	80c70713          	addi	a4,a4,-2036 # 8001fdf8 <log>
    800045f4:	9736                	add	a4,a4,a3
    800045f6:	44d4                	lw	a3,12(s1)
    800045f8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045fa:	faf607e3          	beq	a2,a5,800045a8 <log_write+0x7c>
  }
  release(&log.lock);
    800045fe:	0001b517          	auipc	a0,0x1b
    80004602:	7fa50513          	addi	a0,a0,2042 # 8001fdf8 <log>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	7bc080e7          	jalr	1980(ra) # 80000dc2 <release>
}
    8000460e:	60e2                	ld	ra,24(sp)
    80004610:	6442                	ld	s0,16(sp)
    80004612:	64a2                	ld	s1,8(sp)
    80004614:	6902                	ld	s2,0(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret

000000008000461a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000461a:	1101                	addi	sp,sp,-32
    8000461c:	ec06                	sd	ra,24(sp)
    8000461e:	e822                	sd	s0,16(sp)
    80004620:	e426                	sd	s1,8(sp)
    80004622:	e04a                	sd	s2,0(sp)
    80004624:	1000                	addi	s0,sp,32
    80004626:	84aa                	mv	s1,a0
    80004628:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000462a:	00004597          	auipc	a1,0x4
    8000462e:	05658593          	addi	a1,a1,86 # 80008680 <syscalls+0x248>
    80004632:	0521                	addi	a0,a0,8
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	64a080e7          	jalr	1610(ra) # 80000c7e <initlock>
  lk->name = name;
    8000463c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004640:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004644:	0204a423          	sw	zero,40(s1)
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004654:	1101                	addi	sp,sp,-32
    80004656:	ec06                	sd	ra,24(sp)
    80004658:	e822                	sd	s0,16(sp)
    8000465a:	e426                	sd	s1,8(sp)
    8000465c:	e04a                	sd	s2,0(sp)
    8000465e:	1000                	addi	s0,sp,32
    80004660:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004662:	00850913          	addi	s2,a0,8
    80004666:	854a                	mv	a0,s2
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	6a6080e7          	jalr	1702(ra) # 80000d0e <acquire>
  while (lk->locked) {
    80004670:	409c                	lw	a5,0(s1)
    80004672:	cb89                	beqz	a5,80004684 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004674:	85ca                	mv	a1,s2
    80004676:	8526                	mv	a0,s1
    80004678:	ffffe097          	auipc	ra,0xffffe
    8000467c:	c90080e7          	jalr	-880(ra) # 80002308 <sleep>
  while (lk->locked) {
    80004680:	409c                	lw	a5,0(s1)
    80004682:	fbed                	bnez	a5,80004674 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004684:	4785                	li	a5,1
    80004686:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004688:	ffffd097          	auipc	ra,0xffffd
    8000468c:	470080e7          	jalr	1136(ra) # 80001af8 <myproc>
    80004690:	5d1c                	lw	a5,56(a0)
    80004692:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004694:	854a                	mv	a0,s2
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	72c080e7          	jalr	1836(ra) # 80000dc2 <release>
}
    8000469e:	60e2                	ld	ra,24(sp)
    800046a0:	6442                	ld	s0,16(sp)
    800046a2:	64a2                	ld	s1,8(sp)
    800046a4:	6902                	ld	s2,0(sp)
    800046a6:	6105                	addi	sp,sp,32
    800046a8:	8082                	ret

00000000800046aa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046aa:	1101                	addi	sp,sp,-32
    800046ac:	ec06                	sd	ra,24(sp)
    800046ae:	e822                	sd	s0,16(sp)
    800046b0:	e426                	sd	s1,8(sp)
    800046b2:	e04a                	sd	s2,0(sp)
    800046b4:	1000                	addi	s0,sp,32
    800046b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046b8:	00850913          	addi	s2,a0,8
    800046bc:	854a                	mv	a0,s2
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	650080e7          	jalr	1616(ra) # 80000d0e <acquire>
  lk->locked = 0;
    800046c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ca:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046ce:	8526                	mv	a0,s1
    800046d0:	ffffe097          	auipc	ra,0xffffe
    800046d4:	dbe080e7          	jalr	-578(ra) # 8000248e <wakeup>
  release(&lk->lk);
    800046d8:	854a                	mv	a0,s2
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	6e8080e7          	jalr	1768(ra) # 80000dc2 <release>
}
    800046e2:	60e2                	ld	ra,24(sp)
    800046e4:	6442                	ld	s0,16(sp)
    800046e6:	64a2                	ld	s1,8(sp)
    800046e8:	6902                	ld	s2,0(sp)
    800046ea:	6105                	addi	sp,sp,32
    800046ec:	8082                	ret

00000000800046ee <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046ee:	7179                	addi	sp,sp,-48
    800046f0:	f406                	sd	ra,40(sp)
    800046f2:	f022                	sd	s0,32(sp)
    800046f4:	ec26                	sd	s1,24(sp)
    800046f6:	e84a                	sd	s2,16(sp)
    800046f8:	e44e                	sd	s3,8(sp)
    800046fa:	1800                	addi	s0,sp,48
    800046fc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046fe:	00850913          	addi	s2,a0,8
    80004702:	854a                	mv	a0,s2
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	60a080e7          	jalr	1546(ra) # 80000d0e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000470c:	409c                	lw	a5,0(s1)
    8000470e:	ef99                	bnez	a5,8000472c <holdingsleep+0x3e>
    80004710:	4481                	li	s1,0
  release(&lk->lk);
    80004712:	854a                	mv	a0,s2
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	6ae080e7          	jalr	1710(ra) # 80000dc2 <release>
  return r;
}
    8000471c:	8526                	mv	a0,s1
    8000471e:	70a2                	ld	ra,40(sp)
    80004720:	7402                	ld	s0,32(sp)
    80004722:	64e2                	ld	s1,24(sp)
    80004724:	6942                	ld	s2,16(sp)
    80004726:	69a2                	ld	s3,8(sp)
    80004728:	6145                	addi	sp,sp,48
    8000472a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000472c:	0284a983          	lw	s3,40(s1)
    80004730:	ffffd097          	auipc	ra,0xffffd
    80004734:	3c8080e7          	jalr	968(ra) # 80001af8 <myproc>
    80004738:	5d04                	lw	s1,56(a0)
    8000473a:	413484b3          	sub	s1,s1,s3
    8000473e:	0014b493          	seqz	s1,s1
    80004742:	bfc1                	j	80004712 <holdingsleep+0x24>

0000000080004744 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004744:	1141                	addi	sp,sp,-16
    80004746:	e406                	sd	ra,8(sp)
    80004748:	e022                	sd	s0,0(sp)
    8000474a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000474c:	00004597          	auipc	a1,0x4
    80004750:	f4458593          	addi	a1,a1,-188 # 80008690 <syscalls+0x258>
    80004754:	0001b517          	auipc	a0,0x1b
    80004758:	7ec50513          	addi	a0,a0,2028 # 8001ff40 <ftable>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	522080e7          	jalr	1314(ra) # 80000c7e <initlock>
}
    80004764:	60a2                	ld	ra,8(sp)
    80004766:	6402                	ld	s0,0(sp)
    80004768:	0141                	addi	sp,sp,16
    8000476a:	8082                	ret

000000008000476c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000476c:	1101                	addi	sp,sp,-32
    8000476e:	ec06                	sd	ra,24(sp)
    80004770:	e822                	sd	s0,16(sp)
    80004772:	e426                	sd	s1,8(sp)
    80004774:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004776:	0001b517          	auipc	a0,0x1b
    8000477a:	7ca50513          	addi	a0,a0,1994 # 8001ff40 <ftable>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	590080e7          	jalr	1424(ra) # 80000d0e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004786:	0001b497          	auipc	s1,0x1b
    8000478a:	7d248493          	addi	s1,s1,2002 # 8001ff58 <ftable+0x18>
    8000478e:	0001c717          	auipc	a4,0x1c
    80004792:	76a70713          	addi	a4,a4,1898 # 80020ef8 <ftable+0xfb8>
    if(f->ref == 0){
    80004796:	40dc                	lw	a5,4(s1)
    80004798:	cf99                	beqz	a5,800047b6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000479a:	02848493          	addi	s1,s1,40
    8000479e:	fee49ce3          	bne	s1,a4,80004796 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047a2:	0001b517          	auipc	a0,0x1b
    800047a6:	79e50513          	addi	a0,a0,1950 # 8001ff40 <ftable>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	618080e7          	jalr	1560(ra) # 80000dc2 <release>
  return 0;
    800047b2:	4481                	li	s1,0
    800047b4:	a819                	j	800047ca <filealloc+0x5e>
      f->ref = 1;
    800047b6:	4785                	li	a5,1
    800047b8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047ba:	0001b517          	auipc	a0,0x1b
    800047be:	78650513          	addi	a0,a0,1926 # 8001ff40 <ftable>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	600080e7          	jalr	1536(ra) # 80000dc2 <release>
}
    800047ca:	8526                	mv	a0,s1
    800047cc:	60e2                	ld	ra,24(sp)
    800047ce:	6442                	ld	s0,16(sp)
    800047d0:	64a2                	ld	s1,8(sp)
    800047d2:	6105                	addi	sp,sp,32
    800047d4:	8082                	ret

00000000800047d6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047d6:	1101                	addi	sp,sp,-32
    800047d8:	ec06                	sd	ra,24(sp)
    800047da:	e822                	sd	s0,16(sp)
    800047dc:	e426                	sd	s1,8(sp)
    800047de:	1000                	addi	s0,sp,32
    800047e0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047e2:	0001b517          	auipc	a0,0x1b
    800047e6:	75e50513          	addi	a0,a0,1886 # 8001ff40 <ftable>
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	524080e7          	jalr	1316(ra) # 80000d0e <acquire>
  if(f->ref < 1)
    800047f2:	40dc                	lw	a5,4(s1)
    800047f4:	02f05263          	blez	a5,80004818 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047f8:	2785                	addiw	a5,a5,1
    800047fa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047fc:	0001b517          	auipc	a0,0x1b
    80004800:	74450513          	addi	a0,a0,1860 # 8001ff40 <ftable>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	5be080e7          	jalr	1470(ra) # 80000dc2 <release>
  return f;
}
    8000480c:	8526                	mv	a0,s1
    8000480e:	60e2                	ld	ra,24(sp)
    80004810:	6442                	ld	s0,16(sp)
    80004812:	64a2                	ld	s1,8(sp)
    80004814:	6105                	addi	sp,sp,32
    80004816:	8082                	ret
    panic("filedup");
    80004818:	00004517          	auipc	a0,0x4
    8000481c:	e8050513          	addi	a0,a0,-384 # 80008698 <syscalls+0x260>
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	d10080e7          	jalr	-752(ra) # 80000530 <panic>

0000000080004828 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004828:	7139                	addi	sp,sp,-64
    8000482a:	fc06                	sd	ra,56(sp)
    8000482c:	f822                	sd	s0,48(sp)
    8000482e:	f426                	sd	s1,40(sp)
    80004830:	f04a                	sd	s2,32(sp)
    80004832:	ec4e                	sd	s3,24(sp)
    80004834:	e852                	sd	s4,16(sp)
    80004836:	e456                	sd	s5,8(sp)
    80004838:	0080                	addi	s0,sp,64
    8000483a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000483c:	0001b517          	auipc	a0,0x1b
    80004840:	70450513          	addi	a0,a0,1796 # 8001ff40 <ftable>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	4ca080e7          	jalr	1226(ra) # 80000d0e <acquire>
  if(f->ref < 1)
    8000484c:	40dc                	lw	a5,4(s1)
    8000484e:	06f05163          	blez	a5,800048b0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004852:	37fd                	addiw	a5,a5,-1
    80004854:	0007871b          	sext.w	a4,a5
    80004858:	c0dc                	sw	a5,4(s1)
    8000485a:	06e04363          	bgtz	a4,800048c0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000485e:	0004a903          	lw	s2,0(s1)
    80004862:	0094ca83          	lbu	s5,9(s1)
    80004866:	0104ba03          	ld	s4,16(s1)
    8000486a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000486e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004872:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004876:	0001b517          	auipc	a0,0x1b
    8000487a:	6ca50513          	addi	a0,a0,1738 # 8001ff40 <ftable>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	544080e7          	jalr	1348(ra) # 80000dc2 <release>

  if(ff.type == FD_PIPE){
    80004886:	4785                	li	a5,1
    80004888:	04f90d63          	beq	s2,a5,800048e2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000488c:	3979                	addiw	s2,s2,-2
    8000488e:	4785                	li	a5,1
    80004890:	0527e063          	bltu	a5,s2,800048d0 <fileclose+0xa8>
    begin_op();
    80004894:	00000097          	auipc	ra,0x0
    80004898:	ac0080e7          	jalr	-1344(ra) # 80004354 <begin_op>
    iput(ff.ip);
    8000489c:	854e                	mv	a0,s3
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	29c080e7          	jalr	668(ra) # 80003b3a <iput>
    end_op();
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	b2e080e7          	jalr	-1234(ra) # 800043d4 <end_op>
    800048ae:	a00d                	j	800048d0 <fileclose+0xa8>
    panic("fileclose");
    800048b0:	00004517          	auipc	a0,0x4
    800048b4:	df050513          	addi	a0,a0,-528 # 800086a0 <syscalls+0x268>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	c78080e7          	jalr	-904(ra) # 80000530 <panic>
    release(&ftable.lock);
    800048c0:	0001b517          	auipc	a0,0x1b
    800048c4:	68050513          	addi	a0,a0,1664 # 8001ff40 <ftable>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	4fa080e7          	jalr	1274(ra) # 80000dc2 <release>
  }
}
    800048d0:	70e2                	ld	ra,56(sp)
    800048d2:	7442                	ld	s0,48(sp)
    800048d4:	74a2                	ld	s1,40(sp)
    800048d6:	7902                	ld	s2,32(sp)
    800048d8:	69e2                	ld	s3,24(sp)
    800048da:	6a42                	ld	s4,16(sp)
    800048dc:	6aa2                	ld	s5,8(sp)
    800048de:	6121                	addi	sp,sp,64
    800048e0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048e2:	85d6                	mv	a1,s5
    800048e4:	8552                	mv	a0,s4
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	34c080e7          	jalr	844(ra) # 80004c32 <pipeclose>
    800048ee:	b7cd                	j	800048d0 <fileclose+0xa8>

00000000800048f0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048f0:	715d                	addi	sp,sp,-80
    800048f2:	e486                	sd	ra,72(sp)
    800048f4:	e0a2                	sd	s0,64(sp)
    800048f6:	fc26                	sd	s1,56(sp)
    800048f8:	f84a                	sd	s2,48(sp)
    800048fa:	f44e                	sd	s3,40(sp)
    800048fc:	0880                	addi	s0,sp,80
    800048fe:	84aa                	mv	s1,a0
    80004900:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004902:	ffffd097          	auipc	ra,0xffffd
    80004906:	1f6080e7          	jalr	502(ra) # 80001af8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000490a:	409c                	lw	a5,0(s1)
    8000490c:	37f9                	addiw	a5,a5,-2
    8000490e:	4705                	li	a4,1
    80004910:	04f76763          	bltu	a4,a5,8000495e <filestat+0x6e>
    80004914:	892a                	mv	s2,a0
    ilock(f->ip);
    80004916:	6c88                	ld	a0,24(s1)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	068080e7          	jalr	104(ra) # 80003980 <ilock>
    stati(f->ip, &st);
    80004920:	fb840593          	addi	a1,s0,-72
    80004924:	6c88                	ld	a0,24(s1)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	2e4080e7          	jalr	740(ra) # 80003c0a <stati>
    iunlock(f->ip);
    8000492e:	6c88                	ld	a0,24(s1)
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	112080e7          	jalr	274(ra) # 80003a42 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004938:	46e1                	li	a3,24
    8000493a:	fb840613          	addi	a2,s0,-72
    8000493e:	85ce                	mv	a1,s3
    80004940:	05093503          	ld	a0,80(s2)
    80004944:	ffffd097          	auipc	ra,0xffffd
    80004948:	e4a080e7          	jalr	-438(ra) # 8000178e <copyout>
    8000494c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004950:	60a6                	ld	ra,72(sp)
    80004952:	6406                	ld	s0,64(sp)
    80004954:	74e2                	ld	s1,56(sp)
    80004956:	7942                	ld	s2,48(sp)
    80004958:	79a2                	ld	s3,40(sp)
    8000495a:	6161                	addi	sp,sp,80
    8000495c:	8082                	ret
  return -1;
    8000495e:	557d                	li	a0,-1
    80004960:	bfc5                	j	80004950 <filestat+0x60>

0000000080004962 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004962:	7179                	addi	sp,sp,-48
    80004964:	f406                	sd	ra,40(sp)
    80004966:	f022                	sd	s0,32(sp)
    80004968:	ec26                	sd	s1,24(sp)
    8000496a:	e84a                	sd	s2,16(sp)
    8000496c:	e44e                	sd	s3,8(sp)
    8000496e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004970:	00854783          	lbu	a5,8(a0)
    80004974:	c3d5                	beqz	a5,80004a18 <fileread+0xb6>
    80004976:	84aa                	mv	s1,a0
    80004978:	89ae                	mv	s3,a1
    8000497a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000497c:	411c                	lw	a5,0(a0)
    8000497e:	4705                	li	a4,1
    80004980:	04e78963          	beq	a5,a4,800049d2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004984:	470d                	li	a4,3
    80004986:	04e78d63          	beq	a5,a4,800049e0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000498a:	4709                	li	a4,2
    8000498c:	06e79e63          	bne	a5,a4,80004a08 <fileread+0xa6>
    ilock(f->ip);
    80004990:	6d08                	ld	a0,24(a0)
    80004992:	fffff097          	auipc	ra,0xfffff
    80004996:	fee080e7          	jalr	-18(ra) # 80003980 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000499a:	874a                	mv	a4,s2
    8000499c:	5094                	lw	a3,32(s1)
    8000499e:	864e                	mv	a2,s3
    800049a0:	4585                	li	a1,1
    800049a2:	6c88                	ld	a0,24(s1)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	290080e7          	jalr	656(ra) # 80003c34 <readi>
    800049ac:	892a                	mv	s2,a0
    800049ae:	00a05563          	blez	a0,800049b8 <fileread+0x56>
      f->off += r;
    800049b2:	509c                	lw	a5,32(s1)
    800049b4:	9fa9                	addw	a5,a5,a0
    800049b6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049b8:	6c88                	ld	a0,24(s1)
    800049ba:	fffff097          	auipc	ra,0xfffff
    800049be:	088080e7          	jalr	136(ra) # 80003a42 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049c2:	854a                	mv	a0,s2
    800049c4:	70a2                	ld	ra,40(sp)
    800049c6:	7402                	ld	s0,32(sp)
    800049c8:	64e2                	ld	s1,24(sp)
    800049ca:	6942                	ld	s2,16(sp)
    800049cc:	69a2                	ld	s3,8(sp)
    800049ce:	6145                	addi	sp,sp,48
    800049d0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049d2:	6908                	ld	a0,16(a0)
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	3c8080e7          	jalr	968(ra) # 80004d9c <piperead>
    800049dc:	892a                	mv	s2,a0
    800049de:	b7d5                	j	800049c2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049e0:	02451783          	lh	a5,36(a0)
    800049e4:	03079693          	slli	a3,a5,0x30
    800049e8:	92c1                	srli	a3,a3,0x30
    800049ea:	4725                	li	a4,9
    800049ec:	02d76863          	bltu	a4,a3,80004a1c <fileread+0xba>
    800049f0:	0792                	slli	a5,a5,0x4
    800049f2:	0001b717          	auipc	a4,0x1b
    800049f6:	4ae70713          	addi	a4,a4,1198 # 8001fea0 <devsw>
    800049fa:	97ba                	add	a5,a5,a4
    800049fc:	639c                	ld	a5,0(a5)
    800049fe:	c38d                	beqz	a5,80004a20 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a00:	4505                	li	a0,1
    80004a02:	9782                	jalr	a5
    80004a04:	892a                	mv	s2,a0
    80004a06:	bf75                	j	800049c2 <fileread+0x60>
    panic("fileread");
    80004a08:	00004517          	auipc	a0,0x4
    80004a0c:	ca850513          	addi	a0,a0,-856 # 800086b0 <syscalls+0x278>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	b20080e7          	jalr	-1248(ra) # 80000530 <panic>
    return -1;
    80004a18:	597d                	li	s2,-1
    80004a1a:	b765                	j	800049c2 <fileread+0x60>
      return -1;
    80004a1c:	597d                	li	s2,-1
    80004a1e:	b755                	j	800049c2 <fileread+0x60>
    80004a20:	597d                	li	s2,-1
    80004a22:	b745                	j	800049c2 <fileread+0x60>

0000000080004a24 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a24:	715d                	addi	sp,sp,-80
    80004a26:	e486                	sd	ra,72(sp)
    80004a28:	e0a2                	sd	s0,64(sp)
    80004a2a:	fc26                	sd	s1,56(sp)
    80004a2c:	f84a                	sd	s2,48(sp)
    80004a2e:	f44e                	sd	s3,40(sp)
    80004a30:	f052                	sd	s4,32(sp)
    80004a32:	ec56                	sd	s5,24(sp)
    80004a34:	e85a                	sd	s6,16(sp)
    80004a36:	e45e                	sd	s7,8(sp)
    80004a38:	e062                	sd	s8,0(sp)
    80004a3a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a3c:	00954783          	lbu	a5,9(a0)
    80004a40:	10078663          	beqz	a5,80004b4c <filewrite+0x128>
    80004a44:	892a                	mv	s2,a0
    80004a46:	8aae                	mv	s5,a1
    80004a48:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a4a:	411c                	lw	a5,0(a0)
    80004a4c:	4705                	li	a4,1
    80004a4e:	02e78263          	beq	a5,a4,80004a72 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a52:	470d                	li	a4,3
    80004a54:	02e78663          	beq	a5,a4,80004a80 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a58:	4709                	li	a4,2
    80004a5a:	0ee79163          	bne	a5,a4,80004b3c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a5e:	0ac05d63          	blez	a2,80004b18 <filewrite+0xf4>
    int i = 0;
    80004a62:	4981                	li	s3,0
    80004a64:	6b05                	lui	s6,0x1
    80004a66:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a6a:	6b85                	lui	s7,0x1
    80004a6c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a70:	a861                	j	80004b08 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a72:	6908                	ld	a0,16(a0)
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	22e080e7          	jalr	558(ra) # 80004ca2 <pipewrite>
    80004a7c:	8a2a                	mv	s4,a0
    80004a7e:	a045                	j	80004b1e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a80:	02451783          	lh	a5,36(a0)
    80004a84:	03079693          	slli	a3,a5,0x30
    80004a88:	92c1                	srli	a3,a3,0x30
    80004a8a:	4725                	li	a4,9
    80004a8c:	0cd76263          	bltu	a4,a3,80004b50 <filewrite+0x12c>
    80004a90:	0792                	slli	a5,a5,0x4
    80004a92:	0001b717          	auipc	a4,0x1b
    80004a96:	40e70713          	addi	a4,a4,1038 # 8001fea0 <devsw>
    80004a9a:	97ba                	add	a5,a5,a4
    80004a9c:	679c                	ld	a5,8(a5)
    80004a9e:	cbdd                	beqz	a5,80004b54 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004aa0:	4505                	li	a0,1
    80004aa2:	9782                	jalr	a5
    80004aa4:	8a2a                	mv	s4,a0
    80004aa6:	a8a5                	j	80004b1e <filewrite+0xfa>
    80004aa8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	8a8080e7          	jalr	-1880(ra) # 80004354 <begin_op>
      ilock(f->ip);
    80004ab4:	01893503          	ld	a0,24(s2)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	ec8080e7          	jalr	-312(ra) # 80003980 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ac0:	8762                	mv	a4,s8
    80004ac2:	02092683          	lw	a3,32(s2)
    80004ac6:	01598633          	add	a2,s3,s5
    80004aca:	4585                	li	a1,1
    80004acc:	01893503          	ld	a0,24(s2)
    80004ad0:	fffff097          	auipc	ra,0xfffff
    80004ad4:	25c080e7          	jalr	604(ra) # 80003d2c <writei>
    80004ad8:	84aa                	mv	s1,a0
    80004ada:	00a05763          	blez	a0,80004ae8 <filewrite+0xc4>
        f->off += r;
    80004ade:	02092783          	lw	a5,32(s2)
    80004ae2:	9fa9                	addw	a5,a5,a0
    80004ae4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ae8:	01893503          	ld	a0,24(s2)
    80004aec:	fffff097          	auipc	ra,0xfffff
    80004af0:	f56080e7          	jalr	-170(ra) # 80003a42 <iunlock>
      end_op();
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	8e0080e7          	jalr	-1824(ra) # 800043d4 <end_op>

      if(r != n1){
    80004afc:	009c1f63          	bne	s8,s1,80004b1a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b00:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b04:	0149db63          	bge	s3,s4,80004b1a <filewrite+0xf6>
      int n1 = n - i;
    80004b08:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b0c:	84be                	mv	s1,a5
    80004b0e:	2781                	sext.w	a5,a5
    80004b10:	f8fb5ce3          	bge	s6,a5,80004aa8 <filewrite+0x84>
    80004b14:	84de                	mv	s1,s7
    80004b16:	bf49                	j	80004aa8 <filewrite+0x84>
    int i = 0;
    80004b18:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b1a:	013a1f63          	bne	s4,s3,80004b38 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b1e:	8552                	mv	a0,s4
    80004b20:	60a6                	ld	ra,72(sp)
    80004b22:	6406                	ld	s0,64(sp)
    80004b24:	74e2                	ld	s1,56(sp)
    80004b26:	7942                	ld	s2,48(sp)
    80004b28:	79a2                	ld	s3,40(sp)
    80004b2a:	7a02                	ld	s4,32(sp)
    80004b2c:	6ae2                	ld	s5,24(sp)
    80004b2e:	6b42                	ld	s6,16(sp)
    80004b30:	6ba2                	ld	s7,8(sp)
    80004b32:	6c02                	ld	s8,0(sp)
    80004b34:	6161                	addi	sp,sp,80
    80004b36:	8082                	ret
    ret = (i == n ? n : -1);
    80004b38:	5a7d                	li	s4,-1
    80004b3a:	b7d5                	j	80004b1e <filewrite+0xfa>
    panic("filewrite");
    80004b3c:	00004517          	auipc	a0,0x4
    80004b40:	b8450513          	addi	a0,a0,-1148 # 800086c0 <syscalls+0x288>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	9ec080e7          	jalr	-1556(ra) # 80000530 <panic>
    return -1;
    80004b4c:	5a7d                	li	s4,-1
    80004b4e:	bfc1                	j	80004b1e <filewrite+0xfa>
      return -1;
    80004b50:	5a7d                	li	s4,-1
    80004b52:	b7f1                	j	80004b1e <filewrite+0xfa>
    80004b54:	5a7d                	li	s4,-1
    80004b56:	b7e1                	j	80004b1e <filewrite+0xfa>

0000000080004b58 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b58:	7179                	addi	sp,sp,-48
    80004b5a:	f406                	sd	ra,40(sp)
    80004b5c:	f022                	sd	s0,32(sp)
    80004b5e:	ec26                	sd	s1,24(sp)
    80004b60:	e84a                	sd	s2,16(sp)
    80004b62:	e44e                	sd	s3,8(sp)
    80004b64:	e052                	sd	s4,0(sp)
    80004b66:	1800                	addi	s0,sp,48
    80004b68:	84aa                	mv	s1,a0
    80004b6a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b6c:	0005b023          	sd	zero,0(a1)
    80004b70:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	bf8080e7          	jalr	-1032(ra) # 8000476c <filealloc>
    80004b7c:	e088                	sd	a0,0(s1)
    80004b7e:	c551                	beqz	a0,80004c0a <pipealloc+0xb2>
    80004b80:	00000097          	auipc	ra,0x0
    80004b84:	bec080e7          	jalr	-1044(ra) # 8000476c <filealloc>
    80004b88:	00aa3023          	sd	a0,0(s4)
    80004b8c:	c92d                	beqz	a0,80004bfe <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	ff6080e7          	jalr	-10(ra) # 80000b84 <kalloc>
    80004b96:	892a                	mv	s2,a0
    80004b98:	c125                	beqz	a0,80004bf8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b9a:	4985                	li	s3,1
    80004b9c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ba0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ba4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ba8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bac:	00004597          	auipc	a1,0x4
    80004bb0:	b2458593          	addi	a1,a1,-1244 # 800086d0 <syscalls+0x298>
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	0ca080e7          	jalr	202(ra) # 80000c7e <initlock>
  (*f0)->type = FD_PIPE;
    80004bbc:	609c                	ld	a5,0(s1)
    80004bbe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bc2:	609c                	ld	a5,0(s1)
    80004bc4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bc8:	609c                	ld	a5,0(s1)
    80004bca:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bce:	609c                	ld	a5,0(s1)
    80004bd0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bd4:	000a3783          	ld	a5,0(s4)
    80004bd8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bdc:	000a3783          	ld	a5,0(s4)
    80004be0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004be4:	000a3783          	ld	a5,0(s4)
    80004be8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bec:	000a3783          	ld	a5,0(s4)
    80004bf0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bf4:	4501                	li	a0,0
    80004bf6:	a025                	j	80004c1e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bf8:	6088                	ld	a0,0(s1)
    80004bfa:	e501                	bnez	a0,80004c02 <pipealloc+0xaa>
    80004bfc:	a039                	j	80004c0a <pipealloc+0xb2>
    80004bfe:	6088                	ld	a0,0(s1)
    80004c00:	c51d                	beqz	a0,80004c2e <pipealloc+0xd6>
    fileclose(*f0);
    80004c02:	00000097          	auipc	ra,0x0
    80004c06:	c26080e7          	jalr	-986(ra) # 80004828 <fileclose>
  if(*f1)
    80004c0a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c0e:	557d                	li	a0,-1
  if(*f1)
    80004c10:	c799                	beqz	a5,80004c1e <pipealloc+0xc6>
    fileclose(*f1);
    80004c12:	853e                	mv	a0,a5
    80004c14:	00000097          	auipc	ra,0x0
    80004c18:	c14080e7          	jalr	-1004(ra) # 80004828 <fileclose>
  return -1;
    80004c1c:	557d                	li	a0,-1
}
    80004c1e:	70a2                	ld	ra,40(sp)
    80004c20:	7402                	ld	s0,32(sp)
    80004c22:	64e2                	ld	s1,24(sp)
    80004c24:	6942                	ld	s2,16(sp)
    80004c26:	69a2                	ld	s3,8(sp)
    80004c28:	6a02                	ld	s4,0(sp)
    80004c2a:	6145                	addi	sp,sp,48
    80004c2c:	8082                	ret
  return -1;
    80004c2e:	557d                	li	a0,-1
    80004c30:	b7fd                	j	80004c1e <pipealloc+0xc6>

0000000080004c32 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c32:	1101                	addi	sp,sp,-32
    80004c34:	ec06                	sd	ra,24(sp)
    80004c36:	e822                	sd	s0,16(sp)
    80004c38:	e426                	sd	s1,8(sp)
    80004c3a:	e04a                	sd	s2,0(sp)
    80004c3c:	1000                	addi	s0,sp,32
    80004c3e:	84aa                	mv	s1,a0
    80004c40:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	0cc080e7          	jalr	204(ra) # 80000d0e <acquire>
  if(writable){
    80004c4a:	02090d63          	beqz	s2,80004c84 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c4e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c52:	21848513          	addi	a0,s1,536
    80004c56:	ffffe097          	auipc	ra,0xffffe
    80004c5a:	838080e7          	jalr	-1992(ra) # 8000248e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c5e:	2204b783          	ld	a5,544(s1)
    80004c62:	eb95                	bnez	a5,80004c96 <pipeclose+0x64>
    release(&pi->lock);
    80004c64:	8526                	mv	a0,s1
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	15c080e7          	jalr	348(ra) # 80000dc2 <release>
    kfree((char*)pi);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	d7a080e7          	jalr	-646(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004c78:	60e2                	ld	ra,24(sp)
    80004c7a:	6442                	ld	s0,16(sp)
    80004c7c:	64a2                	ld	s1,8(sp)
    80004c7e:	6902                	ld	s2,0(sp)
    80004c80:	6105                	addi	sp,sp,32
    80004c82:	8082                	ret
    pi->readopen = 0;
    80004c84:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c88:	21c48513          	addi	a0,s1,540
    80004c8c:	ffffe097          	auipc	ra,0xffffe
    80004c90:	802080e7          	jalr	-2046(ra) # 8000248e <wakeup>
    80004c94:	b7e9                	j	80004c5e <pipeclose+0x2c>
    release(&pi->lock);
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	12a080e7          	jalr	298(ra) # 80000dc2 <release>
}
    80004ca0:	bfe1                	j	80004c78 <pipeclose+0x46>

0000000080004ca2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ca2:	7159                	addi	sp,sp,-112
    80004ca4:	f486                	sd	ra,104(sp)
    80004ca6:	f0a2                	sd	s0,96(sp)
    80004ca8:	eca6                	sd	s1,88(sp)
    80004caa:	e8ca                	sd	s2,80(sp)
    80004cac:	e4ce                	sd	s3,72(sp)
    80004cae:	e0d2                	sd	s4,64(sp)
    80004cb0:	fc56                	sd	s5,56(sp)
    80004cb2:	f85a                	sd	s6,48(sp)
    80004cb4:	f45e                	sd	s7,40(sp)
    80004cb6:	f062                	sd	s8,32(sp)
    80004cb8:	ec66                	sd	s9,24(sp)
    80004cba:	1880                	addi	s0,sp,112
    80004cbc:	84aa                	mv	s1,a0
    80004cbe:	8aae                	mv	s5,a1
    80004cc0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	e36080e7          	jalr	-458(ra) # 80001af8 <myproc>
    80004cca:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ccc:	8526                	mv	a0,s1
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	040080e7          	jalr	64(ra) # 80000d0e <acquire>
  while(i < n){
    80004cd6:	0d405163          	blez	s4,80004d98 <pipewrite+0xf6>
    80004cda:	8ba6                	mv	s7,s1
  int i = 0;
    80004cdc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cde:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ce0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ce4:	21c48c13          	addi	s8,s1,540
    80004ce8:	a08d                	j	80004d4a <pipewrite+0xa8>
      release(&pi->lock);
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	0d6080e7          	jalr	214(ra) # 80000dc2 <release>
      return -1;
    80004cf4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cf6:	854a                	mv	a0,s2
    80004cf8:	70a6                	ld	ra,104(sp)
    80004cfa:	7406                	ld	s0,96(sp)
    80004cfc:	64e6                	ld	s1,88(sp)
    80004cfe:	6946                	ld	s2,80(sp)
    80004d00:	69a6                	ld	s3,72(sp)
    80004d02:	6a06                	ld	s4,64(sp)
    80004d04:	7ae2                	ld	s5,56(sp)
    80004d06:	7b42                	ld	s6,48(sp)
    80004d08:	7ba2                	ld	s7,40(sp)
    80004d0a:	7c02                	ld	s8,32(sp)
    80004d0c:	6ce2                	ld	s9,24(sp)
    80004d0e:	6165                	addi	sp,sp,112
    80004d10:	8082                	ret
      wakeup(&pi->nread);
    80004d12:	8566                	mv	a0,s9
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	77a080e7          	jalr	1914(ra) # 8000248e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d1c:	85de                	mv	a1,s7
    80004d1e:	8562                	mv	a0,s8
    80004d20:	ffffd097          	auipc	ra,0xffffd
    80004d24:	5e8080e7          	jalr	1512(ra) # 80002308 <sleep>
    80004d28:	a839                	j	80004d46 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d2a:	21c4a783          	lw	a5,540(s1)
    80004d2e:	0017871b          	addiw	a4,a5,1
    80004d32:	20e4ae23          	sw	a4,540(s1)
    80004d36:	1ff7f793          	andi	a5,a5,511
    80004d3a:	97a6                	add	a5,a5,s1
    80004d3c:	f9f44703          	lbu	a4,-97(s0)
    80004d40:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d44:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d46:	03495d63          	bge	s2,s4,80004d80 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d4a:	2204a783          	lw	a5,544(s1)
    80004d4e:	dfd1                	beqz	a5,80004cea <pipewrite+0x48>
    80004d50:	0309a783          	lw	a5,48(s3)
    80004d54:	fbd9                	bnez	a5,80004cea <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d56:	2184a783          	lw	a5,536(s1)
    80004d5a:	21c4a703          	lw	a4,540(s1)
    80004d5e:	2007879b          	addiw	a5,a5,512
    80004d62:	faf708e3          	beq	a4,a5,80004d12 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d66:	4685                	li	a3,1
    80004d68:	01590633          	add	a2,s2,s5
    80004d6c:	f9f40593          	addi	a1,s0,-97
    80004d70:	0509b503          	ld	a0,80(s3)
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	aa6080e7          	jalr	-1370(ra) # 8000181a <copyin>
    80004d7c:	fb6517e3          	bne	a0,s6,80004d2a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d80:	21848513          	addi	a0,s1,536
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	70a080e7          	jalr	1802(ra) # 8000248e <wakeup>
  release(&pi->lock);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	034080e7          	jalr	52(ra) # 80000dc2 <release>
  return i;
    80004d96:	b785                	j	80004cf6 <pipewrite+0x54>
  int i = 0;
    80004d98:	4901                	li	s2,0
    80004d9a:	b7dd                	j	80004d80 <pipewrite+0xde>

0000000080004d9c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d9c:	715d                	addi	sp,sp,-80
    80004d9e:	e486                	sd	ra,72(sp)
    80004da0:	e0a2                	sd	s0,64(sp)
    80004da2:	fc26                	sd	s1,56(sp)
    80004da4:	f84a                	sd	s2,48(sp)
    80004da6:	f44e                	sd	s3,40(sp)
    80004da8:	f052                	sd	s4,32(sp)
    80004daa:	ec56                	sd	s5,24(sp)
    80004dac:	e85a                	sd	s6,16(sp)
    80004dae:	0880                	addi	s0,sp,80
    80004db0:	84aa                	mv	s1,a0
    80004db2:	892e                	mv	s2,a1
    80004db4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	d42080e7          	jalr	-702(ra) # 80001af8 <myproc>
    80004dbe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dc0:	8b26                	mv	s6,s1
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	f4a080e7          	jalr	-182(ra) # 80000d0e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dcc:	2184a703          	lw	a4,536(s1)
    80004dd0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dd8:	02f71463          	bne	a4,a5,80004e00 <piperead+0x64>
    80004ddc:	2244a783          	lw	a5,548(s1)
    80004de0:	c385                	beqz	a5,80004e00 <piperead+0x64>
    if(pr->killed){
    80004de2:	030a2783          	lw	a5,48(s4)
    80004de6:	ebc1                	bnez	a5,80004e76 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004de8:	85da                	mv	a1,s6
    80004dea:	854e                	mv	a0,s3
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	51c080e7          	jalr	1308(ra) # 80002308 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df4:	2184a703          	lw	a4,536(s1)
    80004df8:	21c4a783          	lw	a5,540(s1)
    80004dfc:	fef700e3          	beq	a4,a5,80004ddc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e00:	09505263          	blez	s5,80004e84 <piperead+0xe8>
    80004e04:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e06:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e08:	2184a783          	lw	a5,536(s1)
    80004e0c:	21c4a703          	lw	a4,540(s1)
    80004e10:	02f70d63          	beq	a4,a5,80004e4a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e14:	0017871b          	addiw	a4,a5,1
    80004e18:	20e4ac23          	sw	a4,536(s1)
    80004e1c:	1ff7f793          	andi	a5,a5,511
    80004e20:	97a6                	add	a5,a5,s1
    80004e22:	0187c783          	lbu	a5,24(a5)
    80004e26:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e2a:	4685                	li	a3,1
    80004e2c:	fbf40613          	addi	a2,s0,-65
    80004e30:	85ca                	mv	a1,s2
    80004e32:	050a3503          	ld	a0,80(s4)
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	958080e7          	jalr	-1704(ra) # 8000178e <copyout>
    80004e3e:	01650663          	beq	a0,s6,80004e4a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e42:	2985                	addiw	s3,s3,1
    80004e44:	0905                	addi	s2,s2,1
    80004e46:	fd3a91e3          	bne	s5,s3,80004e08 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e4a:	21c48513          	addi	a0,s1,540
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	640080e7          	jalr	1600(ra) # 8000248e <wakeup>
  release(&pi->lock);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	f6a080e7          	jalr	-150(ra) # 80000dc2 <release>
  return i;
}
    80004e60:	854e                	mv	a0,s3
    80004e62:	60a6                	ld	ra,72(sp)
    80004e64:	6406                	ld	s0,64(sp)
    80004e66:	74e2                	ld	s1,56(sp)
    80004e68:	7942                	ld	s2,48(sp)
    80004e6a:	79a2                	ld	s3,40(sp)
    80004e6c:	7a02                	ld	s4,32(sp)
    80004e6e:	6ae2                	ld	s5,24(sp)
    80004e70:	6b42                	ld	s6,16(sp)
    80004e72:	6161                	addi	sp,sp,80
    80004e74:	8082                	ret
      release(&pi->lock);
    80004e76:	8526                	mv	a0,s1
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	f4a080e7          	jalr	-182(ra) # 80000dc2 <release>
      return -1;
    80004e80:	59fd                	li	s3,-1
    80004e82:	bff9                	j	80004e60 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e84:	4981                	li	s3,0
    80004e86:	b7d1                	j	80004e4a <piperead+0xae>

0000000080004e88 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e88:	df010113          	addi	sp,sp,-528
    80004e8c:	20113423          	sd	ra,520(sp)
    80004e90:	20813023          	sd	s0,512(sp)
    80004e94:	ffa6                	sd	s1,504(sp)
    80004e96:	fbca                	sd	s2,496(sp)
    80004e98:	f7ce                	sd	s3,488(sp)
    80004e9a:	f3d2                	sd	s4,480(sp)
    80004e9c:	efd6                	sd	s5,472(sp)
    80004e9e:	ebda                	sd	s6,464(sp)
    80004ea0:	e7de                	sd	s7,456(sp)
    80004ea2:	e3e2                	sd	s8,448(sp)
    80004ea4:	ff66                	sd	s9,440(sp)
    80004ea6:	fb6a                	sd	s10,432(sp)
    80004ea8:	f76e                	sd	s11,424(sp)
    80004eaa:	0c00                	addi	s0,sp,528
    80004eac:	84aa                	mv	s1,a0
    80004eae:	dea43c23          	sd	a0,-520(s0)
    80004eb2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	c42080e7          	jalr	-958(ra) # 80001af8 <myproc>
    80004ebe:	892a                	mv	s2,a0

  begin_op();
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	494080e7          	jalr	1172(ra) # 80004354 <begin_op>

  if((ip = namei(path)) == 0){
    80004ec8:	8526                	mv	a0,s1
    80004eca:	fffff097          	auipc	ra,0xfffff
    80004ece:	26e080e7          	jalr	622(ra) # 80004138 <namei>
    80004ed2:	c92d                	beqz	a0,80004f44 <exec+0xbc>
    80004ed4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	aaa080e7          	jalr	-1366(ra) # 80003980 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ede:	04000713          	li	a4,64
    80004ee2:	4681                	li	a3,0
    80004ee4:	e4840613          	addi	a2,s0,-440
    80004ee8:	4581                	li	a1,0
    80004eea:	8526                	mv	a0,s1
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	d48080e7          	jalr	-696(ra) # 80003c34 <readi>
    80004ef4:	04000793          	li	a5,64
    80004ef8:	00f51a63          	bne	a0,a5,80004f0c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004efc:	e4842703          	lw	a4,-440(s0)
    80004f00:	464c47b7          	lui	a5,0x464c4
    80004f04:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f08:	04f70463          	beq	a4,a5,80004f50 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	cd4080e7          	jalr	-812(ra) # 80003be2 <iunlockput>
    end_op();
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	4be080e7          	jalr	1214(ra) # 800043d4 <end_op>
  }
  return -1;
    80004f1e:	557d                	li	a0,-1
}
    80004f20:	20813083          	ld	ra,520(sp)
    80004f24:	20013403          	ld	s0,512(sp)
    80004f28:	74fe                	ld	s1,504(sp)
    80004f2a:	795e                	ld	s2,496(sp)
    80004f2c:	79be                	ld	s3,488(sp)
    80004f2e:	7a1e                	ld	s4,480(sp)
    80004f30:	6afe                	ld	s5,472(sp)
    80004f32:	6b5e                	ld	s6,464(sp)
    80004f34:	6bbe                	ld	s7,456(sp)
    80004f36:	6c1e                	ld	s8,448(sp)
    80004f38:	7cfa                	ld	s9,440(sp)
    80004f3a:	7d5a                	ld	s10,432(sp)
    80004f3c:	7dba                	ld	s11,424(sp)
    80004f3e:	21010113          	addi	sp,sp,528
    80004f42:	8082                	ret
    end_op();
    80004f44:	fffff097          	auipc	ra,0xfffff
    80004f48:	490080e7          	jalr	1168(ra) # 800043d4 <end_op>
    return -1;
    80004f4c:	557d                	li	a0,-1
    80004f4e:	bfc9                	j	80004f20 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f50:	854a                	mv	a0,s2
    80004f52:	ffffd097          	auipc	ra,0xffffd
    80004f56:	c6a080e7          	jalr	-918(ra) # 80001bbc <proc_pagetable>
    80004f5a:	8baa                	mv	s7,a0
    80004f5c:	d945                	beqz	a0,80004f0c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5e:	e6842983          	lw	s3,-408(s0)
    80004f62:	e8045783          	lhu	a5,-384(s0)
    80004f66:	c7ad                	beqz	a5,80004fd0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f68:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6a:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f6c:	6c85                	lui	s9,0x1
    80004f6e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f72:	def43823          	sd	a5,-528(s0)
    80004f76:	a42d                	j	800051a0 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f78:	00003517          	auipc	a0,0x3
    80004f7c:	76050513          	addi	a0,a0,1888 # 800086d8 <syscalls+0x2a0>
    80004f80:	ffffb097          	auipc	ra,0xffffb
    80004f84:	5b0080e7          	jalr	1456(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f88:	8756                	mv	a4,s5
    80004f8a:	012d86bb          	addw	a3,s11,s2
    80004f8e:	4581                	li	a1,0
    80004f90:	8526                	mv	a0,s1
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	ca2080e7          	jalr	-862(ra) # 80003c34 <readi>
    80004f9a:	2501                	sext.w	a0,a0
    80004f9c:	1aaa9963          	bne	s5,a0,8000514e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fa0:	6785                	lui	a5,0x1
    80004fa2:	0127893b          	addw	s2,a5,s2
    80004fa6:	77fd                	lui	a5,0xfffff
    80004fa8:	01478a3b          	addw	s4,a5,s4
    80004fac:	1f897163          	bgeu	s2,s8,8000518e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fb0:	02091593          	slli	a1,s2,0x20
    80004fb4:	9181                	srli	a1,a1,0x20
    80004fb6:	95ea                	add	a1,a1,s10
    80004fb8:	855e                	mv	a0,s7
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	1e2080e7          	jalr	482(ra) # 8000119c <walkaddr>
    80004fc2:	862a                	mv	a2,a0
    if(pa == 0)
    80004fc4:	d955                	beqz	a0,80004f78 <exec+0xf0>
      n = PGSIZE;
    80004fc6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fc8:	fd9a70e3          	bgeu	s4,s9,80004f88 <exec+0x100>
      n = sz - i;
    80004fcc:	8ad2                	mv	s5,s4
    80004fce:	bf6d                	j	80004f88 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fd0:	4901                	li	s2,0
  iunlockput(ip);
    80004fd2:	8526                	mv	a0,s1
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	c0e080e7          	jalr	-1010(ra) # 80003be2 <iunlockput>
  end_op();
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	3f8080e7          	jalr	1016(ra) # 800043d4 <end_op>
  p = myproc();
    80004fe4:	ffffd097          	auipc	ra,0xffffd
    80004fe8:	b14080e7          	jalr	-1260(ra) # 80001af8 <myproc>
    80004fec:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fee:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ff2:	6785                	lui	a5,0x1
    80004ff4:	17fd                	addi	a5,a5,-1
    80004ff6:	993e                	add	s2,s2,a5
    80004ff8:	757d                	lui	a0,0xfffff
    80004ffa:	00a977b3          	and	a5,s2,a0
    80004ffe:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005002:	6609                	lui	a2,0x2
    80005004:	963e                	add	a2,a2,a5
    80005006:	85be                	mv	a1,a5
    80005008:	855e                	mv	a0,s7
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	534080e7          	jalr	1332(ra) # 8000153e <uvmalloc>
    80005012:	8b2a                	mv	s6,a0
  ip = 0;
    80005014:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005016:	12050c63          	beqz	a0,8000514e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000501a:	75f9                	lui	a1,0xffffe
    8000501c:	95aa                	add	a1,a1,a0
    8000501e:	855e                	mv	a0,s7
    80005020:	ffffc097          	auipc	ra,0xffffc
    80005024:	73c080e7          	jalr	1852(ra) # 8000175c <uvmclear>
  stackbase = sp - PGSIZE;
    80005028:	7c7d                	lui	s8,0xfffff
    8000502a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000502c:	e0043783          	ld	a5,-512(s0)
    80005030:	6388                	ld	a0,0(a5)
    80005032:	c535                	beqz	a0,8000509e <exec+0x216>
    80005034:	e8840993          	addi	s3,s0,-376
    80005038:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000503c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	f54080e7          	jalr	-172(ra) # 80000f92 <strlen>
    80005046:	2505                	addiw	a0,a0,1
    80005048:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000504c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005050:	13896363          	bltu	s2,s8,80005176 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005054:	e0043d83          	ld	s11,-512(s0)
    80005058:	000dba03          	ld	s4,0(s11)
    8000505c:	8552                	mv	a0,s4
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	f34080e7          	jalr	-204(ra) # 80000f92 <strlen>
    80005066:	0015069b          	addiw	a3,a0,1
    8000506a:	8652                	mv	a2,s4
    8000506c:	85ca                	mv	a1,s2
    8000506e:	855e                	mv	a0,s7
    80005070:	ffffc097          	auipc	ra,0xffffc
    80005074:	71e080e7          	jalr	1822(ra) # 8000178e <copyout>
    80005078:	10054363          	bltz	a0,8000517e <exec+0x2f6>
    ustack[argc] = sp;
    8000507c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005080:	0485                	addi	s1,s1,1
    80005082:	008d8793          	addi	a5,s11,8
    80005086:	e0f43023          	sd	a5,-512(s0)
    8000508a:	008db503          	ld	a0,8(s11)
    8000508e:	c911                	beqz	a0,800050a2 <exec+0x21a>
    if(argc >= MAXARG)
    80005090:	09a1                	addi	s3,s3,8
    80005092:	fb3c96e3          	bne	s9,s3,8000503e <exec+0x1b6>
  sz = sz1;
    80005096:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000509a:	4481                	li	s1,0
    8000509c:	a84d                	j	8000514e <exec+0x2c6>
  sp = sz;
    8000509e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050a0:	4481                	li	s1,0
  ustack[argc] = 0;
    800050a2:	00349793          	slli	a5,s1,0x3
    800050a6:	f9040713          	addi	a4,s0,-112
    800050aa:	97ba                	add	a5,a5,a4
    800050ac:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800050b0:	00148693          	addi	a3,s1,1
    800050b4:	068e                	slli	a3,a3,0x3
    800050b6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050ba:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050be:	01897663          	bgeu	s2,s8,800050ca <exec+0x242>
  sz = sz1;
    800050c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c6:	4481                	li	s1,0
    800050c8:	a059                	j	8000514e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ca:	e8840613          	addi	a2,s0,-376
    800050ce:	85ca                	mv	a1,s2
    800050d0:	855e                	mv	a0,s7
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	6bc080e7          	jalr	1724(ra) # 8000178e <copyout>
    800050da:	0a054663          	bltz	a0,80005186 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050de:	058ab783          	ld	a5,88(s5)
    800050e2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050e6:	df843783          	ld	a5,-520(s0)
    800050ea:	0007c703          	lbu	a4,0(a5)
    800050ee:	cf11                	beqz	a4,8000510a <exec+0x282>
    800050f0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050f2:	02f00693          	li	a3,47
    800050f6:	a029                	j	80005100 <exec+0x278>
  for(last=s=path; *s; s++)
    800050f8:	0785                	addi	a5,a5,1
    800050fa:	fff7c703          	lbu	a4,-1(a5)
    800050fe:	c711                	beqz	a4,8000510a <exec+0x282>
    if(*s == '/')
    80005100:	fed71ce3          	bne	a4,a3,800050f8 <exec+0x270>
      last = s+1;
    80005104:	def43c23          	sd	a5,-520(s0)
    80005108:	bfc5                	j	800050f8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000510a:	4641                	li	a2,16
    8000510c:	df843583          	ld	a1,-520(s0)
    80005110:	158a8513          	addi	a0,s5,344
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	e4c080e7          	jalr	-436(ra) # 80000f60 <safestrcpy>
  oldpagetable = p->pagetable;
    8000511c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005120:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005124:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005128:	058ab783          	ld	a5,88(s5)
    8000512c:	e6043703          	ld	a4,-416(s0)
    80005130:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005132:	058ab783          	ld	a5,88(s5)
    80005136:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000513a:	85ea                	mv	a1,s10
    8000513c:	ffffd097          	auipc	ra,0xffffd
    80005140:	b1c080e7          	jalr	-1252(ra) # 80001c58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005144:	0004851b          	sext.w	a0,s1
    80005148:	bbe1                	j	80004f20 <exec+0x98>
    8000514a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000514e:	e0843583          	ld	a1,-504(s0)
    80005152:	855e                	mv	a0,s7
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	b04080e7          	jalr	-1276(ra) # 80001c58 <proc_freepagetable>
  if(ip){
    8000515c:	da0498e3          	bnez	s1,80004f0c <exec+0x84>
  return -1;
    80005160:	557d                	li	a0,-1
    80005162:	bb7d                	j	80004f20 <exec+0x98>
    80005164:	e1243423          	sd	s2,-504(s0)
    80005168:	b7dd                	j	8000514e <exec+0x2c6>
    8000516a:	e1243423          	sd	s2,-504(s0)
    8000516e:	b7c5                	j	8000514e <exec+0x2c6>
    80005170:	e1243423          	sd	s2,-504(s0)
    80005174:	bfe9                	j	8000514e <exec+0x2c6>
  sz = sz1;
    80005176:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000517a:	4481                	li	s1,0
    8000517c:	bfc9                	j	8000514e <exec+0x2c6>
  sz = sz1;
    8000517e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005182:	4481                	li	s1,0
    80005184:	b7e9                	j	8000514e <exec+0x2c6>
  sz = sz1;
    80005186:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000518a:	4481                	li	s1,0
    8000518c:	b7c9                	j	8000514e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000518e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005192:	2b05                	addiw	s6,s6,1
    80005194:	0389899b          	addiw	s3,s3,56
    80005198:	e8045783          	lhu	a5,-384(s0)
    8000519c:	e2fb5be3          	bge	s6,a5,80004fd2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051a0:	2981                	sext.w	s3,s3
    800051a2:	03800713          	li	a4,56
    800051a6:	86ce                	mv	a3,s3
    800051a8:	e1040613          	addi	a2,s0,-496
    800051ac:	4581                	li	a1,0
    800051ae:	8526                	mv	a0,s1
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	a84080e7          	jalr	-1404(ra) # 80003c34 <readi>
    800051b8:	03800793          	li	a5,56
    800051bc:	f8f517e3          	bne	a0,a5,8000514a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051c0:	e1042783          	lw	a5,-496(s0)
    800051c4:	4705                	li	a4,1
    800051c6:	fce796e3          	bne	a5,a4,80005192 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051ca:	e3843603          	ld	a2,-456(s0)
    800051ce:	e3043783          	ld	a5,-464(s0)
    800051d2:	f8f669e3          	bltu	a2,a5,80005164 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051d6:	e2043783          	ld	a5,-480(s0)
    800051da:	963e                	add	a2,a2,a5
    800051dc:	f8f667e3          	bltu	a2,a5,8000516a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051e0:	85ca                	mv	a1,s2
    800051e2:	855e                	mv	a0,s7
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	35a080e7          	jalr	858(ra) # 8000153e <uvmalloc>
    800051ec:	e0a43423          	sd	a0,-504(s0)
    800051f0:	d141                	beqz	a0,80005170 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800051f2:	e2043d03          	ld	s10,-480(s0)
    800051f6:	df043783          	ld	a5,-528(s0)
    800051fa:	00fd77b3          	and	a5,s10,a5
    800051fe:	fba1                	bnez	a5,8000514e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005200:	e1842d83          	lw	s11,-488(s0)
    80005204:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005208:	f80c03e3          	beqz	s8,8000518e <exec+0x306>
    8000520c:	8a62                	mv	s4,s8
    8000520e:	4901                	li	s2,0
    80005210:	b345                	j	80004fb0 <exec+0x128>

0000000080005212 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005212:	7179                	addi	sp,sp,-48
    80005214:	f406                	sd	ra,40(sp)
    80005216:	f022                	sd	s0,32(sp)
    80005218:	ec26                	sd	s1,24(sp)
    8000521a:	e84a                	sd	s2,16(sp)
    8000521c:	1800                	addi	s0,sp,48
    8000521e:	892e                	mv	s2,a1
    80005220:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005222:	fdc40593          	addi	a1,s0,-36
    80005226:	ffffe097          	auipc	ra,0xffffe
    8000522a:	990080e7          	jalr	-1648(ra) # 80002bb6 <argint>
    8000522e:	04054063          	bltz	a0,8000526e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005232:	fdc42703          	lw	a4,-36(s0)
    80005236:	47bd                	li	a5,15
    80005238:	02e7ed63          	bltu	a5,a4,80005272 <argfd+0x60>
    8000523c:	ffffd097          	auipc	ra,0xffffd
    80005240:	8bc080e7          	jalr	-1860(ra) # 80001af8 <myproc>
    80005244:	fdc42703          	lw	a4,-36(s0)
    80005248:	01a70793          	addi	a5,a4,26
    8000524c:	078e                	slli	a5,a5,0x3
    8000524e:	953e                	add	a0,a0,a5
    80005250:	611c                	ld	a5,0(a0)
    80005252:	c395                	beqz	a5,80005276 <argfd+0x64>
    return -1;
  if(pfd)
    80005254:	00090463          	beqz	s2,8000525c <argfd+0x4a>
    *pfd = fd;
    80005258:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000525c:	4501                	li	a0,0
  if(pf)
    8000525e:	c091                	beqz	s1,80005262 <argfd+0x50>
    *pf = f;
    80005260:	e09c                	sd	a5,0(s1)
}
    80005262:	70a2                	ld	ra,40(sp)
    80005264:	7402                	ld	s0,32(sp)
    80005266:	64e2                	ld	s1,24(sp)
    80005268:	6942                	ld	s2,16(sp)
    8000526a:	6145                	addi	sp,sp,48
    8000526c:	8082                	ret
    return -1;
    8000526e:	557d                	li	a0,-1
    80005270:	bfcd                	j	80005262 <argfd+0x50>
    return -1;
    80005272:	557d                	li	a0,-1
    80005274:	b7fd                	j	80005262 <argfd+0x50>
    80005276:	557d                	li	a0,-1
    80005278:	b7ed                	j	80005262 <argfd+0x50>

000000008000527a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000527a:	1101                	addi	sp,sp,-32
    8000527c:	ec06                	sd	ra,24(sp)
    8000527e:	e822                	sd	s0,16(sp)
    80005280:	e426                	sd	s1,8(sp)
    80005282:	1000                	addi	s0,sp,32
    80005284:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005286:	ffffd097          	auipc	ra,0xffffd
    8000528a:	872080e7          	jalr	-1934(ra) # 80001af8 <myproc>
    8000528e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005290:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdb0d0>
    80005294:	4501                	li	a0,0
    80005296:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005298:	6398                	ld	a4,0(a5)
    8000529a:	cb19                	beqz	a4,800052b0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000529c:	2505                	addiw	a0,a0,1
    8000529e:	07a1                	addi	a5,a5,8
    800052a0:	fed51ce3          	bne	a0,a3,80005298 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052a4:	557d                	li	a0,-1
}
    800052a6:	60e2                	ld	ra,24(sp)
    800052a8:	6442                	ld	s0,16(sp)
    800052aa:	64a2                	ld	s1,8(sp)
    800052ac:	6105                	addi	sp,sp,32
    800052ae:	8082                	ret
      p->ofile[fd] = f;
    800052b0:	01a50793          	addi	a5,a0,26
    800052b4:	078e                	slli	a5,a5,0x3
    800052b6:	963e                	add	a2,a2,a5
    800052b8:	e204                	sd	s1,0(a2)
      return fd;
    800052ba:	b7f5                	j	800052a6 <fdalloc+0x2c>

00000000800052bc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052bc:	715d                	addi	sp,sp,-80
    800052be:	e486                	sd	ra,72(sp)
    800052c0:	e0a2                	sd	s0,64(sp)
    800052c2:	fc26                	sd	s1,56(sp)
    800052c4:	f84a                	sd	s2,48(sp)
    800052c6:	f44e                	sd	s3,40(sp)
    800052c8:	f052                	sd	s4,32(sp)
    800052ca:	ec56                	sd	s5,24(sp)
    800052cc:	0880                	addi	s0,sp,80
    800052ce:	89ae                	mv	s3,a1
    800052d0:	8ab2                	mv	s5,a2
    800052d2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052d4:	fb040593          	addi	a1,s0,-80
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	e7e080e7          	jalr	-386(ra) # 80004156 <nameiparent>
    800052e0:	892a                	mv	s2,a0
    800052e2:	12050f63          	beqz	a0,80005420 <create+0x164>
    return 0;

  ilock(dp);
    800052e6:	ffffe097          	auipc	ra,0xffffe
    800052ea:	69a080e7          	jalr	1690(ra) # 80003980 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052ee:	4601                	li	a2,0
    800052f0:	fb040593          	addi	a1,s0,-80
    800052f4:	854a                	mv	a0,s2
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	b70080e7          	jalr	-1168(ra) # 80003e66 <dirlookup>
    800052fe:	84aa                	mv	s1,a0
    80005300:	c921                	beqz	a0,80005350 <create+0x94>
    iunlockput(dp);
    80005302:	854a                	mv	a0,s2
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	8de080e7          	jalr	-1826(ra) # 80003be2 <iunlockput>
    ilock(ip);
    8000530c:	8526                	mv	a0,s1
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	672080e7          	jalr	1650(ra) # 80003980 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005316:	2981                	sext.w	s3,s3
    80005318:	4789                	li	a5,2
    8000531a:	02f99463          	bne	s3,a5,80005342 <create+0x86>
    8000531e:	0444d783          	lhu	a5,68(s1)
    80005322:	37f9                	addiw	a5,a5,-2
    80005324:	17c2                	slli	a5,a5,0x30
    80005326:	93c1                	srli	a5,a5,0x30
    80005328:	4705                	li	a4,1
    8000532a:	00f76c63          	bltu	a4,a5,80005342 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000532e:	8526                	mv	a0,s1
    80005330:	60a6                	ld	ra,72(sp)
    80005332:	6406                	ld	s0,64(sp)
    80005334:	74e2                	ld	s1,56(sp)
    80005336:	7942                	ld	s2,48(sp)
    80005338:	79a2                	ld	s3,40(sp)
    8000533a:	7a02                	ld	s4,32(sp)
    8000533c:	6ae2                	ld	s5,24(sp)
    8000533e:	6161                	addi	sp,sp,80
    80005340:	8082                	ret
    iunlockput(ip);
    80005342:	8526                	mv	a0,s1
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	89e080e7          	jalr	-1890(ra) # 80003be2 <iunlockput>
    return 0;
    8000534c:	4481                	li	s1,0
    8000534e:	b7c5                	j	8000532e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005350:	85ce                	mv	a1,s3
    80005352:	00092503          	lw	a0,0(s2)
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	492080e7          	jalr	1170(ra) # 800037e8 <ialloc>
    8000535e:	84aa                	mv	s1,a0
    80005360:	c529                	beqz	a0,800053aa <create+0xee>
  ilock(ip);
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	61e080e7          	jalr	1566(ra) # 80003980 <ilock>
  ip->major = major;
    8000536a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000536e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005372:	4785                	li	a5,1
    80005374:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005378:	8526                	mv	a0,s1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	53c080e7          	jalr	1340(ra) # 800038b6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005382:	2981                	sext.w	s3,s3
    80005384:	4785                	li	a5,1
    80005386:	02f98a63          	beq	s3,a5,800053ba <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000538a:	40d0                	lw	a2,4(s1)
    8000538c:	fb040593          	addi	a1,s0,-80
    80005390:	854a                	mv	a0,s2
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	ce4080e7          	jalr	-796(ra) # 80004076 <dirlink>
    8000539a:	06054b63          	bltz	a0,80005410 <create+0x154>
  iunlockput(dp);
    8000539e:	854a                	mv	a0,s2
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	842080e7          	jalr	-1982(ra) # 80003be2 <iunlockput>
  return ip;
    800053a8:	b759                	j	8000532e <create+0x72>
    panic("create: ialloc");
    800053aa:	00003517          	auipc	a0,0x3
    800053ae:	34e50513          	addi	a0,a0,846 # 800086f8 <syscalls+0x2c0>
    800053b2:	ffffb097          	auipc	ra,0xffffb
    800053b6:	17e080e7          	jalr	382(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    800053ba:	04a95783          	lhu	a5,74(s2)
    800053be:	2785                	addiw	a5,a5,1
    800053c0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053c4:	854a                	mv	a0,s2
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	4f0080e7          	jalr	1264(ra) # 800038b6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053ce:	40d0                	lw	a2,4(s1)
    800053d0:	00003597          	auipc	a1,0x3
    800053d4:	33858593          	addi	a1,a1,824 # 80008708 <syscalls+0x2d0>
    800053d8:	8526                	mv	a0,s1
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	c9c080e7          	jalr	-868(ra) # 80004076 <dirlink>
    800053e2:	00054f63          	bltz	a0,80005400 <create+0x144>
    800053e6:	00492603          	lw	a2,4(s2)
    800053ea:	00003597          	auipc	a1,0x3
    800053ee:	32658593          	addi	a1,a1,806 # 80008710 <syscalls+0x2d8>
    800053f2:	8526                	mv	a0,s1
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	c82080e7          	jalr	-894(ra) # 80004076 <dirlink>
    800053fc:	f80557e3          	bgez	a0,8000538a <create+0xce>
      panic("create dots");
    80005400:	00003517          	auipc	a0,0x3
    80005404:	31850513          	addi	a0,a0,792 # 80008718 <syscalls+0x2e0>
    80005408:	ffffb097          	auipc	ra,0xffffb
    8000540c:	128080e7          	jalr	296(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005410:	00003517          	auipc	a0,0x3
    80005414:	31850513          	addi	a0,a0,792 # 80008728 <syscalls+0x2f0>
    80005418:	ffffb097          	auipc	ra,0xffffb
    8000541c:	118080e7          	jalr	280(ra) # 80000530 <panic>
    return 0;
    80005420:	84aa                	mv	s1,a0
    80005422:	b731                	j	8000532e <create+0x72>

0000000080005424 <sys_dup>:
{
    80005424:	7179                	addi	sp,sp,-48
    80005426:	f406                	sd	ra,40(sp)
    80005428:	f022                	sd	s0,32(sp)
    8000542a:	ec26                	sd	s1,24(sp)
    8000542c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000542e:	fd840613          	addi	a2,s0,-40
    80005432:	4581                	li	a1,0
    80005434:	4501                	li	a0,0
    80005436:	00000097          	auipc	ra,0x0
    8000543a:	ddc080e7          	jalr	-548(ra) # 80005212 <argfd>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005440:	02054363          	bltz	a0,80005466 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005444:	fd843503          	ld	a0,-40(s0)
    80005448:	00000097          	auipc	ra,0x0
    8000544c:	e32080e7          	jalr	-462(ra) # 8000527a <fdalloc>
    80005450:	84aa                	mv	s1,a0
    return -1;
    80005452:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005454:	00054963          	bltz	a0,80005466 <sys_dup+0x42>
  filedup(f);
    80005458:	fd843503          	ld	a0,-40(s0)
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	37a080e7          	jalr	890(ra) # 800047d6 <filedup>
  return fd;
    80005464:	87a6                	mv	a5,s1
}
    80005466:	853e                	mv	a0,a5
    80005468:	70a2                	ld	ra,40(sp)
    8000546a:	7402                	ld	s0,32(sp)
    8000546c:	64e2                	ld	s1,24(sp)
    8000546e:	6145                	addi	sp,sp,48
    80005470:	8082                	ret

0000000080005472 <sys_read>:
{
    80005472:	7179                	addi	sp,sp,-48
    80005474:	f406                	sd	ra,40(sp)
    80005476:	f022                	sd	s0,32(sp)
    80005478:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547a:	fe840613          	addi	a2,s0,-24
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	d90080e7          	jalr	-624(ra) # 80005212 <argfd>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548c:	04054163          	bltz	a0,800054ce <sys_read+0x5c>
    80005490:	fe440593          	addi	a1,s0,-28
    80005494:	4509                	li	a0,2
    80005496:	ffffd097          	auipc	ra,0xffffd
    8000549a:	720080e7          	jalr	1824(ra) # 80002bb6 <argint>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a0:	02054763          	bltz	a0,800054ce <sys_read+0x5c>
    800054a4:	fd840593          	addi	a1,s0,-40
    800054a8:	4505                	li	a0,1
    800054aa:	ffffd097          	auipc	ra,0xffffd
    800054ae:	72e080e7          	jalr	1838(ra) # 80002bd8 <argaddr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b4:	00054d63          	bltz	a0,800054ce <sys_read+0x5c>
  return fileread(f, p, n);
    800054b8:	fe442603          	lw	a2,-28(s0)
    800054bc:	fd843583          	ld	a1,-40(s0)
    800054c0:	fe843503          	ld	a0,-24(s0)
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	49e080e7          	jalr	1182(ra) # 80004962 <fileread>
    800054cc:	87aa                	mv	a5,a0
}
    800054ce:	853e                	mv	a0,a5
    800054d0:	70a2                	ld	ra,40(sp)
    800054d2:	7402                	ld	s0,32(sp)
    800054d4:	6145                	addi	sp,sp,48
    800054d6:	8082                	ret

00000000800054d8 <sys_write>:
{
    800054d8:	7179                	addi	sp,sp,-48
    800054da:	f406                	sd	ra,40(sp)
    800054dc:	f022                	sd	s0,32(sp)
    800054de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e0:	fe840613          	addi	a2,s0,-24
    800054e4:	4581                	li	a1,0
    800054e6:	4501                	li	a0,0
    800054e8:	00000097          	auipc	ra,0x0
    800054ec:	d2a080e7          	jalr	-726(ra) # 80005212 <argfd>
    return -1;
    800054f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f2:	04054163          	bltz	a0,80005534 <sys_write+0x5c>
    800054f6:	fe440593          	addi	a1,s0,-28
    800054fa:	4509                	li	a0,2
    800054fc:	ffffd097          	auipc	ra,0xffffd
    80005500:	6ba080e7          	jalr	1722(ra) # 80002bb6 <argint>
    return -1;
    80005504:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005506:	02054763          	bltz	a0,80005534 <sys_write+0x5c>
    8000550a:	fd840593          	addi	a1,s0,-40
    8000550e:	4505                	li	a0,1
    80005510:	ffffd097          	auipc	ra,0xffffd
    80005514:	6c8080e7          	jalr	1736(ra) # 80002bd8 <argaddr>
    return -1;
    80005518:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000551a:	00054d63          	bltz	a0,80005534 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000551e:	fe442603          	lw	a2,-28(s0)
    80005522:	fd843583          	ld	a1,-40(s0)
    80005526:	fe843503          	ld	a0,-24(s0)
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	4fa080e7          	jalr	1274(ra) # 80004a24 <filewrite>
    80005532:	87aa                	mv	a5,a0
}
    80005534:	853e                	mv	a0,a5
    80005536:	70a2                	ld	ra,40(sp)
    80005538:	7402                	ld	s0,32(sp)
    8000553a:	6145                	addi	sp,sp,48
    8000553c:	8082                	ret

000000008000553e <sys_close>:
{
    8000553e:	1101                	addi	sp,sp,-32
    80005540:	ec06                	sd	ra,24(sp)
    80005542:	e822                	sd	s0,16(sp)
    80005544:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005546:	fe040613          	addi	a2,s0,-32
    8000554a:	fec40593          	addi	a1,s0,-20
    8000554e:	4501                	li	a0,0
    80005550:	00000097          	auipc	ra,0x0
    80005554:	cc2080e7          	jalr	-830(ra) # 80005212 <argfd>
    return -1;
    80005558:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000555a:	02054463          	bltz	a0,80005582 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000555e:	ffffc097          	auipc	ra,0xffffc
    80005562:	59a080e7          	jalr	1434(ra) # 80001af8 <myproc>
    80005566:	fec42783          	lw	a5,-20(s0)
    8000556a:	07e9                	addi	a5,a5,26
    8000556c:	078e                	slli	a5,a5,0x3
    8000556e:	97aa                	add	a5,a5,a0
    80005570:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005574:	fe043503          	ld	a0,-32(s0)
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	2b0080e7          	jalr	688(ra) # 80004828 <fileclose>
  return 0;
    80005580:	4781                	li	a5,0
}
    80005582:	853e                	mv	a0,a5
    80005584:	60e2                	ld	ra,24(sp)
    80005586:	6442                	ld	s0,16(sp)
    80005588:	6105                	addi	sp,sp,32
    8000558a:	8082                	ret

000000008000558c <sys_fstat>:
{
    8000558c:	1101                	addi	sp,sp,-32
    8000558e:	ec06                	sd	ra,24(sp)
    80005590:	e822                	sd	s0,16(sp)
    80005592:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005594:	fe840613          	addi	a2,s0,-24
    80005598:	4581                	li	a1,0
    8000559a:	4501                	li	a0,0
    8000559c:	00000097          	auipc	ra,0x0
    800055a0:	c76080e7          	jalr	-906(ra) # 80005212 <argfd>
    return -1;
    800055a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055a6:	02054563          	bltz	a0,800055d0 <sys_fstat+0x44>
    800055aa:	fe040593          	addi	a1,s0,-32
    800055ae:	4505                	li	a0,1
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	628080e7          	jalr	1576(ra) # 80002bd8 <argaddr>
    return -1;
    800055b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ba:	00054b63          	bltz	a0,800055d0 <sys_fstat+0x44>
  return filestat(f, st);
    800055be:	fe043583          	ld	a1,-32(s0)
    800055c2:	fe843503          	ld	a0,-24(s0)
    800055c6:	fffff097          	auipc	ra,0xfffff
    800055ca:	32a080e7          	jalr	810(ra) # 800048f0 <filestat>
    800055ce:	87aa                	mv	a5,a0
}
    800055d0:	853e                	mv	a0,a5
    800055d2:	60e2                	ld	ra,24(sp)
    800055d4:	6442                	ld	s0,16(sp)
    800055d6:	6105                	addi	sp,sp,32
    800055d8:	8082                	ret

00000000800055da <sys_link>:
{
    800055da:	7169                	addi	sp,sp,-304
    800055dc:	f606                	sd	ra,296(sp)
    800055de:	f222                	sd	s0,288(sp)
    800055e0:	ee26                	sd	s1,280(sp)
    800055e2:	ea4a                	sd	s2,272(sp)
    800055e4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e6:	08000613          	li	a2,128
    800055ea:	ed040593          	addi	a1,s0,-304
    800055ee:	4501                	li	a0,0
    800055f0:	ffffd097          	auipc	ra,0xffffd
    800055f4:	60a080e7          	jalr	1546(ra) # 80002bfa <argstr>
    return -1;
    800055f8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055fa:	10054e63          	bltz	a0,80005716 <sys_link+0x13c>
    800055fe:	08000613          	li	a2,128
    80005602:	f5040593          	addi	a1,s0,-176
    80005606:	4505                	li	a0,1
    80005608:	ffffd097          	auipc	ra,0xffffd
    8000560c:	5f2080e7          	jalr	1522(ra) # 80002bfa <argstr>
    return -1;
    80005610:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005612:	10054263          	bltz	a0,80005716 <sys_link+0x13c>
  begin_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	d3e080e7          	jalr	-706(ra) # 80004354 <begin_op>
  if((ip = namei(old)) == 0){
    8000561e:	ed040513          	addi	a0,s0,-304
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	b16080e7          	jalr	-1258(ra) # 80004138 <namei>
    8000562a:	84aa                	mv	s1,a0
    8000562c:	c551                	beqz	a0,800056b8 <sys_link+0xde>
  ilock(ip);
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	352080e7          	jalr	850(ra) # 80003980 <ilock>
  if(ip->type == T_DIR){
    80005636:	04449703          	lh	a4,68(s1)
    8000563a:	4785                	li	a5,1
    8000563c:	08f70463          	beq	a4,a5,800056c4 <sys_link+0xea>
  ip->nlink++;
    80005640:	04a4d783          	lhu	a5,74(s1)
    80005644:	2785                	addiw	a5,a5,1
    80005646:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	26a080e7          	jalr	618(ra) # 800038b6 <iupdate>
  iunlock(ip);
    80005654:	8526                	mv	a0,s1
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	3ec080e7          	jalr	1004(ra) # 80003a42 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000565e:	fd040593          	addi	a1,s0,-48
    80005662:	f5040513          	addi	a0,s0,-176
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	af0080e7          	jalr	-1296(ra) # 80004156 <nameiparent>
    8000566e:	892a                	mv	s2,a0
    80005670:	c935                	beqz	a0,800056e4 <sys_link+0x10a>
  ilock(dp);
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	30e080e7          	jalr	782(ra) # 80003980 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000567a:	00092703          	lw	a4,0(s2)
    8000567e:	409c                	lw	a5,0(s1)
    80005680:	04f71d63          	bne	a4,a5,800056da <sys_link+0x100>
    80005684:	40d0                	lw	a2,4(s1)
    80005686:	fd040593          	addi	a1,s0,-48
    8000568a:	854a                	mv	a0,s2
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	9ea080e7          	jalr	-1558(ra) # 80004076 <dirlink>
    80005694:	04054363          	bltz	a0,800056da <sys_link+0x100>
  iunlockput(dp);
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	548080e7          	jalr	1352(ra) # 80003be2 <iunlockput>
  iput(ip);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	496080e7          	jalr	1174(ra) # 80003b3a <iput>
  end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	d28080e7          	jalr	-728(ra) # 800043d4 <end_op>
  return 0;
    800056b4:	4781                	li	a5,0
    800056b6:	a085                	j	80005716 <sys_link+0x13c>
    end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	d1c080e7          	jalr	-740(ra) # 800043d4 <end_op>
    return -1;
    800056c0:	57fd                	li	a5,-1
    800056c2:	a891                	j	80005716 <sys_link+0x13c>
    iunlockput(ip);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	51c080e7          	jalr	1308(ra) # 80003be2 <iunlockput>
    end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	d06080e7          	jalr	-762(ra) # 800043d4 <end_op>
    return -1;
    800056d6:	57fd                	li	a5,-1
    800056d8:	a83d                	j	80005716 <sys_link+0x13c>
    iunlockput(dp);
    800056da:	854a                	mv	a0,s2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	506080e7          	jalr	1286(ra) # 80003be2 <iunlockput>
  ilock(ip);
    800056e4:	8526                	mv	a0,s1
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	29a080e7          	jalr	666(ra) # 80003980 <ilock>
  ip->nlink--;
    800056ee:	04a4d783          	lhu	a5,74(s1)
    800056f2:	37fd                	addiw	a5,a5,-1
    800056f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	1bc080e7          	jalr	444(ra) # 800038b6 <iupdate>
  iunlockput(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	4de080e7          	jalr	1246(ra) # 80003be2 <iunlockput>
  end_op();
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	cc8080e7          	jalr	-824(ra) # 800043d4 <end_op>
  return -1;
    80005714:	57fd                	li	a5,-1
}
    80005716:	853e                	mv	a0,a5
    80005718:	70b2                	ld	ra,296(sp)
    8000571a:	7412                	ld	s0,288(sp)
    8000571c:	64f2                	ld	s1,280(sp)
    8000571e:	6952                	ld	s2,272(sp)
    80005720:	6155                	addi	sp,sp,304
    80005722:	8082                	ret

0000000080005724 <sys_symlink>:
{
    80005724:	7129                	addi	sp,sp,-320
    80005726:	fe06                	sd	ra,312(sp)
    80005728:	fa22                	sd	s0,304(sp)
    8000572a:	f626                	sd	s1,296(sp)
    8000572c:	f24a                	sd	s2,288(sp)
    8000572e:	ee4e                	sd	s3,280(sp)
    80005730:	0280                	addi	s0,sp,320
  if(argstr(0,target,MAXPATH)<0 || argstr(1, path, MAXPATH)<0)
    80005732:	08000613          	li	a2,128
    80005736:	f4040593          	addi	a1,s0,-192
    8000573a:	4501                	li	a0,0
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	4be080e7          	jalr	1214(ra) # 80002bfa <argstr>
    80005744:	16054663          	bltz	a0,800058b0 <sys_symlink+0x18c>
    80005748:	08000613          	li	a2,128
    8000574c:	ec040593          	addi	a1,s0,-320
    80005750:	4505                	li	a0,1
    80005752:	ffffd097          	auipc	ra,0xffffd
    80005756:	4a8080e7          	jalr	1192(ra) # 80002bfa <argstr>
    8000575a:	16054363          	bltz	a0,800058c0 <sys_symlink+0x19c>
  begin_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	bf6080e7          	jalr	-1034(ra) # 80004354 <begin_op>
  if((ip = namei(target)) != 0)//目标存在
    80005766:	f4040513          	addi	a0,s0,-192
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	9ce080e7          	jalr	-1586(ra) # 80004138 <namei>
    80005772:	c511                	beqz	a0,8000577e <sys_symlink+0x5a>
    if(ip->type == T_DIR)//不需要处理target为目录的情况
    80005774:	04451703          	lh	a4,68(a0)
    80005778:	4785                	li	a5,1
    8000577a:	0cf70c63          	beq	a4,a5,80005852 <sys_symlink+0x12e>
  if((dp = nameiparent(path,name)) == 0)
    8000577e:	fc040593          	addi	a1,s0,-64
    80005782:	ec040513          	addi	a0,s0,-320
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	9d0080e7          	jalr	-1584(ra) # 80004156 <nameiparent>
    8000578e:	84aa                	mv	s1,a0
    80005790:	c579                	beqz	a0,8000585e <sys_symlink+0x13a>
  ilock(dp);
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	1ee080e7          	jalr	494(ra) # 80003980 <ilock>
  if((sym = dirlookup(dp,name,0) ) !=0 )//target的父目录如果有与name相同的文件
    8000579a:	4601                	li	a2,0
    8000579c:	fc040593          	addi	a1,s0,-64
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	6c4080e7          	jalr	1732(ra) # 80003e66 <dirlookup>
    800057aa:	e161                	bnez	a0,8000586a <sys_symlink+0x146>
  if((sym = ialloc(dp->dev,T_SYMLINK)) == 0)
    800057ac:	4591                	li	a1,4
    800057ae:	4088                	lw	a0,0(s1)
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	038080e7          	jalr	56(ra) # 800037e8 <ialloc>
    800057b8:	892a                	mv	s2,a0
    800057ba:	c179                	beqz	a0,80005880 <sys_symlink+0x15c>
  ilock(sym);
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	1c4080e7          	jalr	452(ra) # 80003980 <ilock>
  sym->nlink = 1;
    800057c4:	4785                	li	a5,1
    800057c6:	04f91523          	sh	a5,74(s2)
  iupdate(sym);
    800057ca:	854a                	mv	a0,s2
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	0ea080e7          	jalr	234(ra) # 800038b6 <iupdate>
  if(dirlink(dp,name,sym->inum)<0)
    800057d4:	00492603          	lw	a2,4(s2)
    800057d8:	fc040593          	addi	a1,s0,-64
    800057dc:	8526                	mv	a0,s1
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	898080e7          	jalr	-1896(ra) # 80004076 <dirlink>
    800057e6:	0a054563          	bltz	a0,80005890 <sys_symlink+0x16c>
  iupdate(dp);
    800057ea:	8526                	mv	a0,s1
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	0ca080e7          	jalr	202(ra) # 800038b6 <iupdate>
  if(writei(sym, 0, (uint64)&target, 0, strlen(target)) != strlen(target))
    800057f4:	f4040513          	addi	a0,s0,-192
    800057f8:	ffffb097          	auipc	ra,0xffffb
    800057fc:	79a080e7          	jalr	1946(ra) # 80000f92 <strlen>
    80005800:	0005071b          	sext.w	a4,a0
    80005804:	4681                	li	a3,0
    80005806:	f4040613          	addi	a2,s0,-192
    8000580a:	4581                	li	a1,0
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	51e080e7          	jalr	1310(ra) # 80003d2c <writei>
    80005816:	89aa                	mv	s3,a0
    80005818:	f4040513          	addi	a0,s0,-192
    8000581c:	ffffb097          	auipc	ra,0xffffb
    80005820:	776080e7          	jalr	1910(ra) # 80000f92 <strlen>
    80005824:	06a99e63          	bne	s3,a0,800058a0 <sys_symlink+0x17c>
  iupdate(sym);
    80005828:	854a                	mv	a0,s2
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	08c080e7          	jalr	140(ra) # 800038b6 <iupdate>
  iunlockput(dp);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	3ae080e7          	jalr	942(ra) # 80003be2 <iunlockput>
  iunlockput(sym);
    8000583c:	854a                	mv	a0,s2
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	3a4080e7          	jalr	932(ra) # 80003be2 <iunlockput>
  end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	b8e080e7          	jalr	-1138(ra) # 800043d4 <end_op>
  return 0;
    8000584e:	4501                	li	a0,0
    80005850:	a08d                	j	800058b2 <sys_symlink+0x18e>
      end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	b82080e7          	jalr	-1150(ra) # 800043d4 <end_op>
      return -1;
    8000585a:	557d                	li	a0,-1
    8000585c:	a899                	j	800058b2 <sys_symlink+0x18e>
    end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	b76080e7          	jalr	-1162(ra) # 800043d4 <end_op>
    return -1;
    80005866:	557d                	li	a0,-1
    80005868:	a0a9                	j	800058b2 <sys_symlink+0x18e>
    iunlockput(dp);
    8000586a:	8526                	mv	a0,s1
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	376080e7          	jalr	886(ra) # 80003be2 <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	b60080e7          	jalr	-1184(ra) # 800043d4 <end_op>
    return -1;
    8000587c:	557d                	li	a0,-1
    8000587e:	a815                	j	800058b2 <sys_symlink+0x18e>
    panic("create: ialloc");
    80005880:	00003517          	auipc	a0,0x3
    80005884:	e7850513          	addi	a0,a0,-392 # 800086f8 <syscalls+0x2c0>
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	ca8080e7          	jalr	-856(ra) # 80000530 <panic>
    panic("create:dirlink");
    80005890:	00003517          	auipc	a0,0x3
    80005894:	ea850513          	addi	a0,a0,-344 # 80008738 <syscalls+0x300>
    80005898:	ffffb097          	auipc	ra,0xffffb
    8000589c:	c98080e7          	jalr	-872(ra) # 80000530 <panic>
    panic("symlink: writei");
    800058a0:	00003517          	auipc	a0,0x3
    800058a4:	ea850513          	addi	a0,a0,-344 # 80008748 <syscalls+0x310>
    800058a8:	ffffb097          	auipc	ra,0xffffb
    800058ac:	c88080e7          	jalr	-888(ra) # 80000530 <panic>
    return -1;
    800058b0:	557d                	li	a0,-1
}
    800058b2:	70f2                	ld	ra,312(sp)
    800058b4:	7452                	ld	s0,304(sp)
    800058b6:	74b2                	ld	s1,296(sp)
    800058b8:	7912                	ld	s2,288(sp)
    800058ba:	69f2                	ld	s3,280(sp)
    800058bc:	6131                	addi	sp,sp,320
    800058be:	8082                	ret
    return -1;
    800058c0:	557d                	li	a0,-1
    800058c2:	bfc5                	j	800058b2 <sys_symlink+0x18e>

00000000800058c4 <sys_unlink>:
{
    800058c4:	7151                	addi	sp,sp,-240
    800058c6:	f586                	sd	ra,232(sp)
    800058c8:	f1a2                	sd	s0,224(sp)
    800058ca:	eda6                	sd	s1,216(sp)
    800058cc:	e9ca                	sd	s2,208(sp)
    800058ce:	e5ce                	sd	s3,200(sp)
    800058d0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058d2:	08000613          	li	a2,128
    800058d6:	f3040593          	addi	a1,s0,-208
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	31e080e7          	jalr	798(ra) # 80002bfa <argstr>
    800058e4:	18054163          	bltz	a0,80005a66 <sys_unlink+0x1a2>
  begin_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	a6c080e7          	jalr	-1428(ra) # 80004354 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058f0:	fb040593          	addi	a1,s0,-80
    800058f4:	f3040513          	addi	a0,s0,-208
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	85e080e7          	jalr	-1954(ra) # 80004156 <nameiparent>
    80005900:	84aa                	mv	s1,a0
    80005902:	c979                	beqz	a0,800059d8 <sys_unlink+0x114>
  ilock(dp);
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	07c080e7          	jalr	124(ra) # 80003980 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000590c:	00003597          	auipc	a1,0x3
    80005910:	dfc58593          	addi	a1,a1,-516 # 80008708 <syscalls+0x2d0>
    80005914:	fb040513          	addi	a0,s0,-80
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	534080e7          	jalr	1332(ra) # 80003e4c <namecmp>
    80005920:	14050a63          	beqz	a0,80005a74 <sys_unlink+0x1b0>
    80005924:	00003597          	auipc	a1,0x3
    80005928:	dec58593          	addi	a1,a1,-532 # 80008710 <syscalls+0x2d8>
    8000592c:	fb040513          	addi	a0,s0,-80
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	51c080e7          	jalr	1308(ra) # 80003e4c <namecmp>
    80005938:	12050e63          	beqz	a0,80005a74 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000593c:	f2c40613          	addi	a2,s0,-212
    80005940:	fb040593          	addi	a1,s0,-80
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	520080e7          	jalr	1312(ra) # 80003e66 <dirlookup>
    8000594e:	892a                	mv	s2,a0
    80005950:	12050263          	beqz	a0,80005a74 <sys_unlink+0x1b0>
  ilock(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	02c080e7          	jalr	44(ra) # 80003980 <ilock>
  if(ip->nlink < 1)
    8000595c:	04a91783          	lh	a5,74(s2)
    80005960:	08f05263          	blez	a5,800059e4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005964:	04491703          	lh	a4,68(s2)
    80005968:	4785                	li	a5,1
    8000596a:	08f70563          	beq	a4,a5,800059f4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000596e:	4641                	li	a2,16
    80005970:	4581                	li	a1,0
    80005972:	fc040513          	addi	a0,s0,-64
    80005976:	ffffb097          	auipc	ra,0xffffb
    8000597a:	494080e7          	jalr	1172(ra) # 80000e0a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000597e:	4741                	li	a4,16
    80005980:	f2c42683          	lw	a3,-212(s0)
    80005984:	fc040613          	addi	a2,s0,-64
    80005988:	4581                	li	a1,0
    8000598a:	8526                	mv	a0,s1
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	3a0080e7          	jalr	928(ra) # 80003d2c <writei>
    80005994:	47c1                	li	a5,16
    80005996:	0af51563          	bne	a0,a5,80005a40 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000599a:	04491703          	lh	a4,68(s2)
    8000599e:	4785                	li	a5,1
    800059a0:	0af70863          	beq	a4,a5,80005a50 <sys_unlink+0x18c>
  iunlockput(dp);
    800059a4:	8526                	mv	a0,s1
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	23c080e7          	jalr	572(ra) # 80003be2 <iunlockput>
  ip->nlink--;
    800059ae:	04a95783          	lhu	a5,74(s2)
    800059b2:	37fd                	addiw	a5,a5,-1
    800059b4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	efc080e7          	jalr	-260(ra) # 800038b6 <iupdate>
  iunlockput(ip);
    800059c2:	854a                	mv	a0,s2
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	21e080e7          	jalr	542(ra) # 80003be2 <iunlockput>
  end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	a08080e7          	jalr	-1528(ra) # 800043d4 <end_op>
  return 0;
    800059d4:	4501                	li	a0,0
    800059d6:	a84d                	j	80005a88 <sys_unlink+0x1c4>
    end_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	9fc080e7          	jalr	-1540(ra) # 800043d4 <end_op>
    return -1;
    800059e0:	557d                	li	a0,-1
    800059e2:	a05d                	j	80005a88 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059e4:	00003517          	auipc	a0,0x3
    800059e8:	d7450513          	addi	a0,a0,-652 # 80008758 <syscalls+0x320>
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	b44080e7          	jalr	-1212(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059f4:	04c92703          	lw	a4,76(s2)
    800059f8:	02000793          	li	a5,32
    800059fc:	f6e7f9e3          	bgeu	a5,a4,8000596e <sys_unlink+0xaa>
    80005a00:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a04:	4741                	li	a4,16
    80005a06:	86ce                	mv	a3,s3
    80005a08:	f1840613          	addi	a2,s0,-232
    80005a0c:	4581                	li	a1,0
    80005a0e:	854a                	mv	a0,s2
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	224080e7          	jalr	548(ra) # 80003c34 <readi>
    80005a18:	47c1                	li	a5,16
    80005a1a:	00f51b63          	bne	a0,a5,80005a30 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a1e:	f1845783          	lhu	a5,-232(s0)
    80005a22:	e7a1                	bnez	a5,80005a6a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a24:	29c1                	addiw	s3,s3,16
    80005a26:	04c92783          	lw	a5,76(s2)
    80005a2a:	fcf9ede3          	bltu	s3,a5,80005a04 <sys_unlink+0x140>
    80005a2e:	b781                	j	8000596e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a30:	00003517          	auipc	a0,0x3
    80005a34:	d4050513          	addi	a0,a0,-704 # 80008770 <syscalls+0x338>
    80005a38:	ffffb097          	auipc	ra,0xffffb
    80005a3c:	af8080e7          	jalr	-1288(ra) # 80000530 <panic>
    panic("unlink: writei");
    80005a40:	00003517          	auipc	a0,0x3
    80005a44:	d4850513          	addi	a0,a0,-696 # 80008788 <syscalls+0x350>
    80005a48:	ffffb097          	auipc	ra,0xffffb
    80005a4c:	ae8080e7          	jalr	-1304(ra) # 80000530 <panic>
    dp->nlink--;
    80005a50:	04a4d783          	lhu	a5,74(s1)
    80005a54:	37fd                	addiw	a5,a5,-1
    80005a56:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	e5a080e7          	jalr	-422(ra) # 800038b6 <iupdate>
    80005a64:	b781                	j	800059a4 <sys_unlink+0xe0>
    return -1;
    80005a66:	557d                	li	a0,-1
    80005a68:	a005                	j	80005a88 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	176080e7          	jalr	374(ra) # 80003be2 <iunlockput>
  iunlockput(dp);
    80005a74:	8526                	mv	a0,s1
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	16c080e7          	jalr	364(ra) # 80003be2 <iunlockput>
  end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	956080e7          	jalr	-1706(ra) # 800043d4 <end_op>
  return -1;
    80005a86:	557d                	li	a0,-1
}
    80005a88:	70ae                	ld	ra,232(sp)
    80005a8a:	740e                	ld	s0,224(sp)
    80005a8c:	64ee                	ld	s1,216(sp)
    80005a8e:	694e                	ld	s2,208(sp)
    80005a90:	69ae                	ld	s3,200(sp)
    80005a92:	616d                	addi	sp,sp,240
    80005a94:	8082                	ret

0000000080005a96 <sys_open>:

uint64
sys_open(void)
{
    80005a96:	7129                	addi	sp,sp,-320
    80005a98:	fe06                	sd	ra,312(sp)
    80005a9a:	fa22                	sd	s0,304(sp)
    80005a9c:	f626                	sd	s1,296(sp)
    80005a9e:	f24a                	sd	s2,288(sp)
    80005aa0:	ee4e                	sd	s3,280(sp)
    80005aa2:	ea52                	sd	s4,272(sp)
    80005aa4:	0280                	addi	s0,sp,320
  int n;

  char sympath[MAXPATH];
  struct inode* symip = 0;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aa6:	08000613          	li	a2,128
    80005aaa:	f5040593          	addi	a1,s0,-176
    80005aae:	4501                	li	a0,0
    80005ab0:	ffffd097          	auipc	ra,0xffffd
    80005ab4:	14a080e7          	jalr	330(ra) # 80002bfa <argstr>
    return -1;
    80005ab8:	597d                	li	s2,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aba:	0c054863          	bltz	a0,80005b8a <sys_open+0xf4>
    80005abe:	f4c40593          	addi	a1,s0,-180
    80005ac2:	4505                	li	a0,1
    80005ac4:	ffffd097          	auipc	ra,0xffffd
    80005ac8:	0f2080e7          	jalr	242(ra) # 80002bb6 <argint>
    80005acc:	0a054f63          	bltz	a0,80005b8a <sys_open+0xf4>

  begin_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	884080e7          	jalr	-1916(ra) # 80004354 <begin_op>

  if(omode & O_CREATE){
    80005ad8:	f4c42783          	lw	a5,-180(s0)
    80005adc:	2007f793          	andi	a5,a5,512
    80005ae0:	c3f9                	beqz	a5,80005ba6 <sys_open+0x110>
    ip = create(path, T_FILE, 0, 0);
    80005ae2:	4681                	li	a3,0
    80005ae4:	4601                	li	a2,0
    80005ae6:	4589                	li	a1,2
    80005ae8:	f5040513          	addi	a0,s0,-176
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	7d0080e7          	jalr	2000(ra) # 800052bc <create>
    80005af4:	84aa                	mv	s1,a0
    if(ip == 0){
    80005af6:	c15d                	beqz	a0,80005b9c <sys_open+0x106>
      end_op();
      return -1;
    }
  }

  if(!(omode &O_NOFOLLOW) && ip->type == T_SYMLINK)
    80005af8:	f4c42703          	lw	a4,-180(s0)
    80005afc:	6785                	lui	a5,0x1
    80005afe:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    80005b02:	8ff9                	and	a5,a5,a4
    80005b04:	c7f5                	beqz	a5,80005bf0 <sys_open+0x15a>
      ip=symip;
      ilock(ip);
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b06:	04449703          	lh	a4,68(s1)
    80005b0a:	478d                	li	a5,3
    80005b0c:	00f71763          	bne	a4,a5,80005b1a <sys_open+0x84>
    80005b10:	0464d703          	lhu	a4,70(s1)
    80005b14:	47a5                	li	a5,9
    80005b16:	16e7e263          	bltu	a5,a4,80005c7a <sys_open+0x1e4>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	c52080e7          	jalr	-942(ra) # 8000476c <filealloc>
    80005b22:	89aa                	mv	s3,a0
    80005b24:	18050863          	beqz	a0,80005cb4 <sys_open+0x21e>
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	752080e7          	jalr	1874(ra) # 8000527a <fdalloc>
    80005b30:	892a                	mv	s2,a0
    80005b32:	16054c63          	bltz	a0,80005caa <sys_open+0x214>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b36:	04449703          	lh	a4,68(s1)
    80005b3a:	478d                	li	a5,3
    80005b3c:	14f70a63          	beq	a4,a5,80005c90 <sys_open+0x1fa>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b40:	4789                	li	a5,2
    80005b42:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b46:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b4a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b4e:	f4c42783          	lw	a5,-180(s0)
    80005b52:	0017c713          	xori	a4,a5,1
    80005b56:	8b05                	andi	a4,a4,1
    80005b58:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b5c:	0037f713          	andi	a4,a5,3
    80005b60:	00e03733          	snez	a4,a4
    80005b64:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b68:	4007f793          	andi	a5,a5,1024
    80005b6c:	c791                	beqz	a5,80005b78 <sys_open+0xe2>
    80005b6e:	04449703          	lh	a4,68(s1)
    80005b72:	4789                	li	a5,2
    80005b74:	12f70563          	beq	a4,a5,80005c9e <sys_open+0x208>
    itrunc(ip);
  }

  iunlock(ip);
    80005b78:	8526                	mv	a0,s1
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	ec8080e7          	jalr	-312(ra) # 80003a42 <iunlock>
  end_op();
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	852080e7          	jalr	-1966(ra) # 800043d4 <end_op>

  return fd;
}
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	70f2                	ld	ra,312(sp)
    80005b8e:	7452                	ld	s0,304(sp)
    80005b90:	74b2                	ld	s1,296(sp)
    80005b92:	7912                	ld	s2,288(sp)
    80005b94:	69f2                	ld	s3,280(sp)
    80005b96:	6a52                	ld	s4,272(sp)
    80005b98:	6131                	addi	sp,sp,320
    80005b9a:	8082                	ret
      end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	838080e7          	jalr	-1992(ra) # 800043d4 <end_op>
      return -1;
    80005ba4:	b7dd                	j	80005b8a <sys_open+0xf4>
    if((ip = namei(path)) == 0){
    80005ba6:	f5040513          	addi	a0,s0,-176
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	58e080e7          	jalr	1422(ra) # 80004138 <namei>
    80005bb2:	84aa                	mv	s1,a0
    80005bb4:	c905                	beqz	a0,80005be4 <sys_open+0x14e>
    ilock(ip);
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	dca080e7          	jalr	-566(ra) # 80003980 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bbe:	04449703          	lh	a4,68(s1)
    80005bc2:	4785                	li	a5,1
    80005bc4:	f2f71ae3          	bne	a4,a5,80005af8 <sys_open+0x62>
    80005bc8:	f4c42783          	lw	a5,-180(s0)
    80005bcc:	df8d                	beqz	a5,80005b06 <sys_open+0x70>
      iunlockput(ip);
    80005bce:	8526                	mv	a0,s1
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	012080e7          	jalr	18(ra) # 80003be2 <iunlockput>
      end_op();
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	7fc080e7          	jalr	2044(ra) # 800043d4 <end_op>
      return -1;
    80005be0:	597d                	li	s2,-1
    80005be2:	b765                	j	80005b8a <sys_open+0xf4>
      end_op();
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	7f0080e7          	jalr	2032(ra) # 800043d4 <end_op>
      return -1;
    80005bec:	597d                	li	s2,-1
    80005bee:	bf71                	j	80005b8a <sys_open+0xf4>
  if(!(omode &O_NOFOLLOW) && ip->type == T_SYMLINK)
    80005bf0:	04449703          	lh	a4,68(s1)
    80005bf4:	4791                	li	a5,4
    80005bf6:	f0f718e3          	bne	a4,a5,80005b06 <sys_open+0x70>
    80005bfa:	4929                	li	s2,10
      if(readi(ip,0,(uint64)&sympath,0,MAXPATH)==-1)
    80005bfc:	59fd                	li	s3,-1
    while(ip->type == T_SYMLINK)
    80005bfe:	4a11                	li	s4,4
      if(readi(ip,0,(uint64)&sympath,0,MAXPATH)==-1)
    80005c00:	08000713          	li	a4,128
    80005c04:	4681                	li	a3,0
    80005c06:	ec840613          	addi	a2,s0,-312
    80005c0a:	4581                	li	a1,0
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	026080e7          	jalr	38(ra) # 80003c34 <readi>
    80005c16:	03350b63          	beq	a0,s3,80005c4c <sys_open+0x1b6>
      iunlockput(ip);
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	fc6080e7          	jalr	-58(ra) # 80003be2 <iunlockput>
      if((symip = namei(sympath)) == 0)
    80005c24:	ec840513          	addi	a0,s0,-312
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	510080e7          	jalr	1296(ra) # 80004138 <namei>
    80005c30:	84aa                	mv	s1,a0
    80005c32:	c905                	beqz	a0,80005c62 <sys_open+0x1cc>
      if(i==10)
    80005c34:	397d                	addiw	s2,s2,-1
    80005c36:	02090c63          	beqz	s2,80005c6e <sys_open+0x1d8>
      ilock(ip);
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	d46080e7          	jalr	-698(ra) # 80003980 <ilock>
    while(ip->type == T_SYMLINK)
    80005c42:	04449783          	lh	a5,68(s1)
    80005c46:	fb478de3          	beq	a5,s4,80005c00 <sys_open+0x16a>
    80005c4a:	bd75                	j	80005b06 <sys_open+0x70>
        iunlockput(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	f94080e7          	jalr	-108(ra) # 80003be2 <iunlockput>
        end_op();
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	77e080e7          	jalr	1918(ra) # 800043d4 <end_op>
        return -1;
    80005c5e:	597d                	li	s2,-1
    80005c60:	b72d                	j	80005b8a <sys_open+0xf4>
        end_op();
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	772080e7          	jalr	1906(ra) # 800043d4 <end_op>
        return -1;
    80005c6a:	597d                	li	s2,-1
    80005c6c:	bf39                	j	80005b8a <sys_open+0xf4>
        end_op();
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	766080e7          	jalr	1894(ra) # 800043d4 <end_op>
        return -1;
    80005c76:	597d                	li	s2,-1
    80005c78:	bf09                	j	80005b8a <sys_open+0xf4>
    iunlockput(ip);
    80005c7a:	8526                	mv	a0,s1
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	f66080e7          	jalr	-154(ra) # 80003be2 <iunlockput>
    end_op();
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	750080e7          	jalr	1872(ra) # 800043d4 <end_op>
    return -1;
    80005c8c:	597d                	li	s2,-1
    80005c8e:	bdf5                	j	80005b8a <sys_open+0xf4>
    f->type = FD_DEVICE;
    80005c90:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c94:	04649783          	lh	a5,70(s1)
    80005c98:	02f99223          	sh	a5,36(s3)
    80005c9c:	b57d                	j	80005b4a <sys_open+0xb4>
    itrunc(ip);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	dee080e7          	jalr	-530(ra) # 80003a8e <itrunc>
    80005ca8:	bdc1                	j	80005b78 <sys_open+0xe2>
      fileclose(f);
    80005caa:	854e                	mv	a0,s3
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	b7c080e7          	jalr	-1156(ra) # 80004828 <fileclose>
    iunlockput(ip);
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	f2c080e7          	jalr	-212(ra) # 80003be2 <iunlockput>
    end_op();
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	716080e7          	jalr	1814(ra) # 800043d4 <end_op>
    return -1;
    80005cc6:	597d                	li	s2,-1
    80005cc8:	b5c9                	j	80005b8a <sys_open+0xf4>

0000000080005cca <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cca:	7175                	addi	sp,sp,-144
    80005ccc:	e506                	sd	ra,136(sp)
    80005cce:	e122                	sd	s0,128(sp)
    80005cd0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	682080e7          	jalr	1666(ra) # 80004354 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cda:	08000613          	li	a2,128
    80005cde:	f7040593          	addi	a1,s0,-144
    80005ce2:	4501                	li	a0,0
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	f16080e7          	jalr	-234(ra) # 80002bfa <argstr>
    80005cec:	02054963          	bltz	a0,80005d1e <sys_mkdir+0x54>
    80005cf0:	4681                	li	a3,0
    80005cf2:	4601                	li	a2,0
    80005cf4:	4585                	li	a1,1
    80005cf6:	f7040513          	addi	a0,s0,-144
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	5c2080e7          	jalr	1474(ra) # 800052bc <create>
    80005d02:	cd11                	beqz	a0,80005d1e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	ede080e7          	jalr	-290(ra) # 80003be2 <iunlockput>
  end_op();
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	6c8080e7          	jalr	1736(ra) # 800043d4 <end_op>
  return 0;
    80005d14:	4501                	li	a0,0
}
    80005d16:	60aa                	ld	ra,136(sp)
    80005d18:	640a                	ld	s0,128(sp)
    80005d1a:	6149                	addi	sp,sp,144
    80005d1c:	8082                	ret
    end_op();
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	6b6080e7          	jalr	1718(ra) # 800043d4 <end_op>
    return -1;
    80005d26:	557d                	li	a0,-1
    80005d28:	b7fd                	j	80005d16 <sys_mkdir+0x4c>

0000000080005d2a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d2a:	7135                	addi	sp,sp,-160
    80005d2c:	ed06                	sd	ra,152(sp)
    80005d2e:	e922                	sd	s0,144(sp)
    80005d30:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	622080e7          	jalr	1570(ra) # 80004354 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d3a:	08000613          	li	a2,128
    80005d3e:	f7040593          	addi	a1,s0,-144
    80005d42:	4501                	li	a0,0
    80005d44:	ffffd097          	auipc	ra,0xffffd
    80005d48:	eb6080e7          	jalr	-330(ra) # 80002bfa <argstr>
    80005d4c:	04054a63          	bltz	a0,80005da0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d50:	f6c40593          	addi	a1,s0,-148
    80005d54:	4505                	li	a0,1
    80005d56:	ffffd097          	auipc	ra,0xffffd
    80005d5a:	e60080e7          	jalr	-416(ra) # 80002bb6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d5e:	04054163          	bltz	a0,80005da0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d62:	f6840593          	addi	a1,s0,-152
    80005d66:	4509                	li	a0,2
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	e4e080e7          	jalr	-434(ra) # 80002bb6 <argint>
     argint(1, &major) < 0 ||
    80005d70:	02054863          	bltz	a0,80005da0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d74:	f6841683          	lh	a3,-152(s0)
    80005d78:	f6c41603          	lh	a2,-148(s0)
    80005d7c:	458d                	li	a1,3
    80005d7e:	f7040513          	addi	a0,s0,-144
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	53a080e7          	jalr	1338(ra) # 800052bc <create>
     argint(2, &minor) < 0 ||
    80005d8a:	c919                	beqz	a0,80005da0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d8c:	ffffe097          	auipc	ra,0xffffe
    80005d90:	e56080e7          	jalr	-426(ra) # 80003be2 <iunlockput>
  end_op();
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	640080e7          	jalr	1600(ra) # 800043d4 <end_op>
  return 0;
    80005d9c:	4501                	li	a0,0
    80005d9e:	a031                	j	80005daa <sys_mknod+0x80>
    end_op();
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	634080e7          	jalr	1588(ra) # 800043d4 <end_op>
    return -1;
    80005da8:	557d                	li	a0,-1
}
    80005daa:	60ea                	ld	ra,152(sp)
    80005dac:	644a                	ld	s0,144(sp)
    80005dae:	610d                	addi	sp,sp,160
    80005db0:	8082                	ret

0000000080005db2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005db2:	7135                	addi	sp,sp,-160
    80005db4:	ed06                	sd	ra,152(sp)
    80005db6:	e922                	sd	s0,144(sp)
    80005db8:	e526                	sd	s1,136(sp)
    80005dba:	e14a                	sd	s2,128(sp)
    80005dbc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dbe:	ffffc097          	auipc	ra,0xffffc
    80005dc2:	d3a080e7          	jalr	-710(ra) # 80001af8 <myproc>
    80005dc6:	892a                	mv	s2,a0
  
  begin_op();
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	58c080e7          	jalr	1420(ra) # 80004354 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dd0:	08000613          	li	a2,128
    80005dd4:	f6040593          	addi	a1,s0,-160
    80005dd8:	4501                	li	a0,0
    80005dda:	ffffd097          	auipc	ra,0xffffd
    80005dde:	e20080e7          	jalr	-480(ra) # 80002bfa <argstr>
    80005de2:	04054b63          	bltz	a0,80005e38 <sys_chdir+0x86>
    80005de6:	f6040513          	addi	a0,s0,-160
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	34e080e7          	jalr	846(ra) # 80004138 <namei>
    80005df2:	84aa                	mv	s1,a0
    80005df4:	c131                	beqz	a0,80005e38 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	b8a080e7          	jalr	-1142(ra) # 80003980 <ilock>
  if(ip->type != T_DIR){
    80005dfe:	04449703          	lh	a4,68(s1)
    80005e02:	4785                	li	a5,1
    80005e04:	04f71063          	bne	a4,a5,80005e44 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e08:	8526                	mv	a0,s1
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	c38080e7          	jalr	-968(ra) # 80003a42 <iunlock>
  iput(p->cwd);
    80005e12:	15093503          	ld	a0,336(s2)
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	d24080e7          	jalr	-732(ra) # 80003b3a <iput>
  end_op();
    80005e1e:	ffffe097          	auipc	ra,0xffffe
    80005e22:	5b6080e7          	jalr	1462(ra) # 800043d4 <end_op>
  p->cwd = ip;
    80005e26:	14993823          	sd	s1,336(s2)
  return 0;
    80005e2a:	4501                	li	a0,0
}
    80005e2c:	60ea                	ld	ra,152(sp)
    80005e2e:	644a                	ld	s0,144(sp)
    80005e30:	64aa                	ld	s1,136(sp)
    80005e32:	690a                	ld	s2,128(sp)
    80005e34:	610d                	addi	sp,sp,160
    80005e36:	8082                	ret
    end_op();
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	59c080e7          	jalr	1436(ra) # 800043d4 <end_op>
    return -1;
    80005e40:	557d                	li	a0,-1
    80005e42:	b7ed                	j	80005e2c <sys_chdir+0x7a>
    iunlockput(ip);
    80005e44:	8526                	mv	a0,s1
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	d9c080e7          	jalr	-612(ra) # 80003be2 <iunlockput>
    end_op();
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	586080e7          	jalr	1414(ra) # 800043d4 <end_op>
    return -1;
    80005e56:	557d                	li	a0,-1
    80005e58:	bfd1                	j	80005e2c <sys_chdir+0x7a>

0000000080005e5a <sys_exec>:

uint64
sys_exec(void)
{
    80005e5a:	7145                	addi	sp,sp,-464
    80005e5c:	e786                	sd	ra,456(sp)
    80005e5e:	e3a2                	sd	s0,448(sp)
    80005e60:	ff26                	sd	s1,440(sp)
    80005e62:	fb4a                	sd	s2,432(sp)
    80005e64:	f74e                	sd	s3,424(sp)
    80005e66:	f352                	sd	s4,416(sp)
    80005e68:	ef56                	sd	s5,408(sp)
    80005e6a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e6c:	08000613          	li	a2,128
    80005e70:	f4040593          	addi	a1,s0,-192
    80005e74:	4501                	li	a0,0
    80005e76:	ffffd097          	auipc	ra,0xffffd
    80005e7a:	d84080e7          	jalr	-636(ra) # 80002bfa <argstr>
    return -1;
    80005e7e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e80:	0c054a63          	bltz	a0,80005f54 <sys_exec+0xfa>
    80005e84:	e3840593          	addi	a1,s0,-456
    80005e88:	4505                	li	a0,1
    80005e8a:	ffffd097          	auipc	ra,0xffffd
    80005e8e:	d4e080e7          	jalr	-690(ra) # 80002bd8 <argaddr>
    80005e92:	0c054163          	bltz	a0,80005f54 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e96:	10000613          	li	a2,256
    80005e9a:	4581                	li	a1,0
    80005e9c:	e4040513          	addi	a0,s0,-448
    80005ea0:	ffffb097          	auipc	ra,0xffffb
    80005ea4:	f6a080e7          	jalr	-150(ra) # 80000e0a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ea8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005eac:	89a6                	mv	s3,s1
    80005eae:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eb0:	02000a13          	li	s4,32
    80005eb4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005eb8:	00391513          	slli	a0,s2,0x3
    80005ebc:	e3040593          	addi	a1,s0,-464
    80005ec0:	e3843783          	ld	a5,-456(s0)
    80005ec4:	953e                	add	a0,a0,a5
    80005ec6:	ffffd097          	auipc	ra,0xffffd
    80005eca:	c56080e7          	jalr	-938(ra) # 80002b1c <fetchaddr>
    80005ece:	02054a63          	bltz	a0,80005f02 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ed2:	e3043783          	ld	a5,-464(s0)
    80005ed6:	c3b9                	beqz	a5,80005f1c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ed8:	ffffb097          	auipc	ra,0xffffb
    80005edc:	cac080e7          	jalr	-852(ra) # 80000b84 <kalloc>
    80005ee0:	85aa                	mv	a1,a0
    80005ee2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ee6:	cd11                	beqz	a0,80005f02 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ee8:	6605                	lui	a2,0x1
    80005eea:	e3043503          	ld	a0,-464(s0)
    80005eee:	ffffd097          	auipc	ra,0xffffd
    80005ef2:	c80080e7          	jalr	-896(ra) # 80002b6e <fetchstr>
    80005ef6:	00054663          	bltz	a0,80005f02 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005efa:	0905                	addi	s2,s2,1
    80005efc:	09a1                	addi	s3,s3,8
    80005efe:	fb491be3          	bne	s2,s4,80005eb4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f02:	10048913          	addi	s2,s1,256
    80005f06:	6088                	ld	a0,0(s1)
    80005f08:	c529                	beqz	a0,80005f52 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f0a:	ffffb097          	auipc	ra,0xffffb
    80005f0e:	ae0080e7          	jalr	-1312(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f12:	04a1                	addi	s1,s1,8
    80005f14:	ff2499e3          	bne	s1,s2,80005f06 <sys_exec+0xac>
  return -1;
    80005f18:	597d                	li	s2,-1
    80005f1a:	a82d                	j	80005f54 <sys_exec+0xfa>
      argv[i] = 0;
    80005f1c:	0a8e                	slli	s5,s5,0x3
    80005f1e:	fc040793          	addi	a5,s0,-64
    80005f22:	9abe                	add	s5,s5,a5
    80005f24:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f28:	e4040593          	addi	a1,s0,-448
    80005f2c:	f4040513          	addi	a0,s0,-192
    80005f30:	fffff097          	auipc	ra,0xfffff
    80005f34:	f58080e7          	jalr	-168(ra) # 80004e88 <exec>
    80005f38:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f3a:	10048993          	addi	s3,s1,256
    80005f3e:	6088                	ld	a0,0(s1)
    80005f40:	c911                	beqz	a0,80005f54 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f42:	ffffb097          	auipc	ra,0xffffb
    80005f46:	aa8080e7          	jalr	-1368(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f4a:	04a1                	addi	s1,s1,8
    80005f4c:	ff3499e3          	bne	s1,s3,80005f3e <sys_exec+0xe4>
    80005f50:	a011                	j	80005f54 <sys_exec+0xfa>
  return -1;
    80005f52:	597d                	li	s2,-1
}
    80005f54:	854a                	mv	a0,s2
    80005f56:	60be                	ld	ra,456(sp)
    80005f58:	641e                	ld	s0,448(sp)
    80005f5a:	74fa                	ld	s1,440(sp)
    80005f5c:	795a                	ld	s2,432(sp)
    80005f5e:	79ba                	ld	s3,424(sp)
    80005f60:	7a1a                	ld	s4,416(sp)
    80005f62:	6afa                	ld	s5,408(sp)
    80005f64:	6179                	addi	sp,sp,464
    80005f66:	8082                	ret

0000000080005f68 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f68:	7139                	addi	sp,sp,-64
    80005f6a:	fc06                	sd	ra,56(sp)
    80005f6c:	f822                	sd	s0,48(sp)
    80005f6e:	f426                	sd	s1,40(sp)
    80005f70:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f72:	ffffc097          	auipc	ra,0xffffc
    80005f76:	b86080e7          	jalr	-1146(ra) # 80001af8 <myproc>
    80005f7a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f7c:	fd840593          	addi	a1,s0,-40
    80005f80:	4501                	li	a0,0
    80005f82:	ffffd097          	auipc	ra,0xffffd
    80005f86:	c56080e7          	jalr	-938(ra) # 80002bd8 <argaddr>
    return -1;
    80005f8a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f8c:	0e054063          	bltz	a0,8000606c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f90:	fc840593          	addi	a1,s0,-56
    80005f94:	fd040513          	addi	a0,s0,-48
    80005f98:	fffff097          	auipc	ra,0xfffff
    80005f9c:	bc0080e7          	jalr	-1088(ra) # 80004b58 <pipealloc>
    return -1;
    80005fa0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fa2:	0c054563          	bltz	a0,8000606c <sys_pipe+0x104>
  fd0 = -1;
    80005fa6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005faa:	fd043503          	ld	a0,-48(s0)
    80005fae:	fffff097          	auipc	ra,0xfffff
    80005fb2:	2cc080e7          	jalr	716(ra) # 8000527a <fdalloc>
    80005fb6:	fca42223          	sw	a0,-60(s0)
    80005fba:	08054c63          	bltz	a0,80006052 <sys_pipe+0xea>
    80005fbe:	fc843503          	ld	a0,-56(s0)
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	2b8080e7          	jalr	696(ra) # 8000527a <fdalloc>
    80005fca:	fca42023          	sw	a0,-64(s0)
    80005fce:	06054863          	bltz	a0,8000603e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fd2:	4691                	li	a3,4
    80005fd4:	fc440613          	addi	a2,s0,-60
    80005fd8:	fd843583          	ld	a1,-40(s0)
    80005fdc:	68a8                	ld	a0,80(s1)
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	7b0080e7          	jalr	1968(ra) # 8000178e <copyout>
    80005fe6:	02054063          	bltz	a0,80006006 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fea:	4691                	li	a3,4
    80005fec:	fc040613          	addi	a2,s0,-64
    80005ff0:	fd843583          	ld	a1,-40(s0)
    80005ff4:	0591                	addi	a1,a1,4
    80005ff6:	68a8                	ld	a0,80(s1)
    80005ff8:	ffffb097          	auipc	ra,0xffffb
    80005ffc:	796080e7          	jalr	1942(ra) # 8000178e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006000:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006002:	06055563          	bgez	a0,8000606c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006006:	fc442783          	lw	a5,-60(s0)
    8000600a:	07e9                	addi	a5,a5,26
    8000600c:	078e                	slli	a5,a5,0x3
    8000600e:	97a6                	add	a5,a5,s1
    80006010:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006014:	fc042503          	lw	a0,-64(s0)
    80006018:	0569                	addi	a0,a0,26
    8000601a:	050e                	slli	a0,a0,0x3
    8000601c:	9526                	add	a0,a0,s1
    8000601e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006022:	fd043503          	ld	a0,-48(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	802080e7          	jalr	-2046(ra) # 80004828 <fileclose>
    fileclose(wf);
    8000602e:	fc843503          	ld	a0,-56(s0)
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	7f6080e7          	jalr	2038(ra) # 80004828 <fileclose>
    return -1;
    8000603a:	57fd                	li	a5,-1
    8000603c:	a805                	j	8000606c <sys_pipe+0x104>
    if(fd0 >= 0)
    8000603e:	fc442783          	lw	a5,-60(s0)
    80006042:	0007c863          	bltz	a5,80006052 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006046:	01a78513          	addi	a0,a5,26
    8000604a:	050e                	slli	a0,a0,0x3
    8000604c:	9526                	add	a0,a0,s1
    8000604e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006052:	fd043503          	ld	a0,-48(s0)
    80006056:	ffffe097          	auipc	ra,0xffffe
    8000605a:	7d2080e7          	jalr	2002(ra) # 80004828 <fileclose>
    fileclose(wf);
    8000605e:	fc843503          	ld	a0,-56(s0)
    80006062:	ffffe097          	auipc	ra,0xffffe
    80006066:	7c6080e7          	jalr	1990(ra) # 80004828 <fileclose>
    return -1;
    8000606a:	57fd                	li	a5,-1
}
    8000606c:	853e                	mv	a0,a5
    8000606e:	70e2                	ld	ra,56(sp)
    80006070:	7442                	ld	s0,48(sp)
    80006072:	74a2                	ld	s1,40(sp)
    80006074:	6121                	addi	sp,sp,64
    80006076:	8082                	ret
	...

0000000080006080 <kernelvec>:
    80006080:	7111                	addi	sp,sp,-256
    80006082:	e006                	sd	ra,0(sp)
    80006084:	e40a                	sd	sp,8(sp)
    80006086:	e80e                	sd	gp,16(sp)
    80006088:	ec12                	sd	tp,24(sp)
    8000608a:	f016                	sd	t0,32(sp)
    8000608c:	f41a                	sd	t1,40(sp)
    8000608e:	f81e                	sd	t2,48(sp)
    80006090:	fc22                	sd	s0,56(sp)
    80006092:	e0a6                	sd	s1,64(sp)
    80006094:	e4aa                	sd	a0,72(sp)
    80006096:	e8ae                	sd	a1,80(sp)
    80006098:	ecb2                	sd	a2,88(sp)
    8000609a:	f0b6                	sd	a3,96(sp)
    8000609c:	f4ba                	sd	a4,104(sp)
    8000609e:	f8be                	sd	a5,112(sp)
    800060a0:	fcc2                	sd	a6,120(sp)
    800060a2:	e146                	sd	a7,128(sp)
    800060a4:	e54a                	sd	s2,136(sp)
    800060a6:	e94e                	sd	s3,144(sp)
    800060a8:	ed52                	sd	s4,152(sp)
    800060aa:	f156                	sd	s5,160(sp)
    800060ac:	f55a                	sd	s6,168(sp)
    800060ae:	f95e                	sd	s7,176(sp)
    800060b0:	fd62                	sd	s8,184(sp)
    800060b2:	e1e6                	sd	s9,192(sp)
    800060b4:	e5ea                	sd	s10,200(sp)
    800060b6:	e9ee                	sd	s11,208(sp)
    800060b8:	edf2                	sd	t3,216(sp)
    800060ba:	f1f6                	sd	t4,224(sp)
    800060bc:	f5fa                	sd	t5,232(sp)
    800060be:	f9fe                	sd	t6,240(sp)
    800060c0:	929fc0ef          	jal	ra,800029e8 <kerneltrap>
    800060c4:	6082                	ld	ra,0(sp)
    800060c6:	6122                	ld	sp,8(sp)
    800060c8:	61c2                	ld	gp,16(sp)
    800060ca:	7282                	ld	t0,32(sp)
    800060cc:	7322                	ld	t1,40(sp)
    800060ce:	73c2                	ld	t2,48(sp)
    800060d0:	7462                	ld	s0,56(sp)
    800060d2:	6486                	ld	s1,64(sp)
    800060d4:	6526                	ld	a0,72(sp)
    800060d6:	65c6                	ld	a1,80(sp)
    800060d8:	6666                	ld	a2,88(sp)
    800060da:	7686                	ld	a3,96(sp)
    800060dc:	7726                	ld	a4,104(sp)
    800060de:	77c6                	ld	a5,112(sp)
    800060e0:	7866                	ld	a6,120(sp)
    800060e2:	688a                	ld	a7,128(sp)
    800060e4:	692a                	ld	s2,136(sp)
    800060e6:	69ca                	ld	s3,144(sp)
    800060e8:	6a6a                	ld	s4,152(sp)
    800060ea:	7a8a                	ld	s5,160(sp)
    800060ec:	7b2a                	ld	s6,168(sp)
    800060ee:	7bca                	ld	s7,176(sp)
    800060f0:	7c6a                	ld	s8,184(sp)
    800060f2:	6c8e                	ld	s9,192(sp)
    800060f4:	6d2e                	ld	s10,200(sp)
    800060f6:	6dce                	ld	s11,208(sp)
    800060f8:	6e6e                	ld	t3,216(sp)
    800060fa:	7e8e                	ld	t4,224(sp)
    800060fc:	7f2e                	ld	t5,232(sp)
    800060fe:	7fce                	ld	t6,240(sp)
    80006100:	6111                	addi	sp,sp,256
    80006102:	10200073          	sret
    80006106:	00000013          	nop
    8000610a:	00000013          	nop
    8000610e:	0001                	nop

0000000080006110 <timervec>:
    80006110:	34051573          	csrrw	a0,mscratch,a0
    80006114:	e10c                	sd	a1,0(a0)
    80006116:	e510                	sd	a2,8(a0)
    80006118:	e914                	sd	a3,16(a0)
    8000611a:	6d0c                	ld	a1,24(a0)
    8000611c:	7110                	ld	a2,32(a0)
    8000611e:	6194                	ld	a3,0(a1)
    80006120:	96b2                	add	a3,a3,a2
    80006122:	e194                	sd	a3,0(a1)
    80006124:	4589                	li	a1,2
    80006126:	14459073          	csrw	sip,a1
    8000612a:	6914                	ld	a3,16(a0)
    8000612c:	6510                	ld	a2,8(a0)
    8000612e:	610c                	ld	a1,0(a0)
    80006130:	34051573          	csrrw	a0,mscratch,a0
    80006134:	30200073          	mret
	...

000000008000613a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000613a:	1141                	addi	sp,sp,-16
    8000613c:	e422                	sd	s0,8(sp)
    8000613e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006140:	0c0007b7          	lui	a5,0xc000
    80006144:	4705                	li	a4,1
    80006146:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006148:	c3d8                	sw	a4,4(a5)
}
    8000614a:	6422                	ld	s0,8(sp)
    8000614c:	0141                	addi	sp,sp,16
    8000614e:	8082                	ret

0000000080006150 <plicinithart>:

void
plicinithart(void)
{
    80006150:	1141                	addi	sp,sp,-16
    80006152:	e406                	sd	ra,8(sp)
    80006154:	e022                	sd	s0,0(sp)
    80006156:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	974080e7          	jalr	-1676(ra) # 80001acc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006160:	0085171b          	slliw	a4,a0,0x8
    80006164:	0c0027b7          	lui	a5,0xc002
    80006168:	97ba                	add	a5,a5,a4
    8000616a:	40200713          	li	a4,1026
    8000616e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006172:	00d5151b          	slliw	a0,a0,0xd
    80006176:	0c2017b7          	lui	a5,0xc201
    8000617a:	953e                	add	a0,a0,a5
    8000617c:	00052023          	sw	zero,0(a0)
}
    80006180:	60a2                	ld	ra,8(sp)
    80006182:	6402                	ld	s0,0(sp)
    80006184:	0141                	addi	sp,sp,16
    80006186:	8082                	ret

0000000080006188 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006188:	1141                	addi	sp,sp,-16
    8000618a:	e406                	sd	ra,8(sp)
    8000618c:	e022                	sd	s0,0(sp)
    8000618e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006190:	ffffc097          	auipc	ra,0xffffc
    80006194:	93c080e7          	jalr	-1732(ra) # 80001acc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006198:	00d5179b          	slliw	a5,a0,0xd
    8000619c:	0c201537          	lui	a0,0xc201
    800061a0:	953e                	add	a0,a0,a5
  return irq;
}
    800061a2:	4148                	lw	a0,4(a0)
    800061a4:	60a2                	ld	ra,8(sp)
    800061a6:	6402                	ld	s0,0(sp)
    800061a8:	0141                	addi	sp,sp,16
    800061aa:	8082                	ret

00000000800061ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061ac:	1101                	addi	sp,sp,-32
    800061ae:	ec06                	sd	ra,24(sp)
    800061b0:	e822                	sd	s0,16(sp)
    800061b2:	e426                	sd	s1,8(sp)
    800061b4:	1000                	addi	s0,sp,32
    800061b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061b8:	ffffc097          	auipc	ra,0xffffc
    800061bc:	914080e7          	jalr	-1772(ra) # 80001acc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061c0:	00d5151b          	slliw	a0,a0,0xd
    800061c4:	0c2017b7          	lui	a5,0xc201
    800061c8:	97aa                	add	a5,a5,a0
    800061ca:	c3c4                	sw	s1,4(a5)
}
    800061cc:	60e2                	ld	ra,24(sp)
    800061ce:	6442                	ld	s0,16(sp)
    800061d0:	64a2                	ld	s1,8(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret

00000000800061d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061d6:	1141                	addi	sp,sp,-16
    800061d8:	e406                	sd	ra,8(sp)
    800061da:	e022                	sd	s0,0(sp)
    800061dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061de:	479d                	li	a5,7
    800061e0:	06a7c963          	blt	a5,a0,80006252 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061e4:	0001b797          	auipc	a5,0x1b
    800061e8:	e1c78793          	addi	a5,a5,-484 # 80021000 <disk>
    800061ec:	00a78733          	add	a4,a5,a0
    800061f0:	6789                	lui	a5,0x2
    800061f2:	97ba                	add	a5,a5,a4
    800061f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061f8:	e7ad                	bnez	a5,80006262 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061fa:	00451793          	slli	a5,a0,0x4
    800061fe:	0001d717          	auipc	a4,0x1d
    80006202:	e0270713          	addi	a4,a4,-510 # 80023000 <disk+0x2000>
    80006206:	6314                	ld	a3,0(a4)
    80006208:	96be                	add	a3,a3,a5
    8000620a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000620e:	6314                	ld	a3,0(a4)
    80006210:	96be                	add	a3,a3,a5
    80006212:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006216:	6314                	ld	a3,0(a4)
    80006218:	96be                	add	a3,a3,a5
    8000621a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000621e:	6318                	ld	a4,0(a4)
    80006220:	97ba                	add	a5,a5,a4
    80006222:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006226:	0001b797          	auipc	a5,0x1b
    8000622a:	dda78793          	addi	a5,a5,-550 # 80021000 <disk>
    8000622e:	97aa                	add	a5,a5,a0
    80006230:	6509                	lui	a0,0x2
    80006232:	953e                	add	a0,a0,a5
    80006234:	4785                	li	a5,1
    80006236:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000623a:	0001d517          	auipc	a0,0x1d
    8000623e:	dde50513          	addi	a0,a0,-546 # 80023018 <disk+0x2018>
    80006242:	ffffc097          	auipc	ra,0xffffc
    80006246:	24c080e7          	jalr	588(ra) # 8000248e <wakeup>
}
    8000624a:	60a2                	ld	ra,8(sp)
    8000624c:	6402                	ld	s0,0(sp)
    8000624e:	0141                	addi	sp,sp,16
    80006250:	8082                	ret
    panic("free_desc 1");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	54650513          	addi	a0,a0,1350 # 80008798 <syscalls+0x360>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2d6080e7          	jalr	726(ra) # 80000530 <panic>
    panic("free_desc 2");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	54650513          	addi	a0,a0,1350 # 800087a8 <syscalls+0x370>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2c6080e7          	jalr	710(ra) # 80000530 <panic>

0000000080006272 <virtio_disk_init>:
{
    80006272:	1101                	addi	sp,sp,-32
    80006274:	ec06                	sd	ra,24(sp)
    80006276:	e822                	sd	s0,16(sp)
    80006278:	e426                	sd	s1,8(sp)
    8000627a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000627c:	00002597          	auipc	a1,0x2
    80006280:	53c58593          	addi	a1,a1,1340 # 800087b8 <syscalls+0x380>
    80006284:	0001d517          	auipc	a0,0x1d
    80006288:	ea450513          	addi	a0,a0,-348 # 80023128 <disk+0x2128>
    8000628c:	ffffb097          	auipc	ra,0xffffb
    80006290:	9f2080e7          	jalr	-1550(ra) # 80000c7e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006294:	100017b7          	lui	a5,0x10001
    80006298:	4398                	lw	a4,0(a5)
    8000629a:	2701                	sext.w	a4,a4
    8000629c:	747277b7          	lui	a5,0x74727
    800062a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062a4:	0ef71163          	bne	a4,a5,80006386 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062a8:	100017b7          	lui	a5,0x10001
    800062ac:	43dc                	lw	a5,4(a5)
    800062ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062b0:	4705                	li	a4,1
    800062b2:	0ce79a63          	bne	a5,a4,80006386 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062b6:	100017b7          	lui	a5,0x10001
    800062ba:	479c                	lw	a5,8(a5)
    800062bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062be:	4709                	li	a4,2
    800062c0:	0ce79363          	bne	a5,a4,80006386 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062c4:	100017b7          	lui	a5,0x10001
    800062c8:	47d8                	lw	a4,12(a5)
    800062ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062cc:	554d47b7          	lui	a5,0x554d4
    800062d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062d4:	0af71963          	bne	a4,a5,80006386 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	4705                	li	a4,1
    800062de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062e0:	470d                	li	a4,3
    800062e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062e6:	c7ffe737          	lui	a4,0xc7ffe
    800062ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fda75f>
    800062ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062f0:	2701                	sext.w	a4,a4
    800062f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f4:	472d                	li	a4,11
    800062f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f8:	473d                	li	a4,15
    800062fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062fc:	6705                	lui	a4,0x1
    800062fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006300:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006304:	5bdc                	lw	a5,52(a5)
    80006306:	2781                	sext.w	a5,a5
  if(max == 0)
    80006308:	c7d9                	beqz	a5,80006396 <virtio_disk_init+0x124>
  if(max < NUM)
    8000630a:	471d                	li	a4,7
    8000630c:	08f77d63          	bgeu	a4,a5,800063a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006310:	100014b7          	lui	s1,0x10001
    80006314:	47a1                	li	a5,8
    80006316:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006318:	6609                	lui	a2,0x2
    8000631a:	4581                	li	a1,0
    8000631c:	0001b517          	auipc	a0,0x1b
    80006320:	ce450513          	addi	a0,a0,-796 # 80021000 <disk>
    80006324:	ffffb097          	auipc	ra,0xffffb
    80006328:	ae6080e7          	jalr	-1306(ra) # 80000e0a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000632c:	0001b717          	auipc	a4,0x1b
    80006330:	cd470713          	addi	a4,a4,-812 # 80021000 <disk>
    80006334:	00c75793          	srli	a5,a4,0xc
    80006338:	2781                	sext.w	a5,a5
    8000633a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000633c:	0001d797          	auipc	a5,0x1d
    80006340:	cc478793          	addi	a5,a5,-828 # 80023000 <disk+0x2000>
    80006344:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006346:	0001b717          	auipc	a4,0x1b
    8000634a:	d3a70713          	addi	a4,a4,-710 # 80021080 <disk+0x80>
    8000634e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006350:	0001c717          	auipc	a4,0x1c
    80006354:	cb070713          	addi	a4,a4,-848 # 80022000 <disk+0x1000>
    80006358:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000635a:	4705                	li	a4,1
    8000635c:	00e78c23          	sb	a4,24(a5)
    80006360:	00e78ca3          	sb	a4,25(a5)
    80006364:	00e78d23          	sb	a4,26(a5)
    80006368:	00e78da3          	sb	a4,27(a5)
    8000636c:	00e78e23          	sb	a4,28(a5)
    80006370:	00e78ea3          	sb	a4,29(a5)
    80006374:	00e78f23          	sb	a4,30(a5)
    80006378:	00e78fa3          	sb	a4,31(a5)
}
    8000637c:	60e2                	ld	ra,24(sp)
    8000637e:	6442                	ld	s0,16(sp)
    80006380:	64a2                	ld	s1,8(sp)
    80006382:	6105                	addi	sp,sp,32
    80006384:	8082                	ret
    panic("could not find virtio disk");
    80006386:	00002517          	auipc	a0,0x2
    8000638a:	44250513          	addi	a0,a0,1090 # 800087c8 <syscalls+0x390>
    8000638e:	ffffa097          	auipc	ra,0xffffa
    80006392:	1a2080e7          	jalr	418(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80006396:	00002517          	auipc	a0,0x2
    8000639a:	45250513          	addi	a0,a0,1106 # 800087e8 <syscalls+0x3b0>
    8000639e:	ffffa097          	auipc	ra,0xffffa
    800063a2:	192080e7          	jalr	402(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    800063a6:	00002517          	auipc	a0,0x2
    800063aa:	46250513          	addi	a0,a0,1122 # 80008808 <syscalls+0x3d0>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	182080e7          	jalr	386(ra) # 80000530 <panic>

00000000800063b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063b6:	7159                	addi	sp,sp,-112
    800063b8:	f486                	sd	ra,104(sp)
    800063ba:	f0a2                	sd	s0,96(sp)
    800063bc:	eca6                	sd	s1,88(sp)
    800063be:	e8ca                	sd	s2,80(sp)
    800063c0:	e4ce                	sd	s3,72(sp)
    800063c2:	e0d2                	sd	s4,64(sp)
    800063c4:	fc56                	sd	s5,56(sp)
    800063c6:	f85a                	sd	s6,48(sp)
    800063c8:	f45e                	sd	s7,40(sp)
    800063ca:	f062                	sd	s8,32(sp)
    800063cc:	ec66                	sd	s9,24(sp)
    800063ce:	e86a                	sd	s10,16(sp)
    800063d0:	1880                	addi	s0,sp,112
    800063d2:	892a                	mv	s2,a0
    800063d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063d6:	00c52c83          	lw	s9,12(a0)
    800063da:	001c9c9b          	slliw	s9,s9,0x1
    800063de:	1c82                	slli	s9,s9,0x20
    800063e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063e4:	0001d517          	auipc	a0,0x1d
    800063e8:	d4450513          	addi	a0,a0,-700 # 80023128 <disk+0x2128>
    800063ec:	ffffb097          	auipc	ra,0xffffb
    800063f0:	922080e7          	jalr	-1758(ra) # 80000d0e <acquire>
  for(int i = 0; i < 3; i++){
    800063f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800063f8:	0001bb97          	auipc	s7,0x1b
    800063fc:	c08b8b93          	addi	s7,s7,-1016 # 80021000 <disk>
    80006400:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006402:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006404:	8a4e                	mv	s4,s3
    80006406:	a051                	j	8000648a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006408:	00fb86b3          	add	a3,s7,a5
    8000640c:	96da                	add	a3,a3,s6
    8000640e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006412:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006414:	0207c563          	bltz	a5,8000643e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006418:	2485                	addiw	s1,s1,1
    8000641a:	0711                	addi	a4,a4,4
    8000641c:	25548063          	beq	s1,s5,8000665c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006420:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006422:	0001d697          	auipc	a3,0x1d
    80006426:	bf668693          	addi	a3,a3,-1034 # 80023018 <disk+0x2018>
    8000642a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000642c:	0006c583          	lbu	a1,0(a3)
    80006430:	fde1                	bnez	a1,80006408 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006432:	2785                	addiw	a5,a5,1
    80006434:	0685                	addi	a3,a3,1
    80006436:	ff879be3          	bne	a5,s8,8000642c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000643a:	57fd                	li	a5,-1
    8000643c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000643e:	02905a63          	blez	s1,80006472 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006442:	f9042503          	lw	a0,-112(s0)
    80006446:	00000097          	auipc	ra,0x0
    8000644a:	d90080e7          	jalr	-624(ra) # 800061d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000644e:	4785                	li	a5,1
    80006450:	0297d163          	bge	a5,s1,80006472 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006454:	f9442503          	lw	a0,-108(s0)
    80006458:	00000097          	auipc	ra,0x0
    8000645c:	d7e080e7          	jalr	-642(ra) # 800061d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006460:	4789                	li	a5,2
    80006462:	0097d863          	bge	a5,s1,80006472 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006466:	f9842503          	lw	a0,-104(s0)
    8000646a:	00000097          	auipc	ra,0x0
    8000646e:	d6c080e7          	jalr	-660(ra) # 800061d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006472:	0001d597          	auipc	a1,0x1d
    80006476:	cb658593          	addi	a1,a1,-842 # 80023128 <disk+0x2128>
    8000647a:	0001d517          	auipc	a0,0x1d
    8000647e:	b9e50513          	addi	a0,a0,-1122 # 80023018 <disk+0x2018>
    80006482:	ffffc097          	auipc	ra,0xffffc
    80006486:	e86080e7          	jalr	-378(ra) # 80002308 <sleep>
  for(int i = 0; i < 3; i++){
    8000648a:	f9040713          	addi	a4,s0,-112
    8000648e:	84ce                	mv	s1,s3
    80006490:	bf41                	j	80006420 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006492:	20058713          	addi	a4,a1,512
    80006496:	00471693          	slli	a3,a4,0x4
    8000649a:	0001b717          	auipc	a4,0x1b
    8000649e:	b6670713          	addi	a4,a4,-1178 # 80021000 <disk>
    800064a2:	9736                	add	a4,a4,a3
    800064a4:	4685                	li	a3,1
    800064a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064aa:	20058713          	addi	a4,a1,512
    800064ae:	00471693          	slli	a3,a4,0x4
    800064b2:	0001b717          	auipc	a4,0x1b
    800064b6:	b4e70713          	addi	a4,a4,-1202 # 80021000 <disk>
    800064ba:	9736                	add	a4,a4,a3
    800064bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064c4:	7679                	lui	a2,0xffffe
    800064c6:	963e                	add	a2,a2,a5
    800064c8:	0001d697          	auipc	a3,0x1d
    800064cc:	b3868693          	addi	a3,a3,-1224 # 80023000 <disk+0x2000>
    800064d0:	6298                	ld	a4,0(a3)
    800064d2:	9732                	add	a4,a4,a2
    800064d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064d6:	6298                	ld	a4,0(a3)
    800064d8:	9732                	add	a4,a4,a2
    800064da:	4541                	li	a0,16
    800064dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064de:	6298                	ld	a4,0(a3)
    800064e0:	9732                	add	a4,a4,a2
    800064e2:	4505                	li	a0,1
    800064e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064e8:	f9442703          	lw	a4,-108(s0)
    800064ec:	6288                	ld	a0,0(a3)
    800064ee:	962a                	add	a2,a2,a0
    800064f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffda00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064f4:	0712                	slli	a4,a4,0x4
    800064f6:	6290                	ld	a2,0(a3)
    800064f8:	963a                	add	a2,a2,a4
    800064fa:	05890513          	addi	a0,s2,88
    800064fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006500:	6294                	ld	a3,0(a3)
    80006502:	96ba                	add	a3,a3,a4
    80006504:	40000613          	li	a2,1024
    80006508:	c690                	sw	a2,8(a3)
  if(write)
    8000650a:	140d0063          	beqz	s10,8000664a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000650e:	0001d697          	auipc	a3,0x1d
    80006512:	af26b683          	ld	a3,-1294(a3) # 80023000 <disk+0x2000>
    80006516:	96ba                	add	a3,a3,a4
    80006518:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000651c:	0001b817          	auipc	a6,0x1b
    80006520:	ae480813          	addi	a6,a6,-1308 # 80021000 <disk>
    80006524:	0001d517          	auipc	a0,0x1d
    80006528:	adc50513          	addi	a0,a0,-1316 # 80023000 <disk+0x2000>
    8000652c:	6114                	ld	a3,0(a0)
    8000652e:	96ba                	add	a3,a3,a4
    80006530:	00c6d603          	lhu	a2,12(a3)
    80006534:	00166613          	ori	a2,a2,1
    80006538:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000653c:	f9842683          	lw	a3,-104(s0)
    80006540:	6110                	ld	a2,0(a0)
    80006542:	9732                	add	a4,a4,a2
    80006544:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006548:	20058613          	addi	a2,a1,512
    8000654c:	0612                	slli	a2,a2,0x4
    8000654e:	9642                	add	a2,a2,a6
    80006550:	577d                	li	a4,-1
    80006552:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006556:	00469713          	slli	a4,a3,0x4
    8000655a:	6114                	ld	a3,0(a0)
    8000655c:	96ba                	add	a3,a3,a4
    8000655e:	03078793          	addi	a5,a5,48
    80006562:	97c2                	add	a5,a5,a6
    80006564:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006566:	611c                	ld	a5,0(a0)
    80006568:	97ba                	add	a5,a5,a4
    8000656a:	4685                	li	a3,1
    8000656c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000656e:	611c                	ld	a5,0(a0)
    80006570:	97ba                	add	a5,a5,a4
    80006572:	4809                	li	a6,2
    80006574:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006578:	611c                	ld	a5,0(a0)
    8000657a:	973e                	add	a4,a4,a5
    8000657c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006580:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006584:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006588:	6518                	ld	a4,8(a0)
    8000658a:	00275783          	lhu	a5,2(a4)
    8000658e:	8b9d                	andi	a5,a5,7
    80006590:	0786                	slli	a5,a5,0x1
    80006592:	97ba                	add	a5,a5,a4
    80006594:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006598:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000659c:	6518                	ld	a4,8(a0)
    8000659e:	00275783          	lhu	a5,2(a4)
    800065a2:	2785                	addiw	a5,a5,1
    800065a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065ac:	100017b7          	lui	a5,0x10001
    800065b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065b4:	00492703          	lw	a4,4(s2)
    800065b8:	4785                	li	a5,1
    800065ba:	02f71163          	bne	a4,a5,800065dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065be:	0001d997          	auipc	s3,0x1d
    800065c2:	b6a98993          	addi	s3,s3,-1174 # 80023128 <disk+0x2128>
  while(b->disk == 1) {
    800065c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065c8:	85ce                	mv	a1,s3
    800065ca:	854a                	mv	a0,s2
    800065cc:	ffffc097          	auipc	ra,0xffffc
    800065d0:	d3c080e7          	jalr	-708(ra) # 80002308 <sleep>
  while(b->disk == 1) {
    800065d4:	00492783          	lw	a5,4(s2)
    800065d8:	fe9788e3          	beq	a5,s1,800065c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065dc:	f9042903          	lw	s2,-112(s0)
    800065e0:	20090793          	addi	a5,s2,512
    800065e4:	00479713          	slli	a4,a5,0x4
    800065e8:	0001b797          	auipc	a5,0x1b
    800065ec:	a1878793          	addi	a5,a5,-1512 # 80021000 <disk>
    800065f0:	97ba                	add	a5,a5,a4
    800065f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065f6:	0001d997          	auipc	s3,0x1d
    800065fa:	a0a98993          	addi	s3,s3,-1526 # 80023000 <disk+0x2000>
    800065fe:	00491713          	slli	a4,s2,0x4
    80006602:	0009b783          	ld	a5,0(s3)
    80006606:	97ba                	add	a5,a5,a4
    80006608:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000660c:	854a                	mv	a0,s2
    8000660e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006612:	00000097          	auipc	ra,0x0
    80006616:	bc4080e7          	jalr	-1084(ra) # 800061d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000661a:	8885                	andi	s1,s1,1
    8000661c:	f0ed                	bnez	s1,800065fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000661e:	0001d517          	auipc	a0,0x1d
    80006622:	b0a50513          	addi	a0,a0,-1270 # 80023128 <disk+0x2128>
    80006626:	ffffa097          	auipc	ra,0xffffa
    8000662a:	79c080e7          	jalr	1948(ra) # 80000dc2 <release>
}
    8000662e:	70a6                	ld	ra,104(sp)
    80006630:	7406                	ld	s0,96(sp)
    80006632:	64e6                	ld	s1,88(sp)
    80006634:	6946                	ld	s2,80(sp)
    80006636:	69a6                	ld	s3,72(sp)
    80006638:	6a06                	ld	s4,64(sp)
    8000663a:	7ae2                	ld	s5,56(sp)
    8000663c:	7b42                	ld	s6,48(sp)
    8000663e:	7ba2                	ld	s7,40(sp)
    80006640:	7c02                	ld	s8,32(sp)
    80006642:	6ce2                	ld	s9,24(sp)
    80006644:	6d42                	ld	s10,16(sp)
    80006646:	6165                	addi	sp,sp,112
    80006648:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000664a:	0001d697          	auipc	a3,0x1d
    8000664e:	9b66b683          	ld	a3,-1610(a3) # 80023000 <disk+0x2000>
    80006652:	96ba                	add	a3,a3,a4
    80006654:	4609                	li	a2,2
    80006656:	00c69623          	sh	a2,12(a3)
    8000665a:	b5c9                	j	8000651c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000665c:	f9042583          	lw	a1,-112(s0)
    80006660:	20058793          	addi	a5,a1,512
    80006664:	0792                	slli	a5,a5,0x4
    80006666:	0001b517          	auipc	a0,0x1b
    8000666a:	a4250513          	addi	a0,a0,-1470 # 800210a8 <disk+0xa8>
    8000666e:	953e                	add	a0,a0,a5
  if(write)
    80006670:	e20d11e3          	bnez	s10,80006492 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006674:	20058713          	addi	a4,a1,512
    80006678:	00471693          	slli	a3,a4,0x4
    8000667c:	0001b717          	auipc	a4,0x1b
    80006680:	98470713          	addi	a4,a4,-1660 # 80021000 <disk>
    80006684:	9736                	add	a4,a4,a3
    80006686:	0a072423          	sw	zero,168(a4)
    8000668a:	b505                	j	800064aa <virtio_disk_rw+0xf4>

000000008000668c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000668c:	1101                	addi	sp,sp,-32
    8000668e:	ec06                	sd	ra,24(sp)
    80006690:	e822                	sd	s0,16(sp)
    80006692:	e426                	sd	s1,8(sp)
    80006694:	e04a                	sd	s2,0(sp)
    80006696:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006698:	0001d517          	auipc	a0,0x1d
    8000669c:	a9050513          	addi	a0,a0,-1392 # 80023128 <disk+0x2128>
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	66e080e7          	jalr	1646(ra) # 80000d0e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066a8:	10001737          	lui	a4,0x10001
    800066ac:	533c                	lw	a5,96(a4)
    800066ae:	8b8d                	andi	a5,a5,3
    800066b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066b6:	0001d797          	auipc	a5,0x1d
    800066ba:	94a78793          	addi	a5,a5,-1718 # 80023000 <disk+0x2000>
    800066be:	6b94                	ld	a3,16(a5)
    800066c0:	0207d703          	lhu	a4,32(a5)
    800066c4:	0026d783          	lhu	a5,2(a3)
    800066c8:	06f70163          	beq	a4,a5,8000672a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066cc:	0001b917          	auipc	s2,0x1b
    800066d0:	93490913          	addi	s2,s2,-1740 # 80021000 <disk>
    800066d4:	0001d497          	auipc	s1,0x1d
    800066d8:	92c48493          	addi	s1,s1,-1748 # 80023000 <disk+0x2000>
    __sync_synchronize();
    800066dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066e0:	6898                	ld	a4,16(s1)
    800066e2:	0204d783          	lhu	a5,32(s1)
    800066e6:	8b9d                	andi	a5,a5,7
    800066e8:	078e                	slli	a5,a5,0x3
    800066ea:	97ba                	add	a5,a5,a4
    800066ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066ee:	20078713          	addi	a4,a5,512
    800066f2:	0712                	slli	a4,a4,0x4
    800066f4:	974a                	add	a4,a4,s2
    800066f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066fa:	e731                	bnez	a4,80006746 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066fc:	20078793          	addi	a5,a5,512
    80006700:	0792                	slli	a5,a5,0x4
    80006702:	97ca                	add	a5,a5,s2
    80006704:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006706:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000670a:	ffffc097          	auipc	ra,0xffffc
    8000670e:	d84080e7          	jalr	-636(ra) # 8000248e <wakeup>

    disk.used_idx += 1;
    80006712:	0204d783          	lhu	a5,32(s1)
    80006716:	2785                	addiw	a5,a5,1
    80006718:	17c2                	slli	a5,a5,0x30
    8000671a:	93c1                	srli	a5,a5,0x30
    8000671c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006720:	6898                	ld	a4,16(s1)
    80006722:	00275703          	lhu	a4,2(a4)
    80006726:	faf71be3          	bne	a4,a5,800066dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000672a:	0001d517          	auipc	a0,0x1d
    8000672e:	9fe50513          	addi	a0,a0,-1538 # 80023128 <disk+0x2128>
    80006732:	ffffa097          	auipc	ra,0xffffa
    80006736:	690080e7          	jalr	1680(ra) # 80000dc2 <release>
}
    8000673a:	60e2                	ld	ra,24(sp)
    8000673c:	6442                	ld	s0,16(sp)
    8000673e:	64a2                	ld	s1,8(sp)
    80006740:	6902                	ld	s2,0(sp)
    80006742:	6105                	addi	sp,sp,32
    80006744:	8082                	ret
      panic("virtio_disk_intr status");
    80006746:	00002517          	auipc	a0,0x2
    8000674a:	0e250513          	addi	a0,a0,226 # 80008828 <syscalls+0x3f0>
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	de2080e7          	jalr	-542(ra) # 80000530 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
