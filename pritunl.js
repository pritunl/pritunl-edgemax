var navTab = '<li class="ui-state-default ui-corner-top pritunl-tab">\
  <a class="" data-container="VpnPritunl">Pritunl</a>\
</li>';

var dataContainer = '<div id="VpnPritunl" class="pritunl wide tall" style="position: absolute; top: 0; background-color: #eaeaea; z-index: 10; display: none; overflow: auto;">\
  <div class="section-container service-form" style="margin-bottom: 30px;">\
    <form class="ui-form" novalidate="novalidate">\
      <fieldset class="pritunl-profiles primary" style="display: none; margin: 20px 0 0 10px; border: 0; padding: 15px 15px 9px 15px; border: 1px solid #ccc; width: 680px;">\
        <legend style="padding: 0 5px; font-weight: bold;">Pritunl Profiles</legend>\
      </fieldset>\
    </form>\
    <form class="ui-form" novalidate="novalidate">\
      <fieldset class="primary" style="margin: 20px 0 10px 10px; border: 0; padding: 15px; border: 1px solid #ccc; width: 680px;">\
        <legend style="padding: 0 5px; font-weight: bold;">Add Pritunl Profile</legend>\
        <label class="primary required" for="pritunl-tun" style="margin: 0 10px 0 5px; text-align: left; width: 318px;">Interface name</label>\
        <div>\
          <input type="text" id="pritunl-tun" class="pritunl-tun text-input">\
          <span for="pritunl-tun" class="pritunl-tun-req-err error" style="display: none">This field is required.</span>\
          <span for="pritunl-tun" class="pritunl-tun-inv-err error" style="display: none">Please enter a valid name such as "vtun0".</span>\
        </div>\
        <label class="primary required" for="pritunl-profile-data" style="margin: 0 10px 0 5px; text-align: left; width: 170px;">Pritunl profile</label>\
        <textarea id="pritunl-profile-data" class="pritunl-profile-data text-input" spellcheck="false" style="clear: left; float: left; width: 470px; height: 376px; margin-left: 5px; margin-top: 4px; resize: none; font-family: \'Courier New\', Courier, monospace;"></textarea>\
        <div style="clear: left; float: left; margin-left: 5px; width: 140px;">\
          <span for="pritunl-profile-data" class="pritunl-profile-req-err error" style="display: none">This field is required.</span>\
          <span for="pritunl-profile-data" class="pritunl-profile-inv-err error" style="display: none">Profile is invalid.</span>\
        </div>\
      </fieldset>\
      <fieldset class="actions" style="margin: 0 0 20px 10px; padding-top: 3px; width: 680px;">\
        <div>\
          <span class="pritunl-add-error" style="display: none; position: relative; top: 0; color: #ffffff; background-color: #ff0000; -webkit-border-radius: 3px; border-radius: 3px; -moz-background-clip: padding; -webkit-background-clip: padding-box; background-clip: padding-box; font-size: 10px; font-weight: bold; padding: 3px 6px; margin-bottom: 4px;"></span>\
          <span class="pritunl-add-success" style="display: none; position: relative; top: 0; color: #ffffff; background-color: #0f7e00; -webkit-border-radius: 3px; border-radius: 3px; -moz-background-clip: padding; -webkit-background-clip: padding-box; background-clip: padding-box; font-size: 10px; font-weight: bold; padding: 3px 6px; margin-bottom: 4px;">The profile has been added successfully</span>\
          <button class="pritunl-add-profile ui-button ui-widget ui-state-default ui-corner-all ui-button-text-icon-primary" role="button" aria-disabled="false"><span\
            class="ui-button-icon-primary ui-icon ui-icon-disk"></span><span class="ui-button-text">Add</span></button>\
        </div>\
      </fieldset>\
    </form>\
  </div>\
</div>';

var profileItem = '<div class="pritunl-profile pritunl-profile-{iface}" style="clear: left; margin-bottom: 9px;">\
  <label class="primary" style="margin: 6px 10px 0 5px; text-align: left; width: 80px; font-weight: bold;">{iface}</label>\
  <button type="button" class="pritunl-delete-profile ui-button ui-widget ui-state-default ui-corner-all ui-button-text-icon-primary"\
    role="button" aria-disabled="false"><span\
    class="ui-button-icon-primary ui-icon ui-icon-close"></span><span\
    class="ui-button-text">Delete</span></button>\
  <span class="pritunl-del-error" style="display: none; margin-top: 5px; position: relative; top: 0; color: #ffffff; background-color: #ff0000; -webkit-border-radius: 3px; border-radius: 3px; -moz-background-clip: padding; -webkit-background-clip: padding-box; background-clip: padding-box; font-size: 10px; font-weight: bold; padding: 3px 6px; margin-bottom: 4px;"></span>\
</div>'

