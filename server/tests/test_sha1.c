/* Known-answer tests for SHA-1 (FIPS 180-1) and HMAC-SHA1 (RFC 2202). */
#include "sha1.h"

#include <stdio.h>
#include <string.h>

static int failures;

static void hex(const uint8_t *d, size_t n, char *out)
{
    static const char *digits = "0123456789abcdef";
    for (size_t i = 0; i < n; i++) {
        out[i * 2]     = digits[d[i] >> 4];
        out[i * 2 + 1] = digits[d[i] & 0xf];
    }
    out[n * 2] = 0;
}

static void expect(const char *what, const uint8_t *got, const char *want)
{
    char s[SHA1_DIGEST_BYTES * 2 + 1];
    hex(got, SHA1_DIGEST_BYTES, s);
    if (strcmp(s, want) != 0) {
        printf("FAIL %s\n  got  %s\n  want %s\n", what, s, want);
        failures++;
    }
}

static void test_sha1_kat(void)
{
    uint8_t d[SHA1_DIGEST_BYTES];

    sha1("", 0, d);
    expect("sha1(\"\")", d, "da39a3ee5e6b4b0d3255bfef95601890afd80709");

    sha1("abc", 3, d);
    expect("sha1(\"abc\")", d, "a9993e364706816aba3e25717850c26c9cd0d89d");

    sha1("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 56, d);
    expect("sha1(448-bit)", d, "84983e441c3bd26ebaae4aa1f95129e5e54670f1");

    /* Exactly one block, to exercise the 56-byte padding boundary. */
    char b64[64];
    memset(b64, 'a', sizeof b64);
    sha1(b64, sizeof b64, d);
    expect("sha1(64x'a')", d, "0098ba824b5c16427bd7a1122a5a442a25ec644d");

    /* 1,000,000 x 'a' - streams many blocks. */
    Sha1Ctx c;
    sha1_init(&c);
    char chunk[1000];
    memset(chunk, 'a', sizeof chunk);
    for (int i = 0; i < 1000; i++)
        sha1_update(&c, chunk, sizeof chunk);
    sha1_final(&c, d);
    expect("sha1(1e6x'a')", d, "34aa973cd4c4daa4f61eeb2bdbad27316534016f");
}

static void test_sha1_streaming_equivalence(void)
{
    /* Feeding byte-at-a-time must equal one-shot, across block boundaries. */
    uint8_t a[SHA1_DIGEST_BYTES], b[SHA1_DIGEST_BYTES];
    uint8_t msg[200];
    for (size_t i = 0; i < sizeof msg; i++)
        msg[i] = (uint8_t)(i * 7 + 3);

    for (size_t n = 0; n <= sizeof msg; n += 13) {
        sha1(msg, n, a);
        Sha1Ctx c;
        sha1_init(&c);
        for (size_t i = 0; i < n; i++)
            sha1_update(&c, msg + i, 1);
        sha1_final(&c, b);
        if (memcmp(a, b, sizeof a) != 0) {
            printf("FAIL streaming mismatch at n=%zu\n", n);
            failures++;
            return;
        }
    }
}

static void test_hmac_rfc2202(void)
{
    uint8_t d[SHA1_DIGEST_BYTES];
    uint8_t key[80];

    memset(key, 0x0b, 20);
    hmac_sha1(key, 20, "Hi There", 8, d);
    expect("rfc2202 #1", d, "b617318655057264e28bc0b6fb378c8ef146be00");

    hmac_sha1("Jefe", 4, "what do ya want for nothing?", 28, d);
    expect("rfc2202 #2", d, "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79");

    memset(key, 0xaa, 20);
    uint8_t data3[50];
    memset(data3, 0xdd, sizeof data3);
    hmac_sha1(key, 20, data3, sizeof data3, d);
    expect("rfc2202 #3", d, "125d7342b9ac11cd91a39af48aa17b4f63f175d3");

    /* Key longer than the block size must be hashed down. */
    memset(key, 0xaa, 80);
    hmac_sha1(key, 80, "Test Using Larger Than Block-Size Key - Hash Key First", 54, d);
    expect("rfc2202 #6", d, "aa4ae5e15272d00e95705637ce8a3b55ed402112");
}

int main(void)
{
    test_sha1_kat();
    test_sha1_streaming_equivalence();
    test_hmac_rfc2202();
    if (failures) {
        printf("%d check(s) failed\n", failures);
        return 1;
    }
    printf("all sha1/hmac tests passed\n");
    return 0;
}
