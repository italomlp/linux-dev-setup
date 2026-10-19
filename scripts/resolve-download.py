#!/usr/bin/env python3
"""Extract narrowly scoped download metadata from official vendor responses."""
import json
import gzip
import re
import sys
import tarfile
from pathlib import Path
from urllib.parse import urlsplit


def fail(message):
    raise SystemExit(message)


def docker_url(path):
    html = Path(path).read_text()
    matches = re.findall(
        r'https://desktop\.docker\.com/linux/main/amd64/[0-9]+/docker-desktop-amd64\.deb',
        html,
    )
    if not matches:
        fail('Docker release notes do not contain an amd64 DEB URL')
    return matches[0]


def docker_checksum(path):
    content = Path(path).read_text()
    matches = re.findall(r'(?mi)^([0-9a-f]{64})\s+\*?docker-desktop-amd64\.deb\s*$', content)
    if len(matches) != 1:
        fail('Docker checksum file must contain exactly one DEB checksum')
    return matches[0]


def github_asset(path, name, repo):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repo):
        fail('Invalid GitHub repository')
    data = json.loads(Path(path).read_text())
    assets = [asset for asset in data.get('assets', []) if asset.get('name') == name]
    if len(assets) != 1:
        fail(f'Expected exactly one GitHub release asset named {name}')
    return validate_github_asset(assets[0], name, repo)


def validate_github_asset(asset, name, repo):
    url = asset.get('browser_download_url', '')
    digest = asset.get('digest', '')
    parsed = urlsplit(url)
    if parsed.scheme != 'https' or parsed.hostname != 'github.com' or not parsed.path.startswith(f'/{repo}/releases/download/') or not parsed.path.endswith('/' + name):
        fail('GitHub asset URL does not match the official repository')
    if not re.fullmatch(r'sha256:[0-9a-f]{64}', digest):
        fail('GitHub asset has no SHA-256 digest')
    return url + '\t' + digest.removeprefix('sha256:')


def github_product(path, product):
    products = {
        'starship': ('starship/starship', 'starship-x86_64-unknown-linux-gnu.tar.gz'),
        'zellij': ('zellij-org/zellij', 'zellij-x86_64-unknown-linux-musl.tar.gz'),
    }
    data = json.loads(Path(path).read_text())
    if product == 'lazygit':
        version = data.get('tag_name', '').removeprefix('v')
        if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version):
            fail('Invalid Lazygit release version')
        repo, name = 'jesseduffield/lazygit', f'lazygit_{version}_linux_x86_64.tar.gz'
    elif product in products:
        repo, name = products[product]
    else:
        fail('Unknown GitHub product')
    return github_asset(path, name, repo) + '\t' + name


def android(path):
    html = Path(path).read_text()
    row = re.search(r'<tr>\s*<td>Linux<br>\(64-bit\)</td>(.*?)</tr>', html, re.S)
    if not row:
        fail('Google page has no Linux 64-bit Studio row')
    filename = re.search(r'android-studio-[A-Za-z0-9_.-]+-linux\.tar\.gz', row.group(1))
    checksum = re.search(r'\b[0-9a-f]{64}\b', row.group(1))
    if not filename or not checksum:
        fail('Google page has no Linux Studio filename or SHA-256')
    links = re.findall(r'https://(?:edgedl\.me\.gvt1\.com|dl\.google\.com)/android/studio/ide-zips/[^"<> ]+/' + re.escape(filename.group()), html)
    if len(links) != 1:
        fail('Google page must contain exactly one matching Studio URL')
    return links[0] + '\t' + checksum.group() + '\t' + filename.group()


def android_cli(path):
    html = Path(path).read_text()
    name = re.search(r'commandlinetools-linux-[0-9]+_latest\.zip', html)
    if not name:
        fail('Google page has no Linux command-line tools archive')
    rows = re.findall(r'<tr\b[^>]*>.*?</tr>', html, re.S)
    row = next((item for item in rows if name.group() in item), '')
    checksum = re.search(r'\b[0-9a-f]{64}\b', row)
    if not checksum:
        fail('Google page has no command-line tools SHA-256')
    links = set(re.findall(r'https://dl\.google\.com/android/repository/' + re.escape(name.group()), html))
    if len(links) != 1:
        fail('Google page has no unique command-line tools URL')
    return links.pop() + '\t' + checksum.group() + '\t' + name.group()


