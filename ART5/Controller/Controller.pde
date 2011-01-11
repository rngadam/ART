/* Serial uses theses pins:
pin 0: RX
pin 1: TX
*/
const byte USERFUNCTION0_PIN = 2; //DIP11
const byte USERFUNCTION1_PIN = 3; //DIP12
const byte TRIGGERSONAR_PIN = 4; //DIP13
const byte SONARSEL0_PIN = 5; //DIP14
const byte SONARSEL1_PIN = 6; //DIP15
const byte DIRSEL0_PIN = 7; //DIP16
const byte DIRSEL1_PIN = 8; //DIP17
const byte DIRSEL2_PIN = 9; //DIP18
const byte ECHOSONAR_PIN = A0; //DIP36

/* SPI (RF communication transceiver) uses these pins:

pin 10	SS	SPI slave select
pin 11	MOSI	SPI master out, slave in
pin 12	MISO	SPI master in, slave out
pin 13	SCK	SPI clock	
*/
void setup() {

}

void loop() {
  digitalWrite(Trig_pin, LOW);
  delayMicroseconds(2);
  digitalWrite(Trig_pin, HIGH);
  delayMicroseconds(10);
  digitalWrite(Trig_pin, LOW);
  return pulseIn(Echo_pin,HIGH);
}
