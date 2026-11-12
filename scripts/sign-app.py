#!/usr/bin/env python3
"""Sign using the explicitly configured project identity."""
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent


def main():
    if len(sys.argv) != 2:
        raise SystemExit('Usage: sign-app.py <app bundle>')
    app = Path(sys.argv[1]).resolve()
    override = os.environ.get('SNAPLET_SIGNING_IDENTITY')
    args = ['codesign', '--force', '--timestamp=none']
    if override:
        args += ['--sign', override]
    else:
        path = ROOT / '.local/signing.json'
        if not path.exists():
            raise SystemExit('Run python3 scripts/configure-local-signing.py after creating the local identity in Keychain Access.')
        config = json.loads(path.read_text())
        identity = config['identity']
        if config.get('common_name') != 'Snaplet' or not re.fullmatch(r'[A-Fa-f0-9]{40}', identity):
            raise SystemExit('Invalid local signing configuration.')
        with (app / 'Contents/Info.plist').open('rb') as file:
            identifier = plistlib.load(file)['CFBundleIdentifier']
        if not re.fullmatch(r'[A-Za-z0-9.-]+', identifier):
            raise SystemExit('Invalid bundle identifier.')
        requirement = f'=designated => identifier "{identifier}" and certificate leaf = H"{identity}"'
        args += ['--sign', identity, '--keychain', config['keychain'], '--requirements', requirement]
    subprocess.run([*args, str(app)], check=True)
    subprocess.run(['codesign', '--verify', '--strict', str(app)], check=True)


if __name__ == '__main__':
    main()
