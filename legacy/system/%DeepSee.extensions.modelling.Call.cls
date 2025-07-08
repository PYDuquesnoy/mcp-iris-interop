/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.Call Extends %RegisteredObject [ System = 4 ]
{

Property config As %DeepSee.extensions.modelling.conf.Call;

Method setConfig(conf As %DeepSee.extensions.modelling.conf.Call) As %Status
{
	set tSC = $$$OK
	try {
		
		set ..config = conf
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method apply() As %Status
{
	set tSC = $$$OK
	try {
		
		set tClassName = ..config.className
		set tParams = ..config.parameters.Count()
		if (tParams) {
			for i = 1:1:tParams {
				set tParams(i) = ..config.parameters.GetAt(i)
			}
			if (tClassName = "") {
				set tSC = $method($this, ..config.method, tParams...)
			} else {
				set tSC = $classmethod(tClassName, ..config.method, tParams...)
			}
		} else {
			if (tClassName = "") {
				set tSC = $method($this, ..config.method)
			} else {
				set tSC = $classmethod(tClassName, ..config.method)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
