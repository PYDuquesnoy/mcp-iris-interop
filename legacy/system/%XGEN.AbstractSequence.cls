/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <div style="color:red;padding:5px; border:1px solid black; background:#FFFFAA;">
/// <b>Note:</b> This class is included because it is needed by
/// other parts of the library. You should not use this or any other class within
/// this package within your applications as a future version will
/// be incompatible. If you are interested in this functionality
/// please contact InterSystems.
/// </div><br/>
/// This is the base class for sequences within an XGEN document.<br/>
/// See <class>%XGEN.AbstractDocument</class> for an overview of XGEN.<br/>
/// A sequence is a container that can hold one or more nodes within
/// an XGEN document. A sequence does the following:
/// <ol>
/// <li><i>optionally</i> Generates one or more lines of code before processing its children.</li>
/// <li>Loops over the child nodes within the sequence and asks each one to generate code in turn.</li>
/// <li><i>optionally</i> Generates one or more lines of code after processing its children.</li>
/// </ol>
/// To create a new sequence within a XGEN document, create a 
/// subclass of this class and override the <method>%OnBeforeGenerateCode</method>
/// and <method>%OnAfterGenerateCode</method> methods to generate sequence-specific
/// code.<br/>
/// Note that a subclass can prevent its child nodes from being processed by
/// setting the <property>skipChildren</property> property to 1 in its
/// <method>%OnBeforeGenerateCode</method> method.
Class %XGEN.AbstractSequence Extends (%XGEN.AbstractNode, %XGEN.AbstractGroup) [ Abstract, Inheritance = right, System = 3 ]
{

}
