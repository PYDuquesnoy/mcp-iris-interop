/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on subclassing this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.FtpCallback">Using FTP</a>.</p>
/// Sub class this and implement the code to handle callbacks generated
/// when we send or receive data. This can be used to give the user
/// an indication it is still working on a large transfer, or abort the transfer. This
/// class is used with <CLASS>%Net.FtpSession</CLASS> only.
Class %Net.FtpCallback Extends %RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

/// Subclass this and add any code that you want called at regular intervals when
/// receiving data from the Ftp server.
Method RetrieveCallback(Command As %String) [ Abstract ]
{
}

/// Subclass this and add any code that you want called at regular intervals when
/// sending data to the Ftp server.
Method StoreCallback(Command As %String) [ Abstract ]
{
}

}
