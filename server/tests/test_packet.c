/* Tests for bunch framing and reassembly.
 *
 * Deliberately NOT asserted here: specific byte vectors for the bunch header.
 * The field order is [STOCK]/unverified (see packet.h), so a byte vector would
 * only enshrine the current guess as truth. These tests instead check
 * properties that hold regardless of the absolute layout:
 *   - the reader and writer agree (round-trip over the full flag matrix)
 *   - conditional fields are genuinely conditional (exact bit-count deltas)
 *   - the reassembler state machine, including every rejection path
 * Once a real capture is available, add byte-vector tests against it and
 * correct the layout in packet.c.
 */
#include "packet.h"

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

/* SerializeInt(max) width: number of masks with mask < max. */
static unsigned int_bits(uint32_t max)
{
    unsigned n = 0;
    for (uint64_t mask = 1; mask < max; mask <<= 1)
        n++;
    return n;
}

static void test_roundtrip_flag_matrix(void)
{
    uint8_t buf[64];

    for (unsigned m = 0; m < 1024; m++) {
        UeBunchHeader h;
        memset(&h, 0, sizeof h);
        h.b_open                      = (m >> 0) & 1;
        h.b_close                     = (m >> 1) & 1;
        h.b_dormant                   = (m >> 2) & 1;
        h.b_is_replication_paused     = (m >> 3) & 1;
        h.b_reliable                  = (m >> 4) & 1;
        h.b_has_package_map_exports   = (m >> 5) & 1;
        h.b_has_must_be_mapped_guids  = (m >> 6) & 1;
        h.b_partial                   = (m >> 7) & 1;
        h.b_partial_initial           = (m >> 8) & 1;
        h.b_partial_final             = (m >> 9) & 1;
        h.ch_index    = 1234;
        h.ch_sequence = 777;
        h.ch_type     = UE_CHTYPE_ACTOR;
        h.data_bits   = 0;

        BitWriter w;
        bw_init(&w, buf, sizeof buf * 8);
        if (ue_bunch_write_header(&w, &h) != 0) {
            printf("FAIL write m=%u\n", m);
            failures++;
            return;
        }

        BitReader r;
        br_init(&r, buf, w.num_bits);
        UeBunchHeader g;
        if (ue_bunch_read_header(&r, &g) != 0) {
            printf("FAIL read m=%u\n", m);
            failures++;
            return;
        }

        /* Fields absent from the wire must come back zeroed. */
        int ok = g.b_open == h.b_open
              && g.b_close == h.b_close
              && g.b_dormant == (h.b_close ? h.b_dormant : 0)
              && g.b_is_replication_paused == h.b_is_replication_paused
              && g.b_reliable == h.b_reliable
              && g.ch_index == h.ch_index
              && g.b_has_package_map_exports == h.b_has_package_map_exports
              && g.b_has_must_be_mapped_guids == h.b_has_must_be_mapped_guids
              && g.b_partial == h.b_partial
              && g.b_partial_initial == (h.b_partial ? h.b_partial_initial : 0)
              && g.b_partial_final == (h.b_partial ? h.b_partial_final : 0)
              && g.ch_sequence == (h.b_reliable ? h.ch_sequence : 0u)
              && g.ch_type == ((h.b_reliable || h.b_open) ? h.ch_type : 0u)
              && g.data_bits == h.data_bits;
        if (!ok) {
            printf("FAIL roundtrip mismatch m=%u\n", m);
            failures++;
            return;
        }
        /* The header must consume the whole buffer it wrote. */
        if (br_bits_left(&r) != 0) {
            printf("FAIL trailing bits m=%u left=%zu\n", m, br_bits_left(&r));
            failures++;
            return;
        }
    }
}

/* Verifies the conditional fields are actually conditional, without asserting
 * the absolute layout: each flag must change the encoded width by exactly the
 * width of the field it gates. */
