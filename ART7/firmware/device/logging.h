#ifdef ERROR_SERIAL_LOGGING    
#define LOG_BAD_STATE(value) \
Serial.print(millis()); \
Serial.print(": "); \
Serial.print(__FUNCTION__); \
Serial.print(':'); \
Serial.print(__LINE__); \
Serial.print(' '); \
Serial.println((int)value);
#define LOG_ERROR(message, context, expected, actual) \
Serial.print("ERROR:"); \
Serial.print(millis()); \
Serial.print(":"); \
Serial.print(message); \
Serial.print(" context:"); \
Serial.print((int)context); \
Serial.print(" expected:"); \
Serial.print((int)expected); \
Serial.print(" actual:"); \
Serial.println((int)actual);     
#else
#define LOG_ERROR(message, source, expected, actual)
#define LOG_BAD_STATE(value)
#endif