import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NS = {'u': 'urn:schemas-microsoft-com:unattend'}


class AccountTests(unittest.TestCase):
    def configure(self, username, password):
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / 'answer.xml'
            result = subprocess.run(
                ['python3', str(ROOT / 'scripts/configure-answer.py'),
                 str(ROOT / 'autounattend.xml'), str(destination), username],
                input=password, text=True, capture_output=True)
            content = destination.read_text() if destination.exists() else None
            return result, content

    def test_rr_is_declared_once_as_administrator(self):
        result, content = self.configure('rr', 'test-only-password')
        self.assertEqual(result.returncode, 0, result.stderr)
        root = ET.fromstring(content)
        accounts = root.findall('.//u:LocalAccount', NS)
        self.assertEqual(len(accounts), 1)
        self.assertEqual(accounts[0].find('u:Name', NS).text, 'rr')
        self.assertEqual(accounts[0].find('u:Group', NS).text, 'Administrators')
        self.assertEqual(accounts[0].find('u:Password/u:Value', NS).text, 'test-only-password')
        self.assertNotIn('CYBERWIN_ADMIN_', content)
        self.assertNotIn('test-only-password', result.stdout + result.stderr)

    def test_xml_password_characters_survive(self):
        password = 'fixture<&>"apostrophe\''
        result, content = self.configure('RR.Operator', password)
        self.assertEqual(result.returncode, 0, result.stderr)
        root = ET.fromstring(content)
        self.assertEqual(root.find('.//u:LocalAccount/u:Name', NS).text, 'RR.Operator')
        self.assertEqual(root.find('.//u:Password/u:Value', NS).text, password)

    def test_invalid_or_reserved_names_fail_without_an_answer(self):
        for name in ('Administrator', 'GUEST', 'rr\\admin', 'bad name', 'x'*21, '../rr'):
            with self.subTest(name=name):
                result, content = self.configure(name, 'test-only-password')
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(content)

    def test_empty_or_control_character_password_fails(self):
        for password in ('', 'one\ntwo', 'one\x00two'):
            result, content = self.configure('rr', password)
            self.assertNotEqual(result.returncode, 0)
            self.assertIsNone(content)


if __name__ == '__main__':
    unittest.main()
