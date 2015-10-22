<?php
    namespace UBNT\App\Api;

    /**
     * The EdgeOS API is used to pass through all commands to the router
     * using UNIX domain sockets. This is used in conjunction with the
     * UI Javascript to get and set config data in bulk. Any set or
     * delete commands will immediately be committed and saved by the
     * daemon and may take several seconds to return results. Additionally
     * each set and delete request should also contain the get data to
     * be returned so differences can be checked and validated.
     *
     * Any request that returns success: 0/1 (eg. auth or ping) will have
     * the generic API success result (from the controller) overwritten with
     * the result of the request itself.
     *
     * GET:  /api/edge/get.json                              gets a pre-defined config structure
     * GET:  /api/edge/partial.json                          gets a partial set of the config structure
     * GET:  /api/edge/data.json                             gets a single set of non-config data
     * POST: /api/edge/set.json                              sets the config data and automatically returns the new config
     * POST: /api/edge/delete.json                           deletes the config data and automatically returns the new config
     * POST: /api/edge/batch.json                            sets and deletes the config data and returns the new config
     * GET:  /api/edge/heartbeat.json                        makes sure the backend daemon is alive and the session is active
     * GET:  /api/edge/ping.json?anon=1                      makes sure the backend daemon is alive
     *
     * POST: /api/edge/operation/reboot.json                 reboots the router
     * POST: /api/edge/operation/shutdown.json               shuts down the router
     * POST: /api/edge/operation/reset-default-config.json   resets the router to default config
     * POST: /api/edge/operation/renew-dhcp.json             renews the DHCP lease
     * POST: /api/edge/operation/release-dhcp.json           releases the DHCP lease
     *
     * GET:  /api/edge/config/save.json                      returns a tar file of the current config system
     * POST: /api/edge/config/restore.json                   accepts a posted config file to replace the current one
     * POST: /api/edge/config/upgrade.json                   accepts a posted file to update the router's system
     * POST: /api/edge/auth.json                             authenticate a user
     *
     * POST: /api/edge/setup.json                            runs the config setup from the wizard
     * POST: /api/edge/feature.json                          runs the feature setup from the wizard
     *
     * GET: /api/edge/getcfg.json                            gets defs and values of all children of the current node
     *
     * @package ubnt
     * @subpackage app
     * @copyright 2012 Ubiquiti Networks, Inc. All rights reserved.
     */
    class Edge extends Api {

        protected $sid;
        protected $authenticated;
        protected $writable;


        /**
         * Determines the config structure to pass to the daemon and hands
         * it off to the request method. Also converts raw posted JSON into
         * an array.
         *
         * @access public
         * @return void
         */
        public function handle() {
            $this->sid = session_id();
            $this->authenticated = \UBNT::auth()->isAuthenticated();
            $this->writable = \UBNT::auth()->getLevel() == 'admin';
            $action = str_replace('.'.$this->router->getExtension(), '', $this->router->getSegment(2));

            if (!$this->writable && !in_array($action, array('auth', 'get', 'data', 'ping', 'heartbeat', 'feature'))) {
                throw new \Api_Exception(\UBNT::language()->translate('Permission denied'), 403);
            }

            if ($this->router->getMethod() == 'POST' && $this->router->getRawData()) {
                $this->router->setVariables(json_decode($this->router->getRawData(), true));
            }

            //close the session to prevent the locking out of other concurrent calls
            if (!$this->internal) {
                if (!($this->router->getSegment(2) == 'config' && str_replace('.'.$this->router->getExtension(), '', $this->router->getSegment(3)) == 'save')) {
                    session_write_close();
                }
            }

            switch ($action) {
                case 'auth':
                    $structure = $this->authStructure($this->router->getVariable('username'), $this->router->getVariable('password'));
                    $open = true;
                    break;

                case 'get':
                    $structure = $this->buildStructure();
                    break;

                case 'partial':
                    $structure['GET'] = json_decode($this->router->getVariable('struct'), true);
                    break;

                case 'data':
                    $structure['GETDATA'] = $this->router->getVariable('data');
                    break;

                case 'set':
                    $structure['SET'] = $this->router->getVariables();
                    $structure['GET'] = $this->parentStructure($structure['SET']);
                    break;

                case 'delete':
                    $structure['DELETE'] = $this->router->getVariables();
                    $structure['GET'] = $this->parentStructure($structure['DELETE']);
                    break;

                case 'batch':
                    $structure = $this->router->getVariables();

                    if (empty($structure['GET'])) {
                        $structure['GET'] = !empty($structure['SET']) ? $this->parentStructure($structure['SET']) : array();
                        empty($structure['DELETE']) || $structure['GET'] = $this->mergeStructure($structure['GET'], $this->parentStructure($structure['DELETE']));

                        /*
                        $changes = !empty($structure['SET']) ? $structure['SET'] : array();
                        empty($structure['DELETE']) || $changes = $this->mergeStructure($changes, $structure['DELETE']);
                        $structure['GET'] = $this->parentStructure($changes);
                        */
                    }
                    break;

                case 'getcfg':
                    $structure['GETCFG'] = $this->router->getVariable('node');
                    break;

                case 'setup':
                    $structure['SETUP'] = $this->router->getVariable('data');
                    break;

                case 'feature':
                    if (($data = $this->router->getVariable('data')) && $this->writable || $data['action'] == 'load') {
                        $structure['FEATURE'] = $data;
                    } else {
                        throw new \Api_Exception(\UBNT::language()->translate('Permission denied'), 403);
                    }
                    break;

                case 'ping':
                    return $this->handleHeartbeat(false);

                case 'heartbeat':
                    return $this->handleHeartbeat(true);

                case 'config':
                    return $this->handleConfig();

                case 'upgrade':
                    return $this->handleUpgrade();

                case 'operation':
                    return $this->handleOperation();

                case 'pritunl-add':
                    if ($this->authenticated) {
                        $confDir = '/config/pritunl';
                        $confId = $this->router->getVariable('id');
                        $confId = preg_replace('/[^a-zA-Z0-9]+/', '', $confId);
                        $caData = $this->router->getVariable('ca');
                        $caPath = sprintf('%s/%s.ca', $confDir, $confId);
                        $certData = $this->router->getVariable('cert');
                        $certPath = sprintf('%s/%s.cert', $confDir, $confId);
                        $keyData = $this->router->getVariable('key');
                        $keyPath = sprintf('%s/%s.key', $confDir, $confId);
                        $tlsData = $this->router->getVariable('tls-auth');
                        $tlsPath = sprintf('%s/%s.tls', $confDir, $confId);

                        $items = array(
                            $caPath => $caData,
                            $certPath => $certData,
                            $keyPath => $keyData,
                            $tlsPath => $tlsData,
                        );

                        foreach ($items as $path => $data) {
                            if ($data != null) {
                                $file = fopen($path, 'w');
                                if (!$file) {
                                    throw new \Api_Exception(
                                        'Failed to open ' + $path, 500);
                                }
                                fwrite($file, $data);
                                if (!fclose($file)) {
                                    throw new \Api_Exception(
                                        'Failed to write ' + $path, 500);
                                }
                            }
                        }
                    } else {
                        throw new \Api_Exception('Permission denied', 403);
                    }
                    break;

                case 'pritunl-remove':
                    if ($this->authenticated) {
                        $confDir = '/config/pritunl';
                        $confId = $this->router->getVariable('id');
                        $confId = preg_replace('/[^a-zA-Z0-9]+/', '', $confId);
                        $caPath = sprintf('%s/%s.ca', $confDir, $confId);
                        $certPath = sprintf('%s/%s.cert', $confDir, $confId);
                        $keyPath = sprintf('%s/%s.key', $confDir, $confId);
                        $tlsPath = sprintf('%s/%s.tls', $confDir, $confId);

                        unlink($caPath);
                        unlink($certPath);
                        unlink($keyPath);
                        unlink($tlsPath);
                    } else {
                        throw new \Api_Exception('Permission denied', 403);
                    }
                    break;

                default:
                    throw new \Api_Exception(\UBNT::language()->translate('Invalid API method'), 404);
            }

            $this->request($structure, !empty($open));
        }


        /**
         * Special handling to combine the ping request and the
         * session validation.
         *
         * @access protected
         * @param boolean $session Whether to check the session
         * @return void
         */
        protected function handleHeartbeat($session) {
            $this->request(array('PING' => null), true);
            $this->result = array(
                'success' => true,
                'PING' => $this->result['success'] ? true : false
            );

            if ($session) {
                $this->result['SESSION'] = $this->authenticated;
            }
        }


        /**
         * Special handling for the config requests.
         *
         * @access protected
         * @return void
         */
        protected function handleConfig() {
            switch ($action = str_replace('.'.$this->router->getExtension(), '', $this->router->getSegment(3))) {
                case 'save':
                    $structure['CONFIG'] = array(
                        'action' => 'save'
                    );
                    break;

                case 'restore':
                    $structure['CONFIG'] = array(
                        'action' => 'restore',
                        'path' => $this->getFilepath(!empty($_GET['qqfile']) ? $_GET['qqfile'] : null)
                    );
                    break;

                default:
                    throw new \Api_Exception(\UBNT::language()->translate('Invalid API method'), 404);
            }

            $this->request($structure);

            switch ($action) {
                case 'save':
                    if (!empty($this->result['CONFIG']['success']) && !empty($this->result['CONFIG']['path'])) {
                        $_SESSION['_cfgPath'] = $this->result['CONFIG']['path'];
                    } else {
                        throw new \Api_Exception(\UBNT::language()->translate('Unable to build config file (%s)', !empty($this->result['CONFIG']['error']) ? $this->result['CONFIG']['error'] : 'Unspecified error'), 500);
                    }
                    break;

                case 'restore':
                    if (empty($this->result['CONFIG']['success'])) {
                        throw new \Api_Exception(\UBNT::language()->translate('Unable to restore config (%s)', !empty($this->result['CONFIG']['error']) ? $this->result['CONFIG']['error'] : 'Unspecified error'), 500);
                    }
                    break;
            }
        }


        /**
         * Special handling for the system upgrade requests.
         *
         * @access protected
         * @return void
         */
        protected function handleUpgrade() {
            $structure['UPGRADE'] = array(
                'path' => $this->getFilepath(!empty($_GET['qqfile']) ? $_GET['qqfile'] : null)
            );

            $this->request($structure);

            if (empty($this->result['UPGRADE']['success'])) {
                throw new \Api_Exception(\UBNT::language()->translate('Unable to upgrade system (%s)', !empty($this->result['UPGRADE']['error']) ? $this->result['UPGRADE']['error'] : 'Unspecified error'), 500);
            }
        }


        /**
         * Special handling the for the operation requests.
         *
         * @access protected
         * @return void
         */
        protected function handleOperation() {
            if ($operation = str_replace('.'.$this->router->getExtension(), '', $this->router->getSegment(3))) {
                $structure['OPERATION'] = array(
                    'op' => $operation
                );

                if ($data = $this->router->getVariables()) {
                    $structure['OPERATION'] = array_merge($data, $structure['OPERATION']);
                }

                $this->request($structure);
            } else {
                throw new \Api_Exception(\UBNT::language()->translate('Invalid API method'), 404);
            }

            if (empty($this->result['OPERATION']['success'])) {
                throw new \Api_Exception(\UBNT::language()->translate('Unable to perform %s operation (%s)', $operation, !empty($this->result['OPERATION']['error']) ? $this->result['OPERATION']['error'] : 'Unspecified error'), 500);
            }
        }


        /**
         * Empties out the values of the array array passed. Useful for
         * converting an array into GET format.
         *
         * @access protected
         * @param array $array The array to empty
         * @return array The emptied array
         */
        protected function emptyStructure($array) {
            array_walk_recursive($array, function(&$item, $key) {
                if ($item && !is_array($item)) {
                    $item = null;
                }
            });
            return $array;
        }


        /**
         * Returns only the parent arrays and filters out all key/value
         * data. Useful for converting an array into GET format without
         * trying to retrieve nodes that have been deleted.
         *
         * @access protected
         * @param array $array The array to filter
         * @return array The parent structure
         */
        protected function parentStructure($array) {
            class_exists('\UBNT\App\Recursion', false) || \UBNT::loader()->loadApp('recursion');
            return \UBNT\App\Recursion::filter($array, function($value) {
                if ($return = is_array($value)) {
                    foreach ($value as $child) {
                        if (!is_array($child)) {
                            $return = false;
                            break;
                        }
                    }
                }
                return $return;
            });
        }


        /**
         * Builds the default config structure to pass through to the
         * daemon. The default structure is for GET only.
         *
         * @access protected
         * @return array The default structure to send to the daemon
         */
        protected function buildStructure() {
            return array(
                'GET' => array(
                    'firewall' => null,
                    'interfaces' => null,
                    'service' => null,
                    'system' => null,
                    'vpn' => null,
                    'protocols' => null
                )
            );
        }


        /**
         * Returns the request structure to authenticate a user with the
         * system daemon.
         *
         * @access protected
         * @param string $username The username to authenticate
         * @param string $password The unencrypted password
         * @return array The authentication structure to send to the daemon
         */
        protected function authStructure($username, $password) {
            return array(
                'AUTH' => array(
                    'username' => $username,
                    'password' => $password
                )
            );
        }


        /**
         * Merges 2 or more arrays with special handling to merge numerically
         * keyed arrays by converting them to and from string keys. This should
         * be passed 2 or more arrays.
         *
         * @access protected
         * @return array The merged structure
         */
        protected function mergeStructure() {
            class_exists('\UBNT\App\Recursion', false) || \UBNT::loader()->loadApp('recursion');
            return forward_static_call_array(array('\UBNT\App\Recursion', 'merge'), func_get_args());
        }

        /**
         * Filters the input to remove any sensitive data for
         * non-admin users.
         *
         * @access protected
         * @param array $input An array of data to filter
         * @return array The filtered result
         */
        protected function filter($input) {
            if (!$this->writable) {
                array_walk_recursive($input, function(&$item, $key) {
                    if (preg_match('/(passphrase|password|pre-shared-secret|key)/', $key)) {
                        $item = is_array($item) ? null : '*********';
                    }
                });
            }
            return $input;
        }

        /**
         * Sends a request to the daemon. This runs in blocking mode which
         * means it will wait for a response. Each request should be preceded
         * by a session ID and the length of the request. The daemon doesn't
         * recognize NULL data so this replaces nulls with "''" before it
         * sends the data and replaces any '' in the result with null.
         *
         * @access protected
         * @param array $structure The config structure to send to the daemon
         * @param boolean $open Whether to allow unauthenticated users to make the request
         * @param string $session Whether to pass the session in the request
         * @return void
         */
        protected function request(array $structure, $open = false, $session = true) {
            if ($this->authenticated || $open) {
                $config = \UBNT::config()->get('edge');

                array_walk_recursive($structure, function(&$item, $key) {
                    if (is_null($item)) {
                        $item = "''";
                    }
                });

                $session && $structure['SESSION_ID'] = $this->sid;
                $structure = json_encode($structure);
                $structure = preg_replace('/,?"__FORCE_ASSOC":true/', '', $structure);
                $buffer = strlen($structure) . "\n" . $structure;

                try {
                    \UBNT::loader()->loadCore('socket');
                    $socket = \UBNT\Core\Socket::factory("\n")
                            ->create(AF_UNIX, SOCK_STREAM, 0)
                            ->connect($config->server->address)
                            ->setBlocking()
                    ;

                    if (($legacy = $config->get('legacy')) && $legacy->sessions) {
                        $socket->write($this->sid, false);
                    }

                    $result = $socket->write($buffer, false)->read(null, 0, "\n");
                    $socket->close();

                    if ($decoded = json_decode($result, true)) {
                        array_walk_recursive($decoded, function(&$item, $key) {
                            if ($item == "''") {
                                $item = null;
                            }
                        });

                        $this->success = true;
                        $this->result = $this->filter($decoded);
                    } else {
                        throw new \Socket_Exception('Invalid result data: ' . $result);
                    }
                } catch (\Socket_Exception $exception) {
                    throw new \Api_Exception($exception->getMessage(), 500, $exception);
                }
            } else {
                throw new \Api_Exception('Permission denied', 403);
            }
        }
    }
