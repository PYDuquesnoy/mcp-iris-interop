/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ASQ.SetUtils [ Abstract, System = 3 ]
{

ClassMethod pp(set As %AbstractSet, offset As %Integer = 0)
{
#define QUOTE(%val) $zu(144,1,%val)
    try {
        set isLabeled = set."_isLabeled"()
        if (isLabeled) {
            write "{"
            set close = "}"
        } else {
            write "["
            set close = "]"
        }
        set it = set.iterator()
        while it.hasNext() {
            set next = it.next()
            if $isobject(next.value) {
                write !,?(offset+2)
                write:isLabeled $$$QUOTE(next.key),": "
                do ..pp(next.value, offset + 2)
            } else {
                write !,?(offset+2),$select(isLabeled:$$$QUOTE(next.key)_": ",1:""),$$$QUOTE(next.value)
            }
            if it.hasNext() {
                write ","
            }
        }
        write !,?offset,close
    } catch exc {
        write !,"Exception caught: ",exc.AsSQLMessage()
    }
    return
}

ClassMethod ppToArray(set As %AbstractSet, offset As %Integer = 0, ByRef output)
{
#define QUOTE(%val) $zu(144,1,%val)
    try {
        if '$get(output) set output = 1, output(1) = ""
        set isLabeled = set."_isLabeled"()
        if (isLabeled) {
            set output(output) = $get(output(output)) _ "{"
            set close = "}"
        } else {
            set output(output) = $get(output(output)) _ "["
            set close = "]"
        }
        set it = set.iterator()
        while it.hasNext() {
            set next = it.next()
            if $isobject(next.value) {
                set output($increment(output)) =  ..pad(offset + 2)
                set:isLabeled output(output) =  output(output) _ $$$QUOTE(next.key) _ ": "
                do ..ppToArray(next.value, offset + 2, .output)
            } else {
                set output($increment(output)) = ..pad(offset+2) _ $select(isLabeled:$$$QUOTE(next.key)_": ",1:"") _ $$$QUOTE(next.value)
            }
            if it.hasNext() {
                set output(output) = $get(output(output)) _ ","
            }
        }
        set output($increment(output)) = ..pad(offset) _ close
    } catch exc {
        set output($increment(output)) = "Exception caught: "  _ exc.AsSQLMessage()
    }
    return
}

ClassMethod pad(offset) As %String
{
    if '$get(offset) return ""
    set $piece(pad," ",offset) = " "
    return pad
}

}
