from glob import glob
import argparse
import os
import sys
import re
import shutil
import platform
import subprocess

def remove_test_files(root_dir):
    cmake_proj_dir = os.path.join(root_dir, 'cmake projects', 'test proj')
    for folder in ['cmake-build-Release', 'cmake-build-Debug', 'cmake-build-RelWithDebInfo', 'cmake-build-MinSizeRel', 'cmake-build']:
        shutil.rmtree(os.path.join(cmake_proj_dir, folder), ignore_errors=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='cmake4vim local test runner')
    parser.add_argument('-e', '--editor', type=str, default='vim', help='Editor: vim, nvim')
    parser.add_argument('-t', '--tests', type=str, default='', help='Test files Example: test1.vader,test2.vader')
    parser.add_argument('-o', '--out_dir', type=str, default='', help='Directory with profiling results')
    parser.add_argument('-p', '--profile', action='store_true', help='Enable profiling')

    args = parser.parse_args()

    # prepare environment
    current_dir = os.path.abspath(os.path.dirname(os.path.realpath(__file__)))
    test_dir = os.path.join(current_dir, 'tests')
    home_dir = os.path.join(current_dir, 'tmp')
    if args.out_dir:
        out_dir = os.path.abspath(args.out_dir)
    else:
        out_dir = os.path.join(current_dir, 'tmp', 'out')
    if not os.path.exists(out_dir) and args.profile:
        os.makedirs(out_dir)
    os_name = platform.system()
    cmake_version = re.search(r'cmake\sversion\s*([\d.]+)', subprocess.run(['cmake', '--version'], stdout=subprocess.PIPE).stdout.decode('utf-8')).group(1)
    os.chdir(current_dir)

    os.environ['HOME'] = home_dir

    # Clone vader and dispatch
    subprocess.run(['git', 'clone', '--depth', '1', 'https://github.com/junegunn/vader.vim.git', home_dir + '/.vim/plugged/vader.vim'])
    subprocess.run(['git', 'clone', '--depth', '1', 'https://github.com/tpope/vim-dispatch.git', home_dir + '/.vim/plugged/vim-dispatch'])
    # get test cases
    if args.tests != '':
        test_cases = args.tests.split(',')
    else:
        test_cases = [y for x in os.walk(test_dir) for y in glob(os.path.join(x[0], '*.vader'))]

    ret_code = 0
    for test_path in test_cases:
        test_case = os.path.basename(test_path).split('.')[0]
        if args.profile:
            os.environ['VIM_PROFILE_FILE'] = os.path.join(home_dir, 'provile_' + test_case + '_' + args.editor + '_cmake' + cmake_version + '_' + os_name + '.txt')
        remove_test_files(current_dir)
        res = subprocess.run([args.editor, '-Es', '-Nu', 'vimrc', '+Vader! -q ' + test_path])
        remove_test_files(current_dir)

        if args.profile:
            os.chdir(os.path.join(current_dir, '..'))
            subprocess.run([sys.executable, '-m', 'covimerage', 'write_coverage', os.environ['VIM_PROFILE_FILE']])
            subprocess.run([sys.executable, '-m', 'coverage', 'xml'])
            os.rename('coverage.xml', os.path.join(out_dir, 'provile_' + test_case + '_' + args.editor + '_cmake' + cmake_version + '_' + os_name + '.xml'))
            os.chdir(current_dir)

        if res.returncode != 0:
            ret_code = res.returncode

    exit(ret_code)
