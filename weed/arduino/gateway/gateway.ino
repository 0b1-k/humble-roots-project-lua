/*
    Author: Fabien Royer
    Copyright 2013-2015 Fabien Royer

    This file is part of the "Humble Roots Project" or "HRP".

    "HRP" is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    "HRP" is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with "HRP".  If not, see <http://www.gnu.org/licenses/>.
*/
#include <PString.h>
#include <LowPower.h>
#include <RFM69.h>
#include <SPI.h>

#define SERIAL_BAUD     115200
#define NETWORK_ID      100
#define THIS_NODE_ID    1
#define FREQUENCY       RF69_433MHZ
#define ENCRYPTKEY      "<YourCryptoKey!>"
#define SERIAL_TIMEOUT  1

RFM69 radio;
char RadioIn[100];
char CmdInput[100];
PString RadioInData(RadioIn, sizeof(RadioIn));
PString Cmd(CmdInput, sizeof(CmdInput));

void setup() {
  //pinMode(9, OUTPUT);
  Serial.begin(SERIAL_BAUD);
  Serial.setTimeout(SERIAL_TIMEOUT);
  delay(10);
  
  radio.initialize(FREQUENCY, THIS_NODE_ID, NETWORK_ID);
  radio.encrypt(ENCRYPTKEY);
  
  Serial.println("\n");
  Serial.flush();
  Serial.println("Humble Roots Gateway");
  Serial.flush();
  Serial.println("Listening");
  Serial.flush();
}

void loop() { 
  if (radio.receiveDone() && radio.DATALEN > 0 && radio.TARGETID == THIS_NODE_ID) {
    RadioInData.begin();
    RadioInData += "node=";
    RadioInData += radio.SENDERID;
    RadioInData += "&rssi=";
    RadioInData += radio.RSSI;
    RadioInData += "&";
    int start = RadioInData.length();
    for(int i=0; i<radio.DATALEN; i++, start++){
      RadioIn[start] = radio.DATA[i];
    }
    RadioIn[start] = 0;
    if (radio.ACKRequested()){
      radio.sendACK();
      delay(3); //need this when sending right after reception .. ?
    }
    Serial.println(RadioIn);
    Serial.flush();
  }

  int byteCount = Serial.available();
  while (byteCount--){
    char data = Serial.read();
    if (Cmd.length() < Cmd.capacity()){
      if (data == '\r'){
        continue;
      } else if (data == '\n'){
        //digitalWrite(9, HIGH);
        SendCommandToNode(CmdInput);
        Cmd.begin();
        //digitalWrite(9, LOW);
      } else {
        Cmd += data;
      }
    }
    else {
      Cmd.begin();
    }
  }
}

void SendCommandToNode(char* data){
  char* scratch = strstr(data, "node=");
  char* cmd = strstr(data, "&");
  if(scratch!=NULL){
    char* token = strtok(scratch, "&");
    if(token!=NULL){
      char* nodeData = strstr(token, "=");
      if(nodeData!=NULL){
        nodeData++;
        int nodeID = atoi(nodeData);
        Serial.print("node=");
        Serial.print(nodeID);
        Serial.print("&");
        Serial.print(++cmd);
        Serial.print("&tx=");
        if(radio.sendWithRetry(nodeID, cmd, strlen(cmd))){
          Serial.println("ack");
        } else {
          Serial.println("nak");
        }
      }
    }
  } else {
    Serial.print("Bad cmd: ");
    Serial.println(data);
  }
  Serial.flush();
}

