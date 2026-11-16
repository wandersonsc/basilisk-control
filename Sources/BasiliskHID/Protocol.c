// SPDX-License-Identifier: MIT
// Original encoder for the Basilisk Ultimate's OpenRazer-documented wire format.
#include "BasiliskHID.h"
#include <string.h>

uint8_t bc_checksum(const BCReport *r) {
    uint8_t crc = 0;
    for (int i = 2; i < 88; ++i) crc ^= r->bytes[i];
    return crc;
}
int bc_polling_hz(uint8_t value) {
    switch (value) { case 1: return 1000; case 2: return 500; case 8: return 125; }
    return 0;
}
static int zone_valid(int zone) {
    return zone == 1 || zone == 4 || zone == 0x10 || zone == 0x11;
}
int bc_build(BCReport *r, BCCommand command, int a, int b, int c, int d, int e) {
    if (!r) return -1;
    memset(r, 0, sizeof(*r));
    uint8_t *p = r->bytes;
    uint8_t *args = p + 8;
    p[1] = 0x1f;
    switch (command) {
        case BC_GET_DPI:
            p[5] = 7; p[6] = 4; p[7] = 0x85; break;
        case BC_SET_DPI:
            if (a < 100 || a > 20000 || b < 100 || b > 20000 || a % 50 || b % 50) return -1;
            p[5] = 7; p[6] = 4; p[7] = 5;
            args[0] = 1;
            args[1] = (uint8_t)(a >> 8); args[2] = (uint8_t)a;
            args[3] = (uint8_t)(b >> 8); args[4] = (uint8_t)b; break;
        case BC_GET_POLLING:
            p[1] = 0xff; p[5] = 1; p[7] = 0x85; break;
        case BC_SET_POLLING:
            if (a != 125 && a != 500 && a != 1000) return -1;
            p[5] = 1; p[7] = 5;
            args[0] = a == 1000 ? 1 : a == 500 ? 2 : 8; break;
        case BC_GET_BATTERY:
            p[5] = 2; p[6] = 7; p[7] = 0x80; break;
        case BC_GET_CHARGING:
            p[5] = 2; p[6] = 7; p[7] = 0x84; break;
        case BC_SET_EFFECT:
            if (!zone_valid(a) || (b != 0 && b != 1 && b != 3) ||
                c < 0 || c > 255 || d < 0 || d > 255 || e < 0 || e > 255) return -1;
            p[5] = b == 1 ? 9 : 6; p[6] = 0x0f; p[7] = 2;
            args[0] = 1; args[1] = (uint8_t)a; args[2] = (uint8_t)b;
            if (b == 1) { args[5] = 1; args[6] = (uint8_t)c; args[7] = (uint8_t)d; args[8] = (uint8_t)e; }
            break;
        case BC_SET_BRIGHTNESS:
            if (!zone_valid(a) || b < 0 || b > 100) return -1;
            p[5] = 3; p[6] = 0x0f; p[7] = 4;
            args[0] = 1; args[1] = (uint8_t)a; args[2] = (uint8_t)((b * 255 + 50) / 100); break;
        default: return -1;
    }
    p[88] = bc_checksum(r);
    return 0;
}
int bc_validate(const BCReport *request, const BCReport *response, size_t length) {
    if (!request || !response || length != BC_REPORT_SIZE) return -1;
    const uint8_t *q = request->bytes, *p = response->bytes;
    if (p[5] > 80 || p[88] != bc_checksum(response) || p[4] != 0 || p[2] || p[3]) return -1;
    if (p[1] != q[1] || p[6] != q[6] || p[7] != q[7]) return 1;
    if (p[0] == 0 || p[0] == 1) return 1;
    if (p[0] == 3) return -3;
    if (p[0] == 4) return -4;
    if (p[0] == 5) return -5;
    if (p[0] != 2 || p[5] < q[5]) return -1;
    return 0;
}
