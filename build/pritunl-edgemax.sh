#!/bin/bash
set -e

if [ $EUID != 0 ]; then
    sudo sh "$0" "$@"
    exit $?
fi

BUILD_NUM=`ls /var/www/htdocs/lib | sort -n | tail -1`
PROFILES_PATH="/config/pritunl"
LIB_DIR="/var/www/htdocs/lib/"$BUILD_NUM"/js"
PRITUNL_PATH=$LIB_DIR"/pritunl.js"
EDGE_PATH="/var/www/php/app/classes/api/edge.php"
EDGE_BAK_PATH="/var/www/php/app/classes/api/edge.php.bak"
FOOTER_PATH="/var/www/php/app/views/common/footer.php"
FOOTER_BAK_PATH="/var/www/php/app/views/common/footer.php.bak"

if [ "$1" == "remove" ]; then
    echo "Removing Pritunl EdgeMax Addon..."

    if [ -d $PROFILES_PATH ]; then
        echo "Removing profiles directory ${PROFILES_PATH}..."
        rm -rf $PROFILES_PATH
    fi

    if [ -f $PRITUNL_PATH ]; then
        echo "Removing ${PRITUNL_PATH}..."
        rm -f $PRITUNL_PATH
    fi

    if [ -f $EDGE_BAK_PATH ]; then
        echo "Restoring ${EDGE_BAK_PATH} to ${EDGE_PATH}..."
        mv -f $EDGE_BAK_PATH $EDGE_PATH
    fi

    if [ -f $FOOTER_BAK_PATH ]; then
        echo "Restoring ${FOOTER_BAK_PATH} to ${FOOTER_PATH}..."
        mv -f $FOOTER_BAK_PATH $FOOTER_PATH
    fi

    echo "Removal complete"
    exit
fi

echo "Installing Pritunl EdgeMax Addon..."
echo "To uninstall run: sh ${0} remove"

if [ ! -d $LIB_DIR ]; then
    echo "Expected directory ${LIB_DIR} does not exist, ensure you are using the latest version of EdgeMax. Please report issues to contact@pritunl.com"
    exit 1
fi

if [ ! -f $EDGE_BAK_PATH ]; then
    SUM=`md5sum ${EDGE_PATH} | awk '{ print $1 }'`
    if [ "$SUM" != "76e0d5f71d0a55a1eb302b0ae9da219f" ]; then
        echo "${EDGE_PATH} md5sum ${SUM} does not match, ensure you are using the latest version of EdgeMax. Please report issues to contact@pritunl.com"
        exit 1
    fi
fi

if [ ! -f $FOOTER_BAK_PATH ]; then
    SUM=`md5sum ${FOOTER_PATH} | awk '{ print $1 }'`
    if [ "$SUM" != "08ffb16467e8c3a8181dd61f93545d38" ]; then
        echo "${FOOTER_PATH} md5sum ${SUM} does not match, ensure you are using the latest version of EdgeMax. Please report issues to contact@pritunl.com"
        exit 1
    fi
fi

if [ ! -f $EDGE_BAK_PATH ]; then
    echo "Backing up ${EDGE_PATH} to ${EDGE_BAK_PATH}..."
    cp $EDGE_PATH $EDGE_BAK_PATH
fi

if [ ! -f $FOOTER_BAK_PATH ]; then
    echo "Backing up ${FOOTER_PATH} to ${FOOTER_BAK_PATH}..."
    cp $FOOTER_PATH $FOOTER_BAK_PATH
fi

echo "Creating profiles directory ${PROFILES_PATH}..."
mkdir -p $PROFILES_PATH
chmod 773 $PROFILES_PATH

echo "Installing ${PRITUNL_PATH}..."
cat > $PRITUNL_PATH <<- EOM
var navTab = '<li class="ui-state-default ui-corner-top pritunl-tab">\\
  <a class="" data-container="VpnPritunl">Pritunl</a>\\
</li>';

var dataContainer = '<div id="VpnPritunl" class="pritunl wide tall" style="position: absolute; top: 0; background-color: #eaeaea; z-index: 10; display: none; overflow: auto;">\\
  <div class="section-container service-form" style="margin-bottom: 30px;">\\
    <form class="ui-form" novalidate="novalidate">\\
      <fieldset class="pritunl-profiles primary" style="display: none; margin: 20px 0 0 10px; border: 0; padding: 15px 15px 9px 15px; border: 1px solid #ccc; width: 680px;">\\
        <legend style="padding: 0 5px; font-weight: bold;">Pritunl Profiles</legend>\\
      </fieldset>\\
    </form>\\
    <form class="ui-form" novalidate="novalidate">\\
      <fieldset class="primary" style="margin: 20px 0 10px 10px; border: 0; padding: 15px; border: 1px solid #ccc; width: 680px;">\\
        <legend style="padding: 0 5px; font-weight: bold;">Add Pritunl Profile</legend>\\
        <label class="primary required" for="pritunl-tun" style="margin: 0 10px 0 5px; text-align: left; width: 318px;">Interface name</label>\\
        <div>\\
          <input type="text" id="pritunl-tun" class="pritunl-tun text-input">\\
          <span for="pritunl-tun" class="pritunl-tun-req-err error" style="display: none">This field is required.</span>\\
          <span for="pritunl-tun" class="pritunl-tun-inv-err error" style="display: none">Please enter a valid name such as "vtun0".</span>\\
        </div>\\
        <label class="primary required" for="pritunl-profile-data" style="margin: 0 10px 0 5px; text-align: left; width: 170px;">Pritunl profile</label>\\
        <textarea id="pritunl-profile-data" class="pritunl-profile-data text-input" spellcheck="false" style="clear: left; float: left; width: 470px; height: 376px; margin-left: 5px; margin-top: 4px; resize: none; font-family: \\'Courier New\\', Courier, monospace;"></textarea>\\
        <div style="clear: left; float: left; margin-left: 5px; width: 140px;">\\
          <span for="pritunl-profile-data" class="pritunl-profile-req-err error" style="display: none">This field is required.</span>\\
          <span for="pritunl-profile-data" class="pritunl-profile-inv-err error" style="display: none">Profile is invalid.</span>\\
        </div>\\
      </fieldset>\\
      <fieldset class="actions" style="margin: 0 0 20px 10px; padding-top: 3px; width: 680px;">\\
        <div>\\
          <span class="pritunl-add-error" style="display: none; position: relative; top: 0; color: #ffffff; background-color: #ff0000; -webkit-border-radius: 3px; border-radius: 3px; -moz-background-clip: padding; -webkit-background-clip: padding-box; background-clip: padding-box; font-size: 10px; font-weight: bold; padding: 3px 6px; margin-bottom: 4px;"></span>\\
          <span class="pritunl-add-success" style="display: none; position: relative; top: 0; color: #ffffff; background-color: #0f7e00; -webkit-border-radius: 3px; border-radius: 3px; -moz-background-clip: padding; -webkit-background-clip: padding-box; background-clip: padding-box; font-size: 10px; font-weight: bold; padding: 3px 6px; margin-bottom: 4px;">The profile has been added successfully</span>\\
          <button class="pritunl-add-profile ui-button ui-widget ui-state-default ui-corner-all ui-button-text-icon-primary" role="button" aria-disabled="false"><span\\
            class="ui-button-icon-primary ui-icon ui-icon-disk"></span><span class="ui-button-text">Add</span></button>\\
        </div>\\
      </fieldset>\\
    </form>\\
  </div>\\
