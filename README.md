# [NOVAGRAPHIX FLASH TEMPLATES](http://novagraphix.de)

## Clicktag

    var ct = function getClicktag():Array {
        var ct:Array = [false, ''];
        var clicktags = [
            'clicktag',
            'clickTag',
            'clickTAG',
            'Clicktag',
            'ClickTag',
            'ClickTAG',
            'CLICKTAG'
        ]
        for(var n = 0; n < clicktags.length; n++) {
            var test = root.loaderInfo.parameters[clicktags[n]];
            if(test != undefined) {
                ct = [clicktags[n], test];
            }
        }
        return ct;
    }(); //

    mc.clicktag.addEventListener(MouseEvent.CLICK, function(event: MouseEvent): void {
        var sURL: String;
        var sTarget: String = "_blank";
        if (root.loaderInfo.parameters.clicktarget) sTarget = root.loaderInfo.parameters.clicktarget;
        if (ct[0]) {
            navigateToURL(new URLRequest(ct[1]), sTarget);
        }
    });