/* packet.h - UE4 bunch framing and partial-bunch reassembly.
 *
 * CONFIDENCE WARNING
 * ------------------
 * The bunch header field order and the constants below are [STOCK]: they are my
 * reconstruction of open-source UE4 4.18 and have NOT been verified against
 * libUE4.so or a real capture. See docs/01-protocol.md section 5.
 *
 * The layout lives in exactly one place - ue_bunch_read_header() and
 * ue_bunch_write_header() in packet.c - so that correcting it once a capture is
 * available is a single localised change. Do not duplicate the field order
 * anywhere else.
 */
#ifndef PUBGM_PACKET_H
#define PUBGM_PACKET_H

#include "bitstream.h"

/* [STOCK] constants - all unverified for this build. */
#define UE_MAX_CHANNELS      32767u
#define UE_MAX_PACKETID      16384u
#define UE_MAX_CHSEQUENCE    1024u
#define UE_CHTYPE_MAX        8u
#define UE_MAX_PACKET_BYTES  1024u
#define UE_MAX_PACKET_BITS   (UE_MAX_PACKET_BYTES * 8u)

/* Cap on a reassembled partial bunch. Guards against a peer claiming an
 * unbounded payload; the real UE4 limit for this build is unverified. */
#define UE_MAX_REASSEMBLY_BITS (64u * 1024u * 8u)

typedef enum {
    UE_CHTYPE_NONE    = 0,
    UE_CHTYPE_CONTROL = 1,
    UE_CHTYPE_ACTOR   = 2,
    UE_CHTYPE_FILE    = 3,
    UE_CHTYPE_VOICE   = 4
} UeChannelType;

typedef struct {
    int      b_open;
    int      b_close;
    int      b_dormant;                 /* only present when b_close */
    int      b_is_replication_paused;
    int      b_reliable;
    uint32_t ch_index;
    int      b_has_package_map_exports;
    int      b_has_must_be_mapped_guids;
    int      b_partial;
    int      b_partial_initial;         /* only present when b_partial */
    int      b_partial_final;           /* only present when b_partial */
    uint32_t ch_sequence;               /* raw wire value when b_reliable */
    uint32_t ch_type;                   /* only present when b_reliable || b_open */
    uint32_t data_bits;                 /* payload length in bits */
} UeBunchHeader;

/* Header codec. Payload is NOT consumed: on success the reader sits at the
 * first payload bit. Sequence numbers are serialised raw; relative decoding
 * (UE4's MakeRelative) is a connection-layer concern, see docs/03-plan.md
 * phase 3.
 *
 * Returns 0 on success, -1 on a malformed or truncated header. A header that
 * declares more payload bits than remain in the reader is rejected. */
int ue_bunch_read_header(BitReader *r, UeBunchHeader *h);
int ue_bunch_write_header(BitWriter *w, const UeBunchHeader *h);

/* Partial-bunch reassembly for a single channel. */
typedef struct {
    uint8_t  buf[UE_MAX_REASSEMBLY_BITS / 8];
    BitWriter w;
    int      active;
    uint32_t ch_index;
    int      started;
} UeReassembler;

typedef enum {
    UE_REASM_INCOMPLETE = 0,  /* accepted, waiting for more */
    UE_REASM_COMPLETE   = 1,  /* final fragment accepted; payload is ready */
    UE_REASM_ERROR      = -1  /* protocol violation; caller should drop the connection */
} UeReasmResult;

void ue_reasm_init(UeReassembler *s);
void ue_reasm_reset(UeReassembler *s);

/* Feed one partial bunch. `r` must sit at the payload start and the header must
 * have b_partial set. Consumes h->data_bits from `r`. */
UeReasmResult ue_reasm_feed(UeReassembler *s, const UeBunchHeader *h, BitReader *r);

/* Valid after UE_REASM_COMPLETE. */
const uint8_t *ue_reasm_data(const UeReassembler *s);
size_t         ue_reasm_bits(const UeReassembler *s);

/* Copy `bits` bits from a reader into a writer. */
void ue_copy_bits(BitWriter *w, BitReader *r, size_t bits);

#endif
