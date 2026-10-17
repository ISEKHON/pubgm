/* bitstream.h - LSB-first bit reader/writer, matching UE4's FBitWriter/FBitReader.
 *
 * Bit order: within each byte, bit 0 (least significant) is filled first.
 * Multi-bit values are written least-significant bit first.
 * See docs/01-protocol.md section 2.
 */
#ifndef PUBGM_BITSTREAM_H
#define PUBGM_BITSTREAM_H

#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint8_t *buf;
    size_t   cap_bits;
    size_t   num_bits;
    int      overflowed;
} BitWriter;

typedef struct {
    const uint8_t *buf;
    size_t         num_bits;
    size_t         pos;
    int            error;
} BitReader;

/* Writer. buf must hold at least (cap_bits + 7) / 8 bytes; it is zeroed. */
void   bw_init(BitWriter *w, uint8_t *buf, size_t cap_bits);
void   bw_write_bit(BitWriter *w, int bit);
void   bw_write_bits(BitWriter *w, uint64_t value, unsigned count); /* count <= 64 */
void   bw_write_bytes(BitWriter *w, const void *data, size_t len);
/* UE4 SerializeInt: writes value in ceil(log2(max)) bits, value < max. */
void   bw_serialize_int(BitWriter *w, uint32_t value, uint32_t max);
/* UE4 SerializeIntPacked: 7 bits per byte, low bit of each byte is "more" flag. */
void   bw_serialize_int_packed(BitWriter *w, uint32_t value);
/* Append the termination bit so the receiver can recover the exact bit length. */
void   bw_finish(BitWriter *w);
size_t bw_num_bytes(const BitWriter *w);

/* Reader. */
void     br_init(BitReader *r, const uint8_t *buf, size_t num_bits);
/* Initialise from a received packet: strips the termination bit. Returns 0 on success,
 * -1 if the packet is empty or its last byte is zero (no termination bit). */
int      br_init_from_packet(BitReader *r, const uint8_t *buf, size_t len_bytes);
int      br_read_bit(BitReader *r);
uint64_t br_read_bits(BitReader *r, unsigned count);
int      br_read_bytes(BitReader *r, void *out, size_t len);
uint32_t br_serialize_int(BitReader *r, uint32_t max);
uint32_t br_serialize_int_packed(BitReader *r);
size_t   br_bits_left(const BitReader *r);

#endif
