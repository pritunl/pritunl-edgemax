import os
import subprocess

SCRIPT = """#!/bin/bash
set -e

cat > /tmp/pritunl.py <<- EOM
%s
EOM

python2 /tmp/pritunl.py "$0" "$@"
"""

try:
    os.makedirs('build')
except:
    pass

pritunl = open('pritunl.py').read()
pritunl = pritunl.replace('\\', '\\\\')
pritunl = pritunl.replace('$', '\$')

open('build/wizard-run', 'w').write(SCRIPT % pritunl.strip('\n'))
subprocess.check_call(['cp', 'validator.json', 'build/validator.json'])
subprocess.check_call(['cp', 'wizard.html', 'build/wizard.html'])

os.chdir('build')

subprocess.check_call(['tar', 'cfz',
    '../pritunl-edgemax.tar.gz',
    'validator.json',
    'wizard.html',
    'wizard-run',
])

#subprocess.check_call(['rm', '-r', '../build'])
