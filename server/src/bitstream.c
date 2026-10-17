#include "bitstream.h"

#include <string.h>

void bw_init(BitWriter *w, uint8_t *buf, size_t cap_bits)
{
    w->buf = buf;
    w->cap_bits = cap_bits;
    w->num_bits = 0;
    w->overflowed = 0;
    memset(buf, 0, (cap_bits + 7) / 8);
}

void bw_write_bit(BitWriter *w, int bit)
{
    if (w->num_bits + 1 > w->cap_bits) {
        w->overflowed = 1;
        return;
    }
    if (bit)
        w->buf[w->num_bits >> 3] |= (uint8_t)(1u << (w->num_bits & 7));
    w->num_bits++;
}

void bw_write_bits(BitWriter *w, uint64_t value, unsigned count)
{
    for (unsigned i = 0; i < count; i++)
        bw_write_bit(w, (int)((value >> i) & 1u));
}

void bw_write_bytes(BitWriter *w, const void *data, size_t len)
{
    const uint8_t *p = data;
    for (size_t i = 0; i < len; i++)
        bw_write_bits(w, p[i], 8);
}

void bw_serialize_int(BitWriter *w, uint32_t value, uint32_t max)
{
    /* UE4 writes bits while (1 << i) < max, LSB first. */
    if (max < 2 || value >= max) {
        w->overflowed = (max >= 2 && value >= max) ? 1 : w->overflowed;
        if (max < 2)
            return;
        value = max - 1;
    }
    for (uint64_t mask = 1; mask < max; mask <<= 1)
        bw_write_bit(w, (value & mask) != 0);
}

void bw_serialize_int_packed(BitWriter *w, uint32_t value)
{
    do {
        uint32_t next = value >> 7;
        bw_write_bits(w, ((value & 0x7f) << 1) | (next ? 1u : 0u), 8);
        value = next;
    } while (value);
}

void bw_finish(BitWriter *w)
{
    bw_write_bit(w, 1);
}

size_t bw_num_bytes(const BitWriter *w)
{
    return (w->num_bits + 7) >> 3;
}

void br_init(BitReader *r, const uint8_t *buf, size_t num_bits)
{
    r->buf = buf;
    r->num_bits = num_bits;
    r->pos = 0;
    r->error = 0;
}

int br_init_from_packet(BitReader *r, const uint8_t *buf, size_t len_bytes)
{
    if (len_bytes == 0 || buf[len_bytes - 1] == 0) {
        br_init(r, buf, 0);
        r->error = 1;
        return -1;
    }
    uint8_t last = buf[len_bytes - 1];
    unsigned top = 7;
    while (!((last >> top) & 1u))
        top--;
    /* The highest set bit of the last byte is the termination bit. */
    br_init(r, buf, (len_bytes - 1) * 8 + top);
    return 0;
}

int br_read_bit(BitReader *r)
{
    if (r->pos + 1 > r->num_bits) {
        r->error = 1;
        return 0;
    }
    int bit = (r->buf[r->pos >> 3] >> (r->pos & 7)) & 1;
    r->pos++;
    return bit;
}

uint64_t br_read_bits(BitReader *r, unsigned count)
{
    uint64_t v = 0;
    for (unsigned i = 0; i < count; i++)
        v |= (uint64_t)br_read_bit(r) << i;
    return v;
}

int br_read_bytes(BitReader *r, void *out, size_t len)
{
    uint8_t *p = out;
    for (size_t i = 0; i < len; i++)
        p[i] = (uint8_t)br_read_bits(r, 8);
    return r->error ? -1 : 0;
}

uint32_t br_serialize_int(BitReader *r, uint32_t max)
{
    uint32_t value = 0;
    for (uint64_t mask = 1; mask < max; mask <<= 1) {
        if (br_read_bit(r))
            value |= (uint32_t)mask;
    }
    return value;
}

uint32_t br_serialize_int_packed(BitReader *r)
{
    uint32_t value = 0;
    for (unsigned shift = 0; shift < 35; shift += 7) {
        uint32_t b = (uint32_t)br_read_bits(r, 8);
        value |= (b >> 1) << shift;
        if (!(b & 1))
            break;
    }
    return value;
}

size_t br_bits_left(const BitReader *r)
{
    return r->num_bits - r->pos;
}
