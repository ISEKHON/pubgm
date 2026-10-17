"""Admin CLI for the private server: full control over players and inventory.

Works directly against the database, so it needs no running server and no
protocol work. Changes are picked up the next time a player's data is sent
(reconnect, or `sync` if the server is running with live push enabled).

    python -I tools/admin.py players
    python -I tools/admin.py show  <name>
    python -I tools/admin.py set   <name> --level 30 --gold 999999
    python -I tools/admin.py grant <name> <res_id> [--count 1]
    python -I tools/admin.py take  <name> <ins_id>
    python -I tools/admin.py ban   <name>      /  unban <name>
    python -I tools/admin.py admin <name> --on /  --off

See docs/15-server-architecture.md.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from store import Store  # noqa: E402

DEFAULT_DB = os.environ.get("PUBGM_DB", "pubgm.db")


def _char(db, name):
    ch = db.get_character_by_name(name)
    if ch is None:
        raise SystemExit(f"no character named {name!r} "
                         f"(try: python -I tools/admin.py players)")
    return ch


def cmd_players(db, _a):
    rows = db.list_characters()
    if not rows:
        print("no characters yet")
        return
    print(f"{'uid':>6}  {'name':<20} {'lvl':>4} {'gold':>10}  flags  openid")
    for r in rows:
        flags = "".join(("B" if r["banned"] else "-",
                         "A" if r["is_admin"] else "-"))
        print(f"{r['uid']:>6}  {r['name']:<20} {r['level']:>4} {r['gold']:>10}"
              f"  {flags}     {r['openid']}")


def cmd_show(db, a):
    ch = _char(db, a.name)
    for k in ch.keys():
        print(f"{k:>12}: {ch[k]}")
    items = db.items(ch["uid"])
    print(f"{'items':>12}: {len(items)}")
    for it in items:
        print(f"{'':>12}  ins={it['ins_id']} res={it['res_id']} x{it['count']}")


def cmd_set(db, a):
    ch = _char(db, a.name)
    fields = {k: v for k, v in (("level", a.level), ("exp", a.exp),
                                ("gold", a.gold), ("signature", a.signature),
                                ("name", a.rename)) if v is not None}
    if not fields:
        raise SystemExit("nothing to set; see --help")
    db.update_character(ch["uid"], **fields)
    print(f"updated {ch['name']}: " + ", ".join(f"{k}={v}" for k, v in fields.items()))


def cmd_grant(db, a):
    ch = _char(db, a.name)
    for _ in range(a.stacks):
        db.add_item(ch["uid"], a.res_id, a.count)
    print(f"granted {a.stacks}x(res {a.res_id} x{a.count}) to {ch['name']}")


def cmd_take(db, a):
    db.remove_item(a.ins_id)
    print(f"removed item {a.ins_id}")


def cmd_ban(db, a):
    ch = _char(db, a.name)
    db.set_flag(ch["openid"], "banned", a.value)
    print(f"{'banned' if a.value else 'unbanned'} {ch['name']}")


def cmd_invite(db, a):
    db.invite(a.openid, a.note or "")
    print(f"invited {a.openid}"
          + (f"  ({a.note})" if a.note else "")
          + "\nthey can log in now; no restart needed")


def cmd_uninvite(db, a):
    db.uninvite(a.openid)
    print(f"removed invite for {a.openid}\n"
          "note: this does not remove an account that already logged in -- "
          "use `ban` for that")


def cmd_invites(db, _a):
    rows = db.invites()
    if not rows:
        print("no invites. A player's openid appears in the server log when "
              "they are rejected.")
        return
    for r in rows:
        print(f"{r['openid']}  {r['note']}")


def cmd_admin(db, a):
    ch = _char(db, a.name)
    db.set_flag(ch["openid"], "is_admin", 0 if a.off else 1)
    print(f"{ch['name']} admin={'off' if a.off else 'on'}")


def build_parser():
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--db", default=DEFAULT_DB, help=f"database (default {DEFAULT_DB})")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("players", help="list every character").set_defaults(fn=cmd_players)

    s = sub.add_parser("show", help="everything about one character")
    s.add_argument("name")
    s.set_defaults(fn=cmd_show)

    s = sub.add_parser("set", help="change a character's fields")
    s.add_argument("name")
    s.add_argument("--level", type=int)
    s.add_argument("--exp", type=int)
    s.add_argument("--gold", type=int)
    s.add_argument("--signature")
    s.add_argument("--rename")
    s.set_defaults(fn=cmd_set)

    s = sub.add_parser("grant", help="add an item to a character's depot")
    s.add_argument("name")
    s.add_argument("res_id", type=int)
    s.add_argument("--count", type=int, default=1, help="count within one stack")
    s.add_argument("--stacks", type=int, default=1, help="how many stacks")
    s.set_defaults(fn=cmd_grant)

    s = sub.add_parser("take", help="remove an item by instance id")
    s.add_argument("ins_id", type=int)
    s.set_defaults(fn=cmd_take)

    s = sub.add_parser("ban", help="block an account from logging in")
    s.add_argument("name")
    s.set_defaults(fn=cmd_ban, value=1)

    s = sub.add_parser("unban")
    s.add_argument("name")
    s.set_defaults(fn=cmd_ban, value=0)

    s = sub.add_parser("invite", help="allow an openid to create an account")
    s.add_argument("openid")
    s.add_argument("--note", help="who this is, for your own reference")
    s.set_defaults(fn=cmd_invite)

    s = sub.add_parser("uninvite", help="revoke an unused invite")
    s.add_argument("openid")
    s.set_defaults(fn=cmd_uninvite)

    sub.add_parser("invites", help="list invites").set_defaults(fn=cmd_invites)

    s = sub.add_parser("admin", help="grant or revoke admin on an account")
    s.add_argument("name")
    s.add_argument("--off", action="store_true")
    s.set_defaults(fn=cmd_admin)
    return p


def main():
    a = build_parser().parse_args()
    a.fn(Store(a.db), a)


if __name__ == "__main__":
    main()
