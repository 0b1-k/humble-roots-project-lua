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
#include <Wire.h>
#include <SI7021.h>
#include <SFE_BMP180.h>
#include <SPI.h>
#include <RFM69.h>
#include <LowPower.h>
#include <PString.h>
#include <EEPROMex.h>
#include <EEPROMVar.h>

#define LOW_BATTERY_THRESHOLD    3.5
#define EXTERNAL_POWER_VOLTAGE   4.3
#define SERIAL_BAUD              115200
#define NETWORK_ID               100
#define GATEWAY_ID               1
#define THIS_NODE_ID             40
#define FREQUENCY                RF69_433MHZ
#define BAT_VOLTAGE_MOSFET       A3
#define BAT_VOLTAGE              A7
#define MAGIC                    31415
#define POWER_DOWN_SECS          60

RFM69 radio;
SI7021 sensor;
SFE_BMP180 pressure;
char Buffer[100];
byte CryptoKey[] = "<YourCryptoKey!>";
PString str(Buffer, sizeof(Buffer));
int MagicAddr = EEPROM.getAddress(sizeof(int));
int CryptoKeyAddr = EEPROM.getAddress(sizeof(CryptoKey));

void setup() {
  Serial.begin(SERIAL_BAUD);
  InitConfig();
  delay(10);
  radio.initialize(FREQUENCY, THIS_NODE_ID, NETWORK_ID);
  radio.encrypt((const char*)CryptoKey);
  sensor.begin();
  if (pressure.begin()) {
    Serial.println("BMP180 init OK");
  } else {
    Serial.println("BMP180 init failed");
  }
  Serial.println("Ready");
  Serial.flush();
}

void InitConfig() {
  if (EEPROM.readInt(MagicAddr) != MAGIC) {
    EEPROM.writeBlock<byte>(CryptoKeyAddr, CryptoKey, sizeof(CryptoKey));
    EEPROM.writeInt(MagicAddr, MAGIC);
    Serial.println("EE init.");
  }
  EEPROM.readBlock<byte>(CryptoKeyAddr, CryptoKey, sizeof(CryptoKey));
  Serial.print("Key: ");
  Serial.println((const char*)CryptoKey);
  Serial.flush();
}

float GetVBat() {
  //turn MOSFET ON and read voltage, should give a valid reading
  pinMode(BAT_VOLTAGE_MOSFET, OUTPUT);
  digitalWrite(BAT_VOLTAGE_MOSFET, LOW);
  float vbat = analogRead(BAT_VOLTAGE)/100.00;
  //put A3 in HI-Z mode (to allow mosfet gate pullup to turn it OFF)
  pinMode(BAT_VOLTAGE_MOSFET, INPUT);
  return vbat;
}

float GetTemp() {
  return float(sensor.getCelsiusHundredths()/100.00);
}

int GetRH() {
  return sensor.getHumidityPercent();
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

void SendData() {
  float vBat = GetVBat();
  str.begin();
  str.print("t=clm&bat=");
  str.print(vBat);
  str.print("&low=");
  str.print((vBat <= LOW_BATTERY_THRESHOLD) ? 1:0);
  str.print("&pwr=");
  str.print((vBat > EXTERNAL_POWER_VOLTAGE) ? 1:0);
  str.print("&tmp=");
  str.print(GetTemp());
  str.print("&rh=");
  str.print(GetRH());

  Serial.print("TX: ");
  Serial.print(Buffer);
  Serial.print(" (");
  Serial.print(str.length());
  Serial.print(")");

  if (radio.sendWithRetry(GATEWAY_ID, Buffer, str.length()))
    Serial.println(":ACK");
  else
    Serial.println(":NACK");
}

