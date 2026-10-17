"""Persistent state for the lobby server: accounts, characters, inventory.

One SQLite file, no daemon, trivially backed up. The lobby server builds its
`sync_base_info` payload from here instead of a hardcoded literal, so characters
survive restarts and several players get distinct identities.

    from store import Store
    db = Store("pubgm.db")
    ch = db.get_character_by_openid(openid) or db.create_character(openid, name, avatar)
    payload = db.role_data(ch)

See docs/15-server-architecture.md for where this fits.
"""
import os
import sqlite3
import time

SCHEMA = """
CREATE TABLE IF NOT EXISTS account (
    openid     TEXT PRIMARY KEY,
    created_at INTEGER NOT NULL,
    last_seen  INTEGER,
    banned     INTEGER NOT NULL DEFAULT 0,
    is_admin   INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS character (
    uid        INTEGER PRIMARY KEY AUTOINCREMENT,
    openid     TEXT NOT NULL REFERENCES account(openid),
    name       TEXT NOT NULL UNIQUE,
    level      INTEGER NOT NULL DEFAULT 1,
    exp        INTEGER NOT NULL DEFAULT 0,
    gold       INTEGER NOT NULL DEFAULT 0,
    gamegender INTEGER NOT NULL DEFAULT 1,
    headid     INTEGER NOT NULL DEFAULT 0,
    hairid     INTEGER NOT NULL DEFAULT 0,
    signature  TEXT NOT NULL DEFAULT '',
    parachute  TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS item (
    ins_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    uid       INTEGER NOT NULL REFERENCES character(uid),
    res_id    INTEGER NOT NULL,
    count     INTEGER NOT NULL DEFAULT 1,
    is_new    INTEGER NOT NULL DEFAULT 1,
    expire_ts INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS item_by_uid ON item(uid);
CREATE TABLE IF NOT EXISTS kv (
    uid   INTEGER NOT NULL,
    key   TEXT NOT NULL,
    value TEXT,
    PRIMARY KEY (uid, key)
);
-- Tickets handed out by the lobby when a player is sent to a match. The game
-- server can check an arriving player against these instead of trusting
-- whatever the client presents.
CREATE TABLE IF NOT EXISTS match_ticket (
    game_id    INTEGER NOT NULL,
    uid        INTEGER,
    key        TEXT NOT NULL,
    packet_key TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (game_id, uid)
);
-- Who is allowed to log in at all. The client's `openid` is self-asserted and
-- cannot be verified, so on a public server this list is the only thing
-- stopping a stranger who finds the port from creating a character.
CREATE TABLE IF NOT EXISTS invite (
    openid     TEXT PRIMARY KEY,
    note       TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL
);
"""

# uid 1 would collide with the client's notion of an unset id in a few places,
# so start character ids somewhere obviously real.
UID_BASE = 10000


