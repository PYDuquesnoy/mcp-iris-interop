/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// This class allows user applications to generate an alert using one of the
/// supported external monitoring protocols. See the External() class method
/// for details. 
Class %Monitor.Alert Extends (%Persistent, %CSP.Page) [ Not Hidden, Inheritance = right, System = 3 ]
{

/// Alert application
Property ApplicationName As %String(TRUNCATE = 1) [ Internal, Required ];

/// Alert name
Property Name As %String(TRUNCATE = 1) [ Internal, Required ];

/// Alert once<br>
/// If FALSE (the default) the alert is notified each time the alert is signalled.<br>
/// If TRUE the alert is only notified once.
Property NotifyOnce As %Boolean [ InitialExpression = 0, Internal ];

/// If TRUE the alert has been notified.
Property Notified As %Boolean [ InitialExpression = 0, Internal, Transient ];

/// Flag indicating if this alert is active
Property Activated As %Boolean [ InitialExpression = 1, Internal ];

/// Alert action
Property AlertAction As %Integer [ InitialExpression = 0, Internal ];

/// Metrics class
Property MetricClass As %String [ Internal ];

/// Metric application
Property MetricApp As %String [ Internal ];

/// Metric group
Property MetricGroup As %String [ Internal ];

/// Metrics property list<br>
/// A comma-separted string of property names whose values
/// are passed as a list to the evaluation method
Property PropertyList As %String(MAXLEN = 132) [ Internal ];

/// Method to be invoked during sampling to determine if an alert should be raised
Property EvalMethod As %String [ Internal ];

Property EvalClass As %String [ Internal ];

/// Method to be invoked if notify type = METHOD [optional]
Property NotifyMethod As %String [ Internal ];

/// Expression to be evaluated [optional]
Property Expression As %String(MAXLEN = 132) [ Internal ];

Property NotifyClass As %String [ Internal ];

Property ItemGroup As %Monitor.ItemGroup [ Internal, Transient ];

/// The application definition for this group
Relationship Application As %Monitor.Application [ Cardinality = parent, Internal, Inverse = Alert ];

/// Unique key index for alert
Index IDKEY On Name [ IdKey, Internal, PrimaryKey, Unique ];

ClassMethod Create(name As %String = "", appname As %String = "", action As %Integer = 0, nmethod As %String = "", nclass As %String = "", mclass As %String = "", prop As %String = "", expr As %String = "", once As %Boolean = 0, evalmethod As %String = "") As %Status [ Internal ]
{
	s $zt="Error"
	i name="" s $ze="Name required" goto Args
	i appname="" s $ze="Application required" goto Args
	; if this alert already exists, error
	s id = ""
	s sc = ##class(%Monitor.Alert).GetId(name,.id)
	i sc=$$$OK s $ze="Alert exists.  Delete it first" goto Error
	s Obj=##Class(%Monitor.Alert).%New()
	i '$IsObject(Obj) q %objlasterror
	s Obj.Name = name
	// Generate application object
	Set Obj.ApplicationName = appname
	Set app = ##class(%Monitor.Application).%OpenId(appname)
	If '$IsObject(app) {
		Set app = ##class(%Monitor.Application).%New()
		i '$IsObject(app) q %objlasterror
		Set app.Name = appname
	}
	Set Obj.Application = app
	; define the alert
	s Obj.AlertAction = action
	s Obj.NotifyOnce = once
	s Obj.Expression = expr
	s Obj.PropertyList = prop
	s Obj.MetricClass = mclass
	s Obj.NotifyMethod = nmethod
	s Obj.NotifyClass = nclass
	s Obj.EvalMethod = evalmethod
	s sc = Obj.Check()
	i sc'=$$$OK goto Args
	s sc = app.%Save()
	g:sc'=$$$OK Error
	Q $$$OK
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
Args s $zt=""
	Quit $$$ERROR($$$InvalidArgument,$ze)
}

/// Delete an alert
ClassMethod Delete(name As %String = "", appname As %String = "") As %Status [ Internal ]
{
 s $zt="Error"
 i name = "" s $ze="Name required" goto Args
 s id=""
 s sc=##class(%Monitor.Alert).GetId(name,.id)
 i sc'=$$$OK s $ze="Alert does not exist: "_name_" / "_appname q 0
 s sc = ##class(%Monitor.Alert).%DeleteId(id)
 i sc'=$$$OK q %objlasterror
 Q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
Args s $zt=""
 Quit $$$ERROR($$$InvalidArgument,$ze)
}

