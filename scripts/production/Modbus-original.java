// Modbus.java 7/23/97 - JAVA program to read registers via gateway
// compile as
// javac Modbus.java
// run as
// java Modbus aswales1.modicon.com 1 2 3


import java.io.* ;
import java.net.* ;
import java.util.*;
import java.awt.* ;



class Modbus {
 public static void main(String argv[]) {
 if (argv.length < 4) {
 System.out.println("usage: java Modbus dns_name unit reg_no num_regs");
 System.out.println("eg java Modbus aswales8.modicon.com 5 0 10");
 return;
 }
 try {
 String ip_adrs = argv[0];
 int unit = Integer.parseInt(argv[1]);
 int reg_no = Integer.parseInt(argv[2]);
 int num_regs = Integer.parseInt(argv[3]);
 System.out.println("ip_adrs = "+ip_adrs+" unit = "+unit+" reg_no = "+
 reg_no+" num_regs = "+num_regs);

 // set up socket
 Socket es = new Socket(ip_adrs,502);
 OutputStream os= es.getOutputStream();
 FilterInputStream is = new BufferedInputStream(es.getInputStream());
 byte obuf[] = new byte[261];
 byte ibuf[] = new byte[261];
 int c = 0;
 int i;

 // build request of form 0 0 0 0 0 6 ui 3 rr rr nn nn
 for (i=0;i<5;i++) obuf[i] = 0;
 obuf[5] = 6;
 obuf[6] = (byte)unit;
 obuf[7] = 3;
 obuf[8] = (byte)(reg_no >> 8);
 obuf[9] = (byte)(reg_no & 0xff);
 obuf[10] = (byte)(num_regs >> 8);
 obuf[11] = (byte)(num_regs & 0xff);

 // send request
 os.write(obuf, 0, 12);

 // read response
 i = is.read(ibuf, 0, 261);
 if (i<9) {
 if (i==0) {
 System.out.println("unexpected close of connection at remote end");
 } else {
 System.out.println("response was too short - "+i+" chars");
 }
 } else if (0 != (ibuf[7] & 0x80)) {
 System.out.println("MODBUS exception response - type "+ibuf[8]);
 } else if (i != (9+2*num_regs)) {
 System.out.println("incorrect response size is "+i+
 " expected"+(9+2*num_regs));
 } else {
 for (i=0;i<num_regs;i++) {
 int w = (ibuf[9+i+i]<<8) + (ibuf[10+i+i]& 0x00FF);
 System.out.println("word "+i+" = "+w);
 }
 }

 // close down
 es.close();
 } catch (Exception e) {
 System.out.println("exception :"+e);
 }
 }
}












