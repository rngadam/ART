const int LEFT_DRIVE[2] = {9, 10};
const int RIGHT_DRIVE[2] = {5, 6};
const int FORWARD_DRIVE = 0;
const int BACKWARD_DRIVE = 1;

const int SENSOR_FORWARD = 12;
const int SENSOR_RIGHT = 7;
const int SENSOR_LEFT = 8;

void setup() {
  Serial.begin(9600);
  pinMode(LEFT_DRIVE[FORWARD_DRIVE], OUTPUT);
  pinMode(LEFT_DRIVE[BACKWARD_DRIVE], OUTPUT);
  
  pinMode(RIGHT_DRIVE[BACKWARD_DRIVE], OUTPUT);
  pinMode(RIGHT_DRIVE[FORWARD_DRIVE], OUTPUT);
  
  pinMode(SENSOR_FORWARD, INPUT);
  pinMode(SENSOR_RIGHT, INPUT);
  pinMode(SENSOR_LEFT, INPUT);
}

const int OK = 1;
const int OBSTACLE = 2;

const int FORWARD = 0;
const int BACKWARD = 1;
const int TURN_RIGHT = 2;
const int TURN_LEFT = 3;
const int IDLE = 4;

const char* COMMANDS[] = {
  "FORWARD",
  "BACKWARD",
  "TURN_LEFT",
  "TURN_RIGHT",
  "IDLE"
};

// LEFT, RIGHT, FORWARD
int sensor_command[][4] = {
  { OK,         OK,         OK,         FORWARD }, 
  { OBSTACLE,   OK,         OK,         FORWARD },
  { OK,         OK,         OBSTACLE,   FORWARD },
  { OK,         OBSTACLE,   OK,         TURN_RIGHT },  
  { OBSTACLE,   OBSTACLE,   OK,         TURN_RIGHT },
  { OK,         OBSTACLE,   OBSTACLE,   TURN_LEFT},
  { OBSTACLE,   OK,         OBSTACLE,   FORWARD },
  { OBSTACLE,   OBSTACLE,   OBSTACLE,   BACKWARD},
};



void forward(const int drive[]) {
  digitalWrite(drive[FORWARD_DRIVE], HIGH);
  digitalWrite(drive[BACKWARD_DRIVE], LOW);
}

void backward(const int drive[]) {
  digitalWrite(drive[FORWARD_DRIVE], LOW);
  digitalWrite(drive[BACKWARD_DRIVE], HIGH);
}

void suspend(const int drive[]) {
  digitalWrite(drive[FORWARD_DRIVE], LOW);
  digitalWrite(drive[BACKWARD_DRIVE], LOW);

}

int read_sensor(int sensor_pin) {
  if(digitalRead(sensor_pin) == 0) {
    return OBSTACLE;
  } else {
    return OK;
  }
}

int current_state[3];
int command;
int new_command;

void loop() 
{
  Serial.println("FORWARD");
  forward(LEFT_DRIVE);
  forward(RIGHT_DRIVE);
  delay(5000);
  Serial.println("LEFT");
  backward(LEFT_DRIVE);
  forward(RIGHT_DRIVE);
  delay(5000);
  Serial.println("RIGHT");
  forward(LEFT_DRIVE);
  backward(RIGHT_DRIVE);
  delay(5000);
  Serial.println("BACKWARD");
  backward(LEFT_DRIVE);
  backward(RIGHT_DRIVE);
  delay(5000);
  Serial.println("IDLE");
  suspend(LEFT_DRIVE);
  suspend(RIGHT_DRIVE);
  delay(5000);
}

/*
void loop() {
  current_state[0] = read_sensor(SENSOR_LEFT);
  current_state[1] = read_sensor(SENSOR_FORWARD);
  current_state[2] = read_sensor(SENSOR_RIGHT);
  
  new_command = IDLE;
  for(int i=0; i<8; i++) {
    if(current_state[0] == sensor_command[i][0] && 
       current_state[1] == sensor_command[i][1] && 
       current_state[2] == sensor_command[i][2]) {
      new_command = sensor_command[i][3];
      break;
    }
  }
  
  if(new_command != command) {
    command = new_command;
    Serial.println(COMMANDS[command]);
    switch(command) {
      case FORWARD:
        forward(LEFT_DRIVE);
        forward(RIGHT_DRIVE);
        break;
      case BACKWARD:
        backward(LEFT_DRIVE);
        backward(RIGHT_DRIVE);
        break;
      case TURN_RIGHT:
        forward(LEFT_DRIVE);
        backward(RIGHT_DRIVE);
        break;
      case TURN_LEFT:
        backward(LEFT_DRIVE);
        forward(RIGHT_DRIVE);
        break;
      case IDLE:
        suspend(LEFT_DRIVE);
        suspend(RIGHT_DRIVE);
        break;
    }  
  }
}
*/
