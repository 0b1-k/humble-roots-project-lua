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
#include <EEPROMex.h>
#include <EEPROMVar.h>
#include <PString.h>
#include <RFM69.h>
#include <SPI.h>

#define LOW_BATTERY_THRESHOLD    4.0
#define EXTERNAL_POWER_VOLTAGE   5.0
#define SERIAL_BAUD              115200
#define NETWORK_ID               100
#define GATEWAY_ID               1
#define THIS_NODE_ID             20
#define FREQUENCY                RF69_433MHZ
#define BAT_VOLTAGE              A7
#define MAGIC                    31415

RFM69 radio;
char Buffer[100];
byte CryptoKey[] = "<YourCryptoKey!>";
PString str(Buffer, sizeof(Buffer));
int MagicAddr = EEPROM.getAddress(sizeof(int));
int CryptoKeyAddr = EEPROM.getAddress(sizeof(CryptoKey));
int Relays[] = {A0, A1, A2, A3, A4, A5};

void setup() {
  Serial.begin(SERIAL_BAUD);
  InitConfig();
  delay(10);
  radio.initialize(FREQUENCY, THIS_NODE_ID, NETWORK_ID);
  radio.encrypt((const char*)CryptoKey);
  InitializeRelays();
  Serial.println("Ready");
}

void InitializeRelays() {
  int count = sizeof(Relays)/sizeof(int);
  for(int r=0; r<count; r++){
    pinMode(Relays[r], OUTPUT);
    digitalWrite(Relays[r], 0);
  }
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
  // actual input voltage = analogRead(A7) * (5.0v/1024)
  return analogRead(BAT_VOLTAGE) * (EXTERNAL_POWER_VOLTAGE / 1024.0);
}

void loop() {
  if (radio.receiveDone() && radio.DATALEN > 0 && radio.TARGETID == THIS_NODE_ID) {
    if (radio.ACKRequested()) {
      radio.sendACK();
    }
    ParseCommand((char*)radio.DATA);
    if (Match("cmd", "act")) {
      const char* r = GetValue("r");
      const char* s = GetValue("s");
      if(r!=NULL && s!=NULL) {
        int relay = atoi(r);
        int state = atoi(s);
        if (relay>=0 && relay<=5 && state>=0 && state <=1) {
            digitalWrite(Relays[relay], state);
            SendData(relay, state);
        }
        else {
            Serial.println("Bad r / s");
        }
      }
      else {
        Serial.println("Bad cmd");
      }
    }
    Serial.flush();
  }
  radio.receiveDone(); // put radio in RX mode
}

void SendData(int relay, int state) {
  float vBat = GetVBat();
  str.begin();
  str.print("t=rly&bat=");
  str.print(vBat);
  str.print("&low=");
  str.print((vBat <= LOW_BATTERY_THRESHOLD) ? 1:0);
  str.print("&pwr=");
  str.print((vBat >= (EXTERNAL_POWER_VOLTAGE - 0.1)) ? 1:0);
  str.print("&r=");
  str.print(relay);
  str.print("&s=");
  str.print(state);

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

const char* Names[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
const char* Values[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
const int maxToken = sizeof(Names) / sizeof(const char*);

void ResetNameValuePairs() {
  for (int i = 0; i < maxToken; i++) {
    Names[i] = 0;
    Values[i] = 0;
  }
}

void ParseCommand(char* cmd) {
  ResetNameValuePairs();
  int tokenCount = maxToken;
  const char* token = strtok(cmd, "&");
  while (token != NULL && tokenCount) {
    char* value = strstr(token, "=");
    if (value != NULL) {
      value[0] = 0;
      value++;
      tokenCount--;
      Names[tokenCount] = token;
      Values[tokenCount] = value;
    }
    token = strtok(NULL, "&");
  }
}

void Dump() {
  for (int i = 0; i < maxToken; i++) {
    if (Names[i] != NULL) {
      Serial.print(Names[i]);
      Serial.print("=");
      Serial.println(Values[i]);
    }
  }
}

bool Match(const char* Name, const char* Value) {
  const char* val = GetValue(Name);
  if (val != NULL) {
    if (strcmp(val, Value) == 0) {
      return true;
    }
  }
  return false;
}

const char* GetValue(const char* Name) {
  for (int i = 0; i < maxToken; i++) {
    if (Names[i] != NULL) {
      if (strcmp(Names[i], Name) == 0) {
        return Values[i];
      }
    }
  }
  return NULL;
}
