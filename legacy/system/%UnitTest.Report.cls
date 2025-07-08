/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %UnitTest.Report Extends %CSP.Page [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// return value 0 = failed, 1 = passed, 2 = skipped
ClassMethod GetTestStatus(namespace, index, suite, case, method, action) As %Integer
{
	New (namespace,index,suite,case,method,action)
	; status precedence order: failed, skipped, passed
	set sp(0)=3,sp(2)=2,sp(1)=1,sphighest=3
	If $d(action) {
		Quit $li(^|namespace|UnitTest.Result(index,suite,case,method,action),1)
	}
	If $d(method) {
		Set status=$li(^|namespace|UnitTest.Result(index,suite,case,method),1) Quit:status=sphighest status
		Set action="" For  Set action=$o(^|namespace|UnitTest.Result(index,suite,case,method,action)) Quit:action=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(namespace,index,suite,case,method,action) if sp(one)>sp(status) set status=one
		Quit status
	}
	If $d(case) {
		Set status=$li(^|namespace|UnitTest.Result(index,suite,case),1) Quit:status=sphighest status
		Set method="" For  Set method=$o(^|namespace|UnitTest.Result(index,suite,case,method)) Quit:method=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(namespace,index,suite,case,method) if sp(one)>sp(status) set status=one
		Quit status
	}
	If $d(suite) {
		Set status=$li(^|namespace|UnitTest.Result(index,suite),1) Quit:status=sphighest status
		Set case="" For  Set case=$o(^|namespace|UnitTest.Result(index,suite,case)) Quit:case=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(namespace,index,suite,case) if sp(one)>sp(status) set status=one
		Quit status
	}
	If $d(index) {
		Set status=1
		Set suite="" For  Set suite=$o(^|namespace|UnitTest.Result(index,suite)) Quit:suite=""  Do  Quit:status=sphighest
		. Set one=..GetTestStatus(namespace,index,suite) if sp(one)>sp(status) set status=one
		Quit status
	}
	Quit 0
}

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	set namespace=%request.Get("NS")
	set index=%request.Get("INDEX")
	set page="Indices"
	if %request.Get("SUITE")'="" {
		set index=index_"||"_%request.Get("SUITE")	
		set page="TestSuite"
		if %request.Get("CASE")'="" {
			set index=index_"||"_%request.Get("CASE")	
			set page="TestCase"
			if %request.Get("METHOD")'="" {
				set index=index_"||"_%request.Get("METHOD")
				set page="TestMethod"
			}
		}	
	} 
	set appdir=$$getDefaultApp^%SYS.cspServer2(namespace)
	set url=appdir_"/%25UnitTest.Portal."_page_".cls?Index="_index
	set %response.Redirect=url
	quit $$$OK
}

}
