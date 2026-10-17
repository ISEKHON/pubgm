#include "packet.h"

#include <string.h>

void ue_copy_bits(BitWriter *w, BitReader *r, size_t bits)
{
    while (bits >= 32) {
        bw_write_bits(w, br_read_bits(r, 32), 32);
        bits -= 32;
    }
    if (bits)
        bw_write_bits(w, br_read_bits(r, (unsigned)bits), (unsigned)bits);
}

/* ---------------------------------------------------------------------------
 * Bunch header codec.
 *
 * THE FIELD ORDER BELOW IS THE SINGLE SOURCE OF TRUTH for the wire layout and
 * is [STOCK]/unverified - see the warning in packet.h. ue_bunch_write_header()
 * mirrors ue_bunch_read_header() field for field; change both together.
 * ------------------------------------------------------------------------- */

int ue_bunch_read_header(BitReader *r, UeBunchHeader *h)
{
    memset(h, 0, sizeof *h);

    h->b_open  = br_read_bit(r);
    h->b_close = br_read_bit(r);
    if (h->b_close)
        h->b_dormant = br_read_bit(r);
    h->b_is_replication_paused = br_read_bit(r);
    h->b_reliable = br_read_bit(r);

    h->ch_index = br_serialize_int(r, UE_MAX_CHANNELS);

    h->b_has_package_map_exports   = br_read_bit(r);
    h->b_has_must_be_mapped_guids  = br_read_bit(r);
    h->b_partial                   = br_read_bit(r);

    if (h->b_reliable)
        h->ch_sequence = br_serialize_int(r, UE_MAX_CHSEQUENCE);

    if (h->b_partial) {
        h->b_partial_initial = br_read_bit(r);
        h->b_partial_final   = br_read_bit(r);
    }

    if (h->b_reliable || h->b_open)
        h->ch_type = br_serialize_int(r, UE_CHTYPE_MAX);

    h->data_bits = br_serialize_int(r, UE_MAX_PACKET_BITS);

    if (r->error)
        return -1;
    if (h->ch_index >= UE_MAX_CHANNELS)
        return -1;
    /* Reject a header claiming more payload than the packet actually carries. */
    if (h->data_bits > br_bits_left(r))
        return -1;
    return 0;
}

int ue_bunch_write_header(BitWriter *w, const UeBunchHeader *h)
{
    if (h->ch_index >= UE_MAX_CHANNELS)
        return -1;
    if (h->data_bits >= UE_MAX_PACKET_BITS)
        return -1;

    bw_write_bit(w, h->b_open);
    bw_write_bit(w, h->b_close);
    if (h->b_close)
        bw_write_bit(w, h->b_dormant);
    bw_write_bit(w, h->b_is_replication_paused);
    bw_write_bit(w, h->b_reliable);

    bw_serialize_int(w, h->ch_index, UE_MAX_CHANNELS);

    bw_write_bit(w, h->b_has_package_map_exports);
    bw_write_bit(w, h->b_has_must_be_mapped_guids);
    bw_write_bit(w, h->b_partial);

    if (h->b_reliable)
        bw_serialize_int(w, h->ch_sequence, UE_MAX_CHSEQUENCE);

    if (h->b_partial) {
        bw_write_bit(w, h->b_partial_initial);
        bw_write_bit(w, h->b_partial_final);
    }

    if (h->b_reliable || h->b_open)
        bw_serialize_int(w, h->ch_type, UE_CHTYPE_MAX);

    bw_serialize_int(w, h->data_bits, UE_MAX_PACKET_BITS);

    return w->overflowed ? -1 : 0;
}

/* ------------------------------------------------------------------------- */

void ue_reasm_init(UeReassembler *s)
{
    s->active = 0;
    s->started = 0;
    s->ch_index = 0;
    bw_init(&s->w, s->buf, UE_MAX_REASSEMBLY_BITS);
}

void ue_reasm_reset(UeReassembler *s)
{
    ue_reasm_init(s);
}

UeReasmResult ue_reasm_feed(UeReassembler *s, const UeBunchHeader *h, BitReader *r)
{
    if (!h->b_partial)
        return UE_REASM_ERROR;
    if (h->data_bits > br_bits_left(r))
        return UE_REASM_ERROR;

    if (h->b_partial_initial) {
        /* A new sequence discards any half-built one; UE4 treats a restarted
         * partial as superseding. */
        ue_reasm_reset(s);
        s->started = 1;
        s->active = 1;
        s->ch_index = h->ch_index;
    } else {
        if (!s->started)
            return UE_REASM_ERROR;          /* continuation with no initial */
        if (h->ch_index != s->ch_index)
            return UE_REASM_ERROR;          /* interleaved channel */
    }

    if (s->w.num_bits + h->data_bits > UE_MAX_REASSEMBLY_BITS)
        return UE_REASM_ERROR;              /* oversized payload */

    ue_copy_bits(&s->w, r, h->data_bits);
    if (r->error || s->w.overflowed)
        return UE_REASM_ERROR;

    if (h->b_partial_final) {
        s->active = 0;
        return UE_REASM_COMPLETE;
    }
    return UE_REASM_INCOMPLETE;
}

const uint8_t *ue_reasm_data(const UeReassembler *s)
{
    return s->buf;
}

size_t ue_reasm_bits(const UeReassembler *s)
{
    return s->w.num_bits;
}
