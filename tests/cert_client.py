import unittest
from argparse import Namespace

import responses
from certbot.configuration import NamespaceConfig
from certbot.errors import PluginError
from responses import matchers

from certbot_dns_porkbun.cert.client import Authenticator


class TestCertClient(unittest.TestCase):
    @responses.activate
    def test_valid_auth(self):
        responses.post(
            url="https://api.porkbun.com/api/json/v3/dns/create/example.com",
            json={"status": "SUCCESS", "id": "123456789"},
            match=[
                matchers.json_params_matcher(
                    {
                        "apikey": "key",
                        "content": "ABCDEF",
                        "name": "_acme-challenge",
                        "prio": None,
                        "secretapikey": "secret",
                        "ttl": 300,
                        "type": "TXT",
                    }
                )
            ],
        )
        responses.add_passthru("https://publicsuffix.org/list/public_suffix_list.dat")
        responses.add_passthru(
            "https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat"
        )

        namespace = Namespace(
            porkbun_key="key",
            porkbun_secret="secret",
            porkbun_propagation_seconds=600,
            config_dir="config_dir",
            work_dir="work_dir",
            logs_dir="logs_dir",
            http01_port=80,
            https_port=443,
            domains=["example.com"],
        )
        config = NamespaceConfig(namespace)

        authenticator = Authenticator(config, name="porkbun")

        authenticator._perform(
            domain="example.com", validation_name="", validation="ABCDEF"
        )

    @responses.activate
    def test_invalid_auth(self):
        responses.post(
            url="https://api.porkbun.com/api/json/v3/dns/create/example.com",
            json={"status": "ERROR", "message": "Invalid API key"},
            match=[
                matchers.json_params_matcher(
                    {
                        "apikey": "key",
                        "content": "ABCDEF",
                        "name": "_acme-challenge",
                        "prio": None,
                        "secretapikey": "secret",
                        "ttl": 300,
                        "type": "TXT",
                    }
                )
            ],
        )
        responses.add_passthru("https://publicsuffix.org/list/public_suffix_list.dat")
        responses.add_passthru(
            "https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat"
        )

        namespace = Namespace(
            porkbun_key="key",
            porkbun_secret="wrong",
            porkbun_propagation_seconds=600,
            config_dir="config_dir",
            work_dir="work_dir",
            logs_dir="logs_dir",
            http01_port=80,
            https_port=443,
            domains=["example.com"],
        )
        config = NamespaceConfig(namespace)

        authenticator = Authenticator(config, name="porkbun")

        with self.assertRaises(PluginError):
            authenticator._perform(
                domain="example.com", validation_name="", validation="ABCDEF"
            )

    @responses.activate
    def test_multi_level_domain(self):
        responses.post(
            url="https://api.porkbun.com/api/json/v3/dns/create/example.co.uk",
            json={"status": "SUCCESS", "id": "123456789"},
            match=[
                matchers.json_params_matcher(
                    {
                        "apikey": "key",
                        "secretapikey": "secret",
                        "content": "ABCDEF",
                        "name": "_acme-challenge",
                        "prio": None,
                        "ttl": 300,
                        "type": "TXT",
                    }
                )
            ],
        )
        responses.add_passthru("https://publicsuffix.org/list/public_suffix_list.dat")
        responses.add_passthru(
            "https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat"
        )

        namespace = Namespace(
            porkbun_key="key",
            porkbun_secret="secret",
            porkbun_propagation_seconds=600,
            config_dir="config_dir",
            work_dir="work_dir",
            logs_dir="logs_dir",
            http01_port=80,
            https_port=443,
            domains=["example.co.uk"],
        )
        config = NamespaceConfig(namespace)

        authenticator = Authenticator(config, name="porkbun")

        authenticator._perform(
            domain="example.co.uk", validation_name="", validation="ABCDEF"
        )

    @responses.activate
    def test_cleanup(self):
        responses.post(
            url="https://api.porkbun.com/api/json/v3/dns/delete/example.com/123456789",
            json={"status": "SUCCESS", "id": "123456789"},
            match=[
                matchers.json_params_matcher(
                    {
                        "apikey": "key",
                        "secretapikey": "secret",
                    }
                )
            ],
        )
        responses.add_passthru("https://publicsuffix.org/list/public_suffix_list.dat")
        responses.add_passthru(
            "https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat"
        )

        namespace = Namespace(
            porkbun_key="key",
            porkbun_secret="secret",
            porkbun_propagation_seconds=600,
            config_dir="config_dir",
            work_dir="work_dir",
            logs_dir="logs_dir",
            http01_port=80,
            https_port=443,
            domains=["example.com"],
        )
        config = NamespaceConfig(namespace)

        authenticator = Authenticator(config, name="porkbun")
        authenticator._validation_to_record["ABCDEF"] = (
            123456789,
            "example.com",
        )

        authenticator._cleanup(
            domain="example.com", validation_name="", validation="ABCDEF"
        )