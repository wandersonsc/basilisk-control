// SPDX-License-Identifier: MIT
#include "BasiliskHID.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#ifdef __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <unistd.h>

static int number(IOHIDDeviceRef device, CFStringRef key) {
    CFTypeRef value = IOHIDDeviceGetProperty(device, key);
    int result = 0;
    if (value && CFGetTypeID(value) == CFNumberGetTypeID())
        CFNumberGetValue((CFNumberRef)value, kCFNumberIntType, &result);
    return result;
}
static void io_error(char *error, size_t cap, const char *action, IOReturn code) {
    snprintf(error, cap, "%s failed (0x%08x). Wake the mouse, close other mouse utilities, and retry. If macOS denied access, allow Basilisk Control in System Settings > Privacy & Security > Input Monitoring, then reopen the app.", action, (unsigned int)code);
}
/* Enumerate without opening the manager: do not claim keyboard/mouse interfaces.
   Only the 90-byte control interface of these two exact products can be opened. */
static IOHIDDeviceRef open_device(int *pid, char *error, size_t cap) {
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (!manager) { snprintf(error, cap, "Could not create the HID manager."); return NULL; }
    int vendor = 0x1532;
    CFNumberRef vendorNumber = CFNumberCreate(NULL, kCFNumberIntType, &vendor);
    const void *keys[] = { CFSTR(kIOHIDVendorIDKey) };
    const void *values[] = { vendorNumber };
    CFDictionaryRef match = CFDictionaryCreate(NULL, keys, values, 1,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    IOHIDManagerSetDeviceMatching(manager, match);
    CFRelease(match); CFRelease(vendorNumber);
    CFSetRef devices = IOHIDManagerCopyDevices(manager);
    IOHIDDeviceRef chosen = NULL;
    int bestScore = -1;
    IOReturn lastError = kIOReturnSuccess;
    if (devices) {
        CFIndex count = CFSetGetCount(devices);
        const void **all = calloc((size_t)count, sizeof(void *));
        if (all) {
            CFSetGetValues(devices, all);
            /* Prefer wired control and vendor usage pages, with fallback to another
               eligible interface when opening the preferred one is denied. */
            for (CFIndex i = 0; i < count; ++i) {
                IOHIDDeviceRef device = (IOHIDDeviceRef)all[i];
                int product = number(device, CFSTR(kIOHIDProductIDKey));
                if (product != 0x0086 && product != 0x0088) continue;
                int feature = number(device, CFSTR(kIOHIDMaxFeatureReportSizeKey));
                if (feature < BC_REPORT_SIZE) continue;
                int page = number(device, CFSTR(kIOHIDPrimaryUsagePageKey));
                int score = (product == 0x0086 ? 100 : 0) + (page >= 0xff00 ? 20 : 0) + (feature == 90 ? 5 : 0);
                if (score <= bestScore) continue;
                IOReturn result = IOHIDDeviceOpen(device, kIOHIDOptionsTypeNone);
                if (result != kIOReturnSuccess) { lastError = result; continue; }
                if (chosen) { IOHIDDeviceClose(chosen, 0); CFRelease(chosen); }
                chosen = (IOHIDDeviceRef)CFRetain(device);
                bestScore = score; *pid = product;
            }
            free(all);
        }
        CFRelease(devices);
    }
    CFRelease(manager);
    if (!chosen) {
        if (lastError) io_error(error, cap, "Opening the mouse", lastError);
        else snprintf(error, cap, "No Basilisk Ultimate control interface found. Connect its USB cable or 2.4 GHz receiver and turn the mouse on. Supported IDs: 1532:0086 and 1532:0088.");
    }
    return chosen;
}
static void close_device(IOHIDDeviceRef device) {
    IOHIDDeviceClose(device, kIOHIDOptionsTypeNone); CFRelease(device);
}
static int exchange(IOHIDDeviceRef device, BCReport request, BCReport *response, char *error, size_t cap) {
    IOReturn result = IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, 0, request.bytes, BC_REPORT_SIZE);
    if (result != kIOReturnSuccess) { io_error(error, cap, "Sending a feature report", result); return -1; }
    /* Basilisk Ultimate needs a longer receiver delay than many wired Razer mice.
       Read busy/stale frames again; never blindly resend a write. */
    for (int attempt = 0; attempt < 10; ++attempt) {
        usleep(35000);
        memset(response, 0, sizeof(*response));
        CFIndex length = BC_REPORT_SIZE;
        result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 0, response->bytes, &length);
        if (result != kIOReturnSuccess) { io_error(error, cap, "Reading a feature report", result); return -1; }
        int valid = bc_validate(&request, response, (size_t)length);
        if (valid == 1) continue;
        if (valid == 0) return 0;
        const char *reason = valid == -3 ? "The mouse rejected the command" :
            valid == -4 ? "The receiver could not reach the mouse" :
            valid == -5 ? "This firmware does not support the command" : "Invalid response length, payload or checksum";
        snprintf(error, cap, "%s (command %02x:%02x). Wake the mouse and try its USB cable. Settings already acknowledged may remain applied.", reason, request.bytes[6], request.bytes[7]);
        return -1;
    }
    snprintf(error, cap, "Timed out waiting for command %02x:%02x. Wake the mouse, close other Razer utilities, and retry. A write may have reached the device; refresh before trying again.", request.bytes[6], request.bytes[7]);
    return -1;
}
static int command(IOHIDDeviceRef device, BCCommand cmd, int a, int b, int c, int d, int e,
                   BCReport *response, char *error, size_t cap) {
    BCReport request;
    if (bc_build(&request, cmd, a, b, c, d, e) != 0) {
        snprintf(error, cap, "Invalid setting. DPI must be 100–20000 in steps of 50; polling must be 125, 500 or 1000 Hz."); return -1;
    }
    return exchange(device, request, response, error, cap);
}
int bc_read_status(BCStatus *status, char *error, size_t cap) {
    memset(status, 0, sizeof(*status)); if (cap) error[0] = 0;
    IOHIDDeviceRef device = open_device(&status->product_id, error, cap);
    if (!device) return -1;
    BCReport reply;
    char issue[768] = {0};
    const BCCommand commands[] = { BC_GET_DPI, BC_GET_POLLING, BC_GET_BATTERY, BC_GET_CHARGING };
    for (int i = 0; i < 4; ++i) {
        if (command(device, commands[i], 0, 0, 0, 0, 0, &reply, issue, sizeof(issue)) != 0) {
            if (cap && !error[0]) snprintf(error, cap, "%s", issue);
            continue;
        }
        const uint8_t *args = reply.bytes + 8;
        if (i == 0) {
            int x = (args[1] << 8) | args[2], y = (args[3] << 8) | args[4];
            if (x >= 100 && x <= 20000 && y >= 100 && y <= 20000) {
                status->dpi_x = x; status->dpi_y = y; status->valid |= 1;
            }
        } else if (i == 1) {
            status->polling = bc_polling_hz(args[0]);
            if (status->polling) status->valid |= 2;
        } else if (i == 2) {
            status->battery_percent = (args[1] * 100 + 127) / 255; status->valid |= 4;
        } else if (args[1] <= 1) {
            status->charging = args[1]; status->valid |= 8;
        }
        if (!(status->valid & (1u << i)) && cap && !error[0])
            snprintf(error, cap, "The mouse returned an unexpected setting value; some readings are unavailable.");
    }
    close_device(device);
    if (!status->valid) {
        if (cap && !error[0]) snprintf(error, cap, "The receiver is present, but the mouse did not return usable readings. Wake it or connect its USB cable.");
        return -1;
    }
    return 0;
}
int bc_set_dpi(int x, int y, char *error, size_t cap) {
    BCReport request;
    if (bc_build(&request, BC_SET_DPI, x, y, 0, 0, 0)) { snprintf(error, cap, "DPI must be 100–20000 in steps of 50."); return -1; }
    int pid = 0; IOHIDDeviceRef device = open_device(&pid, error, cap); if (!device) return -1;
    BCReport reply;
    int result = exchange(device, request, &reply, error, cap);
    if (!result) result = command(device, BC_GET_DPI, 0, 0, 0, 0, 0, &reply, error, cap);
    if (!result && (((reply.bytes[9] << 8) | reply.bytes[10]) != x || ((reply.bytes[11] << 8) | reply.bytes[12]) != y)) {
        snprintf(error, cap, "DPI write was acknowledged, but readback did not match. Refresh to inspect the current setting."); result = -1;
    }
    close_device(device); return result;
}
int bc_set_polling(int hz, char *error, size_t cap) {
    BCReport request;
    if (bc_build(&request, BC_SET_POLLING, hz, 0, 0, 0, 0)) { snprintf(error, cap, "Choose 125, 500 or 1000 Hz."); return -1; }
    int pid = 0; IOHIDDeviceRef device = open_device(&pid, error, cap); if (!device) return -1;
    BCReport reply;
    int result = exchange(device, request, &reply, error, cap);
    if (!result) result = command(device, BC_GET_POLLING, 0, 0, 0, 0, 0, &reply, error, cap);
    if (!result && bc_polling_hz(reply.bytes[8]) != hz) { snprintf(error, cap, "Polling write was acknowledged, but readback did not match. Refresh to inspect the current setting."); result = -1; }
    close_device(device); return result;
}
int bc_set_lighting(int zone, int effect, int red, int green, int blue, int brightness, char *error, size_t cap) {
    BCReport check;
    int zones[] = { 1, 4, 0x11, 0x10 };
    if (bc_build(&check, BC_SET_EFFECT, zone == 0 ? 1 : zone, effect, red, green, blue) ||
        bc_build(&check, BC_SET_BRIGHTNESS, zone == 0 ? 1 : zone, brightness, 0, 0, 0)) {
        snprintf(error, cap, "Invalid lighting setting."); return -1;
    }
    int pid = 0; IOHIDDeviceRef device = open_device(&pid, error, cap); if (!device) return -1;
    BCReport reply; int result = 0;
    for (int i = 0; i < (zone == 0 ? 4 : 1); ++i) {
        int led = zone == 0 ? zones[i] : zone;
        result = command(device, BC_SET_EFFECT, led, effect, red, green, blue, &reply, error, cap);
        if (!result) result = command(device, BC_SET_BRIGHTNESS, led, brightness, 0, 0, 0, &reply, error, cap);
        if (result) break;
    }
    close_device(device); return result;
}
#else
/* Portable builds test the packet code; hardware access is only available on macOS. */
int bc_read_status(BCStatus *s, char *e, size_t n) { memset(s, 0, sizeof(*s)); snprintf(e, n, "macOS is required."); return -1; }
int bc_set_dpi(int x, int y, char *e, size_t n) { (void)x; (void)y; snprintf(e, n, "macOS is required."); return -1; }
int bc_set_polling(int hz, char *e, size_t n) { (void)hz; snprintf(e, n, "macOS is required."); return -1; }
int bc_set_lighting(int z, int f, int r, int g, int b, int v, char *e, size_t n) { (void)z; (void)f; (void)r; (void)g; (void)b; (void)v; snprintf(e, n, "macOS is required."); return -1; }
#endif
