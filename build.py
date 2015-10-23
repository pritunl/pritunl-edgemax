import os
import subprocess

try:
    os.makedirs('build')
except:
    pass

script = open('wizard-run').read()
pritunl = open('pritunl.py').read()

pritunl = pritunl.replace('\\', '\\\\')
pritunl = pritunl.replace('$', '\$')

script = script.replace('#<script>', pritunl.strip('\n'))

open('build/wizard-run', 'w').write(script)
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
