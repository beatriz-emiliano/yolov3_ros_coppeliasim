#!/usr/bin/env python3
from bs4 import BeautifulSoup
import requests

def get(url):
    r = requests.get(url)
    assert(r.status_code == 200)
    return BeautifulSoup(r.content, features='lxml')

def get_github_latest_tag(user_repo):
    s = get(f'https://github.com/{user_repo}/tags')
    return s.select('div.repository-content div.Box-row')[0].select('h4.commit-title a')[0].text.strip()

s = get('https://fontawesome.com/v6.0/docs/changelog/')
print('font-awesome:', s.select('main article header')[0].select('code')[0].text.strip())

print('renderjson:', get_github_latest_tag('caldwell/renderjson'))

print('three-js:', get_github_latest_tag('mrdoob/three.js'))

print('jquery:', get_github_latest_tag('jquery/jquery'))

print('reconnecting-websocket:', get_github_latest_tag('joewalnes/reconnecting-websocket'))

print('dat-gui:', get_github_latest_tag('dataarts/dat.gui'))

print('cbor-js:', get_github_latest_tag('paroga/cbor-js'))
