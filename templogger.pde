/* Name: templogger.pde

 Temperature logger for Arduino with Adafruit data logging shield
 http://www.adafruit.com/index.php?main_page=product_info&products_id=243

 Based on code from Adafruit
 https://github.com/adafruit/Light-and-Temp-logger

 This version is at
 https://github.com/kjordahl/Temperature-logger

 Logs temperature data from 3 temperature sensors, an LM61 analog
 sensor and two 10 kOhm thermistors.  By default the LM61 is on analog
 pin 1 and the thermistors are on pins 2 and 3, but can be set with
 LM61PIN, THERM1 and THERM2 below.

 Uses Narcoleptic library for low power sleep mode between samples
 http://code.google.com/p/narcoleptic/

 Thermistor:
 Vishay 10 kOhm NTC thermistor
 part no: NTCLE100E3103GB0
 <http://www.vishay.com/thermistors/list/product-29049>

 LM61:
 National Semiconductor TO-92 Temperature Sensor
 10 mV/degree with 600 mV offset, temperature range -30 deg C to 100 deg C
 part no: LM61BIZ
 <http://www.national.com/mpf/LM/LM61.html>

 
 Kelsey Jordahl
 kjordahl@alum.mit.edu
 http://kjordahl.net
 Time-stamp: <Wed Apr 27 19:19:34 EDT 2011> 
 */

#include <SD.h>
#include <Wire.h>
#include <RTClib.h>
#include <Narcoleptic.h>


// 10 s logging interval
#define LOG_INTERVAL  10000 // mills between entries (reduce to take more/faster data)

// 60 s write interval (every 6th sample)
#define SYNC_INTERVAL 60000 // mills between calls to flush() - to write data to the card
uint32_t syncTime = 0; // time of last sync()

#define ECHO_TO_SERIAL   1 // echo data to serial port
#define WAIT_TO_START    0 // Wait for serial input in setup()

// the digital pins that connect to the LEDs
#define redLEDpin 2
#define greenLEDpin 3

/* constants for extended Steinhart-Hart equation from thermistor datasheet */
#define A 3.354016E-03
#define B 2.569850E-04
#define C 2.620131E-06
#define D 6.383091E-08

// The analog pins that connect to the sensors
#define LM61PIN 1		/* analog pin for LM61 sensor */
#define THERM1 2		/* analog pin for thermistor 1 */
#define THERM2 3		/* analog pin for thermistor 2 */
#define BANDGAPREF 14            // special indicator that we want to measure the bandgap

#define aref_voltage 3.3         // we tie 3.3V to ARef and measure it with a multimeter!
#define bandgap_voltage 1.1      // this is not super guaranteed but its not -too- off

RTC_DS1307 RTC; // define the Real Time Clock object

// for the data logging shield, we use digital pin 10 for the SD cs line
const int chipSelect = 10;

// the logging file
File logfile;

float lm61(int RawADC) {
  float Temp;
  float voltage = RawADC * aref_voltage / 1024; 
  Temp = (voltage - 0.6) * 100 ;  //10 mV/degree with 600 mV offset
  return Temp;
}

float Thermistor(int RawADC) {
  float Temp;
  Temp = log(((1024/float(RawADC)) - 1)); /* relative to 10 kOhm */
  Temp = 1 / (A + (B * Temp) + (C * Temp * Temp) + (D * Temp * Temp * Temp));
  Temp = Temp - 273.15;		/* convert to C */
  // Temp = (Temp * 9.0)/ 5.0 + 32.0; // Convert Celcius to Fahrenheit
  return Temp;
}

void error(char *str)
{
  Serial.print("error: ");
  Serial.println(str);
  
  // red LED indicates error
  digitalWrite(redLEDpin, HIGH);
  digitalWrite(greenLEDpin, HIGH);

  while(1);
}

void setup(void)
{
  Serial.begin(9600);
  Serial.println();
  
  // use debugging LEDs
  pinMode(redLEDpin, OUTPUT);
  pinMode(greenLEDpin, OUTPUT);
  
#if WAIT_TO_START
  Serial.println("Type any character to start");
  while (!Serial.available());
#endif //WAIT_TO_START

  // initialize the SD card
  Serial.print("Initializing SD card...");
  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(10, OUTPUT);
  
  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    error("Card failed, or not present");
  }
  Serial.println("card initialized.");
  
  // create a new file
  char filename[] = "LOGGER00.CSV";
  for (uint8_t i = 0; i < 100; i++) {
    filename[6] = i/10 + '0';
    filename[7] = i%10 + '0';
    if (! SD.exists(filename)) {
      // only open a new file if it doesn't exist
      logfile = SD.open(filename, FILE_WRITE); 
      break;  // leave the loop!
    }
  }
  
  if (! logfile) {
    error("couldnt create file");
  }
  
  Serial.print("Logging to: ");
  Serial.println(filename);

  // connect to RTC
  Wire.begin();  
  if (!RTC.begin()) {
    logfile.println("RTC failed");
#if ECHO_TO_SERIAL
    Serial.println("RTC failed");
#endif  //ECHO_TO_SERIAL
  }
  

  logfile.println("millis,stamp,datetime,lm61temp,therm1,therm2,vcc");    
