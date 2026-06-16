#!/usr/bin/env python3
"""Manage Claude Code sessions for the CURRENT project directory (no tmux).

Claude Code saves each session as ~/.claude/projects/<cwd-with-slashes-as-dashes>/<id>.jsonl
and stores the --name value as "customTitle" inside it.

Usage (run from your project dir):
  cc-sessions.py resolve <name>   print newest session id whose name == <name> (else nothing)
  cc-sessions.py list             list this project's sessions (name | modified | id)
  cc-sessions.py delete <name>    delete session(s) named <name> (transcript + attachments)
"""
import sys, os, json, glob, time, shutil


def project_dir(cwd=None):
    cwd = cwd or os.getcwd()
    return os.path.expanduser("~/.claude/projects/" + cwd.replace("/", "-"))


def sessions(pdir):
    out = []
    for f in glob.glob(os.path.join(pdir, "*.jsonl")):
        sid = os.path.splitext(os.path.basename(f))[0]
        name = None
        atitle = None
        try:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                for line in fh:
                    if '"customTitle"' in line:          # last one wins (handles /rename)
                        try: name = json.loads(line).get("customTitle", name)
                        except Exception: pass
                    elif atitle is None and '"aiTitle"' in line:
                        try: atitle = json.loads(line).get("aiTitle")
                        except Exception: pass
        except Exception:
            pass
        out.append({"sid": sid, "name": name,
                    "label": name or atitle or "(untitled)",
                    "mtime": os.path.getmtime(f), "file": f})
    out.sort(key=lambda s: s["mtime"], reverse=True)
    return out


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    pdir = project_dir()
    ss = sessions(pdir) if os.path.isdir(pdir) else []

    arg = sys.argv[2] if len(sys.argv) > 2 else None

    if cmd == "resolve":
        if not arg:
            return
        match = [s for s in ss if s["name"] == arg]
        if match:
            print(match[0]["sid"])           # newest match

    elif cmd == "list":
        if not ss:
            print("(no saved sessions for %s)" % os.getcwd()); return
        print("%-28s %-17s %s" % ("NAME", "MODIFIED", "SESSION ID"))
        for s in ss:
            t = time.strftime("%Y-%m-%d %H:%M", time.localtime(s["mtime"]))
            print("%-28s %-17s %s" % (s["label"][:27], t, s["sid"]))

    elif cmd == "delete":
        if not arg:
            print("usage: claude rm <name>"); return
        match = [s for s in ss if s["name"] == arg]
        if not match:
            print("no session named '%s' in %s" % (arg, os.getcwd())); return
        for s in match:
            os.remove(s["file"])
            d = os.path.join(pdir, s["sid"])
            if os.path.isdir(d):
                shutil.rmtree(d)
            print("deleted '%s'  (%s)" % (arg, s["sid"]))

    else:
        print(__doc__)


main()
