/* Tests for the StatelessConnect handshake.
 *
 * As in test_packet.c, no byte vectors are asserted for the packet: the field
 * order is [STOCK]/unverified, so a vector would only enshrine the guess.
 * What IS asserted is the one thing confirmed from the binary - the 195-bit
 * budget - plus codec symmetry and the full server state machine, none of
 * which depend on the absolute field order being right.
 */
#include "handshake.h"

#include <stdio.h>
#include <string.h>

static int failures;

#define CHECK(cond)                                                        \
    do {                                                                   \
        if (!(cond)) {                                                     \
            printf("FAIL %s:%d  %s\n", __FILE__, __LINE__, #cond);         \
            failures++;                                                    \
        }                                                                  \
    } while (0)

static const char SEED[] = "pubgm-test-seed";

static void fill_cookie(uint8_t *c, uint8_t base)
{
    for (int i = 0; i < HS_COOKIE_BYTES; i++)
        c[i] = (uint8_t)(base + i);
}

/* The confirmed constant: the encoded packet must be exactly 195 bits. */
static void test_packet_is_195_bits(void)
{
    uint8_t buf[64];
    BitWriter w;
    HsPacket p;

    memset(&p, 0, sizeof p);
    p.b_handshake_packet = 1;
    p.timestamp = 123.456f;
    fill_cookie(p.cookie, 0x10);

    bw_init(&w, buf, sizeof buf * 8);
    CHECK(hs_encode(&w, &p) == 0);
    CHECK(w.num_bits == HS_PACKET_BITS);
    CHECK(w.num_bits == 195);

    /* 1 + 1 + 1 + 32 + 160 - the budget is fully consumed. */
    CHECK(1 + 1 + 1 + 32 + HS_COOKIE_BYTES * 8 == HS_PACKET_BITS);
}

static void test_codec_roundtrip(void)
{
    uint8_t buf[64];
    BitWriter w;
    BitReader r;
    HsPacket p, g;

    const float stamps[] = { 0.0f, 1.0f, -1.0f, 123.456f, 1e9f, 1e-9f };
    for (int si = 0; si < (int)(sizeof stamps / sizeof stamps[0]); si++) {
        for (int flags = 0; flags < 8; flags++) {
            memset(&p, 0, sizeof p);
            p.b_handshake_packet  = (flags >> 0) & 1;
            p.b_restart_handshake = (flags >> 1) & 1;
            p.secret_id           = (flags >> 2) & 1;
            p.timestamp = stamps[si];
            fill_cookie(p.cookie, (uint8_t)(flags * 7));

            bw_init(&w, buf, sizeof buf * 8);
            CHECK(hs_encode(&w, &p) == 0);
            br_init(&r, buf, w.num_bits);
            CHECK(hs_decode(&r, &g) == 0);

            CHECK(g.b_handshake_packet == p.b_handshake_packet);
            CHECK(g.b_restart_handshake == p.b_restart_handshake);
            CHECK(g.secret_id == p.secret_id);
            CHECK(memcmp(&g.timestamp, &p.timestamp, sizeof(float)) == 0);
            CHECK(memcmp(g.cookie, p.cookie, HS_COOKIE_BYTES) == 0);
            CHECK(br_bits_left(&r) == 0);
        }
    }
}

static void test_decode_rejects_short(void)
{
    uint8_t buf[64];
    BitWriter w;
    BitReader r;
    HsPacket p, g;

    memset(&p, 0, sizeof p);
    p.b_handshake_packet = 1;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(hs_encode(&w, &p) == 0);

    /* One bit short must be refused, not silently truncated. */
    br_init(&r, buf, w.num_bits - 1);
    CHECK(hs_decode(&r, &g) == -1);

    br_init(&r, buf, 0);
    CHECK(hs_decode(&r, &g) == -1);
}

static void test_cookie_properties(void)
{
    HsServer s;
    uint8_t a[HS_COOKIE_BYTES], b[HS_COOKIE_BYTES];

    hs_server_init(&s, SEED, sizeof SEED - 1);

    /* Deterministic for identical inputs. */
    hs_generate_cookie(&s, 0, 10.0f, "10.0.2.15:5555", a);
    hs_generate_cookie(&s, 0, 10.0f, "10.0.2.15:5555", b);
    CHECK(memcmp(a, b, sizeof a) == 0);

    /* Address, timestamp and secret id must each change it. */
    hs_generate_cookie(&s, 0, 10.0f, "10.0.2.16:5555", b);
    CHECK(memcmp(a, b, sizeof a) != 0);
    hs_generate_cookie(&s, 0, 11.0f, "10.0.2.15:5555", b);
    CHECK(memcmp(a, b, sizeof a) != 0);
    hs_generate_cookie(&s, 1, 10.0f, "10.0.2.15:5555", b);
    CHECK(memcmp(a, b, sizeof a) != 0);

    /* Both secrets must differ from one another. */
    CHECK(memcmp(s.secret[0], s.secret[1], HS_SECRET_BYTES) != 0);

    /* A different seed must give different secrets. */
    HsServer s2;
    hs_server_init(&s2, "other-seed", 10);
    CHECK(memcmp(s.secret[0], s2.secret[0], HS_SECRET_BYTES) != 0);

    /* The derived secret must be fully populated, not left partly zero. */
    int nonzero = 0;
    for (int i = 0; i < HS_SECRET_BYTES; i++)
        if (s.secret[0][i])
            nonzero++;
    CHECK(nonzero > HS_SECRET_BYTES / 2);
}

static void test_full_handshake(void)
{
    HsServer s;
    HsPacket in, chal, resp, ack;
    const char *addr = "10.0.2.15:49152";

    hs_server_init(&s, SEED, sizeof SEED - 1);

    /* 1. Client's initial packet: timestamp 0, zeroed cookie. */
    memset(&in, 0, sizeof in);
    in.b_handshake_packet = 1;
    CHECK(hs_server_step(&s, &in, addr, 100.0f, &chal) == HS_SEND_CHALLENGE);
    CHECK(chal.b_handshake_packet == 1);
    CHECK(chal.timestamp == 100.0f);

    /* The challenge must carry a real cookie. */
    uint8_t zero[HS_COOKIE_BYTES] = { 0 };
    CHECK(memcmp(chal.cookie, zero, sizeof zero) != 0);

    /* 2. Client echoes timestamp + cookie back. */
    resp = chal;
    CHECK(hs_server_step(&s, &resp, addr, 100.5f, &ack) == HS_ACCEPT);
    CHECK(ack.timestamp == resp.timestamp);
    CHECK(memcmp(ack.cookie, resp.cookie, HS_COOKIE_BYTES) == 0);
}

static void test_handshake_rejections(void)
{
    HsServer s;
    HsPacket in, chal, resp, out;
    const char *addr = "10.0.2.15:49152";

    hs_server_init(&s, SEED, sizeof SEED - 1);

    /* A non-handshake packet is never ours. */
    memset(&in, 0, sizeof in);
    CHECK(hs_server_step(&s, &in, addr, 100.0f, &out) == HS_IGNORE);

    /* Build a legitimate challenge to tamper with. */
    memset(&in, 0, sizeof in);
    in.b_handshake_packet = 1;
    CHECK(hs_server_step(&s, &in, addr, 100.0f, &chal) == HS_SEND_CHALLENGE);

    /* Forged cookie. */
    resp = chal;
    resp.cookie[0] ^= 0xff;
    CHECK(hs_server_step(&s, &resp, addr, 100.5f, &out) == HS_IGNORE);

    /* Right cookie, wrong source address - cookies are address-bound, so a
     * cookie cannot be replayed from elsewhere. */
    resp = chal;
    CHECK(hs_server_step(&s, &resp, "10.9.9.9:49152", 100.5f, &out) == HS_IGNORE);

    /* Expired cookie. */
    resp = chal;
    CHECK(hs_server_step(&s, &resp, addr, 100.0f + HS_MAX_COOKIE_AGE + 1.0f, &out)
          == HS_IGNORE);

    /* Future-dated timestamp. */
    resp = chal;
    resp.timestamp = 500.0f;
    CHECK(hs_server_step(&s, &resp, addr, 100.5f, &out) == HS_IGNORE);

    /* Wrong secret id selects the other secret, so verification must fail. */
    resp = chal;
    resp.secret_id ^= 1;
    CHECK(hs_server_step(&s, &resp, addr, 100.5f, &out) == HS_IGNORE);

    /* Still valid at the very edge of the window. */
    resp = chal;
    CHECK(hs_server_step(&s, &resp, addr, 100.0f + HS_MAX_COOKIE_AGE, &out)
          == HS_ACCEPT);
}

static void test_restart_handshake(void)
{
    HsServer s;
    HsPacket in, out;
    hs_server_init(&s, SEED, sizeof SEED - 1);

    /* A restart request must be answered with a fresh challenge even though it
     * carries a non-zero cookie. */
    memset(&in, 0, sizeof in);
    in.b_handshake_packet = 1;
    in.b_restart_handshake = 1;
    in.timestamp = 50.0f;
    fill_cookie(in.cookie, 0x55);
    CHECK(hs_server_step(&s, &in, "10.0.2.15:1", 200.0f, &out) == HS_SEND_CHALLENGE);
    CHECK(out.timestamp == 200.0f);
}

static void test_secret_rotation(void)
{
    HsServer s;
    uint8_t before[HS_SECRET_BYTES];
    hs_server_init(&s, SEED, sizeof SEED - 1);

    int active = s.active_secret;
    memcpy(before, s.secret[active], sizeof before);

    hs_rotate_secret(&s, "rotation-seed", 13);
    CHECK(s.active_secret != active);
    /* The previously active secret must survive, so cookies already issued
     * under it still verify during the overlap window. */
    CHECK(memcmp(s.secret[active], before, sizeof before) == 0);
}

static void test_ct_equal(void)
{
    uint8_t a[8] = { 1, 2, 3, 4, 5, 6, 7, 8 };
    uint8_t b[8] = { 1, 2, 3, 4, 5, 6, 7, 8 };
    CHECK(hs_ct_equal(a, b, 8));
    b[7] = 9;
    CHECK(!hs_ct_equal(a, b, 8));
    b[7] = 8;
    b[0] = 9;
    CHECK(!hs_ct_equal(a, b, 8));
    CHECK(hs_ct_equal(a, b, 0));
}

int main(void)
{
    test_packet_is_195_bits();
    test_codec_roundtrip();
    test_decode_rejects_short();
    test_cookie_properties();
    test_full_handshake();
    test_handshake_rejections();
    test_restart_handshake();
    test_secret_rotation();
    test_ct_equal();

    if (failures) {
        printf("%d check(s) failed\n", failures);
        return 1;
    }
    printf("all handshake tests passed\n");
    return 0;
}
