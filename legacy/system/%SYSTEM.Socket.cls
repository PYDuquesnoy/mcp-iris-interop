/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%SYSTEM.Socket</class> class provides an interface for multiplexing TCP devices.<br><br>
/// You could use <method>Fork</method> and <method>Select</method> methods to have one job handle accepting new connection and reading data from connected TCP device at the same time.<br>
/// <p>After a listening TCP device receives a connection, we could use <method>Fork</method> to create a new TCP device for reading data.
/// The original listening TCP device could continue to accept an incoming connection. Then you could use the <method>Select</method> method to wait for both listening and connected TCP device.
/// When a new connect request arrives or incoming data becomes available, the <method>Select</method> will return with the device name which was signaled.</p>
/// <example>Set ListenDev="|TCP|1" Open ListenDev:(:9999:"SA") Set SelectDev=$LB(ListenDev),DevNameIndex=1
/// While (1) {
///    Set ReturnDev=$SYSTEM.Socket.Select(SelectDev)
///    For i=1:1:$ListLength(ReturnDev) {
///        Set Dev=$Li(ReturnDev)
///        If Dev=ListenDev {
///            /* This is the listening device, so it is a new connection. */
///            Set ConnectedDev="|TCP|"_$Increment(DevNameIndex)
///            If '$SYSTEM.Socket.Fork(Dev,ConnectedDev) {
///                /* Failed to create new device, log error here and continue */
///                Continue
///            }
///            /* Put this new device in the select list. */
///            Set SelectDev=SelectDev_$LB(ConnectedDev)
///        } Else {
///            /* This is a connected device, so data is available to read. */
///            /* Note that if remote closed the connection, this read command would get a <READ> error. */
///            /* And you need to close this device and remove it from the 'SelectDev' list */
///            Use Dev Read Data
///            Continue
///        }
///    }
/// }
/// </example><br><br>
/// Use <method>Select</method>, <method>Publish</method>, <method>Export</method> and <method>Import</method> methods to have a listener job accepting incoming connection
/// and pass the connected device to worker job so the worker job could communicate with the remote client. The listener job could pass more than one connected devices to the worker job
/// and the worker job could use <method>Select</method> to handle more than one connected devices.<br>
/// The example code for listener job:<example>
/// /* Assume we already know the process ID of the worker job 'WorkerPID'. */
/// /* Note that you could have more than one worker jobs to handle incoming connections. */
/// S ListenDev="|TCP|1",WorkerPID="A Process' PID" Open ListenDev:(:9999:"SA")
/// While (1) {
///     Use ListenDev Read Data
///     /* A new connection came in, create the Token to be passed to the worker. */
///     Set Token=$SYSTEM.Socket.Publish(ListenDev,WorkerPID)
///     /* Pass the 'Token' to the worker job through the ^TCPConnect(WorkerPID) nodes. */
///     Set ^TCPConnect(WorkerPID,$Increment(^TCPConnect(WorkerPID)))=Token
///     /* Wake up the worker job in case it is waiting in $SYSTEM.Socket.Select(). */
///     Set RC=$SYSTEM.Socket.SelectInterrupt(WorkerPID)
/// 		/* Oops, the worker job is gone. Close it and continue. */
///     if 'RC {
///         /* Disconnect the connection. */
///         Use ListenDev Write *-2 
///         Continue
///     }
///     /* An important note for VMS platform, you need to call Export() method */
///     /* after you are sure the worker already called the Import() method(). */
///     /* Otherwise the Import() call on worker job will fail. */
///     Set RC=$SYSTEM.Socket.Export(ListenDev)
/// 		/* Oops, could not export  the device. Close it and continue. */
///     if 'RC {
///         /* Disconnect the connection. */
///         Use ListenDev Write *-2 
///         Continue
///     }
/// }
/// </example><br>
/// The example code for worker job:<example>
/// /* Assume the worker job already have a TCP device (FirstDev) passed from listener job through JOB command. */
/// Set SelectDev=$LB(FirstDev),DevNameIndex=0,MyPID=$P($J,":")
/// While (1) {
///    /* Wait for the read to be read with 10 seconds time out. */
///    Set ReturnDev=$SYSTEM.Socket.Select(SelectDev,10)
///    If ReturnDev="" {
///        /* The Select() must be timed out. Do whatever it needs to do then continue to read. */
///        Continue
///    }
///    If ReturnDev=-1 {
///        /* The Select() was interrupted, there must be a new connection passed from listener job */
///        Set Index=$O(^TCPConnect(MyPID,""),1,Token)
///        /* If no device in the global then this might be a false alarm, continue. */
///        If Index="" Continue
///        Set ConnectedDev="|TCP|"_$Increment(DevNameIndex)
///        Set RC=$SYSTEM.Socket.Import(ConnectedDev,Token)
///        If 'RC {
///            /* Failed to import the device, clean up and continue. */
///            Kill ^TCPConnect(MyPID,Index)
///            Continue
///        }
///        /* Put this new device in the select list and continue to read. */
///        Set SelectDev=SelectDev_$LB(ConnectedDev)
///        Kill ^TCPConnect(MyPID,Index)
///        /* Important note that for VMS platform, you need to signal listener job that */
///        /* you have called Import() method so it could call Export(). */
///        Continue
///    }
///    For i=1:1:$ListLength(ReturnDev) {
///        Set Dev=$Li(ReturnDev)
///        /* This is a connected device, so data is available to read. */
///        /* Note that if remote closed the connection, this read command would get <READ> error. */
///        /* And you need to close this device and remove it from the 'SelectDev' list */
///        Use Dev Read Data
///        Continue
///    }
/// }
/// </example>
Class %SYSTEM.Socket Extends Help [ System = 4 ]
{

/// Export a socket handle of an accepted TCP device.<br>
/// <br>
/// <b>Parameters:</b> <br>
/// <b>AcceptedDevice</b> - The name of a TCP device that has accepted an incoming connection.<br>
/// <br><b>Return:</b> <br>
/// This method returns 1 if succeeds, otherwise returns 0.<br>
/// <br><b>Usage:</b> <br>
/// This method is called by a donor after a published token is passed to the recipient job.<br>
/// It cleaned up the socket handle in the accepted TCP device so it could go back to accept another incoming connection.<br>
/// For Windows platform, this method does not interact with the recipient job.
/// For UNIX platform, internally it waits for the recipient job to connect to it through UNIX domain so the socket handle could be passed to the recipient job through it.<br>
/// For OpenVMS platform, it is needed to make sure the <method>Import</method> method is called by the recipient job before this method is called, otherwise the <method>Import</method> will fail on the recipient job.
ClassMethod Export(AcceptedDevice As %String) As %Boolean
{
	// Not implmented in kernel, get <UNIMPLEMENT> error.
	d $zu(96,0,22)
}

/// Create another TCP device from an accepted TCP device within the same job.<br>
/// <br>
/// <b>Parameters:</b> <br>
/// <b>AcceptedDevice</b> - The name of a TCP device that has accepted an incoming connection.<br>
/// <b>NewDevice</b> - The name of a TCP device that is created and a socket handle is passed to it from the <var>AcceptedDevice</var>.<br>
/// <br><b>Return:</b> <br>
/// This method returns 1 if succeeds, otherwise returns 0.<br>
/// <br><b>Usage:</b> <br>
/// Combined with the <method>Select</method> method, one job could handle more than one incoming TCP connection while accepting new connection to arrive.<br>
/// The <var>NewDevice</var> must not be opened before this call. After this call the remote end will communicate with the <var>NewDevice</var>.
ClassMethod Fork(AcceptedDevice As %String, NewDevice As %String) As %Boolean
{
	// Not implmented in kernel, get <UNIMPLEMENT> error.
	d $zu(96,0,22)
}

/// Create a TCP device with a token passed from the donor job.<br>
/// <br>
/// <b>Parameters:</b> <br>
/// <b>NewDevice</b> - The name of a TCP device that is created and a socket handle is generated  from the <var>Token</var>.<br>
/// <b>Token</b> - A token passed from the donor job to create a TCP device. It was generated from the <method>Publish</method> method by the donor job.<br>
/// <br><b>Return:</b> <br>
/// This method returns 1 if succeeds, otherwise returns 0.<br>
/// <br><b>Usage:</b> <br>
/// This method is called by a recipient after it received a published token from the donor job.<br>
/// It creates the <var>NewDevice</var> TCP device by using the socket handle generated from the <var>Token</var>.<br>
/// The <var>NewDevice</var> must not be opened before this call. After this call the remote end will communicate with the <var>NewDevice</var>.<br>
/// <br>For Windows platform, this method does not interact with the donor job.<br>
/// <br>For UNIX platform, internally it connects to the donor job through UNIX domain to get the socket handle.<br>
/// <br>For OpenVMS platform, it is needed to make sure the <method>Export</method> method is called by the donor job after this method is called, otherwise the <method>Import</method> will fail.
ClassMethod Import(NewDevice As %String, Token As %String) As %Boolean
{
	// Not implmented in kernel, get <UNIMPLEMENT> error.
	d $zu(96,0,22)
}

/// Publish a token from an accepted TCP device.<br>
/// <br>
/// If the TCP device was opened with the /SSL option and data has been exchanged in this device then 
/// this <method>Publish</method> method will get an <ILLEGAL VALUE> error. If there is no data exchanged yet
/// then the <method>Import</method> on the recipient will open the device with /SSL option implicitly.<br> 
/// <b>Parameters:</b> <br>
/// <b>AcceptedDevice</b> - The name of a TCP device that has accepted an incoming connection.<br>
/// <b>RecipientPID</b> - Process ID of the recipient job. Only Windows platform uses this value.<br>
/// <br>
/// <b>Return:</b> <br>
/// Return a <var>Token</var> for this accepted TCP device.<br>
/// <br><b>Usage:</b> <br>
/// The <var>Token</var> generated by this <method>Publish</method> method is passed to a recipient job to create a TCP device to communicate with the remote end.
ClassMethod Publish(AcceptedDevice As %String, RecipientPID As %Integer) As %String
{
	// Not implmented in kernel, get <UNIMPLEMENT> error.
	d $zu(96,0,22)
}

/// Check a list of TCP devices whether any devices are ready for read, it includes the listening TCP device.<br>
/// <br>
/// <b>Parameters:</b> <br>
/// <b>DeviceList</b> - A list of TCP devices (in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> format) to be checked, the devices have to be either connected or in the listening state.<br>
/// <b>Timeout</b> - A timeout value in seconds for this method to wait. It can be integer or decimal values, it can be down to 100th seconds. A negative value or omit this parameter will be treated as no timeout.<br>
/// <br>
/// <b>Return:</b> <br>
/// Return a list of TCP devices (in $LIST format) that are ready to read.<br>
/// Return a null string if it is timed out.<br>
/// Return -1 if it is interrupted by <method>SelectInterrupt</method>
/// <br><b>Usage:</b> <br>
/// The devices in the list could be a TCP device which has been connected or a TCP device in the listening state and waiting for incoming connection.<br>
/// When a listening TCP device is returned then this device is ready to receive data from remote end, but there might be no data to read. Internally the accept task is performed.<br>
/// For a connected TCP device, the next read command should return some data.<br>
/// The caller should check for null string and -1 for timed out or interruption before you could use the devices returned from the list.<br>
/// The limit of the total number of TCP device in the list is 64. But for Windows platform one slot is reserved for interrupting the waiting. For a device waiting for accepting an incoming connection it might take two slots if IPV6 is enabled.
ClassMethod Select(DeviceList As %List, Timeout As %Decimal) As %List
{
	// Not implmented in kernel, get <UNIMPLEMENT> error.
	d $zu(96,0,22)
}

/// Interrupt a process waiting in %SYSTEM.Socket.Select().<br>
/// <br>
/// <b>Parameters:</b> <br>
/// <b>ProcessID</b> - The process's PID to be interrupted.<br>
/// <br>
/// <b>Return:</b> <br>
/// Return one if succeed, zero if failed.
/// <br><b>Usage:</b> <br>
/// This function is used to make a process break out of <method>Select</method> method so it could continue to do other works.<br>
/// If the process is not waiting in <method>Select</method> method while it is interrupted then when the process calls <method>Select</method> method it would return null string if it has to wait in <method>Select</method> method.<br>
/// The interrupted <method>Select</method> method could return null string if no device is ready to read data.<br>
ClassMethod SelectInterrupt(ProcessID As %Integer) As %Integer
{
	// Not implmented in kernel, get <UNIMPLEMENT> error.
	d $zu(96,0,22)
}

}
