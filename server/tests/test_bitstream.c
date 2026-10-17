#include "bitstream.h"

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

/* Hand-computed vectors: bit order is LSB-first within each byte. */
static void test_bit_order(void)
{
    uint8_t buf[8];
    BitWriter w;

    bw_init(&w, buf, 64);
    bw_write_bit(&w, 1);
    bw_write_bit(&w, 0);
    bw_write_bit(&w, 1);
    CHECK(buf[0] == 0x05);           /* bits 0 and 2 set */
    CHECK(w.num_bits == 3);

    bw_init(&w, buf, 64);
    bw_write_bits(&w, 0x3, 2);       /* 11 */
    bw_write_bits(&w, 0x1, 3);       /* 001 -> bit 2 */
    CHECK(buf[0] == 0x07);           /* bits 0,1,2 */

    bw_init(&w, buf, 64);
    bw_write_bits(&w, 0xAB, 8);
    CHECK(buf[0] == 0xAB);
    bw_write_bits(&w, 0x1FF, 9);     /* crosses byte boundary */
    CHECK(buf[1] == 0xFF && buf[2] == 0x01);
}

static void test_termination_bit(void)
{
    uint8_t buf[8];
    BitWriter w;
    BitReader r;

    bw_init(&w, buf, 64);
    bw_write_bits(&w, 0x5, 3);       /* 101 */
    bw_finish(&w);                   /* 1 at bit 3 */
    CHECK(buf[0] == 0x0D);
    CHECK(bw_num_bytes(&w) == 1);

    CHECK(br_init_from_packet(&r, buf, 1) == 0);
    CHECK(r.num_bits == 3);
    CHECK(br_read_bits(&r, 3) == 0x5);
    CHECK(br_bits_left(&r) == 0);

    /* Byte-aligned payload: termination bit lands at bit 0 of a new byte. */
    bw_init(&w, buf, 64);
    bw_write_bits(&w, 0xAB, 8);
    bw_finish(&w);
    CHECK(bw_num_bytes(&w) == 2 && buf[1] == 0x01);
    CHECK(br_init_from_packet(&r, buf, 2) == 0 && r.num_bits == 8);

    /* Invalid packets. */
    uint8_t zero[2] = {0xFF, 0x00};
    CHECK(br_init_from_packet(&r, zero, 2) == -1);
    CHECK(br_init_from_packet(&r, zero, 0) == -1);
}

static void test_serialize_int(void)
{
    uint8_t buf[8];
    BitWriter w;
    BitReader r;

    /* max=10 needs 4 bits (1,2,4,8 < 10). */
    bw_init(&w, buf, 64);
    bw_serialize_int(&w, 9, 10);
    CHECK(w.num_bits == 4);
    CHECK(buf[0] == 0x09);

    /* max=8 needs exactly 3 bits. */
    bw_init(&w, buf, 64);
    bw_serialize_int(&w, 7, 8);
    CHECK(w.num_bits == 3);

    for (uint32_t max = 2; max < 300; max++) {
        for (uint32_t v = 0; v < max; v++) {
            bw_init(&w, buf, 64);
            bw_serialize_int(&w, v, max);
            br_init(&r, buf, w.num_bits);
            if (br_serialize_int(&r, max) != v || r.error) {
                printf("FAIL serialize_int v=%u max=%u\n", v, max);
                failures++;
                return;
            }
        }
    }
}

static void test_packed(void)
{
    uint8_t buf[16];
    BitWriter w;
    BitReader r;

    /* 5 -> single byte (5<<1)|0 = 0x0A */
    bw_init(&w, buf, 128);
    bw_serialize_int_packed(&w, 5);
    CHECK(w.num_bits == 8 && buf[0] == 0x0A);

    /* 200 = 0x48 + 1*128 -> bytes: ((200&0x7f)<<1)|1 = 0x91, then (1<<1)|0 = 0x02 */
    bw_init(&w, buf, 128);
    bw_serialize_int_packed(&w, 200);
    CHECK(w.num_bits == 16 && buf[0] == 0x91 && buf[1] == 0x02);

    uint32_t vals[] = {0, 1, 127, 128, 255, 16383, 16384, 0xFFFFFFFFu};
    for (size_t i = 0; i < sizeof vals / sizeof vals[0]; i++) {
        bw_init(&w, buf, 128);
        bw_serialize_int_packed(&w, vals[i]);
        br_init(&r, buf, w.num_bits);
        CHECK(br_serialize_int_packed(&r) == vals[i]);
        CHECK(br_bits_left(&r) == 0);
    }
}

static void test_overflow_and_underflow(void)
{
    uint8_t buf[1];
    BitWriter w;
    BitReader r;

    bw_init(&w, buf, 8);
    bw_write_bits(&w, 0xFF, 8);
    CHECK(!w.overflowed);
    bw_write_bit(&w, 1);
    CHECK(w.overflowed && w.num_bits == 8);

    br_init(&r, buf, 8);
    br_read_bits(&r, 8);
    CHECK(!r.error);
    br_read_bit(&r);
    CHECK(r.error);
}

static void test_bytes_unaligned(void)
{
    uint8_t buf[16];
    uint8_t out[3];
    const uint8_t in[3] = {0xDE, 0xAD, 0xBE};
    BitWriter w;
    BitReader r;

    bw_init(&w, buf, 128);
    bw_write_bits(&w, 0x5, 3);       /* misalign by 3 bits */
    bw_write_bytes(&w, in, 3);
    br_init(&r, buf, w.num_bits);
    CHECK(br_read_bits(&r, 3) == 0x5);
    CHECK(br_read_bytes(&r, out, 3) == 0);
    CHECK(memcmp(in, out, 3) == 0);
}

int main(void)
{
    test_bit_order();
    test_termination_bit();
    test_serialize_int();
    test_packed();
    test_overflow_and_underflow();
    test_bytes_unaligned();

    if (failures) {
        printf("%d check(s) failed\n", failures);
        return 1;
    }
    printf("all bitstream tests passed\n");
    return 0;
}
