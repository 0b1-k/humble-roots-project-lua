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

#define LOW_BATTERY_THRESHOLD    3.5
#define EXTERNAL_POWER_VOLTAGE   4.3
#define SERIAL_BAUD              115200
#define NETWORK_ID               100
#define GATEWAY_ID               1
#define THIS_NODE_ID             4
#define FREQUENCY                RF69_433MHZ
#define ENCRYPTKEY               "<YourCryptoKey!>"
#define BAT_VOLTAGE              A7
#define ECHO                     3
#define TRIG                     4
#define POWER_DOWN_SECS          60

RFM69 radio;
char Buffer[100];
PString str(Buffer, sizeof(Buffer));

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(10);
  radio.initialize(FREQUENCY, THIS_NODE_ID, NETWORK_ID);
  radio.encrypt(ENCRYPTKEY);
  pinMode(BAT_VOLTAGE, INPUT);
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  Serial.println("Ready");
  Serial.flush();
}

float GetVBat() {
  // actual input voltage = analogRead(A7) * 0.00322 (3.3v/1024) * 1.47 (10k+4.7k voltage divider ratio)
  return analogRead(BAT_VOLTAGE) * 0.00322 * 1.47;
}

float GetWaterLevel() {
  float duration = 0.0;
  float distance = 0.0;
  
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  
  duration = pulseIn(ECHO, HIGH);
  distance = (duration/2.0) / 29.1;
  
  if (distance >= 400.0 || distance <= 0.0){
    distance = -1.0;
  }
  
  return distance;
}

void loop() {
  SendData();
  Serial.flush();
  radio.sleep();
  PowerDown(POWER_DOWN_SECS);
}

void PowerDown(int seconds){
  while (--seconds > 0) {
    LowPower.powerDown(SLEEP_1S, ADC_OFF, BOD_OFF);
  }
}

void SendData(){
  float vBat = GetVBat();
  str.begin();
  str.print("t=lvl&bat=");
  str.print(vBat);
  str.print("&low=");
  str.print((vBat <= LOW_BATTERY_THRESHOLD) ? 1:0);
  str.print("&pwr=");
  str.print((vBat > EXTERNAL_POWER_VOLTAGE) ? 1:0);
  str.print("&cm=");
  str.print(GetWaterLevel());
  
  Serial.print("TX: ");
  Serial.print(Buffer);
  Serial.print(" (");
  Serial.print(str.length());
  Serial.print(")");
 
  if (radio.sendWithRetry(GATEWAY_ID, Buffer, str.length())) {
    Serial.println(":ACK");
  }
  else {
    Serial.println(":NACK");
  }
}
