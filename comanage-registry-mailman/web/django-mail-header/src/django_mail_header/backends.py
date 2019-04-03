"""
Django backend that uses the RemoteUserBackend as a base
class and that sets the email field on the user model
to be the same as the username field each time a new
user is created.
"""

from django.contrib.auth.backends import RemoteUserBackend

class MailHeaderBackend(RemoteUserBackend):
    def configure_user(self, user):
        username = user.get_username()
        user.email = username;
        user.save()

        return user
