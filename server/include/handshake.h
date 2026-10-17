/* handshake.h - UE4 4.18 StatelessConnect handshake, server side.
 *
 * Constants below are CONFIRMED from libUE4.so (see recon/handshake.md):
 *   cookie 20 bytes (0x14), secret 64 bytes (0x40), packet 195 bits (0xc3).
 * 195 = 1 + 1 + 1 + 32 + 160 exactly, leaving no room for an extra field.
 *
 * The FIELD ORDER is [STOCK]/unverified - taken from open-source UE4 4.18 and
 * not yet observed on the wire for this build. It is isolated in hs_encode() /
 * hs_decode() in handshake.c so correcting it is a one-place change. Right
 * total with wrong order still fails, so expect to adjust during bring-up.
 *
 * Cookie construction is OURS to choose: the server both generates and verifies
 * it, and the client only echoes it back, so it need not match Tencent's.
 */
#ifndef PUBGM_HANDSHAKE_H
#define PUBGM_HANDSHAKE_H

#include "bitstream.h"
#include "sha1.h"

#define HS_COOKIE_BYTES 20                 /* [CONFIRMED] 0x14 */
#define HS_SECRET_BYTES 64                 /* [CONFIRMED] 0x40 */
#define HS_SECRET_COUNT 2                  /* [STOCK] */
#define HS_PACKET_BITS  195                /* [CONFIRMED] 0xc3 */

/* [STOCK] cookie lifetime bounds, in seconds. */
#define HS_SECRET_UPDATE_TIME 15.0f
#define HS_MAX_COOKIE_AGE     40.0f

typedef struct {
    int     b_handshake_packet;
    int     b_restart_handshake;
    int     secret_id;                     /* 1 bit: selects which secret */
    float   timestamp;                     /* 0 in the client's first packet */
    uint8_t cookie[HS_COOKIE_BYTES];
} HsPacket;

/* Codec. Writes/reads exactly HS_PACKET_BITS bits and no termination bit (the
 * caller frames the packet). Returns 0 on success, -1 otherwise. */
int hs_encode(BitWriter *w, const HsPacket *p);
int hs_decode(BitReader *r, HsPacket *p);

typedef struct {
    uint8_t secret[HS_SECRET_COUNT][HS_SECRET_BYTES];
    int     active_secret;
} HsServer;

/* Derives both secrets from `seed`, so tests are reproducible. A real server
 * should pass OS entropy. */
void hs_server_init(HsServer *s, const void *seed, size_t seedlen);
/* Rotates which secret is active, replacing the one being retired. */
void hs_rotate_secret(HsServer *s, const void *seed, size_t seedlen);

/* cookie = HMAC-SHA1(secret[secret_id], timestamp_bytes || client_addr) */
void hs_generate_cookie(const HsServer *s, int secret_id, float timestamp,
                        const char *client_addr, uint8_t out[HS_COOKIE_BYTES]);

typedef enum {
    HS_IGNORE = 0,          /* not for us or malformed: drop silently */
    HS_SEND_CHALLENGE = 1,  /* first contact: `out` holds the challenge */
    HS_ACCEPT = 2           /* cookie verified: create the connection */
} HsAction;

/* Drives one step of the handshake. Keeps NO per-client state - that is the
 * point of "stateless connect": a spoofed source address cannot make the
 * server allocate anything before the cookie verifies. */
HsAction hs_server_step(const HsServer *s, const HsPacket *in,
                        const char *client_addr, float now, HsPacket *out);

/* Constant-time compare, exposed for tests. */
int hs_ct_equal(const void *a, const void *b, size_t n);

#endif
