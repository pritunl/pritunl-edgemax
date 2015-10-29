import sys
import os
import json
import subprocess
import traceback
import pprint

CFG_CMD = '/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper'
CERT_DIR = '/config/pritunl'
DEV_NULL = open(os.devnull, 'w')

def parse_int(string):
    try:
        return int(string)
    except ValueError:
        pass

def send_error(error):
    print json.dumps({
        'success': '0',
        'error': error,
    })

def check_call_silent(args):
    return subprocess.check_call(args, stdout=DEV_NULL, stderr=DEV_NULL)

def check_output_silent(args):
    return subprocess.check_output(args, stderr=DEV_NULL)

def cmd_load():
    profiles = []
    for iface in get_interfaces():
        profiles.append({'interface': iface})

    print json.dumps({
        'success': '1',
        'data': {
            'profiles': profiles,
        },
    })

def cmd_apply():
    if not os.path.exists(CERT_DIR):
        os.makedirs(CERT_DIR)

    with open(sys.argv[3], 'r') as data_file:
        data = data_file.read()
    data = json.loads(data)

    cur_ifaces = set(get_interfaces())
    new_ifaces = set()
    mod_ifaces = set()

    profiles = []
    profile_links = []
    for profile in (data['profiles'] or []) + (data['new_profiles'] or []):
        iface = profile.get('interface') or profile.pop('new_interface')
        profile['interface'] = iface

        if not iface:
            continue

        iface_num = parse_int(iface[4:])
        if iface[:4] != 'vtun' or iface_num is None:
            send_error('Interface "%s" must be a valid ' % iface +
                'interface such as vtun0')
            return

        conf_link = profile.get('conf_link')
        if profile.get('conf') or conf_link:
            if iface in new_ifaces:
                send_error(('Interface "%s" cannot be ' +
                    'used for two profiles') % iface)
                return
            mod_ifaces.add(iface)
        new_ifaces.add(iface)

        if conf_link:
            profile_links.append((iface_num, conf_link))
        else:
            profiles.append(profile)

    for iface_num, conf_link in profile_links:
        conf_link = conf_link.replace('https', '')
        conf_link = conf_link.replace('http', '')
        conf_link = conf_link.replace('pritunl', '')

        for i, proto in enumerate(('https', 'http')):
            try:
                data = json.loads(check_output_silent([
                    'curl', '--insecure', proto+conf_link]))
                break
            except:
                if i == 1:
                    send_error('Failed to download profile link "%s"' % (
                        proto+conf_link))
                    return

        for i, conf_data in enumerate(data.values()):
            while True:
                iface = 'vtun%s' % iface_num
                if i == 0 or iface not in new_ifaces:
                    break
                iface_num += 1
            new_ifaces.add(iface)
            mod_ifaces.add(iface)

            profiles.append({
                'interface': iface,
                'conf': conf_data,
            })

    rem_ifaces = cur_ifaces - new_ifaces

    if rem_ifaces or mod_ifaces:
        check_call_silent([CFG_CMD, 'begin'])

        for iface in rem_ifaces | mod_ifaces:
            check_call_silent([CFG_CMD, 'delete',
                'interfaces', 'openvpn', iface])
            for ext in ('ca', 'cert', 'key', 'tls'):
                path = os.path.join(CERT_DIR, '%s.%s' % (iface, ext))
                if os.path.exists(path):
                    os.remove(path)

        for profile in profiles:
            iface = profile['interface']
            conf_data = profile.get('conf')

            if not conf_data:
                continue

            files, conf = parse_profile(iface, conf_data)
            cmds = get_commands(conf)

            for cmd in cmds:
                check_call_silent([CFG_CMD, 'set'] + cmd)

            for path, data in files.items():
                if data:
                    with open(path, 'w') as data_file:
                        data_file.write(data)

        check_call_silent([CFG_CMD, 'commit'])
        check_call_silent([CFG_CMD, 'save'])
        check_call_silent([CFG_CMD, 'end'])

    for iface_file in os.listdir(CERT_DIR):
        iface = iface_file.split('.')[0]
        if iface not in new_ifaces:
            try:
                os.remove(os.path.join(CERT_DIR, iface_file))
            except:
                pass

    print json.dumps({
        'success': '1'
    })

def get_interfaces():
    ifaces = check_output_silent(['cli-shell-api', 'listActiveNodes',
        'interfaces', 'openvpn'])
    return [x[1:-1] for x in ifaces.split()]

