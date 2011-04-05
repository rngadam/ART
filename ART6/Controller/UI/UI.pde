
import processing.serial.*;

Serial myPort;  // Create object from Serial class
int val;      // Data received from the serial port
boolean port = false;
PFont fontA;

final byte ULTRASONIC_SENSORS = 0;
final byte STATE_CHANGE = 1;
final byte SENSOR_SERVO_POSITION_CHANGE = 2;
final byte CAR_GO_COMMAND = 3;
final byte CAR_SUSPEND_COMMAND = 4;
final byte MAX_TELEMETRY_TYPE = 5;

byte SENSOR_LEFT = 0;
byte SENSOR_FRONT = 1;
byte SENSOR_RIGHT = 2;
byte SENSOR_LEFT_SIDE = 3;
byte SENSOR_RIGHT_SIDE = 4;
byte SENSOR_BACK_LEFT = 5;
byte SENSOR_BACK = 6;
byte SENSOR_BACK_RIGHT = 7;
byte NUMBER_READINGS = 8;

String[] STATES = {
  "INITIAL",
  "FULL_SWEEP",
// units advancement
  "FORWARD_LEFT_UNIT",
  "FORWARD_UNIT",
  "FORWARD_RIGHT_UNIT",
  "REVERSE_LEFT_UNIT",
  "REVERSE_UNIT",
  "REVERSE_RIGHT_UNIT",
  "STANDSTILL_DECISION",
  "STUCK",
  "STOP",
  "SMALL_TURN_CCW",
  "SMALL_TURN_CW",
};

boolean sensor_readings[] = new boolean[NUMBER_READINGS];

char values[] = new char[300];
int valuesIndex = 0;
boolean recording = false;
String lastLine = "No data yet";
String[] lastRecord = {"No time recorded", "No type", "No source", "No value" };
String lastTime;
String lastState;
String previousState;

void setup() 
{
  size(800, 600);
  
  // init variables
  for(int i = 0;i<NUMBER_READINGS; i++) {
    sensor_readings[i] = false;
  }
  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  try {
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, 9600);
    port = true;
  } catch(ArrayIndexOutOfBoundsException e) {
    // no ports available...
    port = false;
  }
  // Load the font. Fonts must be placed within the data 
  // directory of your sketch. Use Tools > Create Font 
  // to create a distributable bitmap font. 
  // For vector fonts, use the createFont() function. 
  fontA = loadFont("Ziggurat-HTF-Black-32.vlw");

  // Set the font and its size (in units of pixels)
  textFont(fontA, 32);
  redraw();
}

void update() {
  if(!port) 
    return;
  int b = 0;
  while(true) {
    b = myPort.read();
    switch(b) {
      case '\r':
        break;
      case '|':
        recording = true;
        break;
      case '\n':
        processLine(new String(values, 0, valuesIndex));
        valuesIndex = 0;
        recording = false;
        return;
      case -1:
        return;
      default:
        values[valuesIndex++] = (char)b;
        if(valuesIndex>=300) {
          valuesIndex = 0;
        }
        break;
      }
    }
}

void processLine(String currentLine) {
  if(!recording) {
    lastLine = currentLine;
  } else {
    lastRecord = currentLine.split(",");
    lastTime = lastRecord[0];
    int type = Integer.valueOf(lastRecord[1]);
    int source = Integer.valueOf(lastRecord[2]);
    int value = Integer.valueOf(lastRecord[3]);
    switch(type) {
      case ULTRASONIC_SENSORS:
        sensor_readings[source] = value == 1;
        break;
      case STATE_CHANGE:
        previousState = STATES[source];
        lastState = STATES[value];
        break;
      case SENSOR_SERVO_POSITION_CHANGE:
        break;
      case CAR_GO_COMMAND:
        break;
      case CAR_SUSPEND_COMMAND:
        break;
      case MAX_TELEMETRY_TYPE:
        break;
      default:
        println("Unknown telemetry type: " + type);
        break;
    }
    println(lastRecord);   
  }
}

void draw() {
  update();
  //if(!update())
  //  return;
  background(255);
  // Use fill() to change the value or color of the text
  fill(0);

  text("port available", 30, 50);
  text(lastLine, 30, 100);
  text("Time: " + lastTime, 30, 150);
  text("State: " + lastState, 30, 200);  
  text("Previous: " + previousState, 30, 250);  
  
  int start = height/2;
  text(sensor_readings[SENSOR_LEFT]?1:0, 100, start);
  text(sensor_readings[SENSOR_FRONT]?1:0, 300, start);
  text(sensor_readings[SENSOR_RIGHT]?1:0, 500, start);

  text(sensor_readings[SENSOR_LEFT_SIDE]?1:0, 50, start + 50);
  text(sensor_readings[SENSOR_RIGHT_SIDE]?1:0, 550, start + 50);

  text(sensor_readings[SENSOR_BACK_LEFT]?1:0, 100, start + 100);
  text(sensor_readings[SENSOR_BACK]?1:0, 300, start + 100);
  text(sensor_readings[SENSOR_BACK_RIGHT]?1:0, 500, start + 100);
}