/// Validate the alert definition
Method Check() As %Status [ Internal ]
{
 s $zt="Error"
 i ..Name = "" s $ze="Name required" goto Error
 i ..MetricClass '= "" {
	 i ..PropertyList="" s $ze="Property required" goto Error 
 	 i (..Expression '= "") && (..EvalMethod '= "") s $ze="Evaluation: expression and method not allowed" goto Error
	 i (..Expression = "") && (..EvalMethod = "") s $ze="Evaluation: method or expression required" goto Error
} else {
	 i ..ApplicationName = "" s $ze="Application name required" goto Error 
	 i ..PropertyList '="" s $ze="-Property without metric" goto Error 
	 i ..EvalMethod'="" s $ze="-Evaluation without metric" goto Error
	 i ..Expression'="" s $ze="-Expression without metric" goto Error
}
 i (..AlertAction < 0) || (..AlertAction > 3) s $ze="Invalid Action code" goto Error
 i (..AlertAction > 1) && (..NotifyMethod="") s $ze="Notify Method required for Action" goto Error 
 ; check mclass, property
 i ..MetricClass '= "" {
		Set id = ""
		d ##class(%Monitor.ItemGroup).MetricsClassItemGroup(..MetricClass, .id)
		If id = "" {
			//no item group.  See if need registration
			s sc = ##class(%Monitor.Manager).Register(..MetricClass)
			I sc '= $$$OK s $ze="Class does not exist: "_..MetricClass goto Error
			d ##class(%Monitor.ItemGroup).MetricsClassItemGroup(..MetricClass, .id)
			I id = "" s $ze="Class not found in Monitor classes: "_..MetricClass goto Error
		}
		f i=1:1 {
			s p=$p(..PropertyList,",",i) i p="" Q
			s found = ##class(%Monitor.Item).ExistsItem(..MetricClass,p)
			i 'found s $ze = "Property does not exist "_p goto Error
		}
		; check methods
		I ..EvalMethod '= "" {
			Set l = $length(..EvalMethod,".")
			Set meth = $p(..EvalMethod,".",l)
			;remove () if supplied
			s meth = $p(meth,"(",1)
			Set class = $p(..EvalMethod,".",1,l-1)
			Set cdef = ##class(%Dictionary.CompiledClass).%OpenId(class)
			If cdef = "" s $ze = "Class does not exist "_class goto Error
			Set count = cdef.Methods.Count()
			For i = 1:1:count {
				s meths(cdef.Methods.GetAt(i).Name)=cdef.Methods.GetAt(i).ClassMethod
			}
			Set mtype = $g(meths(meth))
			If (mtype = "")||('mtype) s $ze="Not a classmethod "_meth goto Error
			Set ..EvalMethod = meth
			Set ..EvalClass = class
		}
}
 ; check methods
 I ..NotifyMethod '= "" {
	 Set cdef = ##class(%Dictionary.CompiledClass).%OpenId(..NotifyClass)
	 If cdef = "" s $ze = "Class does not exist "_class goto Error
	 Set count = cdef.Methods.Count()
	 For i = 1:1:count {
		s meths(cdef.Methods.GetAt(i).Name)=cdef.Methods.GetAt(i).ClassMethod
	}
	 Set mtype = $g(meths(..NotifyMethod))
	 If (mtype = "")||('mtype) s $ze="ERROR: '"_..NotifyMethod_"' is not a Class Method" goto Error
}
 Q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Returns the object id for the alert
ClassMethod GetId(name As %String, ByRef id As %String) As %Status [ Internal ]
{
 // fetch the ID
 &sql(SELECT %ID INTO :id FROM Alert
 WHERE (Name = :name))
 If SQLCODE '= 0 {
	 s id = ""
	 Q 0
 }
 Q $$$OK
}

