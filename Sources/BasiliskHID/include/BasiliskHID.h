#ifndef BASILISK_HID_H
#define BASILISK_HID_H
#include <stdint.h>
#include <stddef.h>

#define BC_REPORT_SIZE 90
typedef struct { uint8_t bytes[BC_REPORT_SIZE]; } BCReport;
typedef enum {
    BC_GET_DPI, BC_SET_DPI, BC_GET_POLLING, BC_SET_POLLING,
    BC_GET_BATTERY, BC_GET_CHARGING, BC_SET_EFFECT, BC_SET_BRIGHTNESS
} BCCommand;
typedef struct {
    int product_id, dpi_x, dpi_y, polling, battery_percent, charging;
    unsigned int valid; /* 1 DPI, 2 polling, 4 battery, 8 charging */
} BCStatus;

/* Portable packet encoder/validator. No hardware or framework dependencies. */
uint8_t bc_checksum(const BCReport *report);
int bc_build(BCReport *report, BCCommand command, int a, int b, int c, int d, int e);
/* 0 success, 1 busy/stale, negative means malformed/device failure. */
int bc_validate(const BCReport *request, const BCReport *response, size_t length);
int bc_polling_hz(uint8_t value);

/* Call from a serial worker, never the UI thread. Errors are NUL-terminated. */
int bc_read_status(BCStatus *status, char *error, size_t capacity);
int bc_set_dpi(int x, int y, char *error, size_t capacity);
int bc_set_polling(int hz, char *error, size_t capacity);
/* zone: 0 all, 1 wheel, 4 logo, 0x11 left, 0x10 right.
   effect: 0 off, 1 static, 3 spectrum. Brightness: 0..100. */
int bc_set_lighting(int zone, int effect, int red, int green, int blue,
                    int brightness, char *error, size_t capacity);
#endif
