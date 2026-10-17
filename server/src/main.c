/* main.c - UDP listener driving the StatelessConnect handshake.
 *
 * Purpose is twofold:
 *   1. Answer the client's handshake so it can progress past connect.
 *   2. Act as an INSTRUMENT: every datagram is logged as raw hex with its exact
 *      bit length, and the decode is reported field by field. The handshake
 *      field order is still [STOCK]/unverified (see handshake.h), so the first
 *      real client packet is the evidence that settles it. A packet that does
 *      not decode is logged rather than dropped silently - that is the data we
 *      are here for.
 *
 * Usage: pubgm_server [port]      (default 7777)
 */
#include "handshake.h"
#include "packet.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

#ifdef _WIN32
#  include <winsock2.h>
#  include <ws2tcpip.h>
#  pragma comment(lib, "ws2_32.lib")
   typedef int socklen_t;
#  define CLOSESOCK closesocket
#else
#  include <arpa/inet.h>
#  include <netinet/in.h>
#  include <sys/socket.h>
#  include <unistd.h>
   typedef int SOCKET;
#  define INVALID_SOCKET (-1)
#  define SOCKET_ERROR   (-1)
#  define CLOSESOCK close
#endif

#define DEFAULT_PORT 7777
#define MAX_DGRAM    2048

static void log_hex(const char *tag, const uint8_t *d, size_t n)
{
    printf("  %s (%zu bytes):", tag, n);
    for (size_t i = 0; i < n; i++) {
        if (i % 16 == 0)
            printf("\n    %04zx  ", i);
        printf("%02x ", d[i]);
    }
    printf("\n");
}

static void log_packet(const HsPacket *p)
{
    printf("    bHandshakePacket  = %d\n", p->b_handshake_packet);
    printf("    bRestartHandshake = %d\n", p->b_restart_handshake);
    printf("    SecretId          = %d\n", p->secret_id);
    printf("    Timestamp         = %.6f\n", (double)p->timestamp);
    printf("    Cookie            = ");
    for (int i = 0; i < HS_COOKIE_BYTES; i++)
        printf("%02x", p->cookie[i]);
    printf("\n");
}

static double now_seconds(void)
{
    return (double)clock() / (double)CLOCKS_PER_SEC;
}

int main(int argc, char **argv)
{
    int port = DEFAULT_PORT;
    if (argc > 1)
        port = atoi(argv[1]);

#ifdef _WIN32
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        fprintf(stderr, "WSAStartup failed\n");
        return 1;
    }
#endif

    SOCKET s = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (s == INVALID_SOCKET) {
        fprintf(stderr, "socket() failed\n");
        return 1;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons((unsigned short)port);
    if (bind(s, (struct sockaddr *)&addr, sizeof addr) == SOCKET_ERROR) {
        fprintf(stderr, "bind() to port %d failed\n", port);
        CLOSESOCK(s);
        return 1;
    }

    HsServer srv;
    /* Deterministic seed keeps bring-up reproducible; swap for OS entropy once
     * this faces anything but our own emulator. */
    hs_server_init(&srv, "pubgm-bringup-seed", 18);

    printf("pubgm handshake server listening on UDP %d\n", port);
    printf("constants: cookie=%d secret=%d packet=%d bits\n",
           HS_COOKIE_BYTES, HS_SECRET_BYTES, HS_PACKET_BITS);
    printf("field order is UNVERIFIED - first client packet settles it\n");
    fflush(stdout);

    uint8_t buf[MAX_DGRAM];
    unsigned long seq = 0;
    for (;;) {
        struct sockaddr_in from;
        socklen_t fromlen = sizeof from;
        int n = recvfrom(s, (char *)buf, sizeof buf, 0,
                         (struct sockaddr *)&from, &fromlen);
        if (n <= 0)
            continue;

        char ip[INET_ADDRSTRLEN] = "?";
        inet_ntop(AF_INET, &from.sin_addr, ip, sizeof ip);
        char who[64];
        snprintf(who, sizeof who, "%s:%u", ip, (unsigned)ntohs(from.sin_port));

        printf("\n[%lu] from %s\n", seq++, who);
        log_hex("rx", buf, (size_t)n);

        /* UE4 frames with a trailing termination bit, so the real payload
         * length is not the byte count. Report both. */
        BitReader r;
        if (br_init_from_packet(&r, buf, (size_t)n) != 0) {
            printf("  no termination bit - not a UE4-framed packet\n");
            fflush(stdout);
            continue;
        }
        printf("  payload bits = %zu (expected %d for a handshake)\n",
               r.num_bits, HS_PACKET_BITS);

        HsPacket in, out;
        if (hs_decode(&r, &in) != 0) {
            printf("  does NOT decode as a handshake packet"
                   " - layout assumption may be wrong\n");
            fflush(stdout);
            continue;
        }
        printf("  decoded as handshake:\n");
        log_packet(&in);

        HsAction act = hs_server_step(&srv, &in, who, (float)now_seconds(), &out);
        if (act == HS_IGNORE) {
            printf("  -> IGNORE\n");
            fflush(stdout);
            continue;
        }
        printf("  -> %s\n", act == HS_SEND_CHALLENGE ? "SEND_CHALLENGE" : "ACCEPT");
        log_packet(&out);

        uint8_t txbuf[64];
        BitWriter w;
        bw_init(&w, txbuf, sizeof txbuf * 8);
        if (hs_encode(&w, &out) != 0) {
            printf("  encode failed\n");
            fflush(stdout);
            continue;
        }
        bw_finish(&w);                      /* UE4 termination bit */
        size_t txlen = bw_num_bytes(&w);
        log_hex("tx", txbuf, txlen);
        sendto(s, (const char *)txbuf, (int)txlen, 0,
               (struct sockaddr *)&from, fromlen);

        if (act == HS_ACCEPT)
            printf("  handshake COMPLETE for %s"
                   " (next: control channel, NMT_Hello)\n", who);
        fflush(stdout);
    }
}
