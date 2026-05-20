import sys
import os

# Insert sga_web into the path so its internal imports work
sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "sga_web"))
)

import pytest
from sga_web.app import create_app


@pytest.fixture
def app():
    # Create the app with the TestingConfig
    app = create_app(config_name="testing")

    # Other setup can go here

    yield app

    # Clean up / teardown can go here


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def runner(app):
    return app.test_cli_runner()
