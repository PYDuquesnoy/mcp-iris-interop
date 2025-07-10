/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Util.DTL.Audit.MessageView Extends Ens.DataTransformDTL [ DependsOn = (Ens.MessageBody, Ens.StringContainer), System = 4 ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='Ens.MessageBody' targetClass='Ens.StringContainer' create='new' language='objectscript' >
<annotation>This DTL is used to provided extra event text for audit entries created when viewing message contents.

For customization create a DTL class with name EnsCustom.Util.DTL.Audit.MessageView

Source is the message body object and aux is the message header  - this might be an empty header if not provided by the viewer (body might be opened directly)</annotation>
<if condition='$IsObject(aux)&amp;&amp;(aux.SessionId&apos;="")' >
<annotation>Obtain SessionId from aux if provided</annotation>
<true>
<assign value='target.StringValue_", SessionId = "_aux.SessionId' property='target.StringValue' action='set' >
<annotation>Add SessionId to text</annotation>
</assign>
</true>
</if>
<if condition='$classname(source)="EnsLib.HL7.Message"' >
<annotation>If source is EnsLib.HL7.Message then record ControlId</annotation>
<true>
<if condition='source.{1:0}="MSH"' >
<true>
<assign value='target.StringValue_", HL7 ControlId = "_source.{1:10}' property='target.StringValue' action='set' >
<annotation>Add MSH ControlId to text</annotation>
</assign>
</true>
<false>
<if condition='(source.{1:0}="BHS")||(source.{1:0}="FHS")' >
<true>
<assign value='target.StringValue_", HL7 Batch/File ControlId = "_source.{1:11}' property='target.StringValue' action='set' >
<annotation>Add BHS or FHS ControlId to text</annotation>
</assign>
</true>
</if>
</false>
</if>
</true>
</if>
</transform>
}

}
