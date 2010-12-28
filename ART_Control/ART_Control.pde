
const int FORWARD =  2;      // the number of the LED pin
const int REVERSE =  3;  
const int LEFT = 4;  
const int RIGHT =  5;  

const int INFRARED_FORWARD = A0;
const int INFRARED_REVERSE = A1;
const int MINIMUM_INFRARED_READING = 500;
int current_reverse = LEFT;
int alt_forward = RIGHT;

char current_state;

void setup() { 
  // initialize the pushbutton pin as an input:
  pinMode(FORWARD, OUTPUT);     
  pinMode(REVERSE, OUTPUT);    
  pinMode(LEFT, OUTPUT);  
  pinMode(RIGHT, OUTPUT);  
  pinMode(INFRARED_FORWARD, INPUT);
  pinMode(INFRARED_REVERSE, INPUT);
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
void loop(){
    // always check if we can go forward
    int value = analogRead(INFRARED_FORWARD);
    if(value >= MINIMUM_INFRARED_READING) {
        // maybe we were correcting, so check that
        char last_state = update_state('F', value);
        digitalWrite(current_reverse, LOW);
        digitalWrite(REVERSE, LOW);   
        if(last_state == 'R') {
          // we just successfully exited a bad loop, turn for a bit for half a second
          digitalWrite(alt_forward, HIGH);
          digitalWrite(FORWARD, HIGH);
          delay(1000);
          digitalWrite(alt_forward, LOW);
        }
        digitalWrite(FORWARD, HIGH);    
    } else {
      // otherwise, still correcting, keep off
      digitalWrite(FORWARD, LOW);
      // we want to try to find an alt path
      int value = analogRead(INFRARED_REVERSE);
      if(value >= MINIMUM_INFRARED_READING) {
        //still have some ability to go backward
        update_state('R', value);
        digitalWrite(current_reverse, HIGH);
        digitalWrite(REVERSE, HIGH);    
      } else {
        // whooaah, even backward is not possible, we're stuck
        digitalWrite(current_reverse, LOW);
        digitalWrite(REVERSE, LOW);   
        update_state('S', value);
      }
    }

}
