#include <Ultrasonic.h>

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

void setup()
{
  setupEngines();
  setupDht11();
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
      //Serial.print((long) hc1.Ranging(CM), DEC);
      Serial.print(" ");

      // Range sensor on top
      Serial.print("UR2");
      //Serial.print((long) hc2.Ranging(CM), DEC);
      Serial.print (" ");
      
      // Temperature and humidity
      float temp=0.0, hum=0.0;
      readDht11(temp, hum);
      Serial.print("T");
      Serial.print(temp);
      Serial.print (" ");
      Serial.print("H");
      Serial.print(hum);
      Serial.println();
    } else if (s[0] == 's') {
      int power;
      
      // Set engine power
      if (s[1] == 'E') {
        int engine = s[2];
        int power = map(int(s[4]), 0, 100, 0, 255);
        switch(engine) {
          // Left engine
          case 'L':
            if (s[3] == '+') {
              digitalWrite(M1, HIGH);
            }
            else if (s[3] == '-')
              digitalWrite(M1, LOW);
              
            analogWrite(E1, power);
          break; 
          
          // Right engine
          case 'R':
            if (s[3] == '+') {
              digitalWrite(M2, HIGH);
            }
            else if (s[3] == '-')
              digitalWrite(M2, LOW);
            analogWrite(E2, power);
          break; 
        }
      }
    }
    Serial.flush();
  }

}
