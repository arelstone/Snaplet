#!/usr/bin/env python3
"""Bind this project to an existing self-signed identity; read public metadata only."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parent.parent
NAME = 'Snaplet'
KEYCHAIN = Path.home() / 'Library/Keychains/login.keychain-db'


def main():
    result = subprocess.run(['security', 'find-certificate', '-a', '-c', NAME, '-p', str(KEYCHAIN)],
                            capture_output=True, text=True)
    certs = re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', result.stdout, re.S)
    if len(certs) != 1:
        raise SystemExit(f'Expected one certificate named {NAME!r} in login Keychain; found {len(certs)}.')
    certificate = certs[0]
    details = subprocess.run(['openssl', 'x509', '-noout', '-subject', '-issuer', '-nameopt', 'RFC2253'],
                             input=certificate, capture_output=True, text=True, check=True).stdout.splitlines()
    subject = details[0].removeprefix('subject=').strip()
    issuer = details[1].removeprefix('issuer=').strip()
    fields = dict(part.split('=', 1) for part in subject.split(','))
    if subject != issuer or fields.get('CN') != NAME or not set(fields).issubset({'CN', 'C'}):
        raise SystemExit('The named identity must be the project-specific self-signed certificate.')
    der = subprocess.run(['openssl', 'x509', '-outform', 'DER'], input=certificate.encode(),
                         capture_output=True, check=True).stdout
    identity = hashlib.sha1(der).hexdigest().upper()
    identities = subprocess.run(['security', 'find-identity', '-p', 'codesigning', str(KEYCHAIN)],
                                capture_output=True, text=True, check=True).stdout
    if identity not in identities:
        raise SystemExit('The local certificate has no available signing identity in login Keychain.')
    directory = ROOT / '.local'
    directory.mkdir(exist_ok=True)
    path = directory / 'signing.json'
    staged = path.with_suffix('.tmp')
    staged.write_text(json.dumps({'common_name': NAME, 'identity': identity, 'keychain': str(KEYCHAIN)}, indent=2) + '\n')
    staged.replace(path)
    print(f'Configured {NAME}; public certificate identity saved in .local/signing.json.')


if __name__ == '__main__':
    main()