def antigravity_ide(path):
    html = Path(path).read_text()
    links = re.findall(r'https://edgedl\.me\.gvt1\.com/edgedl/release2/[^"<> ]+/linux-x64/Antigravity%20IDE\.tar\.gz', html)
    if not links:
        fail('No official Antigravity IDE Linux x64 archive found')
    return links[0]


def antigravity_response(path):
    with open(path, 'rb') as response:
        raw = response.read(512)
    if raw.startswith(b'\x1f\x8b'):
        with gzip.open(path, 'rb') as response:
            prefix = response.read(512)
        if prefix.startswith(b'Antigravity IDE/'):
            return 'archive'
        return 'html-gzip'
    return 'html'


def chatgpt(path):
    html = Path(path).read_text()
    links = re.findall(r'https://persistent\.oaistatic\.com/codex-app-prod/linux/deb/[^"<> ]+/chatgpt_amd64\.deb', html)
    if len(links) != 1:
        fail('Official ChatGPT Linux page must contain one amd64 DEB URL')
    return links[0]


def slack_deb(path):
    html = Path(path).read_text()
    links = re.findall(
        r'https://downloads\.slack-edge\.com/desktop-releases/linux/x64/[0-9.]+/slack-desktop-[0-9.]+-amd64\.deb',
        html,
    )
    links = list(dict.fromkeys(links))
    if len(links) != 1:
        fail('Slack download instructions must contain exactly one official amd64 DEB URL')
    return links[0]


def antigravity_cli(path):
    data = json.loads(Path(path).read_text())
    url, digest = data.get('url', ''), data.get('sha512', '')
    parsed = urlsplit(url)
    if parsed.scheme != 'https' or parsed.hostname not in ('storage.googleapis.com', 'antigravity-cli-auto-updater-974169037036.us-central1.run.app'):
        fail('Antigravity CLI manifest has an unexpected download host')
    if not re.fullmatch(r'[0-9a-f]{128}', digest):
        fail('Antigravity CLI manifest has no valid SHA-512')
    return url + '\t' + digest


def llama_vulkan(path):
    releases = json.loads(Path(path).read_text())
    for release in releases:
        tag = release.get('tag_name', '')
        if not re.fullmatch(r'b[0-9]+', tag):
            continue
        name = f'llama-{tag}-bin-ubuntu-vulkan-x64.tar.gz'
        assets = [asset for asset in release.get('assets', []) if asset.get('name') == name]
        if len(assets) == 1:
            return validate_github_asset(assets[0], name, 'ggml-org/llama.cpp') + '\t' + name + '\t' + tag
    fail('No recent official Ubuntu Vulkan x64 release with SHA-256')


def tar_root(path, root):
    with tarfile.open(path, 'r:gz') as archive:
        for member in archive:
            parts = Path(member.name).parts
            if not parts or parts[0] != root or '..' in parts or member.name.startswith('/') or not (member.isdir() or member.isfile()):
                fail(f'Unsafe archive entry: {member.name}')
    return 'archive paths verified'


if __name__ == '__main__':
    mode, *args = sys.argv[1:]
    if mode == 'docker-url' and len(args) == 1:
        print(docker_url(*args))
    elif mode == 'docker-checksum' and len(args) == 1:
        print(docker_checksum(*args))
    elif mode == 'github' and len(args) == 3:
        print(github_asset(*args))
    elif mode == 'github-product' and len(args) == 2:
        print(github_product(*args))
    elif mode == 'android' and len(args) == 1:
        print(android(*args))
    elif mode == 'android-cli' and len(args) == 1:
        print(android_cli(*args))
    elif mode == 'antigravity-ide' and len(args) == 1:
        print(antigravity_ide(*args))
    elif mode == 'antigravity-response' and len(args) == 1:
        print(antigravity_response(*args))
    elif mode == 'chatgpt' and len(args) == 1:
        print(chatgpt(*args))
    elif mode == 'slack-deb' and len(args) == 1:
        print(slack_deb(*args))
    elif mode == 'antigravity-cli' and len(args) == 1:
        print(antigravity_cli(*args))
    elif mode == 'llama-vulkan' and len(args) == 1:
        print(llama_vulkan(*args))
    elif mode == 'tar-root' and len(args) == 2:
        print(tar_root(*args))
    else:
        fail('Usage: resolve-download.py docker-url FILE | docker-checksum FILE | github FILE ASSET REPO')
