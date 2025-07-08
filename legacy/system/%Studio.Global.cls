/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provide interface to globals
Class %Studio.Global Extends %RegisteredObject [ System = 3 ]
{

/// Kill a global node.
/// You pass it the name of the node and a flag to say if you want to kill subscripts
/// or just this node and leave any subscripts.
ClassMethod Kill(Node As %String, KillSubs As %Boolean = 0) As %Status
{
	If '..validateGlobalNode(Node) Quit $$$ERROR($$$BadGlobalDecode,Node)
	Set $ztrap="killerr"
	If KillSubs {
		Kill @Node
	} Else {
		ZKill @Node
	}
	Quit $$$OK
killerr	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Set a global node.
/// You pass it the name of the node to set, along with the value to set and
/// the values format and it sets this node.
ClassMethod Set(Node As %String, %Value As %String, ValFormat As %Integer) As %Status
{
	If ValFormat=3 Quit $$$ERROR($$$BadGlobalFormat)
    If ValFormat=2 {
        #; Check if %Value was pretty-printed (contains a $c or $lb)
        #; If %Value is not formatted, treat is a literal (ValFormat=1)
        Set regex = ##class(%Regex.Matcher).%New("(""[^""]+"")",%Value)
        Set newValue = $ZCONVERT(regex.ReplaceAll(""),"l")
        If (
            #; %Value contains a $c or $lb
            ((newValue["$char(") || (newValue["$c(") || (newValue["$listbuild(") || (newValue["$lb(")) &&
            #; %Value doesn't contain a $ that isn't part of $c or $lb
            '$MATCH(newValue,".*\$(?!c\(|char\(|lb\(|listbuild\().*") &&
            #; %Value doesn't contain a dotted reference (class member, global, routine)
            '$MATCH(newValue,".*(\.[""#%\p{L}]).*") &&
            #; Now we can attempt to decode %Value
            '..decode(%Value,.%Value)
        ) {
            #; %Value is not a valid expression
            Quit $$$ERROR($$$BadGlobalDecode,%Value)
        }
    }
	If '..validateGlobalNode(Node) Quit $$$ERROR($$$BadGlobalDecode,Node)
	Set $ztrap="seterr"
	Xecute "Set "_Node_"=%Value"
	Quit $$$OK
seterr	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Enumarate this global node and returning the $order items below this
/// It takes the name of a global or local array to inspect including and initial subscripts.
/// It returns the subscript name, the value and the $data of this node. Then it also returns
/// the format of both the subscript and the data:<ul>
/// <li>1 - String format, this is the value of the value/subscript unaltered</li>
/// <li>2 - ObjectScript format, the value has been converted into the ObjectScript representation for easy viewing,
/// for example instead of showing the binary value a list is displayed as '$LB(1,"test")'</li>
/// <li>3 - Not editable. Due to issues with the length of this data not all of it can be displayed so a portion is
/// displayed</li></ul>
/// The <var>Pattern</var> parameter is supplied then it pattern matches on the data of each node and only display
/// data that matches this pattern. The pattern match works the same as the Studio open dialog pattern matching and support
/// both '*' which matches any number of characters and '?' which matches a single character operators. For example
/// 'a*b' will match any string that starts with 'a' and ends with 'b'. If <var>Format</var> is 0 then do not format the
/// resultset output.
Query GlobalList(Node As %String, Pattern As %String, Format As %Boolean = 1) As %Query(ROWSPEC = "Subscript:%String:Subscript name,Value:%String:Value of this node,Data:%Integer:$data value,ValueFormat:%Integer:Format of value,SubscriptFormat:%Integer:Format of the subscript") [ SqlProc ]
{
}

ClassMethod GlobalListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GlobalListExecute ]
{
	Quit $$$OK
}

ClassMethod GlobalListExecute(ByRef qHandle As %Binary, Node As %String, Pattern As %String = "", Format As %Boolean = 1) As %Status
{
	Set as="",ae="",cospattern=""
	If Pattern'="" Do ..genPattern(Pattern,.as,.ae,.cospattern)
	Set qHandle=$listbuild("",Node,1,as,ae,cospattern,Format)
	Quit $$$OK
}

ClassMethod GlobalListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..GlobalListFetchRows(.qHandle,1,.Row,,.AtEnd)
}

ClassMethod GlobalListFetchRows(ByRef qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer = 0) As %Status
{
	Set $ztrap="trap"
	Set RowSet="",number=0
	If qHandle="" Set AtEnd=1,ReturnCount=0 Quit $$$OK
	Set node=$list(qHandle,2),subscript=$list(qHandle),first=$list(qHandle,3),start=$list(qHandle,4),end=$list(qHandle,5),pattern=$list(qHandle,6),format=$list(qHandle,7)
	If FetchCount=0 Set FetchCount=-1
	Set datatype=1,subscripttype=1
	
	#; If we ask for top node give the list of global names
	If node="" {
		New %globaldir
		Do GetDir^%SYS.GD($namespace,"%globaldir")
		#; This only applies to subscripts and not to the global list itself
		Set first=0
		Set subscript=$order(%globaldir(subscript)) Set:subscript'="" data=$data(@("^"_subscript)),value=$get(@("^"_subscript))
		While subscript'="" {
			Set datatype=..format(value,.newvalue,format),subscripttype=1,newsubscript="^"_subscript
			Set RowSet=RowSet_$listbuild(newsubscript,newvalue,data,datatype,subscripttype),number=number+1
			If number=FetchCount||($length(RowSet)>32000) Set exit=1 Quit
			Set subscript=$order(%globaldir(subscript)) Set:subscript'="" data=$data(@("^"_subscript)),value=$get(@("^"_subscript))
		}
	} Else {
		If first {
			Set value=$get(@node),data=$data(@node)
			Set datatype=..format(value,.newvalue,format),subscripttype=..format(subscript,.newsubscript,format)
			Set RowSet=RowSet_$listbuild(newsubscript,newvalue,data,datatype,subscripttype),number=number+1
		}
		If number'=FetchCount,$length(RowSet)'>32000 {
			Set first=0,value="",subscript=$order(@node@(subscript),1,value) Set:subscript'="" data=$data(^(subscript))
			While subscript'="" {
				If (start'=""&&(start]value))||(end'=""&&($extract(value,1,$length(end))]end))||(pattern'=""&&(value'?@pattern)) {
					If data=1 Goto cont
					#; We still need to show subscripts even if data does not match
					Set data=10,value=""
				}
				Set datatype=..format(value,.newvalue,format),subscripttype=..format(subscript,.newsubscript,format)
				Set row=$listbuild(newsubscript,newvalue,data,datatype,subscripttype)
				If RowSet'="",$length(RowSet)+$length(row)>32000 Quit
				Set RowSet=RowSet_row,number=number+1
				If number=FetchCount||($length(RowSet)>32000) Quit
cont			Set value="",subscript=$order(^(subscript),1,value) Set:subscript'="" data=$data(^(subscript))
			}
		}
	}
	If subscript="",'first Set AtEnd=1,qHandle="" Quit $$$OK
	Set ReturnCount=number
	Set $list(qHandle)=subscript,$list(qHandle,3)=0
	Quit $$$OK
	#; If any error occurs just ignore it and show a null resultset
trap	Set AtEnd=1,qHandle="",ReturnCount=number
	Quit $$$OK
}

/// Format the 'value' so it is readable and return the type of format we have used.
ClassMethod format(value As %String, ByRef output As %String, format As %Boolean = 1) As %Integer
{
	Set output=value
	If 'format Quit 1
	If output="" Quit 1
	Set $ztrap="toobig"
	If $length($listbuild(value))>($$$MaxLocalLength-100) Goto toobig
	Set $ztrap="quit3"
	If $listvalid(value) {
		Set tmp=""
		For i=1:1:$listlength(value) {
			Set data=$listdata(value,i)
			If 'data {
				Set tmp=tmp_","
			} Else {
				Set item=$list(value,i)
				Set format=..format(item,.out)
				If format=1 {
					Try {
						Set isstring=$listbuild(+item)'=$listbuild(item)
					} Catch {
						#; If we can not construct the +item due to a MAXVALUE error it must be a string form
						Set isstring=1
					}
					If isstring {
						Set tmp=tmp_""""_$replace(out,"""","""""")_""","
					} Else {
						Set tmp=tmp_out_","
					}
				} ElseIf format=2 {
					Set tmp=tmp_out_","
				} ElseIf format=3 {
					Goto quit3
				}
			}
		}
		Set output="$lb("_$extract(tmp,1,*-1)_")"
		Quit 2
	}
	Set map=$translate(value,$char(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31),$char(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
	If map'[$char(0) Quit 1
	Set value=$replace(value,"""",""""""),map=$replace(map,"""","""""")
	Set f=$find(map,$char(0)),oldf=1,openc=0,tmp=""
	While f'=0 {
		If openc,f-2'<oldf Set tmp=tmp_")" Set openc=0
		Set val=$extract(value,oldf,f-2)
		If val'="" Set tmp=tmp_$select(tmp="":"""",1:"_""")_val
		Set char=$ascii(value,f-1)
		If 'openc { Set tmp=tmp_$select(tmp="":"",1:"""_")_"$c(" } Else { Set tmp=tmp_"," }
		Set tmp=tmp_char
		Set openc=1
		Set oldf=f,f=$find(map,$char(0),f)
	}
	If openc {
		Set tmp=tmp_")"
		If oldf'>$length(value) Set tmp=tmp_"_"""_$extract(value,oldf,*)_""""
	} Else {
		Set tmp=tmp_""""
	}
	Set output=tmp
	Quit 2
quit3	Quit 3
toobig	Set output=$extract(value,1,$$$MaxStringLength\2-100) Quit 3
}

ClassMethod decode(input As %String, ByRef output As %String) As %Integer [ Internal ]
{
    Try {
        #; The parentheses are necessary to force an error if node is not an expression (i.e. contains commands)
        Set output = $XECUTE("Quit ("_input_")")
        Return 1
    } Catch {
        Set output = input
        Return 0
    }
}

/// Returns 1 if node is a valid global reference (with or without subscripts).
ClassMethod validateGlobalNode(node As %String) As %Boolean [ Internal ]
{
    Try {
        #; Must check if node starts with a caret because $QSUBSCRIPT()
        #; accepts local variables. No need to wrap node in a $GET()
        #; because a thrown <UNDEFINED> will correctly return 0.
        If $EXTRACT(node) '= "^" Return 0
        #; Will throw if node does not start with a valid gref.
        If $QSUBSCRIPT(node,0)
        #; Make sure that nothing follows the closing parenthesis
        #; because $QSUBSCRIPT() will return immediately after it
        #; finds the closing parenthesis and allows trailing junk.
        #; To do this, we need to remove all characters inside string
        #; literals and make sure nothing follows the first (should
        #; be only) closing parenthesis. This check will pass if
        #; node has no subscripts.
        If $PIECE(
            ##class(%Regex.Matcher).%New("(""[^""]+"")",node).ReplaceAll(""),
            ")",2,*
        ) '= "" {
            Return 0
        }
        Return 1
    } Catch {
        Return 0
    }
}

/// Passed a pattern match this returns an COS style pattern and a start and stop point.
ClassMethod genPattern(Spec As %String, ByRef AS As %String, ByRef AE As %String, ByRef Pattern As %String) [ Private ]
{
	#; Spec     - Input,  Wildcard specification
	#; AS       - Output, AZ style start
	#; AE       - Output, AZ style end
	#; Pattern  - Output, Generated pattern
	
	#; Handle A:Z style masks
	If Spec[":" Set AS=$piece(Spec,":",1),AE=$piece(Spec,":",2),Pattern="" Quit
	
	#; Double up the quotes
	For i=$length(Spec,"""")-1:-1:1 Set Spec=$piece(Spec,"""",1,i)_""""""_$piece(Spec,"""",i+1,*)
	
	#; Remove duplicate '*' from string
	Set Spec=$zstrip(Spec,"=","*")
	Set (Pattern,Part)="",AS=$piece($translate(Spec,"*?","**"),"*")
	For i=1:1:$length(Spec) {
		If $extract(Spec,i)="?" {
			If Part]"" Set Pattern=Pattern_"1"""_Part_"""",Part=""
			Set n=1 For i=i:1:$length(Spec)-1 Quit:$extract(Spec,i+1)'="?"  Set n=n+1
			Set Pattern=Pattern_n_"E"
		} ElseIf $extract(Spec,i)="*" {
			If Part]"" Set Pattern=Pattern_"1"""_Part_"""",Part=""
			Set Pattern=Pattern_".E"
		} Else {
			Set Part=Part_$extract(Spec,i)
		}
	}
	If Part]"" Set Pattern=Pattern_"1"""_Part_"""",Part=""
	If AS_"*"=Spec Set Pattern=""
	Set AE=AS
	Quit
}

Query LocalList(Pid As %String, Node As %String, Pattern As %String = "", Format As %Boolean = 1) As %Query(ROWSPEC = "Subscript:%String:Subscript name,Value:%String:Value of this node,Data:%Integer:$data value,ValueFormat:%Integer:Format of value,SubscriptFormat:%Integer:Format of the subscript") [ SqlProc ]
{
}

ClassMethod LocalListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GlobalListExecute ]
{
	If $data(qHandle("gbl"),gbl) Kill @gbl
	Quit ..GlobalListClose(.qHandle)
}

ClassMethod LocalListExecute(ByRef qHandle As %Binary, Pid As %String, Node As %String, Pattern As %String = "", Format As %Boolean = 1) As %Status
{
	Set $ztrap="trap"
	Set idx=$increment(^||%Studio.Global)
	Set qHandle("gbl")=$name(^||%Studio.Global(idx))
	Try {
		Set Node=$name(@Node)
	} Catch {
		Return $$$OK
	}
	#; Find out if we should look at public or private variable
	Set var=$piece(Node,"("),sc=$$$OK
	Try {
		If $zutil(88,1,Pid,var)
	} Catch {
		Set sc=$$$ERROR($$$DebugBadPID,Pid)
	}
	If $$$ISERR(sc) Quit sc
	Set var=$zu(88,1,Pid,"~"_var) If var'="",$piece(var,"(")=("~"_$piece(Node,"(")) Set Node="~"_Node
	If Node["(" { Set prefix=$extract(Node,1,*-1)_"," } Else { Set prefix=Node_"(" }
	Set len=$length(prefix),var=Node
	If $zutil(88,6,Pid,Node)#2 Set ^||%Studio.Global(idx)=$zutil(88,2,Pid,Node)
	For  {
		Set var=$zu(88,1,Pid,var)
		Quit:(var="")||($extract(var,1,len)'=prefix)
		Set @("^||%Studio.Global("_idx_","_$extract(var,len+1,*))=$zutil(88,2,Pid,var)
	}
	Quit ..GlobalListExecute(.qHandle,qHandle("gbl"),.Pattern,Format)
trap	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

ClassMethod LocalListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..GlobalListFetchRows(.qHandle,1,.Row,,.AtEnd)
}

ClassMethod LocalListFetchRows(ByRef qHandle As %Binary, FetchCount As %Integer = 0, ByRef RowSet As %List, ByRef ReturnCount As %Integer, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
..GlobalListFetchRows(.qHandle,.FetchCount,.RowSet,.ReturnCount,.AtEnd)
}

}
