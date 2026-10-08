#!/usr/bin/env python3
"""Put the operator's local account details into the answer file via stdin."""
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape

source, destination, username = sys.argv[1:]
# Conservative subset of valid Windows local account names; rr is valid.
if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,19}', username):
    raise SystemExit('Use 1-20 ASCII letters, digits, dots, underscores or hyphens, starting with a letter or digit.')
if username.casefold() in {'administrator', 'guest', 'defaultaccount', 'wdagutilityaccount'}:
    raise SystemExit('Choose a name other than a built-in Windows account.')
password = sys.stdin.read()
if not password or any(ord(c) < 32 for c in password):
    raise SystemExit('The account needs a nonempty password without control characters.')
text = Path(source).read_text(encoding='utf-8')
if text.count('CYBERWIN_ADMIN_NAME') != 1 or text.count('CYBERWIN_ADMIN_PASSWORD') != 1:
    raise SystemExit('Expected exactly one account-name and password placeholder.')
text = text.replace('CYBERWIN_ADMIN_NAME', escape(username))
text = text.replace('CYBERWIN_ADMIN_PASSWORD', escape(password))
ET.fromstring(text)
Path(destination).write_text(text, encoding='utf-8')
