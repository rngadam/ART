/***************************************************************************** 
 * Datatype	RAM usage
 * void keyword	N/A
 * boolean	1 byte
 * char	1 byte
 * unsigned char	1 byte
 * int	2 byte
 * unsigned int	2 byte
 * word	2 byte
 * long	4 byte
 * unsigned long	4 byte
 * float	4 byte
 * double	4 byte
 * string	1 byte + x
 * array	1 byte + x
 * enum	N/A
 * struct	N/A
 * pointer	N/A
 *****************************************************************************/
 
typedef unsigned long time_ms_t;
typedef unsigned int duration_ms_t;

typedef unsigned int distance_cm_t;
typedef unsigned int sensor_reading_t;
typedef unsigned char angle_t;
typedef unsigned char bitmask8_t;
typedef const unsigned char pin_t;
typedef const unsigned char interrupt_t;
typedef unsigned char enum_t;
typedef unsigned char constant_t;
typedef const unsigned int large_constant_t;
typedef unsigned char loop_t;
typedef unsigned char turn_rate_t;
