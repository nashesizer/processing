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
String nasha = "/dev/tty.usbmodem4041081"; //"/dev/tty.usbmodem3422711";  // the name of the device driver to use

OscP5 oscP5;
NetAddress myRemoteLocation;
String computerIP = "127.0.0.1"; // "192.168.0.16"; // change this to the address of your mobile device

int soloButton = 0;
float sendA = 0.5, sendB = 0.5;
boolean refreshScreen = true;
String recievedLast, liveOSCMessageLast, liveOSCMessageND = "";

PFont f;
char trkNoC = '1';
boolean displayTeensyOSC, displayLiveOSC = false;

void setup() {
  size(200, 200); // window only acts as focus for key press
  portConnect();
  /* start oscP5, listening for incoming messages at port 7000 */
  oscP5 = new OscP5(this, 7000);
  myRemoteLocation = new NetAddress(computerIP, 7001); // send messages to this port
  delay(1000);

  // Create the font
  //printArray(PFont.list());
  f = createFont("SourceCodePro-Regular.ttf", 14);
  textFont(f);
}


void draw() { 

  background(102);

  while (nashaPort.available() > 0) {
    String recieved = nashaPort.readString() ;
    print("from Teensy: ");
    println(recieved);
    char c1 = recieved.charAt(0);
    trkNoC = recieved.charAt(2);
    if (c1 == '/') {
      String[] list = split(recieved, ',');
      if (recieved.equals(recievedLast) == true) {
        // do nothing if the last received message is the same as the newly received message
      } else {
        sendOSC(list[0], list[1], list[2]);
      }
      recievedLast = recieved;
    }
  }

  if (refreshScreen) {
    background(102);
    stroke(153, 153, 0);
    line(0, sendB*200, 200, sendB*200);
    line(sendA*200, 0, sendA*200, 200); 
    refreshScreen = false;
  }

  textAlign(CENTER);
  fill(255);
  textSize(15);
  text("current trk #", width/2, 20);
  textSize(50);
  text(trkNoC, width/2, 70);

  if (displayLiveOSC == true) {
    textAlign(CENTER);
    fill(255);
    textSize(11);
    text("from Live: ", width/2, 160);
    text(liveOSCMessageND, width/2, 170);
  }

  if (displayTeensyOSC == true) {
    textAlign(CENTER);
    fill(255);
    textSize(11);
    text("from Teensy: ", width/2, 180);
    text(recievedLast, width/2, 190);
  }
}

// doesn't like this - crashes out. Moved to draw(). Ask Mike.
//void serialEvent(Serial nashaPort) {  // this gets called everytime a line feed is recieved
//  String recieved = nashaPort.readString() ;  
//  //println("got:-",recieved);

//  String[] list = split(recieved, ',');

//  //println("list[0]: ",list[0]);
//  //println("list[1]: ",list[1]);
//  //println("list[2]: ",list[2]);

//  //println("recieved: ", recieved);
//  //println("recievedLast: ", recievedLast);

//  if (recieved.equals(recievedLast) == true) {
//  } else {
//    sendOSC(list[0], list[1], list[2]);
//  }

//  recievedLast = recieved;

//}


void sendOSC(String address, String type, String data) {
  OscMessage liveMessage = new OscMessage(address);
  if (type .equals("i")) {
    liveMessage.add(int(data)); /* add an int to the osc message */
  }  
  if (type .equals("f")) {
    liveMessage.add(float(data)); /* add a float to the osc message */
  }
  if (type .equals("s")) {
    liveMessage.add(data); /* add a string to the osc message */
  }

  /* send the message */
  oscP5.send(liveMessage, myRemoteLocation); 
  println(address+" "+type+" "+data);
}

void portConnect() {      // Open the port that the controller is connected to and use the same speed
  // **********************************
  // if the device you are looking for is 
  // not avaliable the program will 
  // connect to the first one in the list
  // ************************************
  int portNumber = 99;
  String [] ports;
  ports = Serial.list();
  println((Object[])Serial.list()); // uncomment for full list of serial devices
  for (int j = 0; j< ports.length; j++) { 
    if (nasha.equals(Serial.list()[j])) portNumber = j;
  } // go through all ports
  if (portNumber == 99) portNumber = 0; // if we haven't found our port then connect to the first one
  String portName = Serial.list()[portNumber]; 
  println("Connected to "+portName);
  nashaPort = new Serial(this, portName, 250000);
  nashaPort.bufferUntil(10);  // call serialEvent every LF
  nashaPort.clear();
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  print("from Live: ");
  String addr = theOscMessage.addrPattern();
  print(addr); // uncomment for debug print of all received messages
  String typeTag = theOscMessage.typetag();
  print(" typetag:", typeTag);
  //if (addr.indexOf("/ping") != -1) return; // got a ping
  //if (addr.length() < 3) return; // page change from the iPad
  if (typeTag .equals("f")) {
    float  val  = theOscMessage.get(0).floatValue();  
    println(" ", val);
    if (addr.equals("/T2/SendA")) {
      refreshScreen = true;
      sendA = val;
    }
    if (addr.equals("/T2/SendB")) {
      refreshScreen = true;
      sendB = val;
    }
  }
  if (typeTag .equals("i")) {
    int number = theOscMessage.get(0).intValue();
    println(" ", number);
  }
  if (typeTag .equals("s")) {
    String message = theOscMessage.get(0).stringValue();
    println(" ", message);
  }


  // send incoming OSC message to the Teensy
  String liveOSCMessage = "";
  liveOSCMessage += theOscMessage.addrPattern();
  liveOSCMessage += ",";
  liveOSCMessage += theOscMessage.typetag();
  liveOSCMessage += ",";
  if (typeTag .equals("f")) {
    liveOSCMessage += theOscMessage.get(0).floatValue();
  } else if (typeTag .equals("i")) {
    liveOSCMessage += theOscMessage.get(0).intValue();
  } else if (typeTag .equals("s")) {
    liveOSCMessage += theOscMessage.get(0).stringValue();
  }
  liveOSCMessageND = liveOSCMessage;
  liveOSCMessage += ":";

  if (liveOSCMessage.equals(liveOSCMessageLast) == true) {
  } else {
    //nashaPort.clear();
    nashaPort.write(liveOSCMessage);
  }
  liveOSCMessageLast = liveOSCMessage;
}

void mouseDragged() {
  sendA = mouseX/ 200.0; // in a 200 by 200 window
  sendB = mouseY/ 200.0;
  sendOSC("/T1/SendA", "f", str(sendA));
  sendOSC("/T1/SendB", "f", str(sendB));
  refreshScreen = true;
}
void keyPressed() {
  if (key == '1') {
    sendOSC("/T1/Volume", "f", "0.3");
  }
  if (key == '2') {
    sendOSC("/T1/Volume", "f", "0.7");
  }
  if (key == '3') {
    soloButton ^= 1; // toggle button value
    sendOSC("/T1/Solo", "i", str(soloButton));
  }   
  if (key == 't') { // Track Mouse
    //sendOSC("/T1/Pan","f",str(pan));
  }
  if (key == 'z') {
    displayTeensyOSC = !displayTeensyOSC;
  }
    if (key == 'x') {
    displayLiveOSC = !displayLiveOSC;
  }
}