static void test_conditional_field_widths(void)
{
    uint8_t buf[64];
    UeBunchHeader base;
    memset(&base, 0, sizeof base);
    base.ch_index = 7;

    const unsigned expect_base = 1 /*open*/ + 1 /*close*/ + 1 /*paused*/ + 1 /*reliable*/
                               + int_bits(UE_MAX_CHANNELS)
                               + 3 /*exports, mapped guids, partial*/
                               + int_bits(UE_MAX_PACKET_BITS);

    BitWriter w;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &base) == 0);
    CHECK(w.num_bits == expect_base);
    const size_t n_base = w.num_bits;

    /* b_close gates one dormant bit. */
    UeBunchHeader h = base;
    h.b_close = 1;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    CHECK(w.num_bits == n_base + 1);

    /* b_partial gates two bits. */
    h = base;
    h.b_partial = 1;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    CHECK(w.num_bits == n_base + 2);

    /* b_open gates the channel type. */
    h = base;
    h.b_open = 1;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    CHECK(w.num_bits == n_base + int_bits(UE_CHTYPE_MAX));

    /* b_reliable gates both the sequence and the channel type. */
    h = base;
    h.b_reliable = 1;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    CHECK(w.num_bits == n_base + int_bits(UE_MAX_CHSEQUENCE) + int_bits(UE_CHTYPE_MAX));

    /* open + reliable must not write the channel type twice. */
    h = base;
    h.b_open = 1;
    h.b_reliable = 1;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    CHECK(w.num_bits == n_base + int_bits(UE_MAX_CHSEQUENCE) + int_bits(UE_CHTYPE_MAX));
}

static void test_payload_and_validation(void)
{
    uint8_t buf[256];
    UeBunchHeader h;
    BitWriter w;
    BitReader r;
    UeBunchHeader g;

    /* Header followed by a real payload: reader lands on the payload. */
    memset(&h, 0, sizeof h);
    h.ch_index = 3;
    h.data_bits = 37;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    for (unsigned i = 0; i < 37; i++)
        bw_write_bit(&w, (int)(i % 3 == 0));
    br_init(&r, buf, w.num_bits);
    CHECK(ue_bunch_read_header(&r, &g) == 0);
    CHECK(g.data_bits == 37);
    CHECK(br_bits_left(&r) == 37);
    for (unsigned i = 0; i < 37; i++)
        CHECK(br_read_bit(&r) == (int)(i % 3 == 0));

    /* A header claiming more payload than the packet holds is rejected. */
    memset(&h, 0, sizeof h);
    h.ch_index = 3;
    h.data_bits = 500;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    br_init(&r, buf, w.num_bits);              /* no payload written */
    CHECK(ue_bunch_read_header(&r, &g) == -1);

    /* Truncated header. */
    memset(&h, 0, sizeof h);
    h.ch_index = 3;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == 0);
    br_init(&r, buf, w.num_bits - 5);
    CHECK(ue_bunch_read_header(&r, &g) == -1);

    /* Out-of-range values are refused by the writer. */
    memset(&h, 0, sizeof h);
    h.ch_index = UE_MAX_CHANNELS;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == -1);

    memset(&h, 0, sizeof h);
    h.data_bits = UE_MAX_PACKET_BITS;
    bw_init(&w, buf, sizeof buf * 8);
    CHECK(ue_bunch_write_header(&w, &h) == -1);
}

/* Reassembly ------------------------------------------------------------- */

static UeReassembler g_reasm;   /* static: the struct embeds a 64 KB buffer */

static void frag(UeBunchHeader *h, uint32_t ch, int initial, int final_, uint32_t bits)
{
    memset(h, 0, sizeof *h);
    h->ch_index = ch;
    h->b_partial = 1;
    h->b_partial_initial = initial;
    h->b_partial_final = final_;
    h->data_bits = bits;
}

/* Build a reader over `bits` bits whose value at index i is pattern(i+base). */
static void make_payload(uint8_t *buf, BitWriter *w, BitReader *r,
                         unsigned base, unsigned bits)
{
    bw_init(w, buf, 4096);
    for (unsigned i = 0; i < bits; i++)
        bw_write_bit(w, (int)((base + i) % 5 == 0));
    br_init(r, buf, w->num_bits);
}

static void test_reasm_happy_path(void)
{
    uint8_t pbuf[512];
    BitWriter w;
    BitReader r;
    UeBunchHeader h;

    ue_reasm_init(&g_reasm);

    frag(&h, 5, 1, 0, 20);
    make_payload(pbuf, &w, &r, 0, 20);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_INCOMPLETE);

    frag(&h, 5, 0, 0, 20);
    make_payload(pbuf, &w, &r, 20, 20);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_INCOMPLETE);

    frag(&h, 5, 0, 1, 11);
    make_payload(pbuf, &w, &r, 40, 11);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_COMPLETE);

    CHECK(ue_reasm_bits(&g_reasm) == 51);

    /* The concatenation must be bit-exact and in order. */
    BitReader out;
    br_init(&out, ue_reasm_data(&g_reasm), ue_reasm_bits(&g_reasm));
    for (unsigned i = 0; i < 51; i++)
        CHECK(br_read_bit(&out) == (int)(i % 5 == 0));

    /* Single fragment that is both initial and final. */
    ue_reasm_init(&g_reasm);
    frag(&h, 2, 1, 1, 8);
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_COMPLETE);
    CHECK(ue_reasm_bits(&g_reasm) == 8);

    /* Empty final fragment is legal. */
    ue_reasm_init(&g_reasm);
    frag(&h, 2, 1, 0, 8);
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_INCOMPLETE);
    frag(&h, 2, 0, 1, 0);
    make_payload(pbuf, &w, &r, 0, 0);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_COMPLETE);
    CHECK(ue_reasm_bits(&g_reasm) == 8);
}

