/**
 Nashesizer-Hub 0.0.1
 Key 1 & 2- send an OSC message to Live to change volume
 Processing window controls Sends A & B in live
 Processing window reflects Sends A & B adjusted in live
 OSC messages from Live printed in the Processing consol
 Serial Messages from Teensy printed in the Processing consol
 */
 
import oscP5.*;
import netP5.*;
import processing.serial.*;

Serial nashaPort;  // Create object from Serial class
String nasha = "/dev/tty.usbmodem3422711";  // the name of the device driver to use

OscP5 oscP5;
NetAddress myRemoteLocation;
String iPadIP = "127.0.0.1"; // change this to the address of your mobile device

int soloButton = 0;
float sendA = 0.5, sendB = 0.5;
boolean refreshScreen = true;

void setup() {
  size(200,200); // window only acts as focus for key press
  portConnect();
  /* start oscP5, listening for incoming messages at port 7000 */
  oscP5 = new OscP5(this,7000);
  myRemoteLocation = new NetAddress(iPadIP,7001); // send messages to this port
}


void draw() { 
  if(refreshScreen){
    background(102);
    stroke(153,153,0);
    line(0,sendB*200,200, sendB*200);
    line(sendA*200,0,sendA*200,200); 
    refreshScreen = false;
  }
}

void sendOSC(String address, String type, String data) {
  OscMessage liveMessage = new OscMessage(address);
  if(type .equals("i")) {
      liveMessage.add(int(data)); /* add an int to the osc message */
  }  
  if(type .equals("f")) {
      liveMessage.add(float(data)); /* add a float to the osc message */
  }
  if(type .equals("s")) {
      liveMessage.add(data); /* add a string to the osc message */
  }
    
  /* send the message */
  oscP5.send(liveMessage, myRemoteLocation); 
}

void portConnect(){      // Open the port that the controller is connected to and use the same speed
     // **********************************
    // if the device you are looking for is 
    // not avaliable the program will 
    // connect to the first one in the list
    // ************************************
    int portNumber = 99;
    String [] ports;
    ports = Serial.list();
    println((Object[])Serial.list()); // uncomment for full list of serial devices
      for(int j = 0; j< ports.length; j++) { 
    if(nasha.equals(Serial.list()[j])) portNumber = j;         
    } // go through all ports
    if(portNumber == 99) portNumber = 0; // if we haven't found our port then connect to the first one
    String portName = Serial.list()[portNumber]; 
    println("Connected to "+portName);
    nashaPort = new Serial(this, portName, 250000);
    nashaPort.bufferUntil(10);  // call serialEvent every LF
 }

void serialEvent(Serial nashaPort) {  // this gets called everytime a line feed is recieved
  String recieved = nashaPort.readString() ;  
    println("got:-",recieved);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  String addr = theOscMessage.addrPattern();
  print(addr); // uncomment for debug print of all received messages
  String typeTag = theOscMessage.typetag();
  println(" typetag: ", typeTag);
  if(addr.indexOf("/ping") != -1) return; // got a ping
  if(addr.length() < 3) return; // page change from the iPad
  if(typeTag .equals("f")){
  float  val  = theOscMessage.get(0).floatValue();  
  println(" ",val);
  if(addr .equals("/Live/T2/SendA")){
    refreshScreen = true;
    sendA = val;
  }
  if(addr .equals("/Live/T2/SendB")){
    refreshScreen = true;
    sendB = val;
  }
  }
  if(typeTag .equals("i")){
  int number = theOscMessage.get(0).intValue();
  println(" ",number);
}
  if(typeTag .equals("s")){
  String message = theOscMessage.get(0).stringValue();
  println(" ",message);
}
}

void mouseDragged() {
    sendA = mouseX/ 200.0; // in a 200 by 200 window
    sendB = mouseY/ 200.0;
    sendOSC("/T2/SendA","f",str(sendA));
    sendOSC("/T2/SendB","f",str(sendB));
    refreshScreen = true;
}
   void keyPressed() {
     if(key == '1'){
       sendOSC("/T2/Volume","f","0.3");
     }
     if(key == '2'){
       sendOSC("/T2/Volume","f","0.7");
     }
     if(key == '3'){
       soloButton ^= 1; // toggle button value
       sendOSC("/T2/Solo","i",str(soloButton));
     }   
     if(key == 't'){ // Track Mouse
       //sendOSC("/T2/Pan","f",str(pan));
     }
     
 }