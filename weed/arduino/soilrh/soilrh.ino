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

#define LOW_BATTERY_THRESHOLD    3.5
#define EXTERNAL_POWER_VOLTAGE   4.3
#define SERIAL_BAUD              115200
#define NETWORK_ID               100
#define GATEWAY_ID               1
#define THIS_NODE_ID             2 // or 60
#define FREQUENCY                RF69_433MHZ
#define SOIL_PROBE               A1
#define BAT_VOLTAGE              A7
#define DRY_SOIL_CALIB           30
#define WET_SOIL_CALIB           700
#define RH_MAX_SAMPLES           10
#define POWER_DOWN_SECS          60

RFM69 radio;
char Buffer[100];
byte CryptoKey[] = "<YourCryptoKey!>";
PString str(Buffer, sizeof(Buffer));
int CalibDry = DRY_SOIL_CALIB;
int CalibWet = WET_SOIL_CALIB;

void setup() {
  Serial.begin(SERIAL_BAUD);
  radio.initialize(FREQUENCY, THIS_NODE_ID, NETWORK_ID);
  radio.encrypt((const char*)CryptoKey);
  pinMode(SOIL_PROBE, INPUT);
  pinMode(BAT_VOLTAGE, INPUT);
  Serial.println("Ready");
  Serial.flush();
}

float GetVBat() {
  // actual input voltage = analogRead(A7) * 0.00322 (3.3v/1024) * 1.47 (10k+4.7k voltage divider ratio)
  return analogRead(BAT_VOLTAGE) * 0.00322 * 1.47;
}

int GetRawRH(int samples) {
  float rawRH = 0.0;
  for (int i = 0; i < samples; i++) {
    rawRH += analogRead(SOIL_PROBE);
    delay(2);
  }
  return rawRH / samples;
}

int GetSoilRH(int samples) {
  return map(GetRawRH(samples), CalibDry, CalibWet, 0.0, 100.0);
}

void loop() {
  SendData();
  radio.sleep();
  PowerDown(POWER_DOWN_SECS);
}

void PowerDown(int seconds){
  while (--seconds > 0) {
    LowPower.powerDown(SLEEP_1S, ADC_OFF, BOD_OFF);
  }
}

void SendData() {
  float vBat = GetVBat();
  str.begin();
  str.print("t=srh&bat=");
  str.print(vBat);
  str.print("&low=");
  str.print((vBat <= LOW_BATTERY_THRESHOLD) ? 1:0);
  str.print("&pwr=");
  str.print((vBat > EXTERNAL_POWER_VOLTAGE) ? 1:0);
  str.print("&p=");
  str.print(GetSoilRH(RH_MAX_SAMPLES));

  Serial.print("TX: ");
  Serial.print(Buffer);
  Serial.print(" (");
  Serial.print(str.length());
  Serial.print(")");

  if (radio.sendWithRetry(GATEWAY_ID, Buffer, str.length())) {
    Serial.println(":ACK");
  } else {
    Serial.println(":NAK");
  }
  Serial.flush();
}

