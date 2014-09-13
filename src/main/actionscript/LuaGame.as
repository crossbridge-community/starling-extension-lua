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
import com.adobe.utils.AGALMacroAssembler;

import crossbridge.lua.__lua_objrefs;

import flash.external.ExternalInterface;
import flash.utils.Dictionary;

import starling.core.Starling;
import starling.display.Sprite;
import starling.events.Event;
import starling.textures.RenderTexture;

public class LuaGame extends Sprite {
    public static var luascript:String;
    public var luastate:int;
    private var panicabort:Boolean;

    public function LuaGame() {
        // trick mxmlc into linking these classes
        var pointlessref1:LuaDisplayObject;
        var pointlessref2:AGALMacroAssembler;
        var pointlesref3:RenderTexture;

        addEventListener(Event.ADDED_TO_STAGE, onAdded);
        addEventListener(Event.ENTER_FRAME, update);
    }

    private function push_objref(o:*):void {
        var udptr:int = Lua.push_flashref(luastate);
        __lua_objrefs[udptr] = o;
    }

    public function onError(e:*):void {
        trace(e);
        if (ExternalInterface.available) {
            ExternalInterface.call("reportError", e.toString());
        }
        Starling.current.stop();
    }

    public function atPanic(e:*):void {
        onError("Lua Panic: " + Lua.luaL_checklstring(luastate, -1, 0));
        panicabort = true;
    }

    private function onAdded(e:*):void {
        // Initialize Lua and load our script
        var err:int = 0;
        luastate = Lua.luaL_newstate();
        panicabort = false;
        Lua.lua_atpanic(luastate, atPanic);
        Lua.luaL_openlibs(luastate);

        err = Lua.luaL_loadstring(luastate, luascript);
        if (err) {
            onError("Error " + err + ": " + Lua.luaL_checklstring(luastate, 1, 0));
            Lua.lua_close(luastate)
            return
        }

        try {
            __lua_objrefs = new Dictionary();

            // This runs everything in the global scope
            err = Lua.lua_pcallk(luastate, 0, Lua.LUA_MULTRET, 0, 0, null);

            // give the lua code a reference to this and Starling
            Lua.lua_getglobal(luastate, "setupGame");
            push_objref(this);
            push_objref(Starling.current.nativeStage.stage3Ds[0].context3D);
            Lua.lua_pushinteger(luastate, Starling.current.viewPort.width);
            Lua.lua_pushinteger(luastate, Starling.current.viewPort.height);
            Lua.lua_callk(luastate, 4, 0, 0, null);
        } catch (e:*) {
            onError("Exception thrown while initializing code:\n" + e + e.getStackTrace());
        }
    }

    private function update(e:*):void {
        try {
            Lua.lua_getglobal(luastate, "starlingUpdate")
            Lua.lua_callk(luastate, 0, 0, 0, null)
        } catch (e:*) {
            if (!panicabort)
                onError("Exception thrown while calling starlingUpdate:\n" + e + e.getStackTrace());
        }
    }
}
}
