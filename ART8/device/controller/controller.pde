const int LEFT_DRIVE[2] = {
  5, 6};
const int RIGHT_DRIVE[2] = {
  9, 10};
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
    return 0;
  } 
  else {
    return 1;
  }
}



void loop() {

  int left = read_sensor(SENSOR_LEFT);
  int mid = read_sensor(SENSOR_FORWARD);
  int right = read_sensor(SENSOR_RIGHT);

  //anything infront
  if (mid) {
    FWD();
  }


  if (!right) {
    BREAK();
    LEFT();
  }

  if (!left) {
    BREAK();
    RIGHT();
  }


  if (!mid) {
    if (!right) {
      BREAK();
      LEFT();
    }

    if (!left) {
      BREAK();
      RIGHT();
    } 

    if (!mid) {
      REV();
      delay(100);
      LEFT();
      delay(50);
    }
  }
}



void FWD() {
  forward(LEFT_DRIVE);
  forward(RIGHT_DRIVE);
}
void REV() {
  backward(LEFT_DRIVE);
  backward(RIGHT_DRIVE);
}
void LEFT() {
  backward(LEFT_DRIVE);
  forward(RIGHT_DRIVE);
}
void RIGHT() {
  forward(LEFT_DRIVE);
  backward(RIGHT_DRIVE);
}
void BREAK() {
  suspend(LEFT_DRIVE);
  suspend(RIGHT_DRIVE);
}