</div>';

var profileItem = '<div class="pritunl-profile pritunl-profile-{iface}" style="clear: left; margin-bottom: 9px;">\\
  <label class="primary" style="margin: 6px 10px 0 5px; text-align: left; width: 80px; font-weight: bold;">{iface}</label>\\
  <button type="button" class="pritunl-delete-profile ui-button ui-widget ui-state-default ui-corner-all ui-button-text-icon-primary"\\
    role="button" aria-disabled="false"><span\\
    class="ui-button-icon-primary ui-icon ui-icon-close"></span><span\\
    class="ui-button-text">Delete</span></button>\\
  <span class="pritunl-del-error" style="display: none; margin-top: 5px; position: relative; top: 0; color: #ffffff; background-color: #ff0000; -webkit-border-radius: 3px; border-radius: 3px; -moz-background-clip: padding; -webkit-background-clip: padding-box; background-clip: padding-box; font-size: 10px; font-weight: bold; padding: 3px 6px; margin-bottom: 4px;"></span>\\
</div>'

var injectPritunl = function() {
  if (!\$('#Vpn .section-tabs .ui-tabs-nav').length) {
    setTimeout(injectPritunl, 50);
    return;
  }

  var profiles = {};
  var removing;

  var addProfile = function(iface, id) {
    \$('.pritunl-profiles').append(
      profileItem.replace('{iface}', iface).replace('{iface}', iface));

    var \$profile = \$('.pritunl-profile-' + iface);
    var \$profileButton = \$('.pritunl-profile-' + iface +
      ' .pritunl-delete-profile');

    \$profileButton.click(function() {
      if (removing) {
        return;
      }
      removing = true;
      \$profileButton.addClass('ui-state-disabled').find(
        '.ui-button-icon-primary').removeClass(
        'ui-icon-close').addClass(
        'ui-icon-spinner').attr('disabled', 'disabled');
      \$profile.find('.pritunl-del-error').hide();

      var ifaces = {};
      ifaces[iface] = null;

      \$.ajax({
        type: 'POST',
        url: '/api/edge/batch.json',
        dataType: 'json',
        contentType: 'application/json',
        headers: {
          'X-CSRF-TOKEN': UBNT.Utils.Cookies.get('X-CSRF-TOKEN'),
        },
        data: JSON.stringify({
          'DELETE': {
            'interfaces': {
              'openvpn': ifaces
            }
          }
        }),
        success: function(resp) {
          var err;

          if (resp['COMMIT'] && resp['COMMIT']['error']) {
            err = resp['COMMIT']['error']
          } else if (resp['SAVE'] && resp['SAVE']['error']) {
            err = resp['SAVE']['error']
          } else if (resp['SET'] && resp['SET']['error']) {
            err = resp['SET']['error']
          } else if (resp['DELETE'] && resp['DELETE']['error']) {
            err = resp['DELETE']['error']
          }

          if (err) {
            if (typeof err === 'object') {
              err = JSON.stringify(err);
            }
            err = err.replace(/[^\\x00-\\x7F]/g, '');
            \$profile.find('.pritunl-del-error').text(
              'Erroring removing configuration: ' + err).css(
              'display', 'block');

            \$profileButton.removeClass('ui-state-disabled').find(
              '.ui-button-icon-primary').removeClass(
              'ui-icon-spinner').addClass(
              'ui-icon-close').removeAttr('disabled');
            removing = false;
          } else {
            \$.ajax({
              type: 'POST',
              url: '/api/edge/pritunl-remove.json',
              dataType: 'json',
              contentType: 'application/json',
              headers: {
                'X-CSRF-TOKEN': UBNT.Utils.Cookies.get('X-CSRF-TOKEN'),
              },
              data: JSON.stringify({
                'id': id,
              }),
              success: function() {
                removing = false;
                update();
              },
              error: function() {
                \$profile.find('.pritunl-del-error').text(
                  'Failed to remove certificates in "/config/pritunl"').css(
                  'display', 'block');

                \$profileButton.removeClass('ui-state-disabled').find(
                  '.ui-button-icon-primary').removeClass(
                  'ui-icon-spinner').addClass(
                  'ui-icon-close').removeAttr('disabled');
                removing = false;
              }
            });
          }
        },
        error: function() {
          \$profile.find('.pritunl-del-error').text(
            'Unknown server error removing configuration').css(
            'display', 'block');

          \$profileButton.removeClass('ui-state-disabled').find(
            '.ui-button-icon-primary').removeClass(
            'ui-icon-spinner').addClass(
            'ui-icon-close').removeAttr('disabled');
          removing = false;
        }
      });
    });
  };

  var update = function() {
    \$.ajax({
      type: 'GET',
      url: '/api/edge/get.json',
      dataType: 'json',
      headers: {
        'X-CSRF-TOKEN': UBNT.Utils.Cookies.get('X-CSRF-TOKEN'),
      },
      success: function(evt) {
        var iface;
        var id;
        var profile;
        profiles = {};

        var data = evt['GET'];
        if (data) {
          data = data['interfaces'];
          if (data) {
            data = data['openvpn'];
          }
        }

        if (data) {
          for (iface in data) {
            profile = data[iface];

            if (!profile['description'] || profile['description'].indexOf(
                'pritunl') === -1) {
              continue;
            }

            id = profile['tls'];
            if (!id) {
              continue;
            }
            id = id['cert-file'];
            if (!id) {
              continue;
            }
            id = id.replace('/config/pritunl/', '').replace('.cert', '');
            if (id.length !== 64) {
              continue;
            }

            profiles[iface] = id;
          }
        }

        \$('.pritunl-profiles .pritunl-profile').remove();
        if (!profiles.length) {
          \$('.pritunl-profiles').hide();
        } else {
          \$('.pritunl-profiles').show();
        }

        var hasProfile;
        for (iface in profiles) {
          hasProfile = true;
          addProfile(iface, profiles[iface]);
        }

        if (hasProfile) {
          \$('.pritunl-profiles').show();
        } else {
          \$('.pritunl-profiles').hide();
        }
      },
      error: function() {

      }
    });
  };

  update();

  var randChrs = 'abcdefghijklmnopqrstuvwxyz' +
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  var randStr = function(length) {
    var result = '';
    for (var i = length; i > 0; --i) {
      result += randChrs[Math.round(Math.random() * (randChrs.length - 1))];
    }
    return result;
  }

  \$('#Vpn .section-tabs .ui-tabs-nav').append(navTab);
  \$('#Vpn .section-container.tall').append(dataContainer);

  \$('#Navigation li').click(function() {
    \$('.pritunl-tab').removeClass('ui-tabs-selected ui-state-active');
    \$('#VpnPritunl').hide();
  });
  \$('#Vpn .section-tabs li').mouseup(function(evt) {
    \$tar = \$(evt.currentTarget);

    if (\$tar.hasClass('pritunl-tab')) {
      \$('#Vpn .section-tabs .ui-tabs-nav .ui-tabs-selected').each(
        function (_, elem) {
          \$(elem).removeClass('ui-tabs-selected ui-state-active');
        });
      \$(evt.currentTarget).addClass('ui-tabs-selected ui-state-active');
      \$('#VpnPritunl').show();
    } else {
      \$('.pritunl-tab').removeClass('ui-tabs-selected ui-state-active');
      \$('#VpnPritunl').hide();
    }
  });

  \$('.pritunl button').live('mouseenter', function(evt) {
    \$(evt.currentTarget).addClass('ui-state-hover');
  }).live('mouseleave', function(evt) {
    \$(evt.currentTarget).removeClass('ui-state-hover');
    \$(evt.currentTarget).removeClass('ui-state-active');
  }).live('mousedown', function(evt) {
    \$(evt.currentTarget).addClass('ui-state-active');
  }).live('mouseup', function(evt) {
    \$(evt.currentTarget).removeClass('ui-state-active');
  });

  var profileParse = function(iface, data) {
    var i;
    var id = profiles[iface] || randStr(64);
    var line;
    var key;
    var val;
    var split;
    var cipher;
    var keysize;
    var keyDirection;
    var dataKey;
    var dataBlock = '';
    var lines = data.split('\\n');
    var data = {
      'description': 'pritunl' + iface.substr(4),
      'mode': 'client',
      'openvpn-option': [
        '--setenv UV_PLATFORM edge'
      ],
      'tls':{
        'ca-cert-file': '/config/pritunl/' + id + '.ca',
        'cert-file': '/config/pritunl/' + id + '.cert',
        'key-file': '/config/pritunl/' + id + '.key'
      }
    };
    var secData = {
      'id': id
    };

    for (i = 0; i < lines.length; i++) {
      line = lines[i];

      if (line.substr(0, 1) === '#' || line.substr(0, 1) === ';') {
        continue;
      }

      if (['#', ';'].indexOf(line.substr(0, 1)) !== -1 || !line) {
        continue;
      }

      if (line.substr(0, 1) === '<') {
        if (line.substr(1, 1) === '/') {
          if (!dataKey || !dataBlock) {
            return null;
          }
          secData[dataKey] = dataBlock;
          dataKey = null;
          dataBlock = '';
        } else {
          dataKey = line.substr(1, line.length - 2);
        }
        continue;
      } else if (dataKey) {
        dataBlock += line + '\\n';
        continue;
      }

      key = line.split(' ')[0];
      val = line.substr(key.length + 1);

      if (key === 'setenv') {
        data['openvpn-option'].push('--' + line)
      } else if (key === 'dev-type' && val === 'tap') {
        data['device-type'] = 'tap';
      } else if (key === 'remote') {
        data['remote-host'] = data['remote-host'] || [];
        split = val.split(' ');

        data['remote-host'].push(split[0]);
        if (split.length > 1) {
          data['remote-port'] = split[1];
        }
        if (split.length > 2) {
          data['protocol'] = split[2];
        }
      } else if (key === 'port') {
        data['remote-port'] = val;
      } else if (key === 'proto') {
        data['protocol'] = val;
      } else if (key === 'cipher') {
        cipher = val;
      } else if (key === 'keysize') {
        keysize = val;
      } else if (key === 'auth') {
        data['hash'] = val.toLowerCase();
      } else if (key === 'push-peer-info') {
        data['openvpn-option'].push('--' + key);
      } else if (
            key === 'ping' ||
            key === 'ping-restart' ||
            key === 'server-poll-timeout' ||
            key === 'reneg-sec' ||
            key === 'sndbuf' ||
            key === 'rcvbuf' ||
            key === 'remote-cert-tls' ||
            key === 'comp-lzo') {
        data['openvpn-option'].push('--' + key + ' ' + val);
      } else if (key === 'key-direction') {
        keyDirection = val;
      }
    }

    if (cipher) {
      var cipherLow = cipher.toLowerCase();
      if (cipherLow === 'bf-cbc') {
        if (keysize === '256') {
          data['encryption'] = 'bf256';
        } else {
          data['encryption'] = 'bf128';
        }
      } else if (cipherLow === 'aes-128-cbc') {
        data['encryption'] = 'aes128';
      } else if (cipherLow === 'aes-192-cbc') {
        data['encryption'] = 'aes192';
      } else if (cipherLow === 'aes-256-cbc') {
        data['encryption'] = 'aes256';
      } else if (cipherLow === 'des-cbc') {
        data['encryption'] = 'des';
      } else if (cipherLow === 'des-ede3-cbc') {
        data['encryption'] = '3des';
      } else {
        if (cipher) {
          data['openvpn-option'].push('--cipher ' + cipher);
        }
        if (keysize) {
          data['openvpn-option'].push('--keysize ' + keysize);
        }
      }
    }

    if (secData['tls-auth']) {
      var tlsOpt = '--tls-auth /config/pritunl/' + id + '.tls';
      if (keyDirection) {
        tlsOpt += ' ' + keyDirection;
      }
      data['openvpn-option'].push(tlsOpt);
    }

    var innerData = {};
    innerData[iface] = data;

    return [{
      'SET': {
        'interfaces': {
          'openvpn': innerData
        }
      }
    }, secData];
  };

  var tunChanged = false;
  var tunValidate = function() {
    var val = \$('.pritunl .pritunl-tun').val();

    if (!val) {
      \$('.pritunl-tun-inv-err').hide();
      \$('.pritunl-tun-req-err').show();
    } else if (val.indexOf('vtun') !== 0 || !val.substr(4).match(/^\\d+\$/)) {
      \$('.pritunl-tun-req-err').hide();
      \$('.pritunl-tun-inv-err').show();
    } else {
      \$('.pritunl-tun-inv-err').hide();
      \$('.pritunl-tun-req-err').hide();
      return val;
    }
  };
  \$('.pritunl .pritunl-tun').bind('change', function() {
    tunChanged = true;
    tunValidate();
  }).bind('input', function() {
    if (tunChanged) {
      tunValidate();
    }
  });

  var profileChanged = false;
  var profileValidate = function() {
    var val = \$('.pritunl .pritunl-profile-data').val();

    if (!val) {
      \$('.pritunl-profile-inv-err').hide();
      \$('.pritunl-profile-req-err').show();
    } else {
      \$('.pritunl-profile-inv-err').hide();
      \$('.pritunl-profile-req-err').hide();
      return val;
    }
  };
  \$('.pritunl .pritunl-profile-data').bind('change', function() {
    profileChanged = true;
    profileValidate();
  }).bind('input', function() {
    if (profileChanged) {
      profileValidate();
    }
  });

  \$('.pritunl .pritunl-add-profile').click(function(evt) {
    evt.preventDefault();

    if (\$('.pritunl-add-profile').hasClass('ui-state-disabled')) {
      return;
    }
    \$('.pritunl-add-profile').addClass('ui-state-disabled');
    \$('.pritunl-add-success').hide();
    \$('.pritunl-add-error').hide();

    var iface = tunValidate();
    var profile = profileValidate();
    if (!iface || !profile) {
      \$('.pritunl-profile-inv-err').show();
      \$('.pritunl-profile-req-err').hide();
      \$('.pritunl-add-profile').removeClass('ui-state-disabled');
      return;
    }

    var data = profileParse(iface, profile);
    if (!data) {
      \$('.pritunl-profile-inv-err').show();
      \$('.pritunl-profile-req-err').hide();
      \$('.pritunl-add-profile').removeClass('ui-state-disabled');
      return;
    }

    \$('.pritunl-add-profile .ui-button-icon-primary').removeClass(
      'ui-icon ui-icon-disk').addClass(
      'ui-icon ui-icon-spinner').attr('disabled', 'disabled');

    \$.ajax({
      type: 'POST',
      url: '/api/edge/pritunl-add.json',
      dataType: 'json',
      contentType: 'application/json',
      headers: {
        'X-CSRF-TOKEN': UBNT.Utils.Cookies.get('X-CSRF-TOKEN'),
      },
      data: JSON.stringify(data[1]),
      success: function() {
        \$.ajax({
          type: 'POST',
          url: '/api/edge/batch.json',
          dataType: 'json',
          contentType: 'application/json',
          headers: {
            'X-CSRF-TOKEN': UBNT.Utils.Cookies.get('X-CSRF-TOKEN'),
          },
          data: JSON.stringify(data[0]),
          success: function(resp) {
            var err;

            if (resp['COMMIT'] && resp['COMMIT']['error']) {
              err = resp['COMMIT']['error']
            } else if (resp['SAVE'] && resp['SAVE']['error']) {
              err = resp['SAVE']['error']
            } else if (resp['SET'] && resp['SET']['error']) {
              err = resp['SET']['error']
            }

            if (err) {
              if (typeof err === 'object') {
                err = JSON.stringify(err);
              }
              err = err.replace(/[^\\x00-\\x7F]/g, '');
              \$('.pritunl-add-success').hide();
              \$('.pritunl-add-error').text(
                'Erroring saving configuration: ' + err).css(
                'display', 'block');
            } else {
              tunChanged = false;
              profileChanged = false;

              \$('.pritunl-add-success').css('display', 'block');
            }

            \$('.pritunl-add-profile .ui-button-icon-primary').removeClass(
              'ui-icon ui-icon-spinner').addClass(
              'ui-icon ui-icon-disk').removeAttr('disabled');
            \$('.pritunl-add-profile').removeClass('ui-state-disabled');

            update();
          },
          error: function() {
            \$('.pritunl-add-success').hide();
            \$('.pritunl-add-error').text(
              'Unknown server error saving configuration').css(
              'display', 'block');

            \$('.pritunl-add-profile .ui-button-icon-primary').removeClass(
              'ui-icon ui-icon-spinner').addClass(
              'ui-icon ui-icon-disk').removeAttr('disabled');
            \$('.pritunl-add-profile').removeClass('ui-state-disabled');
          }
        });
      },
      error: function() {
        \$('.pritunl-add-success').hide();
        \$('.pritunl-add-error').text(
          'Failed to write certificates to "/config/pritunl"').css(
          'display', 'block');

        \$('.pritunl-add-profile .ui-button-icon-primary').removeClass(
          'ui-icon ui-icon-spinner').addClass(
          'ui-icon ui-icon-disk').removeAttr('disabled');
        \$('.pritunl-add-profile').removeClass('ui-state-disabled');
      }
    });
  });
};