def parse_profile(iface, conf_data):
    block_type = None
    block_data = ''
    cipher = None
    keysize = None
    key_direction = None
    tls_auth = False
    file_prefix = os.path.join(CERT_DIR, '%s.' % iface)
    files = {
        file_prefix + 'tls': None,
    }
    conf = {
        'description': 'pritunl' + iface[4:],
        'mode': 'client',
        'openvpn-option': [
            '--setenv UV_PLATFORM edge',
        ],
        'tls': {
            'ca-cert-file': file_prefix + 'ca',
            'cert-file': file_prefix + 'cert',
            'key-file': file_prefix + 'key',
        },
    }

    for line in conf_data.splitlines():
        if not line or line[0] in ('#', ';'):
            continue

        if line[0] == '<':
            if line[1] == '/':
                if not block_type or not block_data:
                    raise ValueError('Invalid conf block')
                file_path = os.path.join(CERT_DIR,
                    '%s.%s' % (iface, block_type))
                files[file_path] = block_data
                block_type = None
                block_data = ''
            else:
                block_type = line[1:-1]
                if block_type == 'tls-auth':
                    tls_auth = True
                    block_type = 'tls'
            continue
        elif block_type:
            block_data += line + '\n'
            continue

        split = line.split(None, 1)
        key = split[0]
        if len(split) > 1:
            val = split[1]
        else:
            val = None

        if key == 'dev-type' and val == 'tap':
            conf['device-type'] = 'tap';
        elif key == 'remote':
            conf['remote-host'] = conf.get('remote-host', [])
            split = val.split()

            conf['remote-host'].append(split[0])
            if len(split) > 1:
                conf['remote-port'] = split[1]
            if len(split) > 2:
                conf['protocol'] = split[2]
        elif key == 'port':
            conf['remote-port'] = val
        elif key == 'proto':
            conf['protocol'] = val
        elif key == 'cipher':
            cipher = val
        elif key == 'keysize':
            keysize = val
        elif key == 'auth':
            conf['hash'] = val.lower()
        elif key == 'push-peer-info':
            conf['openvpn-option'].append('--' + key)
        elif key in (
                    'setenv',
                    'ping',
                    'ping-restart',
                    'hand-window',
                    'server-poll-timeout',
                    'reneg-sec',
                    'sndbuf',
                    'rcvbuf',
                    'remote-cert-tls',
                    'comp-lzo',
                ):
            conf['openvpn-option'].append('--%s %s' % (key, val))
        elif key == 'key-direction':
            key_direction = val

    if cipher:
        cipher_low = cipher.lower();
        if cipher_low == 'bf-cbc':
            if keysize == '256':
                conf['encryption'] = 'bf256'
            else:
                conf['encryption'] = 'bf128'
        elif cipher_low == 'aes-128-cbc':
            conf['encryption'] = 'aes128'
        elif cipher_low == 'aes-192-cbc':
            conf['encryption'] = 'aes192'
        elif cipher_low == 'aes-256-cbc':
            conf['encryption'] = 'aes256'
        elif cipher_low == 'des-cbc':
            conf['encryption'] = 'des'
        elif cipher_low == 'des-ede3-cbc':
            conf['encryption'] = '3des'
        else:
            if cipher:
                conf['openvpn-option'].append('--cipher ' + cipher)
            if keysize:
                conf['openvpn-option'].append('--keysize ' + keysize)

        if tls_auth:
            tls_opt = '--tls-auth %stls' % file_prefix
            if key_direction:
                tls_opt += ' ' + key_direction
            conf['openvpn-option'].append(tls_opt)

    conf = {
        'interfaces': {
            'openvpn': {
                iface: conf,
            },
        },
    }

    return files, conf

def get_commands(conf):
    cmds = []

    def parse_node(cmd, node):
        if isinstance(node, dict):
            for key, val in node.items():
                parse_node(cmd + [key], val)
        elif isinstance(node, list):
            for val in node:
                cmds.append(cmd + [val])
        else:
            cmds.append(cmd + [node])

    parse_node([], conf)

    return cmds

try:
    if sys.argv[2] == 'load':
        cmd_load()
    elif sys.argv[2] == 'apply':
        cmd_apply()
except:
    send_error(traceback.format_exc())
    raise
