#include <Ultrasonic.h>
#include <Wire.h>

//Arduino PWM Speed Control：
int E1 = 6;  
int M1 = 7;
int E2 = 5;                        
int M2 = 4;                          

// Range sensors

// SHARP
#define SHARP_SENSOR_ANALOG_PIN 0
#define VOLTS_PER_UNIT    .0049F        // (.0049 for 10 bit A-D)

// HC-SR04
#define UR1_TRIG_PIN 11
#define UR1_ECHO_PIN 13

#define UR2_TRIG_PIN 2
#define UR2_ECHO_PIN 3

#define DHT11_PIN 0 // ADC0

// Compass sensor

int compassAddress = 0x42 >> 1; // HMC6352

Ultrasonic hc1(UR1_TRIG_PIN, UR1_ECHO_PIN), hc2(UR2_TRIG_PIN, UR2_ECHO_PIN);

float sharpDistance() {
  float volts;
  float inches;
  float cm;

  float sensorRead = analogRead(SHARP_SENSOR_ANALOG_PIN);
  volts = (float)sensorRead * VOLTS_PER_UNIT; // ("proxSens" is from analog read)
  inches = 23.897 * pow(volts,-1.1907); //calc inches using "power" trend line from Excel
  cm = 60.495 * pow(volts,-1.1904);     // same in cm
  if (volts < .2) {
    inches = -1.0;        // out of range   
    cm = -1.0;
  }
  return cm;
}

void setupEngines() {
  pinMode(M1, OUTPUT);  
  pinMode(M2, OUTPUT);
  
}

byte read_dht11_dat()
{
  byte i = 0;
  byte result=0;
  for(i=0; i< 8; i++)
  {
    while(!(PINC & _BV(DHT11_PIN)));  // wait for 50us
    delayMicroseconds(30);
    if(PINC & _BV(DHT11_PIN)) 
      result |=(1<<(7-i));
    while((PINC & _BV(DHT11_PIN)));  // wait '1' finish
    }
    return result;
}

void setupDht11() {
  DDRC |= _BV(DHT11_PIN);
  PORTC |= _BV(DHT11_PIN);
}

bool readDht11(float &temp, float &hum) {
  byte dht11_dat[5];
  byte dht11_in;
  byte i;// start condition
         // 1. pull-down i/o pin from 18ms
  PORTC &= ~_BV(DHT11_PIN);
  delay(18);
  PORTC |= _BV(DHT11_PIN);
  delayMicroseconds(40);
  DDRC &= ~_BV(DHT11_PIN);
  delayMicroseconds(40);
  
  dht11_in = PINC & _BV(DHT11_PIN);
  if(dht11_in)
  {
    //Serial.println("dht11 start condition 1 not met");
    return false;
  }
  delayMicroseconds(80);
  dht11_in = PINC & _BV(DHT11_PIN);
  if(!dht11_in)
  {
    //Serial.println("dht11 start condition 2 not met");
    return false;
  }
  
  delayMicroseconds(80);// now ready for data reception
  for (i=0; i<5; i++)
    dht11_dat[i] = read_dht11_dat();
  DDRC |= _BV(DHT11_PIN);
  PORTC |= _BV(DHT11_PIN);
  byte dht11_check_sum = dht11_dat[0]+dht11_dat[1]+dht11_dat[2]+dht11_dat[3];// check check_sum
  if(dht11_dat[4]!= dht11_check_sum)
  {
    //Serial.println("DHT11 checksum error");
    return false;
  }
  
  hum = int(dht11_dat[0] * 10) + int(dht11_dat[1]);
  temp = int(dht11_dat[2] * 10) + int(dht11_dat[3]);
  
}

void setupCompass() {
  Wire.begin();  
}

float readCompass() {
  Wire.beginTransmission(compassAddress);
  Wire.send("A");              // The "Get Data" command
  Wire.endTransmission();
  delay(10);                   // The HMC6352 needs at least a 70us (microsecond) delay
  // after this command.  Using 10ms just makes it safe
  // Read the 2 heading bytes, MSB first
  // The resulting 16bit word is the compass heading in 10th's of a degree
  // For example: a heading of 1345 would be 134.5 degrees
  Wire.requestFrom(compassAddress, 2);        // Request the 2 byte heading (MSB comes first)
  int i = 0;
  byte headingData[2];
  
  while(Wire.available() && i < 2)
  { 
    headingData[i] = Wire.receive();
    i++;
  }
  int headingValue = headingData[0]*256 + headingData[1];    
  return int(headingValue/10) + (0.1*(int(headingValue%10)));
}

#define ENGINE_FORWARD 0
#define ENGINE_BACKWARD 1