/// This class method allows a application to send an alert using an external 
/// monitoring or management interface, currently just SNMP. This call may 
/// be used within the Alert Evaluation Method to forward alerts generated by the
/// Monitor, or from anywhere within the application itself to simply create
/// an SNMP Trap.<p>
/// <p>
/// The parameters used are:<p>
/// <p>
/// <var>type</var> = use 'SNMP' to indicate how to send the alert<p>
/// <var>appname</var> = a brief string (MAXLEN=20) to identify the source or application creating the alert<p>
/// <var>severity</var> = a severity code where 0=info, 1=warning, 2=severe, 3=fatal<p>
/// <var>msg</var> = a text message (MAXLEN=1024) which describes the problem or event<p>
/// 
/// For SNMP, the alert is sent using the cacheAppAlert trap, with each of the 
/// parameters attached as auxiliary objects (see the ISC-CACHE.MIB).
ClassMethod External(type As %String = "SNMP", appname As %String = "", severity As %Integer = 0, msg As %String = "") As %Status
{
	if type'="SNMP" q $$$ERROR($$$InvalidArgument)
	if $l(appname)>20 q $$$ERROR($$$InvalidArgument)
	if $l(msg)>1024 q $$$ERROR($$$InvalidArgument)
	if (+severity<0)!(+severity>3) q $$$ERROR($$$InvalidArgument)
	s status=$$$OK
    if (type="SNMP") {
	    l +^IRIS.Temp.Alerts("SNMP"):3
	    e  q $$$ERROR($$$LockFailedToAcquireExclusive,$name(^IRIS.Temp.Alerts("SNMP")))
	    if +$g(^IRIS.Temp.Alerts("SNMP")) {
		    s index=^IRIS.Temp.Alerts("SNMP")+1
	        s ^IRIS.Temp.Alerts("SNMP")=index
	        s oid="1.3.6.1.4.1.16563."
	        s ^IRIS.Temp.Alerts("SNMP",index)=oid_"1.2.100"
	        s cfg=$p($zu(86),"*",2),l=$l(cfg),ci=l f i=1:1:l s ci=ci_"."_$a(cfg,i)
	        s ^IRIS.Temp.Alerts("SNMP",index,1)=$lb(oid_"1.1.1.1.1."_ci,4,$p($zu(86),"*",2))
	        s ^IRIS.Temp.Alerts("SNMP",index,2)=$lb(oid_"1.3.2",4,$g(appname))
	        s ^IRIS.Temp.Alerts("SNMP",index,3)=$lb(oid_"1.3.3",2,+$g(severity))
	        s ^IRIS.Temp.Alerts("SNMP",index,4)=$lb(oid_"1.3.4",4,$g(msg))
	        i $$$ISWINDOWS s n=$zu(190,0)
	    } else {
		    s status=$$$ERROR($$$GeneralError,"SNMP not enabled")
	    }
	    l -^IRIS.Temp.Alerts("SNMP")
    }
    q status
}

/// Query for data values for all alerts
Query List() As %SQLQuery [ Internal ]
{
SELECT Name,Activated,ApplicationName,AlertAction,NotifyMethod,NotifyClass,MetricClass,
   PropertyList,Expression,NotifyOnce FROM Alert
}

/// Returns all Alerts defined in this namespace
Query Alerts() As %SQLQuery(CONTAINID = 1) [ Internal ]
{
SELECT %ID FROM Alert
}

/// A list of all Alerts for an Application (called by SNMP)
Query AppAlerts(aid As %String) As %SQLQuery(ROWSPEC = "ID,Name,App,Group,Items") [ Internal ]
{
SELECT ID, Name, MetricApp, MetricGroup, PropertyList FROM Alert
  WHERE (ApplicationName = :aid)
}

/// Returns all Alerts defined for a given Metrics Class
Query ClassAlerts(mclass As %String) As %SQLQuery(CONTAINID = 1) [ Internal ]
{
SELECT %ID FROM Alert WHERE MetricClass = :mclass
}

Storage Default
{
<Data name="AlertDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AlertAction</Value>
</Value>
<Value name="3">
<Value>ApplicationName</Value>
</Value>
<Value name="4">
<Value>EvalMethod</Value>
</Value>
<Value name="5">
<Value>GroupName</Value>
</Value>
<Value name="6">
<Value>MetricClass</Value>
</Value>
<Value name="7">
<Value>NotifyMethod</Value>
</Value>
<Value name="8">
<Value>PropertyList</Value>
</Value>
<Value name="9">
<Value>MetricApp</Value>
</Value>
<Value name="10">
<Value>MetricGroup</Value>
</Value>
<Value name="11">
<Value>EvalClass</Value>
</Value>
<Value name="12">
<Value>NotifyClass</Value>
</Value>
<Value name="13">
<Value>Expression</Value>
</Value>
<Value name="14">
<Value>Reset</Value>
</Value>
<Value name="15">
<Value>AlertOnce</Value>
</Value>
<Value name="16">
<Value>Disabled</Value>
</Value>
<Value name="17">
<Value>Enabled</Value>
</Value>
<Value name="18">
<Value>NotifyOnce</Value>
</Value>
<Value name="19">
<Value>Activated</Value>
</Value>
</Data>
<DataLocation>^Monitor.AlertD</DataLocation>
<DefaultData>AlertDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Monitor.AlertD</IdLocation>
<IndexLocation>^Monitor.AlertI</IndexLocation>
<StreamLocation>^Monitor.AlertS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
