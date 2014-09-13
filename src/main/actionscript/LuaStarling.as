/*
 * =BEGIN MIT LICENSE
 * 
 * The MIT License (MIT)
 *
 * Copyright (c) 2013 Adobe Systems Inc
 * Copyright (c) 2014 The CrossBridge Team
 * https://github.com/crossbridge-community
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * =END MIT LICENSE
 *
 */
package {
import crossbridge.lua.CModule;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.events.AsyncErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.external.ExternalInterface;
import flash.geom.Rectangle;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.system.Security;

import starling.core.Starling;

[SWF(width="640", height="480", frameRate="60", backgroundColor="#999999")]
public class LuaStarling extends Sprite {

    private static var CANVAS_WIDTH:Number = 640;

    private static var CANVAS_HEIGHT:Number = 480;

    private var mStarling:Starling;

    private var scriptLoader:URLLoader;

    public function LuaStarling() {
        trace(this, "created");
        addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
    }

    private function onAdded(event:Event):void {
        trace(this, "onAdded");
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);

        // Init Stage
        stage.frameRate = 60;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.quality = StageQuality.MEDIUM;

        // Initialize CrossBridge LUA
        CModule.startAsync(this);

        // Check for HTML or Standalone based
        if (ExternalInterface.available) {
            Security.allowDomain("*");
            try {
                ExternalInterface.addCallback("newLuaScript", newLuaScript);
            } catch (error:Error) {
                trace(this, error);
            }
        } else {
            loadScript();
        }

        // Initialize the Starling world
        /*if (Capabilities.manufacturer.toLowerCase().indexOf("ios") != -1 ||
         Capabilities.manufacturer.toLowerCase().indexOf("android") != -1)
         {
         _width = Capabilities.screenResolutionX
         _height = Capabilities.screenResolutionY
         }*/

        //Starling.multitouchEnabled = true
    }

    private function loadScript():void {
        scriptLoader = new URLLoader();
        scriptLoader.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onError, false, 0, true);
        scriptLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError, false, 0, true);
        scriptLoader.addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
        scriptLoader.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
        scriptLoader.load(new URLRequest("game.lua"));
    }

    private function onComplete(event:Event):void {
        trace(this, "onComplete");
        LuaGame.luascript = scriptLoader.data;
        scriptLoader = null;
        initStarling();
    }

    private function initStarling():void {
        trace(this, "initStarling");
        if (mStarling) {
            mStarling.stop();
            mStarling.dispose();
        }
        mStarling = new Starling(LuaGame, stage, new Rectangle(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT));
        mStarling.showStats = true;
        mStarling.simulateMultitouch = false;
        mStarling.enableErrorChecking = false;
        mStarling.start();
    }

    private function newLuaScript(value:String):void {
        LuaGame.luascript = value;
        initStarling();
    }

    public function onError(event:Event):void {
        trace(this, "onError: " + event);
        if (ExternalInterface.available) {
            ExternalInterface.call("reportError", event.toString())
        }
    }

    // Console

    public function write(fd:int, buf:int, nbyte:int, errno_ptr:int):int {
        var str:String = CModule.readString(buf, nbyte);
        trace(str);
        return nbyte;
    }
}
}
