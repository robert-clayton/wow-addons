"""Regression checks for catalog data loss and ATT sibling coordinate leakage."""
import contextlib
import csv
import importlib.util
import io
import json
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts/db' / filename)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class CatalogValidation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='collectionist-db-test-')
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)
        self.builder = module('catalog_builder', 'build-db.py')
        self.builder.DUMP = str(self.path / 'shipped.jsonl')
        self.builder.DB_PATH = str(self.path / 'test.db')
        self.emitter = module('catalog_emitter', 'emit-lua.py')
        self.emitter.OUT_DIR = str(self.path / 'emitted')

    def build(self, **fields):
        entry = dict(speciesID=3243, name='Pippin', petType=10, source='tradingpost')
        entry.update(fields)
        row = dict(__kind='collectible', module='pets', expansion='df', group={}, entry=entry)
        Path(self.builder.DUMP).write_text(json.dumps(row)+'\n')
        with contextlib.redirect_stdout(io.StringIO()):
            self.builder.main()
        con = sqlite3.connect(self.builder.DB_PATH)
        self.addCleanup(con.close)
        return con

    def test_guide_survives_database_and_emission(self):
        guide = 'First line.\nThen click "the object".'
        con = self.build(steps=guide)
        self.assertEqual(con.execute('SELECT steps FROM collectible').fetchone()[0], guide)
        self.emitter.emit(con)
        text = '\n'.join(p.read_text() for p in Path(self.emitter.OUT_DIR).glob('*.lua'))
        self.assertIn('steps = '+self.emitter.lua_str(guide), text)

    def test_invalid_pet_family_fails_instead_of_skipping(self):
        with self.assertRaises(SystemExit):
            self.build(petType=11)

    def test_invalid_waypoint_fails_instead_of_disappearing(self):
        with self.assertRaisesRegex(ValueError, 'Invalid primary waypoint'):
            self.build(waypoint=[1,.5,1.5,'Outside map'])

    def test_bad_integrity_view_is_fatal(self):
        with self.assertRaises(SystemExit):
            self.build(navigationOnly=True, score=10)

    def test_historical_waypoint_is_retained(self):
        con = self.build(unavailable=True, waypoint=[1,.5,.5,'Historical spawn'])
        self.assertEqual(con.execute('SELECT COUNT(*) FROM waypoint_on_unavailable').fetchone()[0], 1)
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(self.builder.validate_integrity(con), 0)

    def test_att_coordinates_cannot_leak_between_siblings(self):
        fixture = self.path / 'nodes.lua'
        fixture.write_text('''m(1,{g={
 n(11,{questID=21}),
 n(12,{awp=120100,coords={[1]={{25,50},{30,60}}},g={q(22,{})}}),
 n(13,{description="braces { and g={ inside text",g={q(23,{coords={[2]={{70,80}}}})}})
}})''')
        def extract(kind):
            result = subprocess.run(['luajit', str(ROOT/'scripts/extract-att-sources.lua'), kind, str(fixture)],
                                    check=True, text=True, capture_output=True)
            return {r['id']: r for r in csv.DictReader(io.StringIO(result.stdout))}
        rows = extract('self:n')
        self.assertEqual(rows['11']['coord_x'], '')
        self.assertEqual(rows['11']['awp_own'], '')
        self.assertEqual(rows['12']['coord_x'], '25')
        self.assertEqual(rows['12']['extra_spawns'], '30,60')
        self.assertEqual(rows['13']['coord_x'], '')
        self.assertEqual(extract('q')['22']['coord_y'], '50')
        self.assertEqual(extract('self:q')['22']['coord_y'], '')


if __name__ == '__main__':
    unittest.main()