var injectPritunl = function() {
  if (!$('#Vpn .section-tabs .ui-tabs-nav').length) {
    setTimeout(injectPritunl, 50);
    return;
  }

  var profiles = {};
  var removing;

  var addProfile = function(iface, id) {
    $('.pritunl-profiles').append(
      profileItem.replace('{iface}', iface).replace('{iface}', iface));

    var $profile = $('.pritunl-profile-' + iface);
    var $profileButton = $('.pritunl-profile-' + iface +
      ' .pritunl-delete-profile');

    $profileButton.click(function() {
      if (removing) {
        return;
      }
      removing = true;
      $profileButton.addClass('ui-state-disabled').find(
        '.ui-button-icon-primary').removeClass(
        'ui-icon-close').addClass(
        'ui-icon-spinner').attr('disabled', 'disabled');
      $profile.find('.pritunl-del-error').hide();

      var ifaces = {};
      ifaces[iface] = null;

      $.ajax({
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
            err = err.replace(/[^\x00-\x7F]/g, '');
            $profile.find('.pritunl-del-error').text(
              'Erroring removing configuration: ' + err).css(
              'display', 'block');

            $profileButton.removeClass('ui-state-disabled').find(
              '.ui-button-icon-primary').removeClass(
              'ui-icon-spinner').addClass(
              'ui-icon-close').removeAttr('disabled');
            removing = false;
          } else {
            $.ajax({
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
                $profile.find('.pritunl-del-error').text(
                  'Failed to remove certificates in "/config/pritunl"').css(
                  'display', 'block');

                $profileButton.removeClass('ui-state-disabled').find(
                  '.ui-button-icon-primary').removeClass(
                  'ui-icon-spinner').addClass(
                  'ui-icon-close').removeAttr('disabled');
                removing = false;
              }
            });
          }
        },
        error: function() {
          $profile.find('.pritunl-del-error').text(
            'Unknown server error removing configuration').css(
            'display', 'block');

          $profileButton.removeClass('ui-state-disabled').find(
            '.ui-button-icon-primary').removeClass(
            'ui-icon-spinner').addClass(
            'ui-icon-close').removeAttr('disabled');
          removing = false;
        }
      });
    });
  };

  var update = function() {
    $.ajax({
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

        $('.pritunl-profiles .pritunl-profile').remove();
        if (!profiles.length) {
          $('.pritunl-profiles').hide();
        } else {
          $('.pritunl-profiles').show();
        }

        var hasProfile;
        for (iface in profiles) {
          hasProfile = true;
          addProfile(iface, profiles[iface]);
        }

        if (hasProfile) {
          $('.pritunl-profiles').show();
        } else {
          $('.pritunl-profiles').hide();
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

  $('#Vpn .section-tabs .ui-tabs-nav').append(navTab);
  $('#Vpn .section-container.tall').append(dataContainer);

  $('#Navigation li').click(function() {
    $('.pritunl-tab').removeClass('ui-tabs-selected ui-state-active');
    $('#VpnPritunl').hide();
  });
  $('#Vpn .section-tabs li').mouseup(function(evt) {
    $tar = $(evt.currentTarget);

    if ($tar.hasClass('pritunl-tab')) {
      $('#Vpn .section-tabs .ui-tabs-nav .ui-tabs-selected').each(
        function (_, elem) {
          $(elem).removeClass('ui-tabs-selected ui-state-active');
        });
      $(evt.currentTarget).addClass('ui-tabs-selected ui-state-active');
      $('#VpnPritunl').show();
    } else {
      $('.pritunl-tab').removeClass('ui-tabs-selected ui-state-active');
      $('#VpnPritunl').hide();
    }
  });

  $('.pritunl button').live('mouseenter', function(evt) {
    $(evt.currentTarget).addClass('ui-state-hover');
  }).live('mouseleave', function(evt) {
    $(evt.currentTarget).removeClass('ui-state-hover');
    $(evt.currentTarget).removeClass('ui-state-active');
  }).live('mousedown', function(evt) {
    $(evt.currentTarget).addClass('ui-state-active');
  }).live('mouseup', function(evt) {
    $(evt.currentTarget).removeClass('ui-state-active');
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
    var lines = data.split('\n');
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
        dataBlock += line + '\n';
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
    var val = $('.pritunl .pritunl-tun').val();

    if (!val) {
      $('.pritunl-tun-inv-err').hide();
      $('.pritunl-tun-req-err').show();
    } else if (val.indexOf('vtun') !== 0 || !val.substr(4).match(/^\d+$/)) {
      $('.pritunl-tun-req-err').hide();
      $('.pritunl-tun-inv-err').show();
    } else {
      $('.pritunl-tun-inv-err').hide();
      $('.pritunl-tun-req-err').hide();
      return val;
    }
  };
  $('.pritunl .pritunl-tun').bind('change', function() {
    tunChanged = true;
    tunValidate();
  }).bind('input', function() {
    if (tunChanged) {
      tunValidate();
    }
  });

  var profileChanged = false;
  var profileValidate = function() {
    var val = $('.pritunl .pritunl-profile-data').val();

    if (!val) {
      $('.pritunl-profile-inv-err').hide();
      $('.pritunl-profile-req-err').show();
    } else {
      $('.pritunl-profile-inv-err').hide();
      $('.pritunl-profile-req-err').hide();
      return val;
    }
  };
  $('.pritunl .pritunl-profile-data').bind('change', function() {
    profileChanged = true;
    profileValidate();
  }).bind('input', function() {
    if (profileChanged) {
      profileValidate();
    }
  });

  $('.pritunl .pritunl-add-profile').click(function(evt) {
    evt.preventDefault();

    if ($('.pritunl-add-profile').hasClass('ui-state-disabled')) {
      return;
    }
    $('.pritunl-add-profile').addClass('ui-state-disabled');
    $('.pritunl-add-success').hide();
    $('.pritunl-add-error').hide();

    var iface = tunValidate();
    var profile = profileValidate();
    if (!iface || !profile) {
      $('.pritunl-profile-inv-err').show();
      $('.pritunl-profile-req-err').hide();
      $('.pritunl-add-profile').removeClass('ui-state-disabled');
      return;
    }

    var data = profileParse(iface, profile);
    if (!data) {
      $('.pritunl-profile-inv-err').show();
      $('.pritunl-profile-req-err').hide();
      $('.pritunl-add-profile').removeClass('ui-state-disabled');
      return;
    }

    $('.pritunl-add-profile .ui-button-icon-primary').removeClass(
      'ui-icon ui-icon-disk').addClass(
      'ui-icon ui-icon-spinner').attr('disabled', 'disabled');

    $.ajax({
      type: 'POST',
      url: '/api/edge/pritunl-add.json',
      dataType: 'json',
      contentType: 'application/json',
      headers: {
        'X-CSRF-TOKEN': UBNT.Utils.Cookies.get('X-CSRF-TOKEN'),
      },
      data: JSON.stringify(data[1]),
      success: function() {
        $.ajax({
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
              err = err.replace(/[^\x00-\x7F]/g, '');
              $('.pritunl-add-success').hide();
              $('.pritunl-add-error').text(
                'Erroring saving configuration: ' + err).css(
                'display', 'block');
            } else {
              tunChanged = false;
              profileChanged = false;

              $('.pritunl-add-success').css('display', 'block');
            }

            $('.pritunl-add-profile .ui-button-icon-primary').removeClass(
              'ui-icon ui-icon-spinner').addClass(
              'ui-icon ui-icon-disk').removeAttr('disabled');
            $('.pritunl-add-profile').removeClass('ui-state-disabled');

            update();
          },
          error: function() {
            $('.pritunl-add-success').hide();
            $('.pritunl-add-error').text(
              'Unknown server error saving configuration').css(
              'display', 'block');

            $('.pritunl-add-profile .ui-button-icon-primary').removeClass(
              'ui-icon ui-icon-spinner').addClass(
              'ui-icon ui-icon-disk').removeAttr('disabled');
            $('.pritunl-add-profile').removeClass('ui-state-disabled');
          }
        });
      },
      error: function() {
        $('.pritunl-add-success').hide();
        $('.pritunl-add-error').text(
          'Failed to write certificates to "/config/pritunl"').css(
          'display', 'block');

        $('.pritunl-add-profile .ui-button-icon-primary').removeClass(
          'ui-icon ui-icon-spinner').addClass(
          'ui-icon ui-icon-disk').removeAttr('disabled');
        $('.pritunl-add-profile').removeClass('ui-state-disabled');
      }
    });
  });
};

injectPritunl();