class Store:
    def __init__(self, path="pubgm.db"):
        self.path = path
        new = not os.path.exists(path)
        self.db = sqlite3.connect(path, check_same_thread=False)
        self.db.row_factory = sqlite3.Row
        self.db.executescript(SCHEMA)
        if new:
            self.db.execute(
                "INSERT INTO sqlite_sequence(name, seq) VALUES ('character', ?)"
                " ON CONFLICT DO NOTHING", (UID_BASE,))
        self.db.commit()

    # --- accounts ---------------------------------------------------------

    def touch_account(self, openid):
        """Create the account if new, stamp last_seen, return the row."""
        openid = _text(openid)
        now = int(time.time())
        self.db.execute(
            "INSERT INTO account (openid, created_at, last_seen) VALUES (?,?,?)"
            " ON CONFLICT(openid) DO UPDATE SET last_seen=excluded.last_seen",
            (openid, now, now))
        self.db.commit()
        return self.db.execute(
            "SELECT * FROM account WHERE openid=?", (openid,)).fetchone()

    def is_banned(self, openid):
        row = self.db.execute("SELECT banned FROM account WHERE openid=?",
                              (_text(openid),)).fetchone()
        return bool(row and row["banned"])

    # --- admission control ------------------------------------------------

    def invite(self, openid, note=""):
        self.db.execute(
            "INSERT INTO invite (openid, note, created_at) VALUES (?,?,?)"
            " ON CONFLICT(openid) DO UPDATE SET note=excluded.note",
            (_text(openid), note, int(time.time())))
        self.db.commit()

    def uninvite(self, openid):
        self.db.execute("DELETE FROM invite WHERE openid=?", (_text(openid),))
        self.db.commit()

    def invites(self):
        return self.db.execute("SELECT * FROM invite ORDER BY created_at").fetchall()

    def may_login(self, openid, registration="invite"):
        """(allowed, reason). `registration` is open | invite | closed.

        - open    anyone may create an account (LAN / trusted network only)
        - invite  known accounts, plus anyone on the invite list
        - closed  only accounts that already exist
        """
        openid = _text(openid)
        if self.is_banned(openid):
            return False, "banned"
        known = self.db.execute(
            "SELECT 1 FROM account WHERE openid=?", (openid,)).fetchone() is not None
        if known:
            return True, "known"
        if registration == "open":
            return True, "open"
        if registration == "invite":
            invited = self.db.execute(
                "SELECT 1 FROM invite WHERE openid=?", (openid,)).fetchone()
            return (True, "invited") if invited else (False, "not_invited")
        return False, "closed"

    def set_flag(self, openid, field, value):
        if field not in ("banned", "is_admin"):
            raise ValueError(f"not a settable flag: {field}")
        self.db.execute(f"UPDATE account SET {field}=? WHERE openid=?",
                        (int(value), _text(openid)))
        self.db.commit()

    # --- characters -------------------------------------------------------

    def get_character_by_openid(self, openid):
        return self.db.execute(
            "SELECT * FROM character WHERE openid=? ORDER BY uid LIMIT 1",
            (_text(openid),)).fetchone()

    def get_character_by_name(self, name):
        return self.db.execute("SELECT * FROM character WHERE name=?",
                               (_text(name),)).fetchone()

    def create_character(self, openid, name, gamegender=1, headid=0, hairid=0,
                         gold=0):
        self.touch_account(openid)
        now = int(time.time())
        cur = self.db.execute(
            "INSERT INTO character (openid, name, gamegender, headid, hairid,"
            " gold, created_at) VALUES (?,?,?,?,?,?,?)",
            (_text(openid), _text(name), _int(gamegender), _int(headid),
             _int(hairid), gold, now))
        self.db.commit()
        return self.db.execute("SELECT * FROM character WHERE uid=?",
                               (cur.lastrowid,)).fetchone()

    def update_character(self, uid, **fields):
        allowed = {"level", "exp", "gold", "gamegender", "headid", "hairid",
                   "signature", "parachute", "name"}
        bad = set(fields) - allowed
        if bad:
            raise ValueError(f"not updatable: {sorted(bad)}")
        if not fields:
            return
        sets = ", ".join(f"{k}=?" for k in fields)
        self.db.execute(f"UPDATE character SET {sets} WHERE uid=?",
                        (*fields.values(), uid))
        self.db.commit()

    def list_characters(self):
        return self.db.execute(
            "SELECT c.*, a.banned, a.is_admin FROM character c"
            " JOIN account a USING (openid) ORDER BY c.uid").fetchall()

    # --- inventory --------------------------------------------------------

    def add_item(self, uid, res_id, count=1, expire_ts=0):
        self.db.execute(
            "INSERT INTO item (uid, res_id, count, expire_ts) VALUES (?,?,?,?)",
            (uid, int(res_id), int(count), int(expire_ts)))
        self.db.commit()

    def remove_item(self, ins_id):
        self.db.execute("DELETE FROM item WHERE ins_id=?", (ins_id,))
        self.db.commit()

    def items(self, uid):
        return self.db.execute("SELECT * FROM item WHERE uid=?", (uid,)).fetchall()

    # --- match tickets ----------------------------------------------------

    def record_match(self, uid, game_id, key, packet_key):
        """Remember a ticket the lobby handed out, for the game server to check."""
        self.db.execute(
            "INSERT OR REPLACE INTO match_ticket"
            " (game_id, uid, key, packet_key, created_at) VALUES (?,?,?,?,?)",
            (int(game_id), uid, _text(key), _text(packet_key), int(time.time())))
        self.db.commit()

    def check_ticket(self, game_id, key):
        """Return the ticket row if this (game_id, key) pair was issued."""
        return self.db.execute(
            "SELECT * FROM match_ticket WHERE game_id=? AND key=?",
            (int(game_id), _text(key))).fetchone()

    # --- payload ----------------------------------------------------------

    def role_data(self, ch, svr_time=None):
        """Build the `sync_base_info` roleData for a character row.

        The shape here is load-bearing; see docs/14-lobby-reached.md.

        - `avatar` MUST be a table: data_mgr.lua indexes avatar.gamegender /
          .headid / .hairid directly, and indexing a number aborts the client's
          init (the lobby scene loads but its UI never builds).
        - `task`, `activeness`, `week_signup` and `share_award` are deliberately
          OMITTED. Each is nil-guarded with a harmless else-branch, but the
          non-nil path dereferences sub-fields (pairs(task.list),
          #week_signup.list) and calls UI updaters during early init. Sending
          an empty table passes the guard and crashes; sending nothing is safe.
          Add them back only together with their full sub-structure.
        """
        depot = {"items": {
            str(it["ins_id"]): {
                "instid": it["ins_id"], "res_id": it["res_id"],
                "count": it["count"], "isnew": it["is_new"],
                "valid_hours": 0, "expire_ts": it["expire_ts"],
            } for it in self.items(ch["uid"])
        }}
        return {
            "name": ch["name"],
            "openid": ch["openid"],
            "uid": ch["uid"],
            "level": ch["level"],
            "exp": ch["exp"],
            "gold": ch["gold"],
            "avatar": {
                "gamegender": ch["gamegender"],
                "headid": ch["headid"],
                "hairid": ch["hairid"],
            },
            "depot": depot,
            "rolewear": {},
            "parachute": ch["parachute"],
            "signature": ch["signature"],
            "pic_url": "",
            "rela_sex": ch["gamegender"],
            "segment_info": {},
            "login_reward": {},
            "last_login_reward_remind": 0,
            "cur_avatar_box_id": 0,
            "qq_vip": 0,
            "xy_red_point": 0,
            "anchor": 0,
            "svr_time": int(svr_time if svr_time is not None else time.time()),
            "wxsubscribe": {"setflag": 0},
            "qqsubscribe": {"setflag": 0},
        }


def _text(v):
    return v.decode("utf-8", "replace") if isinstance(v, (bytes, bytearray)) else str(v)


def _int(v):
    """Accept the lobby codec's decoded forms: int, or ('small', byte)."""
    if isinstance(v, tuple) and len(v) == 2:
        return int(v[1])
    try:
        return int(v)
    except (TypeError, ValueError):
        return 0