#if ECHO_TO_SERIAL
  Serial.println("millis,stamp,datetime,lm61temp,therm1,therm2,vcc");
#endif //ECHO_TO_SERIAL
 
  // If you want to set the aref to something other than 5v
  analogReference(EXTERNAL);
}

void loop(void)
{
  DateTime now;

  // delay for the amount of time we want between readings
  // Use Narcoleptic.delay to put in low power mode
  Narcoleptic.delay((LOG_INTERVAL -1) - ((millis() + Narcoleptic.millis()) % LOG_INTERVAL));
  
  digitalWrite(greenLEDpin, HIGH);
  
  // log milliseconds since starting
  uint32_t m = millis() + Narcoleptic.millis();
  logfile.print(m);           // milliseconds since start
  logfile.print(", ");    
#if ECHO_TO_SERIAL
  Serial.print(m);         // milliseconds since start
  Serial.print(", ");  
#endif

  // fetch the time
  now = RTC.now();
  // log time
  logfile.print(now.unixtime()); // seconds since 1/1/1970
  logfile.print(", ");
  logfile.print('"');
  logfile.print(now.year(), DEC);
  logfile.print("/");
  logfile.print(now.month(), DEC);
  logfile.print("/");
  logfile.print(now.day(), DEC);
  logfile.print(" ");
  logfile.print(now.hour(), DEC);
  logfile.print(":");
  logfile.print(now.minute(), DEC);
  logfile.print(":");
  logfile.print(now.second(), DEC);
  logfile.print('"');
#if ECHO_TO_SERIAL
  Serial.print(now.unixtime()); // seconds since 1/1/1970
  Serial.print(", ");
  Serial.print('"');
  Serial.print(now.year(), DEC);
  Serial.print("/");
  Serial.print(now.month(), DEC);
  Serial.print("/");
  Serial.print(now.day(), DEC);
  Serial.print(" ");
  Serial.print(now.hour(), DEC);
  Serial.print(":");
  Serial.print(now.minute(), DEC);
  Serial.print(":");
  Serial.print(now.second(), DEC);
  Serial.print('"');
#endif //ECHO_TO_SERIAL

  analogRead(LM61PIN);
  delay(10); 
  int lm61reading = analogRead(LM61PIN);
  float lm61temp = lm61(lm61reading);
  
  analogRead(THERM1);
  delay(10);
  int thermreading = analogRead(THERM1);
  float therm1temp = Thermistor(thermreading);
  
  analogRead(THERM2);
  delay(10);
  thermreading = analogRead(THERM2);
  float therm2temp = Thermistor(thermreading);
  
  logfile.print(", ");    
  logfile.print(lm61temp);
  logfile.print(", ");    
  logfile.print(therm1temp);
  logfile.print(", ");    
  logfile.print(therm2temp);
#if ECHO_TO_SERIAL
  Serial.print(", ");   
  Serial.print(lm61temp);
  Serial.print(", ");   
  Serial.print(therm1temp);
  Serial.print(", ");   
  Serial.print(therm2temp);
#endif //ECHO_TO_SERIAL

  // Log the estimated 'VCC' voltage by measuring the internal 1.1v ref
  analogRead(BANDGAPREF); 
  delay(10);
  int refReading = analogRead(BANDGAPREF); 
  float supplyvoltage = (bandgap_voltage * 1024) / refReading; 
  
  logfile.print(", ");
  logfile.print(supplyvoltage);
#if ECHO_TO_SERIAL
  Serial.print(", ");   
  Serial.print(supplyvoltage);
#endif // ECHO_TO_SERIAL

  logfile.println();
#if ECHO_TO_SERIAL
  Serial.println();
#endif // ECHO_TO_SERIAL

  digitalWrite(greenLEDpin, LOW);

  // Now we write data to disk! Don't sync too often - requires 2048 bytes of I/O to SD card
  // which uses a bunch of power and takes time
  uint32_t t = millis() + Narcoleptic.millis();
  if ((t - syncTime) < SYNC_INTERVAL) return;
  syncTime = t;
  
  // blink LED to show we are syncing data to the card & updating FAT!
  digitalWrite(redLEDpin, HIGH);
  logfile.flush();
  digitalWrite(redLEDpin, LOW);
  
}


