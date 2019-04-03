"""
Django middleware that builds on the RemoteUserMiddleware
base class and sets the header to inspect for the username
to HTTP_MAIL.
"""

from django.contrib.auth.middleware import RemoteUserMiddleware

class MailHeaderMiddleware(RemoteUserMiddleware):
    header = 'HTTP_MAIL'
