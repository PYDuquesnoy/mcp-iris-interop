/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <br>
/// UDP Communications
/// </br>
/// <P>A typical model is that you have a provider that waits to receive msgs from many hosts on a well defined port, and there are many requestors that send pkts to the provider.</P>
/// <P>Basically a provider creates a UDP object and waits for a request and then responds to the request (if it is required).</P>
/// <EXAMPLE>
/// 	s prv=##class(%Net.UDP).%New([port num])	// new a provider that can receive
/// 							// pkts on a well defined port
/// 	s pkt=prv.Recv([time out])			// Waits for a pkt to arrive or times out
/// 	s bytes=prv.Reply([answer pkt])			// send a pkt back to the requestor.
/// </EXAMPLE>
/// <P>The requestor must know the host and port or the subnet and port to
/// send or broadcast a packet to.</P>
/// <EXAMPLE>
/// 	s clnt=##class(%Net.UDP).%New()				// Create an anonymous requestor
/// 	  							// using a dynamic port num
/// 	s bytes=clnt.Send([pkt],[host or subnet],[port])	// send a pkt to the provider
/// </EXAMPLE>
/// i.e.
/// <EXAMPLE>
/// 	 
/// 	;;       Provider			;		Requestor
/// 	   s prv=##class(%Net.UDP).%New(2050)	;
/// 						s clnt=##class(%Net.UDP).%New()
/// 						s host=##class(%Net.UDP).GetHostAddr("localhost")
/// 						w clnt.Send("Hello 2050",host,2050)
/// 						; 10
/// 	   w "Provider Rcvd=",prv.Recv()		
/// 	;Provider Rcvd=Hello 2050			
/// 	   w prv.Reply("A msg from 2050")		
/// 	;15   		      	   
/// 						w "Requestor rcvd=",clnt.Recv()
/// 						; Requestor rcvd=A msg from 2050
/// 	  w "pkt was from=",$system.INetInfo.AddrToHostName(prv.LastAddr),":",prv.LastPort,!
/// 	;pkt was from=localhost:58135
/// </EXAMPLE>
/// <P>
/// On some platforms the sender and receiver must have the same IP protocol for the packets to reach each other or the UDP object must be bound to the same type of IP protocol as the destination so it can send, otherwise send will fail and it will return -1.
/// i.e. the sender or receiver UDP socket must be bound to IPv4 or IPv6 explicitly . You can specify the IPv4 or IPv6 protocol type when you %New the UDP object. You do this by specifying the default host IP format. Based on this host IP format, UDP binds and communicates using that protocol type:
/// </P>
/// <EXAMPLE>
/// s u=##class(%Net.UDP).%New(3001,"::")			// IPv6
/// s u=##class(%Net.UDP).%New(3002,"0.0.0.0")		// IPv4
/// </EXAMPLE>
/// You can use netstat -an  to find out how it's bound!!
/// <P>
///   UDP    0.0.0.0:3002           *:*
/// </P><P>
///   UDP    [::]:3001              *:*
/// </P>
/// If the UDP object is only a sender with a default port you can pass zero for port num.
/// <EXAMPLE>
/// s u=##class(%Net.UDP).%New(0,"::")			// IPv6
/// s u=##class(%Net.UDP).%New(0,"0.0.0.0")		// IPv4
/// </EXAMPLE>
/// <P>
/// Note: On some platforms it may require two different UDP objects one for IPv4 and one for IPv6 communication.
/// </P><P>
/// In the following example the sender is bound to IPv4 and it cannot send to a IPv6 destination.
/// </P>
/// <EXAMPLE>
/// s h=##class(%Net.UDP).GetHostAddr("::1")
/// s c=##class(%Net.UDP).%New() 
/// w c.Send("chello",h,3002)
/// -1
/// </EXAMPLE>
/// <EXAMPLE>
/// s c=##class(%Net.UDP).%New(0,"::") 
/// w c.Send("hello",h,3002)
/// 5
/// </EXAMPLE>
/// <P>Note that UDP is an unreliable protocol; it may drop some pkts.</P>
/// <P>It's recommended to send or reply to packets in some canonical format, especially on a Unicode system (i.e. lists, or UTF8).</P>
Class %Net.UDP Extends %RegisteredObject [ System = 3 ]
{

Property Descriptor As %Integer [ Internal ];

Property LastAddr As %String;

Property LastPort As %Integer;

/// <p>This callback method is invoked by the %New method to provide notification that a new instance of an object is being created.</p>
/// <p>If this method returns an error then the object will not be created.</p>
/// <B>%New</B> 
/// instantiates a new UDP datagram socket. If host and a port is specified, the socket will be
/// bound to that host and IP. If the specified host and port is in use, it will retry once
/// every second for the specified timeout duration until it becomes available. If a
/// timeout is not specified it will try to bind to that host and port only once.
/// <P>On success it will return a %Net.UDP object/oref, on failure it will return "".</P>
/// <P>If rcvsiz or sendsiz are provided the socket is initialized to send and
/// receive at least that size packet. </P>
/// <P>The default receive buffer size is 16k (16384 bytes).</P>
/// 
Method %OnNew(port As %Integer = 0, host As %String = "", timeout As %Integer = 0, sendsiz As %Integer = 0, rcvsiz As %Integer = 0) As %Library.Status
{
	s des=$system.UDP.Init(host,port,timeout,sendsiz,rcvsiz)
	if (des > 0) {
	   s ..Descriptor = des
	} else {
	   return $$$ERROR($$$GeneralError,"failed to init")
	}
	Quit $$$OK
}

/// Send a packet to a specified destination and port.
/// <P>
/// Destination is in $system.INetInfo.INetBinaryAddrToText() or
/// %Net.UDP.GetHostAddr() format (basically an IPv4 or IPv6 binary address).
/// </P>
/// <P>
/// The port must be a 16 bit port number.
/// </P>
/// <P>
/// The Send method returns the number of bytes sent.
/// </P>
/// 
Method Send(pkt As %String, dest As %String, port As %Integer) As %Integer
{
	d:(..Descriptor<=0) $ZU(96,0,6)
	return $system.UDP.Send(..Descriptor, .pkt, dest, port)
}

/// Receives a packet from the socket.
/// <P>
/// It takes an optional timeout. It returns an empty string after the specified seconds.
/// </P>
/// <P>
/// The returned string is the received raw pkt data. It might be truncated to the
/// specified receive buffer length (Receive length is specified during the class instantiation).
/// </P>
/// <P>
/// The sender's host and port can be accessed through <B>LastAddr</B> and <B>LastPort</B> properties.
/// </P>
/// 
Method Recv(timeout As %Integer = 0) As %String
{
   try {
	d:(..Descriptor<=0) $ZU(96,0,6)
	return $system.UDP.Recv(..Descriptor, timeout)
   } catch e {
     	throw e
   }
}

/// It's exactly the  same as the Send() method, except it doesn't require the
/// destination address. It sends to the last received <B>Recv</B> source.
/// 
Method Reply(pkt As %String) As %Integer
{
	d:(..Descriptor<=0) $ZU(96,0,6)
	quit $system.UDP.Reply(..Descriptor, .pkt)
}

/// Converts the passed in host name or IP to a binary form of the IP for efficient
/// use by the Send() method. The returned IP is IPv4 or IPv6 depending on the
/// instance setting.
/// <P>
/// The returned IP could be converted to a text format by.
/// </P>
/// <EXAMPLE>
/// w $system.INetInfo.AddrToHostName(x)
/// </EXAMPLE>
/// 
ClassMethod GetHostAddr(host As %String) As %String
{
	quit $system.UDP.GetHostAddr(host)
}

/// Returns the last received packet's IP address.
/// 
Method LastAddrGet() As %String [ Internal ]
{
	d:(..Descriptor<=0) $ZU(96,0,6)
	quit $system.UDP.LastRcvdAddr(..Descriptor)
}

/// Returns the last received packet's port.
/// 
Method LastPortGet() As %Integer [ Internal ]
{
	d:(..Descriptor<=0) $ZU(96,0,6)
	quit $system.UDP.LastRcvdPort(..Descriptor)
}

Method %OnClose() As %Status [ Final, Internal, Private ]
{
	try {
	    d:(..Descriptor > 0) $system.UDP.Close(..Descriptor)
   	} catch {
	    // w "Unexpected udp obj ",..Descriptor
   	}
	set ..Descriptor = 0
	Quit $$$OK
}

}
