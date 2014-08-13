//
// ModbusReadDemand.java - simple program to read one MODBUS/TCP parameter, based on 
// the example provided by Schneider Electric's tech support.  The EGX100s only support 
// a small subset of MIB-II so you can't see the power values via SNMP, sigh.
//
// N.B. - This version is hard-wired to the first MODBUS unit on the bus, word 3 
//		  (demand in KW).  The correction factor is passed on the command line with
// 		  IP number of the device to query.
//
// compile as
// javac ModbusReadDemand.java
// run as
// java ModbusReadDemand 159.28.165.102 62.5
//
import java.io.* ;
import java.net.* ;

class ModbusReadDemand {
 public static void main(String argv[]) {
 if (argv.length < 2) {
	 System.out.println("usage: java ModbusReadDemand {IP | DNS name} CorrectionFactor");
	 System.out.println("eg java ModbusReadDemand 159.28.165.103 62.5");
	 return;
 }
 try {
 String ip_adrs = argv[0];
 float correction = Float.parseFloat(argv[1]); 
 int unit = 1; 
 int reg_no = 3; 
 int num_regs = 1;

 // set up socket
 Socket es = new Socket(ip_adrs,502);
 OutputStream os= es.getOutputStream();
 FilterInputStream is = new BufferedInputStream(es.getInputStream());
 byte obuf[] = new byte[261];
 byte ibuf[] = new byte[261];
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
 	float pReal = w / correction ; 
 	System.out.println("\"" + pReal + "\"");
 }
 }

 // close down
 es.close();
 } catch (Exception e) {
 System.out.println("exception :"+e);
 }
 }
}
