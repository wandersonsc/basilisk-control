// SPDX-License-Identifier: MIT
#include "BasiliskHID.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static BCReport build(BCCommand cmd, int a, int b, int c, int d, int e) {
    BCReport r; assert(bc_build(&r, cmd, a, b, c, d, e) == 0); return r;
}
static void checksum(BCReport *r) { r->bytes[88] = bc_checksum(r); }
static void vectors(void) {
    /* Fixed packet fixtures, including expected XOR bytes. */
    BCReport dpi = build(BC_SET_DPI, 1600, 800, 0, 0, 0);
    const uint8_t prefix[] = {0, 0x1f, 0, 0, 0, 7, 4, 5, 1, 6, 0x40, 3, 0x20, 0, 0};
    assert(memcmp(dpi.bytes, prefix, sizeof(prefix)) == 0);
    assert(dpi.bytes[88] == 0x62 && dpi.bytes[89] == 0);
    for (int i = 15; i < 88; ++i) assert(dpi.bytes[i] == 0);
    BCReport poll = build(BC_GET_POLLING, 0, 0, 0, 0, 0);
    assert(poll.bytes[1] == 0xff && poll.bytes[7] == 0x85 && poll.bytes[88] == 0x84);
    BCReport light = build(BC_SET_EFFECT, 4, 1, 255, 64, 128);
    const uint8_t rgb[] = {1, 4, 1, 0, 0, 1, 255, 64, 128};
    assert(light.bytes[5] == 9 && light.bytes[6] == 15 && light.bytes[7] == 2);
    assert(memcmp(light.bytes + 8, rgb, sizeof(rgb)) == 0 && light.bytes[88] == 0x3e);
    BCReport battery = build(BC_GET_BATTERY, 0, 0, 0, 0, 0);
    assert(battery.bytes[1] == 0x1f && battery.bytes[5] == 2 && battery.bytes[6] == 7 && battery.bytes[7] == 0x80);
    BCReport charge = build(BC_GET_CHARGING, 0, 0, 0, 0, 0);
    assert(charge.bytes[7] == 0x84);
    BCReport off = build(BC_SET_EFFECT, 0x11, 0, 0, 0, 0);
    assert(off.bytes[5] == 6 && off.bytes[10] == 0);
    BCReport spectrum = build(BC_SET_EFFECT, 0x10, 3, 0, 0, 0);
    assert(spectrum.bytes[5] == 6 && spectrum.bytes[10] == 3);
}
static void ranges(void) {
    BCReport r;
    assert(bc_build(&r, BC_SET_DPI, 99, 100, 0, 0, 0) == -1);
    assert(bc_build(&r, BC_SET_DPI, 100, 20001, 0, 0, 0) == -1);
    assert(bc_build(&r, BC_SET_DPI, 125, 800, 0, 0, 0) == -1);
    for (int dpi = 100; dpi <= 20000; dpi += 50) {
        r = build(BC_SET_DPI, dpi, dpi, 0, 0, 0);
        assert(((r.bytes[9] << 8) | r.bytes[10]) == dpi);
        assert(((r.bytes[11] << 8) | r.bytes[12]) == dpi);
        assert(r.bytes[88] == bc_checksum(&r));
    }
    int rates[] = {125, 500, 1000};
    for (int i = 0; i < 3; ++i) {
        r = build(BC_SET_POLLING, rates[i], 0, 0, 0, 0);
        assert(bc_polling_hz(r.bytes[8]) == rates[i] && r.bytes[1] == 0x1f);
    }
    assert(bc_build(&r, BC_SET_POLLING, 250, 0, 0, 0, 0) == -1);
    assert(bc_polling_hz(0xff) == 0);
    assert(bc_build(&r, BC_SET_EFFECT, 0xff, 1, 0, 0, 0) == -1);
    assert(bc_build(&r, BC_SET_EFFECT, 4, 4, 0, 0, 0) == -1);
    assert(bc_build(&r, BC_SET_EFFECT, 4, 1, 256, 0, 0) == -1);
    for (int level = 0; level <= 100; ++level) {
        r = build(BC_SET_BRIGHTNESS, 1, level, 0, 0, 0);
        assert(r.bytes[10] == (level * 255 + 50) / 100);
    }
    assert(bc_build(&r, BC_SET_BRIGHTNESS, 1, 101, 0, 0, 0) == -1);
}
static void replies(void) {
    BCReport request = build(BC_GET_DPI, 0, 0, 0, 0, 0);
    BCReport response = request; response.bytes[0] = 2;
    assert(bc_validate(&request, &response, 90) == 0);
    assert(bc_validate(&request, &response, 89) == -1);
    assert(bc_validate(&request, &response, 91) == -1);
    response.bytes[10] ^= 1;
    assert(bc_validate(&request, &response, 90) == -1);
    checksum(&response);
    assert(bc_validate(&request, &response, 90) == 0);
    response.bytes[0] = 1;
    assert(bc_validate(&request, &response, 90) == 1);
    response.bytes[0] = 0;
    assert(bc_validate(&request, &response, 90) == 1);
    response.bytes[0] = 2; response.bytes[1] = 0xff;
    assert(bc_validate(&request, &response, 90) == 1);
    response.bytes[1] = request.bytes[1]; response.bytes[7] = 5; checksum(&response);
    assert(bc_validate(&request, &response, 90) == 1);
    response = request; response.bytes[0] = 3;
    assert(bc_validate(&request, &response, 90) == -3);
    response.bytes[0] = 4; assert(bc_validate(&request, &response, 90) == -4);
    response.bytes[0] = 5; assert(bc_validate(&request, &response, 90) == -5);
    response.bytes[0] = 2; response.bytes[5] = 81; checksum(&response);
    assert(bc_validate(&request, &response, 90) == -1);
    response.bytes[5] = 1; checksum(&response);
    assert(bc_validate(&request, &response, 90) == -1);
    response = request; response.bytes[0] = 2; response.bytes[4] = 1; checksum(&response);
    assert(bc_validate(&request, &response, 90) == -1);
    assert(bc_validate(NULL, &response, 90) == -1);
}
int main(void) {
    vectors(); ranges(); replies();
    puts("PASS: packet fixtures, all supported DPI values, polling mappings, brightness bounds, reply integrity, stale/busy frames and firmware errors.");
    return 0;
}
