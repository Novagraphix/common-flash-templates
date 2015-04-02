/*
 asLocalConnect v0.5 (AS3) - The better Way for LocalConnections 
 ===============================================================
 Please visited also http://flash.area-network.de

 Copyright (c) 2007, Markus Bordihn (http://markusbordihn.de)
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the flash.area-network.de nor the names of its contributors
      may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

package de.markusbordihn.flash.as3 {

 import flash.utils.*;
 import flash.display.Stage;
 import flash.display.MovieClip;
 import flash.events.Event;
 import flash.events.TimerEvent;
 import flash.events.StatusEvent;
 import flash.net.LocalConnection;
 
 public class asLocalConnect extends MovieClip {

  private static var asLocalConnectVersion:String = "0.5";
  private var _frameRate:Number;         // Cache FrameRate
  private var _quality:String;           // Cache Quality
  private var verboseLevel:Number = 2;   // Default Verbose Level

  private var connection:Object = {
   channel: 0,        // Unique ID for Local Connection Channel
   name: "",          // Name of Local Connection
   status: false,     // Status of Local Connection
   security: 6,       // Connection Security (1=no Security)
   allowDomain: [],   // Allow Domains
   domain: "",          // Current Domain
   load: null,        // Object onLoad
   unload: null,      // Object onUnload
   sync: null,        // Object onSync
   syncLoad: null,    // Object onLoad for onSync Backup
   func: {},          // Function Object for this LocalConnection
   send: {
    result: null,     // Last Result for .send(...)
    status: null      // Object onStatus
   }
  };

  private var heartbeats:Object = {
   id: null,          // Keep the Interval ID for the Heartbeat
   status: false,     // Status of all HeartBeat Connections
   load: null,        // Object for onLoad
   counter: null,     // Counter for Heartbeat, after 10 Request the Request will be only 1 per Second.
   list: [],          // List of all LocalConnections for HeartBeat inc. Status for each
   beat: {
    id: null,         // Keep the Interval ID for the Heartbeater
    timeframe: 400,   // TimeFrame for Heartbeat in ms
    interval: null    // Interval Time for the Heartbeat
   }
  };
  
  private var heartbeat_lc:Object = {
   connection: null,  // Heart Beat LocalConnection Object
   func: null         // Heart Beat Functions
  };

  private var sync_lc:Object = {
   sync: false        // Set to true when Synchronisation is ready
  };
  
  public var main_lc:Object = {
   connection: null,  // Main LocalConnection Object
   func: {
    echo: echo,       // Define simple echo Function
    exec: exec,       // Define simple exec Function
    heartbeat_update: heartbeat_update // Define Heart Beat Update Function
   }
  };

  /*
   Main Object Declaration for asLocalConnect (connectionName:String, global:Object)
   ---
   Initial asLocalConncet and add Eventlistener for the StageHelper
  */
  public function asLocalConnect(... args) : void {
   //log('Load Version: '+ asLocalConnectVersion +' from Markus Bordihn (http://markusbordihn.de)', 2);
   this.main_lc.connection = new LocalConnection();
   this.connection.allowDomain = [];
   addEventListener(Event.ADDED_TO_STAGE, StageHelper);
   if (args) {
       if (args[0]) {
           if (typeof args[0] === "string" && args[0] !== null && args[0] !== "") {
               this.connect(args[0]);
           }
       }
   }
  }

  /*
   INTERNAL: Stage Helper, to check access to the stage object
  */
  private function StageHelper(e:Event):void {
   log("StageHelper: " + this + " added to " + getQualifiedClassName(parent), 2);
   this._frameRate = stage.frameRate;
   this._quality = stage.quality;
   log('Current Framerate: ' + this._frameRate, 2);
   log('Current Quality: ' + this._quality, 2);
  }

  /*
   [Object].version()
   ---
   Return the asLocalConnection Versions Number.
  */
  public function version() : String {
   return asLocalConnectVersion;
  }

  /*
   [Object].connect(connectionName)
   ---
   Try to connect the asLocalConnect Object with the passed ConnectionName, will return "true" after a succuessfull connection.
   Do also some error checking and test if the ConnectionName already exists, include the Channel feature.
  */
  public function connect(connectionName:String) : Boolean {
   var result = false;
   if (this.connection.status) {
       log('asLocalConnect is already connect for this Object with the Name:' + connectionName + ' Channel:' + this.connection.channel,0);
   } else {
       if (connectionName.length > 3) {
           connectionName=checkName(connectionName);
           var status=false;
           try {
            status = !this.main_lc.connection.connect(connectionName + '_' + this.connection.channel);
           } catch (e:ArgumentError) {
            log('asLocalConnect Name: ' + connectionName + ' is already in used, try to change Channel !',1);
            for (var n=1; n <= 10; n++) {
                 var subcheck = true;
                 try {
                  this.main_lc.connection.connect(connectionName + '_' + n)
                 } catch (e:ArgumentError) {
                  subcheck = false;
                 }
                 if (subcheck) {
                     log('Found free Channel for asLocalConnect with Name:' + connectionName + ' Channel:' + this.connection.channel,3)
                     this.connection.channel = n;
                     status = true;
                     break;
                 }
            }
           }
           if (status) {
               log('Init Connection: ' + connectionName + ' connect to Channel: ' + this.connection.channel,2);
               this.connection.name = connectionName;
               this.connection.domain = domain();
               this.connection.status = true;
               this.main_lc.connection.client = this.main_lc.func;
               result =  true;
           } else {
               log('It is not possible to set up a asLocalConnect for Name:' + connectionName,0);
           }
       } else {
           log('asLocalConnect Name ' + connectionName + ' is to short !',0);
       }
   }
   return result;
  }

  /*
   [Object].listen(name, function)
   ---
   Set up the Listener to recieve Commands over .send, with a Listener the asLocalConnect will ignore the request.
  */
  public function listen(listnerName:String, functionName:Function) : void {
   if (listnerName && functionName !== null) {
       log('Add the Listern named "' + listnerName + '"',3);
       this.connection.func[listnerName] = functionName;
   }
  }

  /*
   [Object].allowDomain(domain)
   ---
   Add a Domain to the allowDomain List, remove a Domain from this list is not require yet, but it is possible when needed.
  */
  public function allowDomain(domain:String) : void {
   var check_new=true;
   if (domain === "*") {
       this.connection.allowDomain = [];
       if (this.connection.domain.indexOf('localhost') !== -1 && this.connection.domain.indexOf('127.0.0.1') !== -1) {
           trace('test3');
           log('Warning: allowDomain("*") was used in a webserver location(' + this.main_lc.connection.domain() + '), please check if you really want no Security Restrictions !',1);
       }
   } else {
       for (var n in this.connection.allowDomain) {
            if (domain === this.connection.allowDomain[n]) {
                log('Domain: ' + domain + ' is already in the allowDomain List !', 1)
                check_new = false;
                 break;
            }
       }
   }
   if (check_new) {
       if (this.connection.security < 7) {
           log('Add ' + domain + ' to allowDomain List.', 2);
           this.connection.allowDomain.push(domain);
           this.main_lc.connection.allowDomain.apply(null,this.connection.allowDomain);
       } else {
           log('The Security Level ' + this.connection.security + ' is not allowed to add the domain ' + domain + ' to the allowDomain List.', 1);
       }
   }
  }

  /*
   [Object].setSecurity(SecurityLevel)
   ---
   Set the Security Levels in a easy way, because of the changes in AS3 this has only basic possibilitys.
  */
  public function setSecurity(securityLevel:Number) : void {
   if (securityLevel) {
       log('Security Level is set to: ' + securityLevel, 2);
       this.connection.security = securityLevel;
       switch(securityLevel) {
        case 1 :  // No Security for testing (Null-Label) / Allow all Domains
         this.allowDomain("*");
        break;
        case 5 : // AllowDomains and SameDomain with local testing
         if (domain() === "localhost" || domain() === "127.0.0.1") {
             this.allowDomain("*");
         } else {
             this.allowDomain(domain());
         }
        break;
        case 6 : // AllowDomains and SameDomain
         this.allowDomain(domain());
        break;
        case 7 : // Only AllowDomains ignore SameDomain
         if(this.connection.allowDomain.length > 0) {
            this.main_lc.connection.allowDomain.apply(null,this.connection.allowDomain);
         }
        break;
        case 8 : // Only SameDomain ignore AllowDomains
         this.main_lc.connection.allowDomain(domain());
        break;
        case 9 : // Offline
         this.main_lc.connection.allowDomain(""); 
        break;
       }
   }
  }

  /*
   [Object].onLoad(function)
   ---
   Setup onLoad Event Handler, execute a function after connection is successfull.
  */
  /*public function onLoad(onLoad_function:Function) : void {
   if (onLoad_function !== null) {
       log('Add onLoad Event Handler.',3)
       this.addEventListener("load",onLoad_function);
	   //this.connection.load = onLoad_function;
   } else {
       log('onLoad Function is null !',0);
   }
  }*/

  /*
   [Object].onUnload(function)
   ---
   Setup onUnload Event Handler, execute a function after connection is lost.
  */
  /*public function onUnload(onUnload_function:Function) : void {
   if (onUnload_function !== null) {
       log('Add onUnload Event Handler.',3)
       this.connection.unload = onUnload_function;
   } else {
       log('onUnload Function is null !',0);
   }
  }*/

  /*
   [Object].onSync
   ---
   Setup onSync Event Handler, execute a function after successfull Sychronisation.
  */
  public function onSync(onSync_function:Function) : void {
   if (onSync_function !== null) {
       log('Add onSync Event Handler.',3)
       this.connection.func['asLocalConnect_sync'] = onSync_function;
   } else {
       log('onSync Function is null !',0);
   }
  }

  /*
   [Object].onStatus(FunctionName)
   ---
   Trigger a Function when with return the Status of the send
  */
  public function onStatus(onStatus_function:Function)  : void {
   if (onStatus_function !== null) {
       log('Add onStatus Event Handler.',3)
       this.connection.send.status = onStatus_function;
       this.connection.send.result = false;
   } else {
       log('onStatus Function is null !',0);
   }
  }
  
  /*
   [Object].send(connectionName, functionName, Arguments)
   ---
   Send a request to the named ConnectionName and FunctionName with additional Arguments.
  */
  public function send(connectionName:String, methodName:String, ...args) {
   if (connectionName && methodName && (this.connection.name == "" || (this.connection.name && this.connection.status))) {
       this.main_lc.connection.addEventListener(StatusEvent.STATUS, this.send_setStatus);
       this.main_lc.connection.send(checkName(connectionName) + '_' + this.connection.channel,'exec',methodName,args);
       log('Send request to exec "' + methodName + '" to "' + connectionName, 3);
   } else {
       log('Can\'t send request to exec "' + methodName + '" to "' + connectionName, 3);
   }
  }
  
  /*
   INTERNAL: send_setStatus()
  */
  private function send_setStatus(event:StatusEvent) : void {
   this.connection.send.result = (event.level === "status") ? true : false;
   log('The Result of the last asLocalConnect.send() is: ' + this.connection.send.result, 2);
   if (typeof this.connection.send.status === "function") {
       log('Trigger onStatus Event...',2)
       this.connection.send.status(event);
   }
   this.main_lc.connection.removeEventListener(StatusEvent.STATUS, this.send_setStatus);
  }

  /*
   [Object].sync(Master, connectionNames)
   ---
   Init the Sychronisation between the different Object, when addChild() was used then it also higher the framerate and set the quality to "LOW".
   After a connection this will reset to the initial value.
  */
  public function sync(master:String, ...slaves) : void {
   if (this.connection.name && this.connection.status) {
       if (slaves.length > 0) {
           var
            subtest = false,
            connetionNames:Object = slaves;
            
           log('Init Sync for ' + connetionNames.length + ' Connections',2);
           listen("asLocalConnect_sync_start", sync_start);
           if (checkName(master) === this.connection.name) {
               this.connection.syncLoad = init_sync_broadcast;
           }
           if (stage !== null) {
               if (this._frameRate >= 1) {
                   log('Set frameRate to 450 for better Sychronisation',3);
                   stage.frameRate = 450;
               }
               if (this._quality !== "LOW") {
                   log('Set Stage Quality to LOW for better Sychronisation',3);
                   stage.quality = "LOW";
               }
           }
           for (var n=0; n < connetionNames.length; n++) {
                if (connetionNames[n] === master) {
                    subtest = true;
                }
           }
           if (!subtest) {
               connetionNames.push(master);
           }
           this.heartbeats.beat.timeframe = 100;
           heartbeat.apply(null,connetionNames);
       } else {
           log('Sync was not started, because connectionNames are missing.',0);
       }
   } else {
       log('Sync was not started, because asLocalConnect is not connected or has no connection Name.',0);
   }
  }

  /*
   INTERNAL: Set Timer Events for the best possible Sychronisation
  */
  private function sync_start(syncTime:Number, methodName:String, ...args) : void {
   if (syncTime) {
       var correctTimer:Number = syncTime - Number((new Date).getTime());
       var syncTimer:Timer = new Timer(correctTimer, 1);
       if (args.length > 0) {
           syncTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function() {sync_exec(methodName, args);});
       } else {
           syncTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function() {sync_exec(methodName);});
       }
       syncTimer.start();
       log('Recieved Syn Timer: ' + syncTime, 2);
       log('Set Timer Event ' + correctTimer + 'ms for function "' + methodName + '"' + ((args.length > 0) ? ' width ' + args.length + ' argument' : ''), 2);
   } else {
       log('Sync not starting, missing Parameter !', 2);
   }
  }

  /*
   INTERNAL: Send Broadcast for Sync Events
  */
  private function init_sync_broadcast() : void {
   sync_broadcast(true, 'asLocalConnect_sync');
  }

  /*
   INTERNAL: Execute Sync Commands after same Basic Checks
  */
  private function sync_exec(methodName:String, ...args) : void {
   log('Sync Timer will now execute function ' + methodName + ((args.length > 0) ? ' with ' + args.length + ' argument:' + args : ''),3);
   if (!this.sync_lc.sync && stage !== null) {
       if (this._frameRate >= 1) {
           log('Set frameRate back to the default value of ' + this._frameRate,3);
           stage.frameRate = this._frameRate;
       }
       if (this._quality !== stage.quality) {
           log('Set Stage Quality back to the default value of ' + this._quality,3);
           stage.quality = this._quality;
       }
   }
   if (this.connection.func[methodName] !== null && typeof this.connection.func[methodName] === "function") {
       if (args.length > 0) {
           this.connection.func[methodName](args);
       } else {
           this.connection.func[methodName]();
       }
       this.sync_lc.sync = true;
       log('Sync Timer was executed on ' + (new Date).getTime(),3);
   } else {
       if (methodName === "asLocalConnect_sync") {
           log('Sync Timer don\'t found a default onSych Event, so nothing will executed.',3);
       } else {
           log('Sync Timer don\'t found a function named ' + methodName + ' please check if .listen(\'' + methodName + '\',{function}) is correct !',2);
       }
   }
  }

  /*
   [Object].broadcast(FunctionName, Arguments)
   ---
   Send a normal Broadcast to all Objects, please keep in mind this is not synchron.
  */
  public function broadcast(methodName:String, ...args) : void {
   if (methodName && this.heartbeats.status) {
       log('Try to send Broadcast for "' + methodName + '"' + ((args) ? ' with ' + args.length + ' arguments' : '') + ' to ' + this.heartbeats.list.length + ' Connections.', 3);
       var 
        n = 0,
        result = true;
       
       for (n in this.heartbeats.list) {
            if(this.heartbeats.list[n][1] > 0) {
               this.main_lc.connection.send(this.heartbeats.list[n][0] + '_' + this.connection.channel, 'exec', methodName, args);
            }
       }
   } else {
    log('Broadcast failed !' + ((!this.heartbeats.status) ? ' Its seems Heartbeat is not connected.' : '') + ((methodName) ? '' : ' There is no methodeName to execute.') ,0);
   }
  }
  
  /*
   [Object].sync_broadcast(execute function self, FunctionName, Arguments)
   ---
   Try to send a synchron Broadcast to all Objects, use Timer Events to lower the execution differents to -10ms/+10ms.
  */
  public function sync_broadcast(execSelf:Boolean, methodName:String, ...args) : void {
   if (this.heartbeats.status) {
       var syncTimer:Number = Number((new Date).getTime()) + 500;
       log('Start Sync Timer: ' + syncTimer + ' for function "' + methodName + '"' + ((args.length > 0) ? ' width ' + args.length + ' arguments' : '') , 2);
       if (args.length > 0) {
           broadcast("asLocalConnect_sync_start", syncTimer, methodName, args);
           if (execSelf) {
               sync_start(syncTimer, methodName, args);
        }
       } else {
           broadcast("asLocalConnect_sync_start", syncTimer, methodName);
           if (execSelf) {
               sync_start(syncTimer, methodName);
        }
       }
   } else {
       log('Broadcast of Sync failed, Sychronisation is not established !', 2);
   }
  }

  /*
   [Object].domain()
   ---
   Return the current Domain of the asLocalConnect Object, it most case this is the same Domain as the SWF file is located.
  */
  public function domain() : String {
   return this.main_lc.connection.domain;
  }

  /*
   [Object].heartbeat(connectionNames)
   ---
   Init HeartBeat for the passed Connection Names, set up Timer Events to check the connection as fast as possible.
  */
  public function heartbeat(...args) : void {
   if (args && this.connection.status) {
    log('Init HeartBeat for '+ args.length +' Connections \tChannel:'+ this.connection.channel,2);
    this.heartbeat_init();
    for (var n=0; n < args.length; n++) {
     if (checkName(args[n]) !== this.connection.name) {
         this.heartbeats.list.push([checkName(args[n]),0]);
     } else {
         log('Exclude own asLocalConnect Name:' + args[n] + ' from the HeartBeat List.', 3);
     }
    }
    this.heartbeats.beat.interval = this.heartbeats.beat.timeframe * args.length + (Math.round(100*Math.random()));
    this.heartbeat_lc.connection = new LocalConnection();
    this.heartbeat_lc.connection.connect(this.connection.name + this.connection.channel + '_HeartBeat');
    this.heartbeat_lc.connection.addEventListener(StatusEvent.STATUS, this.heartbeat_status);
   
    if (!this.heartbeats.beat.id) {
     this.heartbeats.beat.id = setInterval(this.heartbeat_beater, this.heartbeats.beat.interval);
    }
   }
  }

  /*
   [Object].heartbeatstatus(connectionName)
   ---
   Return the Status for all HeartBeat Connections or for only on Connection over an Object.
  */
  public function heartbeatstatus(... args) : Boolean {
   var
    n = 0,
    search = {
     id: null,
     found: false,
     value: this.heartbeats.status
    }; 

   if((args.length > 0) ? (typeof args[0] === "string") : false) {
      search.value = false;
      search.id = checkName(args[0]);
   }
 
   for (n in this.heartbeats.list) {
        if ((search.id) ? ( (search.id === this.heartbeats.list[n][0]) ? true : false) : true) {
            log('Connection Status\tName:' + this.heartbeats.list[n][0] + ' \tChannel:' + this.connection.channel + '\tStatus: ' + ((this.heartbeats.list[n][1]) ? true : false),3);
            search.value = this.heartbeats.list[n][1];
            search.found = true;
        }
   }
   
   if (!search.found && search.id) {
       log('Connection Status for Name:' + search.id + ' is not possible, Connection not found !',1);
   }
   
   return search.value;
  }

  /*
   [Object].close()
   ---
   Close the current Connection and reset the HeartBeat
  */
  public function close() : void {
   log('Close all asLocalConnect Connections...', 3);
   this.main_lc.connection.close();
   this.heartbeat_lc.connection.close();
   this.heartbeat_init();
   this.connection.status = false;
  }

  /*
   [Object].info()
   ---
   Return asLocalConnection Information for the current Connection with a trace and over an Object.
  */
  public function info() : Object {
   log('Name: '+ this.connection.name + '\tChannel: '+ this.connection.channel + '\tStatus:' + this.connection.status, 2);
   return {channel: this.connection.channel, name: this.connection.name, status: this.connection.status};
  }

  /*
   [Object].onHeartBeat
   ---
   Set the onHeartBeat Event when a HeartBeat will send out.
  */
  public function onHeartBeat(HeartBeat_function:Function) : void {
   if (HeartBeat_function !== null) {
       this.heartbeats.load = HeartBeat_function;
   }
  }

  /*
   INTERNAL: Simple Echo Handler
  */
  private function echo(msg:String) : void {
   if (msg) {
       trace('Echo: ' + msg);
   }
  }

  /*
   INTERNAL: Listener to Handel Requests and Execute Functions
  */
  private function exec(methodName:String, args) : void {
   if (methodName) {
       if (typeof(args) == 'object') {
           this.connection.func[methodName].apply(null,args);
       } else {
           this.connection.func[methodName](args);
       }
   }
  }

  /*
   INTERNAL: Init Heartbeat and set values to default
  */
  private function heartbeat_init() : void{
   if (this.heartbeats.id) {
       clearInterval(this.heartbeats.id);
       this.heartbeats.id="";
   }
   if (this.heartbeats.beat.id) {
       clearInterval(this.heartbeats.beat.id);
       this.heartbeats.beat.id="";
   }
   this.heartbeats.status=false;
   this.heartbeats.counter=0;
   this.heartbeats.list=[];
  }

  /*
   INTERNAL: Update Heartbeat List with Connections Numbers
  */
  private function heartbeat_update(connectionName:String, connectionNumber:Number) : void {
   for (var n in this.heartbeats.list) {
        if(connectionName === this.heartbeats.list[n][0]) {
           if(connectionNumber < 9) {
              this.heartbeats.list[n][1] = connectionNumber;
           }
           break;
       }
   }
  }
 
  /*
   INTERNAL: Reset all Heartbeat Counter to 0 and execute OnUnload Event
  */
  private function heartbeat_flush() : void {
   for (var n in this.heartbeats.list) {
        this.heartbeats.list[n][1]=0;
   }
   if (this.connection.unload !== null) {
       log('Trigger OnUnload Event...', 3);
       this.connection.unload();
   }
  }

  /*
   INTERNAL: Send the Beat for the Heartbeat
  */
  private function heartbeat_beat(connectionName:String, checkNum:Number) : void {
   this.heartbeat_lc.connection.send(connectionName+'_'+this.connection.channel,"heartbeat_update",this.connection.name,checkNum);
  }
 
  /*
   INTERNAL: Heartbeater, Calculate Timers and send a broadcast to all Objects for the Heartbeat
  */
  private function heartbeat_beater() : void {
   for (var n in this.heartbeats.list) {
        var checkTimer:Number=n * this.heartbeats.beat.timeframe;
        setTimeout(heartbeat_beat,checkTimer,this.heartbeats.list[n][0],this.heartbeats.list[n][1]+1);
   }
   if(this.heartbeats.load !== null) {
      this.heartbeats.load();
   }
  }
 
  /*
   INTERNAL: Check the Heartbeat Status
  */
  private function heartbeat_status(event:StatusEvent) : void {
   switch (event.level) {
    case 'status' :
     if(!this.heartbeats.id && !this.heartbeats.status) {
        if (++this.heartbeats.counter <= 10) {
            this.heartbeat_interval();
        } else {
         this.heartbeats.id = setInterval(this.heartbeat_interval, this.heartbeats.beat.interval);
        }
     }
    break;
    case 'error'  :
     if (this.heartbeats.status) {
         this.heartbeat_flush();
         this.heartbeats.status = false;
     }       
     if(!this.heartbeats.id) { 
        this.heartbeats.id = setInterval(this.heartbeat_interval, this.heartbeats.beat.interval);
     }
    break;
   }
  }
 
  /*
   INTERNAL: Interval Timer Event for the Heartbeat
  */
  private function heartbeat_interval() : void {
   var 
    hbstatus=true; 

   for (var n in this.heartbeats.list) {
        if (this.heartbeats.list[n][1] < 2) {
            hbstatus=false;
        }
   }
   if(hbstatus) {
      log('Heartbeat is connected, take a look if have something to do...' , 2);
      if (this.heartbeats.id) {
          clearInterval(this.heartbeats.id);
          log('Remove HeartBeat Event with ID ' + this.heartbeats.id , 3);
          this.heartbeats.id="";
      }
      this.heartbeats.status=true;
      if (this.connection.load !== null) {
          log('Trigger OnLoad Event...', 3);
          this.connection.load();
      }
      if (this.connection.syncLoad !== null) {
          log('Trigger Sync OnLoad Event...', 3);
          this.connection.syncLoad();
      }
   } else {
      log('Connection: ' + this.connection.name + ' \tChannel:' + this.connection.channel + '\tHeartBeat Status: ' + hbstatus , 3);
   }
  }

  /*
   INTERNAL: Verbose Handler for Messages Log
  */
  private function log(message: String, level: Number) : void {
   if (this.verboseLevel >= level) {
       /* 
        Level 0 : error
        Level 1 : warning
        Level 2 : info
        Level 3 : debug
        Level 4 : -
        LeveL 5 : all
       */
       if (message) {
           trace('[asLocalConnect:' + ((this.connection.name) ? this.connection.name + ':' : '' ) + level + '] ' + message);
       }
   }
  }

  /*
   Set Verbose Level
   ---
   Define the Verbose Level for asLocalConnect, when you need more Information for Error Checking usw 3 or 5.
  */
  public function verbose(level: Number) : void {
   if (level >= 0 && level <= 5) {
       this.verboseLevel = level;
       log('Set Verbose Level to: ' + level,level);
   } else {
       log('Verbose Level is only possible from 0 - 5 !',0);
   }
  }

  /*
   INTERNAL: check and return asLocalConnectName 
  */
  private function checkName(Name:String) : String {
   if (Name.substr(0,1) != '_') {
       return '_'+Name;
   } else {
       return Name;
   }
  }

 }
}