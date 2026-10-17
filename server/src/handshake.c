#include "handshake.h"

#include <string.h>

int hs_ct_equal(const void *a, const void *b, size_t n)
{
    const uint8_t *x = (const uint8_t *)a, *y = (const uint8_t *)b;
    uint8_t d = 0;
    for (size_t i = 0; i < n; i++)
        d |= (uint8_t)(x[i] ^ y[i]);
    return d == 0;
}

/* ---------------------------------------------------------------------------
 * Wire layout. THE SINGLE SOURCE OF TRUTH - see the warning in handshake.h.
 * hs_encode and hs_decode mirror each other field for field; change together.
 * ------------------------------------------------------------------------- */

static uint32_t float_bits(float f)
{
    uint32_t u;
    memcpy(&u, &f, sizeof u);
    return u;
}

static float bits_float(uint32_t u)
{
    float f;
    memcpy(&f, &u, sizeof f);
    return f;
}

int hs_encode(BitWriter *w, const HsPacket *p)
{
    size_t start = w->num_bits;

    bw_write_bit(w, p->b_handshake_packet);
    bw_write_bit(w, p->b_restart_handshake);
    bw_write_bit(w, p->secret_id & 1);
    bw_write_bits(w, float_bits(p->timestamp), 32);
    bw_write_bytes(w, p->cookie, HS_COOKIE_BYTES);

    if (w->overflowed)
        return -1;
    /* The confirmed 195-bit budget is a hard invariant: if this trips, the
     * layout above no longer sums to HANDSHAKE_PACKET_SIZE_BITS. */
    return (w->num_bits - start) == HS_PACKET_BITS ? 0 : -1;
}

int hs_decode(BitReader *r, HsPacket *p)
{
    memset(p, 0, sizeof *p);
    if (br_bits_left(r) < HS_PACKET_BITS)
        return -1;

    p->b_handshake_packet  = br_read_bit(r);
    p->b_restart_handshake = br_read_bit(r);
    p->secret_id           = br_read_bit(r);
    p->timestamp           = bits_float((uint32_t)br_read_bits(r, 32));
    if (br_read_bytes(r, p->cookie, HS_COOKIE_BYTES) != 0)
        return -1;

    return r->error ? -1 : 0;
}

/* ------------------------------------------------------------------------- */

static void derive_secret(uint8_t out[HS_SECRET_BYTES],
                          const void *seed, size_t seedlen, uint8_t index)
{
    /* Expand the seed to 64 bytes with counter-mode HMAC-SHA1. */
    for (unsigned blk = 0; ; blk++) {
        size_t off = (size_t)blk * SHA1_DIGEST_BYTES;
        if (off >= HS_SECRET_BYTES)
            break;
        uint8_t msg[2];
        uint8_t d[SHA1_DIGEST_BYTES];
        msg[0] = index;
        msg[1] = (uint8_t)blk;
        hmac_sha1(seed, seedlen, msg, sizeof msg, d);
        size_t n = HS_SECRET_BYTES - off;
        if (n > SHA1_DIGEST_BYTES)
            n = SHA1_DIGEST_BYTES;
        memcpy(out + off, d, n);
    }
}

void hs_server_init(HsServer *s, const void *seed, size_t seedlen)
{
    for (int i = 0; i < HS_SECRET_COUNT; i++)
        derive_secret(s->secret[i], seed, seedlen, (uint8_t)i);
    s->active_secret = 0;
}

void hs_rotate_secret(HsServer *s, const void *seed, size_t seedlen)
{
    /* Replace the secret going out of service, then make it active. */
    int next = (s->active_secret + 1) % HS_SECRET_COUNT;
    derive_secret(s->secret[next], seed, seedlen, (uint8_t)(next + 0x80));
    s->active_secret = next;
}

void hs_generate_cookie(const HsServer *s, int secret_id, float timestamp,
                        const char *client_addr, uint8_t out[HS_COOKIE_BYTES])
{
    uint8_t msg[4 + 128];
    size_t alen = strlen(client_addr);
    if (alen > sizeof msg - 4)
        alen = sizeof msg - 4;

    uint32_t tb = float_bits(timestamp);
    msg[0] = (uint8_t)(tb);
    msg[1] = (uint8_t)(tb >> 8);
    msg[2] = (uint8_t)(tb >> 16);
    msg[3] = (uint8_t)(tb >> 24);
    memcpy(msg + 4, client_addr, alen);

    /* HMAC-SHA1 output is exactly HS_COOKIE_BYTES. */
    hmac_sha1(s->secret[secret_id & 1], HS_SECRET_BYTES, msg, 4 + alen, out);
}

HsAction hs_server_step(const HsServer *s, const HsPacket *in,
                        const char *client_addr, float now, HsPacket *out)
{
    static const uint8_t zero_cookie[HS_COOKIE_BYTES] = { 0 };

    if (!in->b_handshake_packet)
        return HS_IGNORE;

    /* [STOCK] The client's first packet carries timestamp 0 and a zeroed
     * cookie; anything else is treated as a challenge response. */
    int is_initial = (in->timestamp == 0.0f)
                  && hs_ct_equal(in->cookie, zero_cookie, HS_COOKIE_BYTES);

    if (is_initial || in->b_restart_handshake) {
        memset(out, 0, sizeof *out);
        out->b_handshake_packet = 1;
        out->secret_id = s->active_secret;
        out->timestamp = now;
        hs_generate_cookie(s, s->active_secret, now, client_addr, out->cookie);
        return HS_SEND_CHALLENGE;
    }

    /* Challenge response: recompute and compare. No stored state is consulted,
     * so nothing was allocated for an unverified peer. */
    if (in->timestamp > now || (now - in->timestamp) > HS_MAX_COOKIE_AGE)
        return HS_IGNORE;                  /* stale or future-dated */

    uint8_t expect[HS_COOKIE_BYTES];
    hs_generate_cookie(s, in->secret_id, in->timestamp, client_addr, expect);
    if (!hs_ct_equal(expect, in->cookie, HS_COOKIE_BYTES))
        return HS_IGNORE;

    memset(out, 0, sizeof *out);
    out->b_handshake_packet = 1;
    out->secret_id = in->secret_id;
    out->timestamp = in->timestamp;
    memcpy(out->cookie, in->cookie, HS_COOKIE_BYTES);
    return HS_ACCEPT;
}
