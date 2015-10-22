<?php
    /**
     * @package ubnt
     * @subpackage views
     * @copyright 2012 Ubiquiti Networks, Inc. All rights reserved.
     */
?>

        <?php if ($compressed): ?>
            <script type="text/javascript" src="/lib/<?php echo $build; ?>/js/core.min.js"></script>
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
        if (!Modernizr.websockets || (BROWSER_IS_SAFARI && navigator.userAgent.match(/Version\/([0-9])+/)[1] < 6.0)) {
            WEB_SOCKET_FORCE_FLASH = true;
        }
        </script>

        <script type="text/javascript">
            var UBNT_DISCOVER_DISABLE = false;
        </script>

        <?php if ($authenticated): ?>
            <?php if ($compressed): ?>
                <script type="text/javascript" src="/lib/<?php echo $build; ?>/js/websocket.min.js"></script>
                <script type="text/javascript" src="/lib/<?php echo $build; ?>/js/fileuploader.min.js"></script>
                <script type="text/javascript" src="/lib/<?php echo $build; ?>/js/edge.min.js"></script>
            <?php else: ?>
                <?php if (!empty($debug)): ?>
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

                <?php foreach (array('global', 'dashboard', 'interfaces', 'routing', 'security', 'services', 'vpn', 'users', 'wizard', 'tree', 'analysis', 'qos') as $section): ?>
                <script type="text/javascript" src="/lib/js/edge/routers/<?php echo $section ?>.js"></script>
                <script type="text/javascript" src="/lib/js/edge/views/<?php echo $section ?>.js"></script>
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
            <?php if ($compressed): ?>
                <script type="text/javascript" src="/lib/<?php echo $build; ?>/js/edge/login.js"></script>
            <?php else: ?>
                <script type="text/javascript" src="/lib/js/edge/login.js"></script>
            <?php endif; ?>
        <?php endif; ?>


        <script type="text/javascript">
            $(function() {
                try {
                    if (EDGE.Config.User.level != 'admin') {
                        $('body').addClass('readonly');
                    }
                    window.app.initialize(null, DEV_MODE);
                } catch (e) {
                    window.app.fatal(Msg.E_Runtime + ': ' + e, 'Runtime Error', true);
                }

            });
       </script>

        <script type="text/javascript">
            $.xss = function(text) {
                return text ? $("<div />").text(text).html() : null;
            };
        </script>

        <script type="text/javascript" src="/lib/<?php echo $build; ?>/js/pritunl.js"></script>
    </body>
</html>