static void test_reasm_rejections(void)
{
    uint8_t pbuf[512];
    BitWriter w;
    BitReader r;
    UeBunchHeader h;

    /* Continuation with no initial fragment. */
    ue_reasm_init(&g_reasm);
    frag(&h, 5, 0, 0, 8);
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_ERROR);

    /* Interleaved channel mid-sequence. */
    ue_reasm_init(&g_reasm);
    frag(&h, 5, 1, 0, 8);
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_INCOMPLETE);
    frag(&h, 6, 0, 0, 8);
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_ERROR);

    /* A non-partial bunch must never reach the reassembler. */
    ue_reasm_init(&g_reasm);
    memset(&h, 0, sizeof h);
    h.ch_index = 5;
    h.data_bits = 8;
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_ERROR);

    /* data_bits beyond what the reader holds. */
    ue_reasm_init(&g_reasm);
    frag(&h, 5, 1, 0, 200);
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_ERROR);

    /* A restarted sequence discards the partial one. */
    ue_reasm_init(&g_reasm);
    frag(&h, 5, 1, 0, 16);
    make_payload(pbuf, &w, &r, 0, 16);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_INCOMPLETE);
    frag(&h, 5, 1, 1, 8);
    make_payload(pbuf, &w, &r, 0, 8);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_COMPLETE);
    CHECK(ue_reasm_bits(&g_reasm) == 8);      /* not 24 */
}

static void test_reasm_oversize(void)
{
    static uint8_t pbuf[8192];
    BitWriter w;
    BitReader r;
    UeBunchHeader h;

    ue_reasm_init(&g_reasm);
    frag(&h, 1, 1, 0, 4096);
    make_payload(pbuf, &w, &r, 0, 4096);
    CHECK(ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_INCOMPLETE);

    /* Keep appending until the cap rejects a fragment. */
    int rejected = 0;
    for (int i = 0; i < 200; i++) {
        frag(&h, 1, 0, 0, 4096);
        make_payload(pbuf, &w, &r, 0, 4096);
        if (ue_reasm_feed(&g_reasm, &h, &r) == UE_REASM_ERROR) {
            rejected = 1;
            break;
        }
    }
    CHECK(rejected);
    CHECK(ue_reasm_bits(&g_reasm) <= UE_MAX_REASSEMBLY_BITS);
}

static void test_copy_bits_unaligned(void)
{
    uint8_t src[256], dst[256];
    BitWriter sw, dw;
    BitReader sr;

    /* Cross the 32-bit chunk boundary from a misaligned start. */
    bw_init(&sw, src, sizeof src * 8);
    bw_write_bits(&sw, 0x5, 3);
    for (unsigned i = 0; i < 100; i++)
        bw_write_bit(&sw, (int)(i % 7 == 0));
    br_init(&sr, src, sw.num_bits);
    CHECK(br_read_bits(&sr, 3) == 0x5);

    bw_init(&dw, dst, sizeof dst * 8);
    bw_write_bit(&dw, 1);                      /* misalign the destination too */
    ue_copy_bits(&dw, &sr, 100);
    CHECK(!dw.overflowed && !sr.error);
    CHECK(dw.num_bits == 101);

    BitReader dr;
    br_init(&dr, dst, dw.num_bits);
    CHECK(br_read_bit(&dr) == 1);
    for (unsigned i = 0; i < 100; i++)
        CHECK(br_read_bit(&dr) == (int)(i % 7 == 0));
}

int main(void)
{
    test_roundtrip_flag_matrix();
    test_conditional_field_widths();
    test_payload_and_validation();
    test_reasm_happy_path();
    test_reasm_rejections();
    test_reasm_oversize();
    test_copy_bits_unaligned();

    if (failures) {
        printf("%d check(s) failed\n", failures);
        return 1;
    }
    printf("all packet tests passed\n");
    return 0;
}
