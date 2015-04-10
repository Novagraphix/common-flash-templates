# [NOVAGRAPHIX FLASH TEMPLATES](http://novagraphix.de)

## Clicktag

    import flash.events.Event;
    import flash.external.ExternalInterface;

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
    }();

    mc.clicktag.addEventListener(MouseEvent.CLICK, function(event: MouseEvent): void {
        var sTarget: String = "_blank";
        if (root.loaderInfo.parameters.clicktarget) sTarget = root.loaderInfo.parameters.clicktarget;
        if (ct[0]) {
            if (ExternalInterface.available) {
                var userAgent:String = ExternalInterface.call('function(){ return navigator.userAgent; }');
                if (userAgent.indexOf("MSIE") >= 0) {
                    ExternalInterface.call('window.open', ct[1], "_blank");
                } else {
                    navigateToURL(new URLRequest(ct[1]), sTarget);
                }
            } else {
                navigateToURL(new URLRequest(ct[1]), sTarget);
            }
        }
    });

## Noch ein Ansatz

    function getClickTag():String {
        for (var key:String in root.loaderInfo.parameters)
        {
            if(key.toLowerCase()=="clicktag")
                return root.loaderInfo.parameters[key];
        }
        return "";
    }

    mc.clicktag.addEventListener(MouseEvent.CLICK,function(event: MouseEvent): void {
            navigateToURL(new URLRequest(getClickTag()),"_blank");
    });

## Für mehrere Clicktags (clicktag1, clicktag2, etc)

    function getClickTag(cnt:uint):String {
        for (var key:String in root.loaderInfo.parameters)
        {
            if(key.toLowerCase()=="clicktag" + cnt)
                return root.loaderInfo.parameters[key];
        }
        return "";
    }

    mc.clicktag.addEventListener(MouseEvent.CLICK,function(event: MouseEvent): void {
            navigateToURL(new URLRequest(getClickTag(1)),"_blank");
    });