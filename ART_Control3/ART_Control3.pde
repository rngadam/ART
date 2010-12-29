 
const int FORWARD =  2;      // the number of the LED pin
const int REVERSE =  3;  
const int LEFT = 4;  
const int RIGHT =  5;  

const int INFRARED_FORWARD_LEFT = A0;
const int INFRARED_FORWARD_RIGHT = A1;
const int MINIMUM_INFRARED_READING = 500;

char current_state;

int last_cmd[2];

void setup() { 
  // initialize the pushbutton pin as an input:
  pinMode(FORWARD, OUTPUT);     
  pinMode(REVERSE, OUTPUT);    
  pinMode(LEFT, OUTPUT);  
  pinMode(RIGHT, OUTPUT);  
  pinMode(INFRARED_FORWARD_LEFT, INPUT);
  pinMode(INFRARED_FORWARD_RIGHT, INPUT);
  last_cmd[0] = 0;
  last_cmd[1] = 0;
  Serial.begin(9600);
}

char update_state(char state, int reason) {
  char previous_state = current_state;
  if(state != current_state) {
    current_state = state;
    Serial.print(current_state);  
    Serial.println(reason);
  }
  return previous_state;
}

void pwm(int dir, int index, int duration) {
  // if it's been longer than s
  int current_time = millis();
  // target is in the future
  if(current_time < last_cmd[index]) {    
    digitalWrite(dir, HIGH);
  // we want to make sure that the desired time off time has elapsed
  } else if((current_time - last_cmd[index]) > duration) {
    // ...then we do follow the command
    digitalWrite(dir, HIGH);
    // ...and we wait until we're in the future to change that
    last_cmd[index] = current_time + duration;
  } else {
    // lets wait a bit so as not to go too fast...
    digitalWrite(dir, LOW);
  }
}

void go(int dir) {
  switch(dir) {
    case FORWARD:
      digitalWrite(REVERSE, LOW);
      // lets not go too fast...   
      pwm(FORWARD, 0, 250);
      break;
    case REVERSE:
      digitalWrite(FORWARD, LOW);   
      go(REVERSE);
      break;  
    case LEFT:
      digitalWrite(RIGHT, LOW);   
      digitalWrite(LEFT, HIGH);   
      break;
    case RIGHT:
      digitalWrite(LEFT, LOW);   
      digitalWrite(RIGHT, HIGH);   
      break;            
  }
}

void suspend(int dir) {
  digitalWrite(dir, LOW);
}

void full_stop() {
  suspend(FORWARD);
  suspend(REVERSE);
  suspend(LEFT);
  suspend(RIGHT);
}

void loop(){
    int left_value = analogRead(INFRARED_FORWARD_LEFT);
    int right_value = analogRead(INFRARED_FORWARD_RIGHT);
    if(left_value >= MINIMUM_INFRARED_READING && right_value >= MINIMUM_INFRARED_READING) {
      // everything looks good, move fast!
      go(FORWARD);
      update_state('F', left_value);
    } else if(left_value < MINIMUM_INFRARED_READING && right_value < MINIMUM_INFRARED_READING)  {
      // both sides have something, go in reverse
      go(REVERSE);
      if(current_state != 'H' && current_state != 'E') {
        if(left_value > right_value) {
          // there's an obstacle on our right? reverse while keeping right
          go(RIGHT);
          update_state('H', right_value);
        } else {
          // there's an obstacle on our left, reverse while keeping left
          go(LEFT);
          update_state('E', left_value);
        }
      }
    }  else {
      //we should be able to go forward, but need to do a turn too
      go(FORWARD);
      if(left_value > right_value) {
        // there's an obstacle on our right?
        go(LEFT);
        update_state('L', right_value);
      } else {
        // there's an obstacle on our left?
        go(RIGHT);
        update_state('R', left_value);
      }
    }
}
