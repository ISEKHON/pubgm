/* sha1.h - SHA-1 and HMAC-SHA1.
 *
 * Used only to build and verify the handshake cookie. The cookie is generated
 * AND verified by this server; the client merely echoes it back, so this
 * construction does not have to match Tencent's. It only has to be consistent
 * and 20 bytes (see docs/01-protocol.md section 3.1).
 */
#ifndef PUBGM_SHA1_H
#define PUBGM_SHA1_H

#include <stddef.h>
#include <stdint.h>

#define SHA1_DIGEST_BYTES 20
#define SHA1_BLOCK_BYTES  64

typedef struct {
    uint32_t h[5];
    uint64_t bitlen;
    uint8_t  buf[SHA1_BLOCK_BYTES];
    size_t   buflen;
} Sha1Ctx;

void sha1_init(Sha1Ctx *c);
void sha1_update(Sha1Ctx *c, const void *data, size_t len);
void sha1_final(Sha1Ctx *c, uint8_t out[SHA1_DIGEST_BYTES]);
void sha1(const void *data, size_t len, uint8_t out[SHA1_DIGEST_BYTES]);

void hmac_sha1(const void *key, size_t keylen,
               const void *msg, size_t msglen,
               uint8_t out[SHA1_DIGEST_BYTES]);

#endif
