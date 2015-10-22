import os

try:
    os.makedirs('build')
except:
    pass

script = open('pritunl-edgemax.sh').read()
pritunl = open('pritunl.js').read()
edge = open('edge.php').read()
footer = open('footer.php').read()

pritunl = pritunl.replace('\\', '\\\\')
pritunl = pritunl.replace('$', '\$')
edge = edge.replace('\\', '\\\\')
edge = edge.replace('$', '\$')
footer = footer.replace('\\', '\\\\')
footer = footer.replace('$', '\$')

script = script.replace('#<pritunl>', pritunl.strip('\n'))
script = script.replace('#<edge>', edge.strip('\n'))
script = script.replace('#<footer>', footer.strip('\n'))

open('build/pritunl-edgemax.sh', 'w').write(script)