// Engine related
void setLeftEnginePower(int power, int direction) {
  if (direction == ENGINE_FORWARD)
    digitalWrite(M1, HIGH);
  else if (direction == ENGINE_BACKWARD)
    digitalWrite(M1, LOW);

  int engPower = map(power, 0, 100, 0, 255);
  analogWrite(E1, engPower);
}

void setRightEnginePower(int power, int direction) {
  if (direction == ENGINE_FORWARD)
    digitalWrite(M2, HIGH);
  else if (direction == ENGINE_BACKWARD)
    digitalWrite(M2, LOW);

  int engPower = map(power, 0, 100, 0, 255);
  analogWrite(E2, engPower);
}

void setEnginePower(int power, int direction) {
  setLeftEnginePower(power, direction); 
  setRightEnginePower(power, direction); 
}

void stopEngines() {
  setEnginePower(0, ENGINE_FORWARD);
}

void engineRotateRight(int power) {
  setLeftEnginePower(power, ENGINE_FORWARD);
  setRightEnginePower(power, ENGINE_FORWARD);

}

void engineRotateLeft(int power) {
  setLeftEnginePower(power, ENGINE_BACKWARD);
  setRightEnginePower(power, ENGINE_BACKWARD);

}

void rotateRight(int rotate) {
  int hdg, startHdg, destHdg;
  
  hdg = startHdg = readCompass();
  destHdg = startHdg + rotate;
  engineRotateRight(100);
  if ((hdg + rotate) >= 359) {
    while (1) {
      delay(50);
      hdg = readCompass();
      if ((hdg>=359) || (hdg <=5)){
        destHdg = destHdg - 360;
        break;
      }
    }
  }
  while (hdg < destHdg) {
    delay(50);
    hdg = readCompass();
    
  }
  stopEngines();
  
}

void setHeading(int hdg) {
  int currentHdg = readCompass();
  //delay(100);
  //currentHdg = readCompass();
  int destHdg;
  
  if (hdg == currentHdg)
    return;

  if (hdg > currentHdg)
    destHdg = hdg - currentHdg;
  else
    destHdg = (360 - currentHdg) + hdg;
  rotateRight(destHdg);
  
}

void setup()
{
  setupEngines();
  setupDht11();
  setupCompass();
  Serial.begin(9600);
}

void loop()
{
  char s[15];
  int bytes=0;
  while (1) {
    if (Serial.available()>0) {
      s[bytes] = char(Serial.read());
      if (s[bytes] == '\n') {
        s[bytes] = '\0';
        break;  
      }
      bytes++;
    }
  }
  
  if (bytes>0) { 
    // Setter/Getter
    if (s[0] == 'g') {
      // Return sensors and engines reads
      
      // Range sensor on front
      Serial.print("UR1");
      Serial.print((long) hc1.Ranging(CM), DEC);
      Serial.print(" ");

      // Range sensor on top
      Serial.print("UR2");
      //Serial.print((long) hc2.Ranging(CM), DEC);
      Serial.print (" ");
      
      // Temperature and humidity
      float temp=0.0, hum=0.0;
      readDht11(temp, hum);
      Serial.print("TMP");
      Serial.print(temp);
      Serial.print (" ");
      Serial.print("HUM");
      Serial.print(hum);
      Serial.print(" ");
      
      // LDR
      Serial.print("LDR");
      Serial.print(analogRead(2));
      Serial.print(" ");
      
      // Compass
      Serial.print("HDG");
      Serial.print(readCompass());
      Serial.println();
    } else if (s[0] == 's') {
      int power;
      int engine;
      // Set engine power
      switch (s[1]) {
        case 'E':
          engine = s[2];
          switch(engine) {
            // Left engine
            case 'L':
              switch (s[3]) {
                case '+':
                  setLeftEnginePower(power, ENGINE_FORWARD);
                break;
                case '-':
                  setLeftEnginePower(power, ENGINE_BACKWARD);
                break;
              }
            break; 
          
            // Right engine
            case 'R':
              switch (s[3]) {
                case '+':
                  setRightEnginePower(power, ENGINE_FORWARD);
                break;
                case '-':
                  setRightEnginePower(power, ENGINE_BACKWARD);
                break;
              }
            break; 
          }
        break;
        case 'H':
          int hdg = atoi(&s[2]);
          setHeading(hdg);
        break;
      }
      Serial.println("end");
    } else if (s[0] == 'r') {
      // Rotate
      char dir = s[1];
      switch(dir) {
        case 'R':
          int rotate = atoi(&s[2]);
          rotateRight(rotate);
        break;
      }
      Serial.println("end");      
    }
    //Serial.flush();
  }
 
}
