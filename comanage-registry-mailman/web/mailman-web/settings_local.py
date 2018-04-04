"""
Django Settings for Mailman Suite (hyperkitty + postorius)

For more information on this file, see
https://docs.djangoproject.com/en/1.8/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/1.8/ref/settings/
"""

# Try to get the address of Mailman Core automatically.
import os
import socket
MAILMAN_HOST_IP_AUTO = socket.gethostbyname('mailman-core')

# Mailman API credentials
MAILMAN_REST_API_URL = os.environ.get('MAILMAN_REST_URL', 'http://mailman-core:8001')
MAILMAN_REST_API_USER = os.environ.get('MAILMAN_REST_USER', 'restadmin')
MAILMAN_REST_API_PASS = os.environ.get('MAILMAN_REST_PASSWORD', 'restpass')
MAILMAN_ARCHIVER_KEY = os.environ.get('HYPERKITTY_API_KEY')
MAILMAN_ARCHIVER_FROM = (MAILMAN_HOST_IP_AUTO, os.environ.get('MAILMAN_HOST_IP', '172.19.199.2'))


