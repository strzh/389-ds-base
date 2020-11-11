# --- BEGIN COPYRIGHT BLOCK ---
# Copyright (C) 2019 Red Hat, Inc.
# All rights reserved.
#
# License: GPL (version 3 or any later version).
# See LICENSE for details.
# --- END COPYRIGHT BLOCK ---

import ldap
import logging
import pytest
import os
from lib389.schema import Schema
from lib389.config import Config
from lib389.idm.user import UserAccounts
from lib389.idm.group import Groups
from lib389._constants import DEFAULT_SUFFIX
from lib389.topologies import log, topology_st as topo

pytestmark = pytest.mark.tier0

log = log.getChild(__name__)


@pytest.fixture(scope="function")
def validate_syntax_off(topo, request):
    config = Config(topo.standalone)
    config.replace("nsslapd-syntaxcheck", "off")

    def fin():
        config.replace("nsslapd-syntaxcheck", "on")
    request.addfinalizer(fin)


def test_valid(topo, validate_syntax_off):
    """Test syntax-validate task with valid entries

    :id: ec402a5b-bfb1-494d-b751-71b0d31a4d83
    :setup: Standalone instance
    :steps:
        1. Set nsslapd-syntaxcheck to off
        2. Clean error log
        3. Run syntax validate task
        4. Assert that there are no errors in the error log
        5. Set nsslapd-syntaxcheck to on
    :expectedresults:
        1. It should succeed
        2. It should succeed
        3. It should succeed
        4. It should succeed
        5. It should succeed
    """

    inst = topo.standalone

    log.info('Clean the error log')
    inst.deleteErrorLogs()

    schema = Schema(inst)
    log.info('Attempting to add task entry...')
    validate_task = schema.validate_syntax(DEFAULT_SUFFIX)
    validate_task.wait()
    exitcode = validate_task.get_exit_code()
    assert exitcode == 0
    error_lines = inst.ds_error_log.match('.*Found 0 invalid entries.*')
    assert (len(error_lines) == 1)
    log.info('Found 0 invalid entries - Success')


def test_invalid_uidnumber(topo, validate_syntax_off):
    """Test syntax-validate task with invalid uidNumber attribute value

    :id: 30fdcae6-ffa6-4ec4-8da9-6fb138fc1828
    :setup: Standalone instance
    :steps:
        1. Set nsslapd-syntaxcheck to off
        2. Clean error log
        3. Add a user with uidNumber attribute set to an invalid value (string)
        4. Run syntax validate task
        5. Assert that there is corresponding error in the error log
        6. Set nsslapd-syntaxcheck to on
    :expectedresults:
        1. It should succeed
        2. It should succeed
        3. It should succeed
        4. It should succeed
        5. It should succeed
        6. It should succeed
    """

    inst = topo.standalone

    log.info('Clean the error log')
    inst.deleteErrorLogs()

    users = UserAccounts(inst, DEFAULT_SUFFIX)
    users.create_test_user(uid="invalid_value")

    schema = Schema(inst)
    log.info('Attempting to add task entry...')
    validate_task = schema.validate_syntax(DEFAULT_SUFFIX)
    validate_task.wait()
    exitcode = validate_task.get_exit_code()
    assert exitcode == 0
    error_lines = inst.ds_error_log.match('.*uidNumber: value #0 invalid per syntax.*')
    assert (len(error_lines) == 1)
    log.info('Found an invalid entry with wrong uidNumber - Success')


def test_invalid_dn_syntax_crash(topo):
    """Add an entry with an escaped space, restart the server, and try to delete
    it.  In this case the DN is not correctly parsed and causes cache revert to
    to dereference a NULL pointer.  So the delete can fail as long as the server
    does not crash.

    :id: 62d87272-dfb8-4627-9ca1-dbe33082caf8
    :setup: Standalone Instance
    :steps:
        1. Add entry with leading escaped space in the RDN
        2. Restart the server so the entry is rebuilt from the database
        3. Delete the entry
        4. The server should still be running
    :expectedresults:
        1. Success
        2. Success
        3. Success
        4. Success
    """

    # Create group
    groups = Groups(topo.standalone, DEFAULT_SUFFIX)
    group = groups.create(properties={'cn': ' test'})

    # Restart the server
    topo.standalone.restart()

    # Delete group
    try:
        group.delete()
    except ldap.NO_SUCH_OBJECT:
        # This is okay in this case as we are only concerned about a crash
        pass

    # Make sure server is still running
    groups.list()


if __name__ == '__main__':
    # Run isolated
    # -s for DEBUG mode
    CURRENT_FILE = os.path.realpath(__file__)
    pytest.main("-s %s" % CURRENT_FILE)
