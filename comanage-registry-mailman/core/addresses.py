# Copyright (C) 2011-2017 by the Free Software Foundation, Inc.
#
# This file is part of GNU Mailman.
#
# GNU Mailman is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# GNU Mailman is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# GNU Mailman.  If not, see <http://www.gnu.org/licenses/>.
#
# This file includes patches needed for integration with COmanage Registry.
# Inclusion of the patches in the upstream GNU Mailman distribution is pending.

"""REST for addresses."""

from lazr.config import as_boolean
from mailman.interfaces.address import (
    ExistingAddressError, InvalidEmailAddressError)
from mailman.interfaces.usermanager import IUserManager
from mailman.rest.helpers import (
    BadRequest, CollectionMixin, NotFound, bad_request, child, created, etag,
    no_content, not_found, okay)
from mailman.rest.members import MemberCollection
from mailman.rest.preferences import Preferences
from mailman.rest.validator import Validator
from mailman.utilities.datetime import now
from operator import attrgetter
from public import public
from zope.component import getUtility


class _AddressBase(CollectionMixin):
    """Shared base class for address representations."""

    def _resource_as_dict(self, address):
        """See `CollectionMixin`."""
        # The canonical url for an address is its lower-cased version,
        # although it can be looked up with either its original or lower-cased
        # email address.
        representation = dict(
            email=address.email,
            original_email=address.original_email,
            registered_on=address.registered_on,
            self_link=self.api.path_to('addresses/{}'.format(address.email)),
            )
        # Add optional attributes.  These can be None or the empty string.
        if address.display_name:
            representation['display_name'] = address.display_name
        if address.verified_on:
            representation['verified_on'] = address.verified_on
        if address.user:
            uid = self.api.from_uuid(address.user.user_id)
            representation['user'] = self.api.path_to('users/{}'.format(uid))
            if address == address.user.preferred_address:
                representation['preferred'] = True
        return representation

    def _get_collection(self, request):
        """See `CollectionMixin`."""
        return sorted(getUtility(IUserManager).addresses,
                      key=attrgetter('original_email'))


@public
class AllAddresses(_AddressBase):
    """The addresses."""

    def on_get(self, request, response):
        """/addresses"""
        resource = self._make_collection(request)
        okay(response, etag(resource))


class _VerifyResource:
    """A helper resource for verify/unverify POSTS."""

    def __init__(self, address, action):
        self._address = address
        self._action = action
        assert action in ('verify', 'unverify')

    def on_post(self, request, response):
        # We don't care about the POST data, just do the action.
        if self._action == 'verify' and self._address.verified_on is None:
            self._address.verified_on = now()
        elif self._action == 'unverify':
            self._address.verified_on = None
        no_content(response)


@public
class AnAddress(_AddressBase):
    """An address."""

    def __init__(self, email):
        """Get an address by either its original or lower-cased email.

        :param email: The email address of the `IAddress`.
        :type email: string
        """
        self._address = getUtility(IUserManager).get_address(email)

    def on_get(self, request, response):
        """Return a single address."""
        if self._address is None:
            not_found(response)
        else:
            okay(response, self._resource_as_json(self._address))

    def on_delete(self, request, response):
        if self._address is None:
            not_found(response)
        else:
            getUtility(IUserManager).delete_address(self._address)
            no_content(response)

    @child()
    def memberships(self, context, segments):
        """/addresses/<email>/memberships"""
        if len(segments) != 0:
            return NotFound(), []
        if self._address is None:
            return NotFound(), []
        return AddressMemberships(self._address)

    @child()
    def preferences(self, context, segments):
        """/addresses/<email>/preferences"""
        if len(segments) != 0:
            return NotFound(), []
        if self._address is None:
            return NotFound(), []
        child = Preferences(
            self._address.preferences,
            'addresses/{}'.format(self._address.email))
        return child, []

    @child()
    def verify(self, context, segments):
        """/addresses/<email>/verify"""
        if len(segments) != 0:
            return BadRequest(), []
        if self._address is None:
            return NotFound(), []
        child = _VerifyResource(self._address, 'verify')
        return child, []

    @child()
    def unverify(self, context, segments):
        """/addresses/<email>/verify"""
        if len(segments) != 0:
            return BadRequest(), []
        if self._address is None:
            return NotFound(), []
        child = _VerifyResource(self._address, 'unverify')
        return child, []

    @child()
    def user(self, context, segments):
        """/addresses/<email>/user"""
        if self._address is None:
            return NotFound(), []
        # Avoid circular imports.
        from mailman.rest.users import AddressUser
        return AddressUser(self._address)


@public
class UserAddresses(_AddressBase):
    """The addresses of a user."""

    def __init__(self, user):
        super().__init__()
        self._user = user

    def _get_collection(self, request):
        """See `CollectionMixin`."""
        return sorted(self._user.addresses,
                      key=attrgetter('original_email'))

    def on_get(self, request, response):
        """/addresses"""
        assert self._user is not None
        okay(response, etag(self._make_collection(request)))

    def on_post(self, request, response):
        """POST to /addresses

        Add a new address to the user record.
        """
        assert self._user is not None

        preferred = None

        user_manager = getUtility(IUserManager)
        validator = Validator(email=str,
                              display_name=str,
                              preferred=as_boolean,
                              absorb_existing=bool,
                              _optional=('display_name', 'absorb_existing', 'preferred'))
        try:
            data = validator(request)

            # We cannot set the address to be preferred when it is
            # created so remove it from the arguments here and
            # set it below.
            preferred = data.pop('preferred', False)
        except ValueError as error:
            bad_request(response, str(error))
            return
        absorb_existing = data.pop('absorb_existing', False)
        try:
            address = user_manager.create_address(**data)
        except InvalidEmailAddressError:
            bad_request(response, b'Invalid email address')
            return
        except ExistingAddressError:
            # If the address is not linked to any user, link it to the current
            # user and return it.  Since we're linking to an existing address,
            # ignore any given display_name attribute.
            address = user_manager.get_address(data['email'])
            if address.user is None:
                address.user = self._user
                location = self.api.path_to(
                    'addresses/{}'.format(address.email))
                created(response, location)
                return
            elif not absorb_existing:
                bad_request(response, 'Address belongs to other user')
                return
            else:
                # The address exists and is linked but we can merge the users.
                address = user_manager.get_address(data['email'])
                self._user.absorb(address.user)
        else:
            # Link the address to the current user and return it.
            address.user = self._user

            # Set the preferred address here if we were signalled to do so.
            if preferred:
                address.verified_on = now()
                self._user.preferred_address = address

        location = self.api.path_to('addresses/{}'.format(address.email))
        created(response, location)


def membership_key(member):
    # Sort first by mailing list, then by address, then by role.
    return member.list_id, member.address.email, member.role.value


@public
class AddressMemberships(MemberCollection):
    """All the memberships of a particular email address."""

    def __init__(self, address):
        super().__init__()
        self._address = address

    def _get_collection(self, request):
        """See `CollectionMixin`."""
        # XXX Improve this by implementing a .memberships attribute on
        # IAddress, similar to the way IUser does it.
        #
        # Start by getting the IUser that controls this address.  For now, if
        # the address is not controlled by a user, return the empty set.
        # Later when we address the XXX comment, it will return some
        # memberships.  But really, it should not be legal to subscribe an
        # address to a mailing list that isn't controlled by a user -- maybe!
        user = getUtility(IUserManager).get_user(self._address.email)
        if user is None:
            return []
        return sorted((member for member in user.memberships.members
                       if member.address == self._address),
                      key=membership_key)
