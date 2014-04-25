#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

SessionManager = "com.deepin.SessionManager"

power_request = (power) ->
    # option = ["lock","suspend","logout","restart","shutdown"]
    try
        dbus_power = get_dbus("session",SessionManager,"RequestLock")
        echo dbus_power
    catch e
        echo "dbus_power error:#{e}"
    if not dbus_power? then return
    document.body.style.cursor = "wait" if power isnt "suspend" and power isnt "lock"
    echo "Warning: The system will request ----#{power}----"
    switch power
        when "lock" then dbus_power.RequestLock()
        when "suspend" then dbus_power.RequestSuspend()
        when "logout" then dbus_power.RequestLogout()
        when "restart" then dbus_power.RequestReboot()
        when "shutdown" then dbus_power.RequestShutdown()
        else return



power_get_inhibit = (power) ->
    LOGIN1 =
        name:"org.freedesktop.login1"
        path:"/org/freedesktop/login1"
        interface:"org.freedesktop.login1.Manager"
    try
        dbus_login1 = get_dbus("system",LOGIN1,"ListInhibitors")
        echo dbus_login1
    catch e
        echo "dbus_login1 error:#{e}"
    if not dbus_login1? then return
    
    inhibitorsList = dbus_login1.ListInhibitors_sync()
    cannot_excute = []
    for inhibit,i in inhibitorsList
        type = inhibit[0]
        switch type
            when "shutdown" then cannot_excute.push({type:"shutdown",inhibit:inhibit})
            when "idle"  then cannot_excute.push({type:"suspend",inhibit:inhibit})
            when "handle-suspend-key"  then cannot_excute.push({type:"suspend",inhibit:inhibit})
            when "handle-power-key"
                cannot_excute.push({type:"restart",inhibit:inhibit})
                cannot_excute.push({type:"shutdown",inhibit:inhibit})
                cannot_excute.push({type:"logout",inhibit:inhibit})
    
    if cannot_excute.length == 0 then return
    for tmp in cannot_excute
        if power is tmp.type then return tmp.inhibit
    return null

power_can = (power)->
    inhibit = power_get_inhibit(power)
    if inhibit is null
        echo "#power_can:#{power} true"
        return true
    else
        echo "#power_can:#{power} false"
        #return false
        return true

inhibit_test = ->
    LOGIN1 =
        name:"org.freedesktop.login1"
        path:"/org/freedesktop/login1"
        interface:"org.freedesktop.login1.Manager"
    try
        dbus_login1 = get_dbus("system",LOGIN1,"Inhibit")
    catch e
        echo "dbus_login1 error:#{e}"
    if not dbus_login1? then return
    
    dsc_update_inhibits = []
    dsc_update_inhibits = ["shutdown","sleep","idle","handle-power-key","handle-suspend-key","handle-hibernate-key","handle-lid-switch"]
    for inhibit in dsc_update_inhibits
        dbus_login1.Inhibit_sync(
            inhibit,
            "DeepinSoftCenter",
            "Please wait a moment while system update is being performed... Do not turn off your computer.",
            "block"
        )
    power = "shutdown"
    power_can(power)

#inhibit_test()

power_can_from_deepin_dbus = (power) ->
    try
        dbus_power = get_dbus("session",SessionManager,"CanShutdown")
        echo dbus_power
    catch e
        echo "dbus_power error:#{e}"
    if not dbus_power? then return
    result = true
    switch power
        when "lock" then result = true
        when "suspend" then result = dbus_power.CanSuspend_sync()
        when "logout" then result = dbus_power.CanLogout_sync()
        when "restart" then result = dbus_power.CanReboot_sync()
        when "shutdown" then result = dbus_power.CanShutdown_sync()
        else result = false
    echo "power_can : -----------Can_#{power} :#{result}------------"
    if result is undefined then result = true
    return result

power_force = (power) ->
    try
        dbus_power = get_dbus("session",SessionManager,"ForceReboot")
        echo dbus_power
    catch e
        echo "dbus_power error:#{e}"
    if not dbus_power? then return
    # option = ["lock","suspend","logout","restart","shutdown"]
    echo dbus_power
    document.body.style.cursor = "wait" if power isnt "suspend" and power isnt "lock"
    echo "Warning: The system will ----#{power}---- Force!!"
    switch power
        when "lock" then dbus_power.RequestLock()
        when "suspend" then dbus_power.RequestSuspend()
        when "logout" then dbus_power.ForceLogout()
        when "restart" then dbus_power.ForceReboot()
        when "shutdown" then dbus_power.ForceShutdown()
        else return