injectPritunl();
EOM

echo "Patching ${EDGE_PATH}..."
cat > $EDGE_PATH <<- EOM
<?php
    namespace UBNT\\App\\Api;

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

        protected \$sid;
        protected \$authenticated;
        protected \$writable;


        /**
         * Determines the config structure to pass to the daemon and hands
         * it off to the request method. Also converts raw posted JSON into
         * an array.
         *
         * @access public
         * @return void
         */
        public function handle() {
            \$this->sid = session_id();
            \$this->authenticated = \\UBNT::auth()->isAuthenticated();
            \$this->writable = \\UBNT::auth()->getLevel() == 'admin';
            \$action = str_replace('.'.\$this->router->getExtension(), '', \$this->router->getSegment(2));

            if (!\$this->writable && !in_array(\$action, array('auth', 'get', 'data', 'ping', 'heartbeat', 'feature'))) {
                throw new \\Api_Exception(\\UBNT::language()->translate('Permission denied'), 403);
            }

            if (\$this->router->getMethod() == 'POST' && \$this->router->getRawData()) {
                \$this->router->setVariables(json_decode(\$this->router->getRawData(), true));
            }

            //close the session to prevent the locking out of other concurrent calls
            if (!\$this->internal) {
                if (!(\$this->router->getSegment(2) == 'config' && str_replace('.'.\$this->router->getExtension(), '', \$this->router->getSegment(3)) == 'save')) {
                    session_write_close();
                }
            }

            switch (\$action) {
                case 'auth':
                    \$structure = \$this->authStructure(\$this->router->getVariable('username'), \$this->router->getVariable('password'));
                    \$open = true;
                    break;

                case 'get':
                    \$structure = \$this->buildStructure();
                    break;

                case 'partial':
                    \$structure['GET'] = json_decode(\$this->router->getVariable('struct'), true);
                    break;

                case 'data':
                    \$structure['GETDATA'] = \$this->router->getVariable('data');
                    break;

                case 'set':
                    \$structure['SET'] = \$this->router->getVariables();
                    \$structure['GET'] = \$this->parentStructure(\$structure['SET']);
                    break;

                case 'delete':
                    \$structure['DELETE'] = \$this->router->getVariables();
                    \$structure['GET'] = \$this->parentStructure(\$structure['DELETE']);
                    break;

                case 'batch':
                    \$structure = \$this->router->getVariables();

                    if (empty(\$structure['GET'])) {
                        \$structure['GET'] = !empty(\$structure['SET']) ? \$this->parentStructure(\$structure['SET']) : array();
                        empty(\$structure['DELETE']) || \$structure['GET'] = \$this->mergeStructure(\$structure['GET'], \$this->parentStructure(\$structure['DELETE']));

                        /*
                        \$changes = !empty(\$structure['SET']) ? \$structure['SET'] : array();
                        empty(\$structure['DELETE']) || \$changes = \$this->mergeStructure(\$changes, \$structure['DELETE']);
                        \$structure['GET'] = \$this->parentStructure(\$changes);
                        */
                    }
                    break;

                case 'getcfg':
                    \$structure['GETCFG'] = \$this->router->getVariable('node');
                    break;

                case 'setup':
                    \$structure['SETUP'] = \$this->router->getVariable('data');
                    break;

                case 'feature':
                    if ((\$data = \$this->router->getVariable('data')) && \$this->writable || \$data['action'] == 'load') {
                        \$structure['FEATURE'] = \$data;
                    } else {
                        throw new \\Api_Exception(\\UBNT::language()->translate('Permission denied'), 403);
                    }
                    break;

                case 'ping':
                    return \$this->handleHeartbeat(false);

                case 'heartbeat':
                    return \$this->handleHeartbeat(true);

                case 'config':
                    return \$this->handleConfig();

                case 'upgrade':
                    return \$this->handleUpgrade();

                case 'operation':
                    return \$this->handleOperation();

                case 'pritunl-add':
                    if (\$this->authenticated) {
                        \$confDir = '/config/pritunl';
                        \$confId = \$this->router->getVariable('id');
                        \$confId = preg_replace('/[^a-zA-Z0-9]+/', '', \$confId);
                        \$caData = \$this->router->getVariable('ca');
                        \$caPath = sprintf('%s/%s.ca', \$confDir, \$confId);
                        \$certData = \$this->router->getVariable('cert');
                        \$certPath = sprintf('%s/%s.cert', \$confDir, \$confId);
                        \$keyData = \$this->router->getVariable('key');
                        \$keyPath = sprintf('%s/%s.key', \$confDir, \$confId);
                        \$tlsData = \$this->router->getVariable('tls-auth');
                        \$tlsPath = sprintf('%s/%s.tls', \$confDir, \$confId);

                        \$items = array(
                            \$caPath => \$caData,
                            \$certPath => \$certData,
                            \$keyPath => \$keyData,
                            \$tlsPath => \$tlsData,
                        );

                        foreach (\$items as \$path => \$data) {
                            if (\$data != null) {
                                \$file = fopen(\$path, 'w');
                                if (!\$file) {
                                    throw new \\Api_Exception(
                                        'Failed to open ' + \$path, 500);
                                }
                                fwrite(\$file, \$data);
                                if (!fclose(\$file)) {
                                    throw new \\Api_Exception(
                                        'Failed to write ' + \$path, 500);
                                }
                            }
                        }
                    } else {
                        throw new \\Api_Exception('Permission denied', 403);
                    }
                    break;

                case 'pritunl-remove':
                    if (\$this->authenticated) {
                        \$confDir = '/config/pritunl';
                        \$confId = \$this->router->getVariable('id');
                        \$confId = preg_replace('/[^a-zA-Z0-9]+/', '', \$confId);
                        \$caPath = sprintf('%s/%s.ca', \$confDir, \$confId);
                        \$certPath = sprintf('%s/%s.cert', \$confDir, \$confId);
                        \$keyPath = sprintf('%s/%s.key', \$confDir, \$confId);
                        \$tlsPath = sprintf('%s/%s.tls', \$confDir, \$confId);

                        unlink(\$caPath);
                        unlink(\$certPath);
                        unlink(\$keyPath);
                        unlink(\$tlsPath);
                    } else {
                        throw new \\Api_Exception('Permission denied', 403);
                    }
                    break;

                default:
                    throw new \\Api_Exception(\\UBNT::language()->translate('Invalid API method'), 404);
            }

            \$this->request(\$structure, !empty(\$open));
        }


        /**
         * Special handling to combine the ping request and the
         * session validation.
         *
         * @access protected
         * @param boolean \$session Whether to check the session
         * @return void
         */
        protected function handleHeartbeat(\$session) {
            \$this->request(array('PING' => null), true);
            \$this->result = array(
                'success' => true,
                'PING' => \$this->result['success'] ? true : false
            );

            if (\$session) {
                \$this->result['SESSION'] = \$this->authenticated;
            }
        }


        /**
         * Special handling for the config requests.
         *
         * @access protected
         * @return void
         */
        protected function handleConfig() {
            switch (\$action = str_replace('.'.\$this->router->getExtension(), '', \$this->router->getSegment(3))) {
                case 'save':
                    \$structure['CONFIG'] = array(
                        'action' => 'save'
                    );
                    break;

                case 'restore':
                    \$structure['CONFIG'] = array(
                        'action' => 'restore',
                        'path' => \$this->getFilepath(!empty(\$_GET['qqfile']) ? \$_GET['qqfile'] : null)
                    );
                    break;

                default:
                    throw new \\Api_Exception(\\UBNT::language()->translate('Invalid API method'), 404);
            }

            \$this->request(\$structure);

            switch (\$action) {
                case 'save':
                    if (!empty(\$this->result['CONFIG']['success']) && !empty(\$this->result['CONFIG']['path'])) {
                        \$_SESSION['_cfgPath'] = \$this->result['CONFIG']['path'];
                    } else {
                        throw new \\Api_Exception(\\UBNT::language()->translate('Unable to build config file (%s)', !empty(\$this->result['CONFIG']['error']) ? \$this->result['CONFIG']['error'] : 'Unspecified error'), 500);
                    }
                    break;

                case 'restore':
                    if (empty(\$this->result['CONFIG']['success'])) {
                        throw new \\Api_Exception(\\UBNT::language()->translate('Unable to restore config (%s)', !empty(\$this->result['CONFIG']['error']) ? \$this->result['CONFIG']['error'] : 'Unspecified error'), 500);
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
            \$structure['UPGRADE'] = array(
                'path' => \$this->getFilepath(!empty(\$_GET['qqfile']) ? \$_GET['qqfile'] : null)
            );

            \$this->request(\$structure);

            if (empty(\$this->result['UPGRADE']['success'])) {
                throw new \\Api_Exception(\\UBNT::language()->translate('Unable to upgrade system (%s)', !empty(\$this->result['UPGRADE']['error']) ? \$this->result['UPGRADE']['error'] : 'Unspecified error'), 500);
            }
        }


        /**
         * Special handling the for the operation requests.
         *
         * @access protected
         * @return void
         */
        protected function handleOperation() {
            if (\$operation = str_replace('.'.\$this->router->getExtension(), '', \$this->router->getSegment(3))) {
                \$structure['OPERATION'] = array(
                    'op' => \$operation
                );

                if (\$data = \$this->router->getVariables()) {
                    \$structure['OPERATION'] = array_merge(\$data, \$structure['OPERATION']);
                }

                \$this->request(\$structure);
            } else {
                throw new \\Api_Exception(\\UBNT::language()->translate('Invalid API method'), 404);
            }

            if (empty(\$this->result['OPERATION']['success'])) {
                throw new \\Api_Exception(\\UBNT::language()->translate('Unable to perform %s operation (%s)', \$operation, !empty(\$this->result['OPERATION']['error']) ? \$this->result['OPERATION']['error'] : 'Unspecified error'), 500);
            }
        }


        /**
         * Empties out the values of the array array passed. Useful for
         * converting an array into GET format.
         *
         * @access protected
         * @param array \$array The array to empty
         * @return array The emptied array
         */
        protected function emptyStructure(\$array) {
            array_walk_recursive(\$array, function(&\$item, \$key) {
                if (\$item && !is_array(\$item)) {
                    \$item = null;
                }
            });
            return \$array;
        }


        /**
         * Returns only the parent arrays and filters out all key/value
         * data. Useful for converting an array into GET format without
         * trying to retrieve nodes that have been deleted.
         *
         * @access protected
         * @param array \$array The array to filter
         * @return array The parent structure
         */
        protected function parentStructure(\$array) {
            class_exists('\\UBNT\\App\\Recursion', false) || \\UBNT::loader()->loadApp('recursion');
            return \\UBNT\\App\\Recursion::filter(\$array, function(\$value) {
                if (\$return = is_array(\$value)) {
                    foreach (\$value as \$child) {
                        if (!is_array(\$child)) {
                            \$return = false;
                            break;
                        }
                    }
                }
                return \$return;
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
         * @param string \$username The username to authenticate
         * @param string \$password The unencrypted password
         * @return array The authentication structure to send to the daemon
         */
        protected function authStructure(\$username, \$password) {
            return array(
                'AUTH' => array(
                    'username' => \$username,
                    'password' => \$password
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
            class_exists('\\UBNT\\App\\Recursion', false) || \\UBNT::loader()->loadApp('recursion');
            return forward_static_call_array(array('\\UBNT\\App\\Recursion', 'merge'), func_get_args());
        }

        /**
         * Filters the input to remove any sensitive data for
         * non-admin users.
         *
         * @access protected
         * @param array \$input An array of data to filter
         * @return array The filtered result
         */
        protected function filter(\$input) {
            if (!\$this->writable) {
                array_walk_recursive(\$input, function(&\$item, \$key) {
                    if (preg_match('/(passphrase|password|pre-shared-secret|key)/', \$key)) {
                        \$item = is_array(\$item) ? null : '*********';
                    }
                });
            }
            return \$input;
        }

        /**
         * Sends a request to the daemon. This runs in blocking mode which
         * means it will wait for a response. Each request should be preceded
         * by a session ID and the length of the request. The daemon doesn't
         * recognize NULL data so this replaces nulls with "''" before it
         * sends the data and replaces any '' in the result with null.
         *
         * @access protected
         * @param array \$structure The config structure to send to the daemon
         * @param boolean \$open Whether to allow unauthenticated users to make the request
         * @param string \$session Whether to pass the session in the request
         * @return void
         */
        protected function request(array \$structure, \$open = false, \$session = true) {
            if (\$this->authenticated || \$open) {
                \$config = \\UBNT::config()->get('edge');

                array_walk_recursive(\$structure, function(&\$item, \$key) {
                    if (is_null(\$item)) {
                        \$item = "''";
                    }
                });

                \$session && \$structure['SESSION_ID'] = \$this->sid;
                \$structure = json_encode(\$structure);
                \$structure = preg_replace('/,?"__FORCE_ASSOC":true/', '', \$structure);
                \$buffer = strlen(\$structure) . "\\n" . \$structure;

                try {
                    \\UBNT::loader()->loadCore('socket');
                    \$socket = \\UBNT\\Core\\Socket::factory("\\n")
                            ->create(AF_UNIX, SOCK_STREAM, 0)
                            ->connect(\$config->server->address)
                            ->setBlocking()
                    ;

                    if ((\$legacy = \$config->get('legacy')) && \$legacy->sessions) {
                        \$socket->write(\$this->sid, false);
                    }

                    \$result = \$socket->write(\$buffer, false)->read(null, 0, "\\n");
                    \$socket->close();

                    if (\$decoded = json_decode(\$result, true)) {
                        array_walk_recursive(\$decoded, function(&\$item, \$key) {
                            if (\$item == "''") {
                                \$item = null;
                            }
                        });

                        \$this->success = true;
                        \$this->result = \$this->filter(\$decoded);
                    } else {
                        throw new \\Socket_Exception('Invalid result data: ' . \$result);
                    }
                } catch (\\Socket_Exception \$exception) {
                    throw new \\Api_Exception(\$exception->getMessage(), 500, \$exception);
                }
            } else {
                throw new \\Api_Exception('Permission denied', 403);
            }
        }
    }
EOM

echo "Patching ${FOOTER_PATH}..."
cat > $FOOTER_PATH <<- EOM
<?php
    /**
     * @package ubnt
     * @subpackage views
     * @copyright 2012 Ubiquiti Networks, Inc. All rights reserved.
     */
?>

        <?php if (\$compressed): ?>
            <script type="text/javascript" src="/lib/<?php echo \$build; ?>/js/core.min.js"></script>
        <?php else: ?>
            <script type="text/javascript" src="/lib/js/libs/jquery-1.7.2.min.js"></script>
            <script type="text/javascript" src="/lib/js/libs/jquery-ui-1.8.19.custom.min.js"></script>

            <!--[if lte IE 9]>
                <script type="text/javascript" src="/lib/js/libs/polyfills/jquery.placeholder.min.js"></script>
                <script type="text/javascript" src="/lib/js/ubnt/ubnt.polyfills.js"></script>
            <![endif]-->
        <?php endif; ?>

        <script type="text/javascript">
        /**
         * @if browser does not support HTML5 WebSocket, or browser is Safari 5.1 or earlier, then use flash WebSocket instead of native html5 WebSocket and hide CLI window from UI.
         */
        var BROWSER_IS_SAFARI = (navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Chrome') == -1);
        if (!Modernizr.websockets || (BROWSER_IS_SAFARI && navigator.userAgent.match(/Version\\/([0-9])+/)[1] < 6.0)) {
            WEB_SOCKET_FORCE_FLASH = true;
        }
        </script>

        <script type="text/javascript">
            var UBNT_DISCOVER_DISABLE = false;
        </script>

        <?php if (\$authenticated): ?>
            <?php if (\$compressed): ?>
                <script type="text/javascript" src="/lib/<?php echo \$build; ?>/js/websocket.min.js"></script>
                <script type="text/javascript" src="/lib/<?php echo \$build; ?>/js/fileuploader.min.js"></script>
                <script type="text/javascript" src="/lib/<?php echo \$build; ?>/js/edge.min.js"></script>
            <?php else: ?>
                <?php if (!empty(\$debug)): ?>
                <script type="text/javascript" src="/lib/js/edge/debug.js"></script>
                <?php endif; ?>

                <script type="text/javascript" src="/lib/js/libs/datatables.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/datatables-extended.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/datatables-sorting.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/datatables-redraw.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.ui.selectmenu.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.validate.min.js"></script>

                <!-- addon libs -->
                <script type="text/javascript" src="/lib/js/libs/json2.js"></script>
                <script type="text/javascript" src="/lib/js/libs/underscore.js"></script>
                <script type="text/javascript" src="/lib/js/libs/backbone.js"></script>
                <script type="text/javascript" src="/lib/js/libs/fileuploader.js"></script>
                <script type="text/javascript" src="/lib/js/libs/swfobject.js"></script>
                <script type="text/javascript" src="/lib/js/libs/websocket.js"></script>
                <script type="text/javascript" src="/lib/js/libs/d3.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.layout.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.ui.addable.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.ui.tabslite.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.ui.form.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.ui.dialoglite.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.ui.dialogmanager.js"></script>
                <script type="text/javascript" src="/lib/js/libs/plugins/jquery.ui.graph.js"></script>

                <!-- ubnt libs -->
                <script type="text/javascript" src="/lib/js/ubnt/plugins/jquery.ubnt.infotip.js"></script>
                <script type="text/javascript" src="/lib/js/ubnt/plugins/jquery.ubnt.button.js"></script>
                <script type="text/javascript" src="/lib/js/ubnt/ubnt.js"></script>
                <script type="text/javascript" src="/lib/js/ubnt/Logger.js"></script>
                <script type="text/javascript" src="/lib/js/ubnt/ubnt.backbone.js"></script>
                <script type="text/javascript" src="/lib/js/ubnt/ubnt.utils.js"></script>
                <script type="text/javascript" src="/lib/js/ubnt/views/uicomponents/tooltip.js"></script>

                <!-- edge app -->
                <script type="text/javascript" src="/lib/js/edge/msg_en_us.js"></script>
                <script type="text/javascript" src="/lib/js/edge/core.js"></script>
                <script type="text/javascript" src="/lib/js/edge/validation.js"></script>
                <script type="text/javascript" src="/lib/js/edge/tz.js"></script>

                <?php foreach (array('global', 'dashboard', 'interfaces', 'routing', 'security', 'services', 'vpn', 'users', 'wizard', 'tree', 'analysis', 'qos') as \$section): ?>
                <script type="text/javascript" src="/lib/js/edge/routers/<?php echo \$section ?>.js"></script>
                <script type="text/javascript" src="/lib/js/edge/views/<?php echo \$section ?>.js"></script>
                <?php endforeach; ?>

                <script type="text/javascript" src="/lib/js/edge/views/toolbox.js"></script>
                <script type="text/javascript" src="/lib/js/edge/views/dialogs.js"></script>
                <script type="text/javascript" src="/lib/js/edge/views/dialogs/CLIDialog.js"></script>
                <script type="text/javascript" src="/lib/js/edge/data/models.js"></script>
                <script type="text/javascript" src="/lib/js/edge/data/collections.js"></script>
                <script type="text/javascript" src="/lib/js/edge/data/toolbox.js"></script>
                <script type="text/javascript" src="/lib/js/edge/data/stats.js"></script>
                <script type="text/javascript" src="/lib/js/edge/app.js"></script>
            <?php endif; ?>

        <?php else: ?>
            <?php if (\$compressed): ?>
                <script type="text/javascript" src="/lib/<?php echo \$build; ?>/js/edge/login.js"></script>
            <?php else: ?>
                <script type="text/javascript" src="/lib/js/edge/login.js"></script>
            <?php endif; ?>
        <?php endif; ?>


        <script type="text/javascript">
            \$(function() {
                try {
                    if (EDGE.Config.User.level != 'admin') {
                        \$('body').addClass('readonly');
                    }
                    window.app.initialize(null, DEV_MODE);
                } catch (e) {
                    window.app.fatal(Msg.E_Runtime + ': ' + e, 'Runtime Error', true);
                }

            });
       </script>

        <script type="text/javascript">
            \$.xss = function(text) {
                return text ? \$("<div />").text(text).html() : null;
            };
        </script>

        <script type="text/javascript" src="/lib/<?php echo \$build; ?>/js/pritunl.js"></script>
    </body>
</html>
EOM

echo "Installation complete"
