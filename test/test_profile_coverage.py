import tempfile
import unittest
from pathlib import Path

from profile_coverage import read_profile, write_lcov


class ProfileCoverageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.source = self.root / 'autoload' / 'space dir' / 'sample.vim'
        self.source.parent.mkdir(parents=True)
        self.lines = ['" comment', 'function! Sample() abort',
                      '    let value = join(["a",', '        \\ "b"])',
                      '    if value ==# "ab"', '        return value',
                      '    else', '        return "unused"', '    endif',
                      'endfunction', 'call Sample()']
        self.source.write_text('\n'.join(self.lines), encoding='utf-8')

    @staticmethod
    def row(text, count=0):
        return (f'{count:5d}' if count else '     ') + ' ' * 23 + text

    def profile(self, name='profile.txt', hits=2, location_separator=':'):
        rows = ['SCRIPT  ' + str(self.source), 'Sourced 1 time',
                'Total time: 0.1', ' Self time: 0.1', '',
                'count  total (s)   self (s)']
        rows += [self.row(text, 1 if number in (2, 11) else 0)
                 for number, text in enumerate(self.lines, 1)]
        rows += ['', 'FUNCTION  Sample()',
                 f'    Defined: {self.source}{location_separator}2',
                 f'Called {hits} times', 'Total time: 0.1', ' Self time: 0.1', '',
                 'count  total (s)   self (s)']
        rows += [self.row('    let value = join(["a", "b"])', hits),
                 self.row(self.lines[4], hits), self.row(self.lines[5], hits),
                 self.row(self.lines[6]), self.row(self.lines[7]), self.row(self.lines[8])]
        rows += ['', 'FUNCTIONS SORTED ON TOTAL TIME', 'count total (s) self (s) function', '']
        path = self.root / name
        path.write_text('\n'.join(rows), encoding='utf-8')
        return path

    def test_functions_continuations_and_unexecuted_lines(self):
        coverage = read_profile(self.profile(), self.root)[self.source]
        self.assertEqual({2: 1, 3: 2, 4: 2, 5: 2, 6: 2, 7: 0, 8: 0, 11: 1}, coverage)

    def test_merges_suites_and_writes_relative_lcov_paths(self):
        output = self.root / 'coverage.info'
        write_lcov([self.profile(), self.profile('second.txt', 3, ' line ')], self.root, output)
        self.assertEqual('SF:autoload/space dir/sample.vim\n'
                         'DA:2,2\nDA:3,5\nDA:4,5\nDA:5,5\nDA:6,5\nDA:7,0\nDA:8,0\nDA:11,2\n'
                         'LF:8\nLH:6\nend_of_record\n', output.read_text(encoding='utf-8'))

    def test_vim_nanosecond_timing_columns(self):
        profile = self.profile()
        contents = profile.read_text(encoding='utf-8').splitlines()
        expanded = []
        for line in contents:
            if line[:5].strip().isdigit():
                line = line[:5] + '   0.000045000   0.000019000 ' + line[28:]
            expanded.append(line)
        profile.write_text('\n'.join(expanded), encoding='utf-8')
        coverage = read_profile(profile, self.root)[self.source]
        self.assertEqual(2, coverage[3])
        self.assertEqual(2, coverage[4])
        self.assertEqual(0, coverage[8])

    def test_never_sourced_plugin_files_remain_uncovered(self):
        source = self.root / 'autoload' / 'unused.vim'
        source.write_text('" comment\nlet unused = 1\n', encoding='utf-8')
        output = self.root / 'coverage.info'
        write_lcov([self.profile()], self.root, output)
        self.assertIn('SF:autoload/unused.vim\nDA:2,0\nLF:1\nLH:0\nend_of_record\n',
                      output.read_text(encoding='utf-8'))

    def test_excludes_test_and_dependency_scripts(self):
        profile = self.profile()
        contents = profile.read_text(encoding='utf-8')
        for source in [self.root / 'test' / 'fixture.vim', self.root.parent / 'external.vim']:
            profile.write_text(contents.replace(str(self.source), str(source)), encoding='utf-8')
            self.assertEqual({}, read_profile(profile, self.root))

    def test_missing_and_empty_profiles_fail(self):
        with self.assertRaises(FileNotFoundError):
            read_profile(self.root / 'missing', self.root)
        with self.assertRaisesRegex(ValueError, 'No Vim coverage'):
            write_lcov([], self.root, self.root / 'coverage.info')

    def test_mismatched_function_source_fails(self):
        profile = self.profile()
        profile.write_text(profile.read_text(encoding='utf-8').replace(
            '    let value = join(["a", "b"])', '    let value = "wrong"'), encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'Function/source mismatch'):
            read_profile(profile, self.root)

    def test_generated_popup_lambda_does_not_map_to_call_site(self):
        profile = self.profile()
        contents = profile.read_text(encoding='utf-8')
        contents += ('\nFUNCTION  <lambda>1()\n'
                     f'    Defined: {self.source}:3\n'
                     'Called 0 times\nTotal time: 0.000000000\n Self time: 0.000000000\n\n'
                     'count     total (s)      self (s)\n'
                     + self.row('      return popup_close(1001)') + '\n\n')
        profile.write_text(contents, encoding='utf-8')
        coverage = read_profile(profile, self.root)[self.source]
        self.assertEqual({2: 1, 3: 2, 4: 2, 5: 2, 6: 2, 7: 0, 8: 0, 11: 1}, coverage)

    def test_function_without_source_location_fails(self):
        profile = self.profile()
        contents = '\n'.join(line for line in profile.read_text(encoding='utf-8').splitlines()
                             if not line.startswith('    Defined:'))
        profile.write_text(contents, encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'source locations'):
            read_profile(profile, self.root)
