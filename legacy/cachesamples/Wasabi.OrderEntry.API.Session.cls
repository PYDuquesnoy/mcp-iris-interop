Include %occIO

/// Usage of %occIO for public consumption?....to be detemined
/// 
/// <p>
/// This class is designed to be an SOA interface, or <i>Service</i>, to use the <class>Wasabi.OrderEntry.Data.Cart</class>
/// <class>Wasabi.OrderEntry.Data.Orders</class> and <class>Wasabi.OrderEntry.Data.Invoice</class>
/// structures to provide the business logic for a Sample Retail Order Entry system.
/// </p>
/// <p>
/// This does not preclude the usage of the <class>Wasabi.OrderEntry.Data.Cart</class>
/// <class>Wasabi.OrderEntry.Data.Orders</class> and <class>Wasabi.OrderEntry.Data.Invoice</class> classes
/// directly, but this presuppose that it is the only active interface to modifying (Create, Update, Delete)
/// any of these classes.
/// </p>
/// Direct read only access to the <class>Wasabi.OrderEntry.Data.Car</class>
/// <class>Wasabi.OrderEntry.Data.Orders</class> and <class>Wasabi.OrderEntry.Data.Invoice</class> classes
/// is assumed for reporting, and real time Business Intelegence.
/// <p>
Class Wasabi.OrderEntry.API.Session Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right ]
{

/// Holding area for Active Cart
Property Cart As Wasabi.OrderEntry.Data.Cart [ Private ];

/// Holding area for Active Order
Property Orders As Wasabi.OrderEntry.Data.Orders [ Private ];

/// HOlding area for  Active Invoice
Property Invoice As Wasabi.OrderEntry.Data.Invoice [ Private ];

/// Holding area for Active Customer
Property Customer As Wasabi.Data.Customer;

/// Holding area the Active 'Outlet'.
/// <br>
/// <font color="red">This may or may not be the
/// Order's Address, as this interface to the ProductManegement subsystem
/// was not 100% finalized.</font>
Property Outlet [ Private ];

/// Holding Area for Shipping Address
/// If this is left blank, than the "Customer" address will be used
Property ShippingAddress As Wasabi.Data.AddressSerial;

/// Holding Area for Billing Address
/// If this is left blank, than the "Customer" address will be used
Property BillingAddress As Wasabi.Data.AddressSerial;

/// Customer is required, and for "unknown" customer
/// there needs to be some sort of record with a unique.
Method CreateCart(CustomerToken As %String, Customer As Wasabi.Data.Customer) As %Status
{
	set ..Cart = ##class(Wasabi.OrderEntry.Data.Cart).%New()
	set ..Cart.Customer = Customer
	set ..Cart.TokenKey = CustomerToken
	// Clear any current Order and Invoice
	set ..Orders = ""
	set ..Invoice = ""
	quit $$$OK
}

/// Allows the calling layer to switch from an "Unknown Customer" customer to a
/// REAL Customer
Method SetCartCustomer(Customer As Wasabi.Data.Customer) As %Status
{
	if IsObject(..Cart) {
		set ..Cart.Customer = Customer
	} else {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Trying to Set "_..Cart.Customer.Name_" into a NULL Cart",..%ClassName(1)_"::"_$$$CurrentMethod))
	}
	quit $$$OK
}

/// Inserts a Product into the active Cart
/// if the "Quantity" is 0, the item will be removed
Method AddToCart(Product As Wasabi.ProductManagement.Data.Product, Quantity As %Integer = 1) As %Status
{
	;
	$$$ThrowStatus($$$ERROR($$$MethodNotImplemented,..%ClassName(1)_"::"_$$$CurrentMethod))
	;
	Quit $$$OK
}

/// Create a "Cart Check Point" by saving the internal 
/// <class>Wasabi.OrderEntry.Data.Cart</class> instance
Method SaveCart() As %Status
{
	;
	$$$ThrowStatus($$$ERROR($$$MethodNotImplemented,..%ClassName(1)_"::"_$$$CurrentMethod))
	;
	Quit $$$OK
}

/// Clears ALL Items from the internal 
/// <class>Wasabi.OrderEntry.Data.Cart</class> instance.
Method ClearCart() As %Status
{
	;
	$$$ThrowStatus($$$ERROR($$$MethodNotImplemented,..%ClassName(1)_"::"_$$$CurrentMethod))
	;
	Quit $$$OK
}

/// Reloads the internal 
/// <class>Wasabi.OrderEntry.Data.Cart</class> instance back to the last "Checkpoint" that
/// was created by the <method>SaveCart</method>
Method RevertCart() As %Status
{
	;
	$$$ThrowStatus($$$ERROR($$$MethodNotImplemented,..%ClassName(1)_"::"_$$$CurrentMethod))
	;
	Quit $$$OK
}

/// Returns a Result Set of the <u>Product, Quantity, Price</u> from the internal 
/// <class>Wasabi.OrderEntry.Data.Cart</class> instance.
Method ListCart(ByRef Results As %Library.IResultSet) As %Status
{
	;
	$$$ThrowStatus($$$ERROR($$$MethodNotImplemented,..%ClassName(1)_"::"_$$$CurrentMethod))
	;
	Quit $$$OK
}

/// Locates last <method>SaveCart</method> created Check Point for the cart that
/// was marked with the CustomerToken key and sets it as the internal 
/// <class>Wasabi.OrderEntry.Data.Cart</class> instance.
Method ActivateCart(CustomerToken As %String) As %Status
{
	;
	$$$ThrowStatus($$$ERROR($$$MethodNotImplemented,..%ClassName(1)_"::"_$$$CurrentMethod))
	;
	Quit $$$OK
}

/// Converts the the internal 
/// <class>Wasabi.OrderEntry.Data.Cart</class> instance into an the internal 
/// <class>Wasabi.OrderEntry.Data.Orders</class> instance
/// <p>
/// This method assumes that this is a "fixed quote" for an order, with the undiscounted
/// prices being replicated from each Cart item, along with the discription also being replicated
/// into the Order record. This is done to record the details of the quote and make this snapshot of
/// information be protected from future changes to products and prices.
/// </p>
/// <p>
/// Creating an order does not remove the Cart, since this is not an commited contract between seller
/// and customer, changes could be made and new "quote" Orders may be create or perhaps even abandoned.
/// </p>
Method CreateOrder(SalesPerson As Wasabi.Data.SalesPerson) As %Boolean
{
	set ..Orders = ##class(Wasabi.OrderEntry.Data.Order).%New()
	if IsObject(..Orders) {
		set ..Orders.Customer = ..Cart.Customer
		set ..Orders.SalesPerson = SalesPerson
		set ..Orders.CurrentStatus = "NEW"
		if ..BillingAddress.IsEmpty() {
			if ..Cart.Customer.Address.IsEmpty(){
				$$$ThrowStatus($$$ERROR($$$GeneralError,"We cannot create an Order without an Address",..%ClassName(1)_"::"_$$$CurrentMethod))	
			}else{
				do ..Orders.BillingAddress.CopyFrom(..Cart.Customer.Address)
			}
		}else{
			do ..Orders.BillingAddress.CopyFrom(..BillingAddress)
		}		
		if ..ShippingAddress.IsEmpty() {
			if ..Cart.Customer.Address.IsEmpty(){
				$$$ThrowStatus($$$ERROR($$$GeneralError,"Cart Address Empty",..%ClassName(1)_"::"_$$$CurrentMethod))	
			}else{
				do ..Orders.ShippingAddress.CopyFrom(..Cart.Customer.Address)
			}
		}else{
			do ..Orders.ShippingAddress.CopyFrom(..ShippingAddress)
		}
		set ..Outlet=##class(Wasabi.Data.Employee).LocationGetStored(SalesPerson)
		set CartItem = ..Cart.LineItems.Next()
		while CartItem '= "" {
			set OrderItem = ##class(Wasabi.OrderEntry.Data.LineItem).%New()
			set OrderItem.Orders = ..Orders
			set OrderItem.Product = CartItem.Product
			set OrderItem.Quantity = CartItem.Quantity
			set OrderItem.UnitPrice = ##class(Wasabi.ProductManagement.API).GetCurrentPrice(..Customer,..Outlet,.catalog,CartItem.Product) // estimated price was CartItem.UnitPrice
			set CartItem = ..Cart.LineItems.Next()			
		}
		try{
			$$$THROWONERROR(sc, ..Orders.%Save())
		}catch ErrorObject {
			THROW ##class(Wasabi.OrderEntry.Exception).%New("CreateOrderNoSave",ErrorObject.Code,ErrorObject.Location,"Saving Order for "_..Cart.Customer.Name,ErrorObject)
		}
		//people can add more info until they confirm an order -- set ..Cart = ""
		set ..Invoice = ""
	}
	Quit $$$OK
}

/// This method:
///   Commits inventory to this Order
///   Changes the Order status to "ACCEPTED"
///   Removes the "Cart" thus disallowing any further changes to the Order
/// return true if order is fully confirmed as is, false if more interaction is required
/// Arguments:
///   Returns: 
///    Throws: Wasabi.OrderEntry.Exception
///            Wasabi.OrderEntry.CriticalException
/// <p>
/// This method is called as an indication that the "Offer Order" has been accepted by the customer.
/// </p>
/// <p>
/// If there is no Order, or the active Order is NOT in a "NEW" status, then this method should fail
/// </p>
Method ConfirmOrder(AcceptPartialOrder As %Boolean = 1)
{
	//Get committed item quantity
	set partial = 0 //is this a partial order
	try {
		set ..Orders.CurrentStatus = "ERROR: ConfirmOrder"
		set key = ""
		set OrderItem = ..Orders.LineItems.GetNext(.key)
		while '$IsObject(OrderItem) {
			set ..Orders.CurrentStatus = "ERROR: PartialConfirmOrder"
			set OrderItem.Committed = ##class(Wasabi.ProductManagement.API).Commit(OrderItem.Product,OrderItem.Quantity,..Outlet)
			if (OrderItem.Committed '= OrderItem.Quantity)
			{
				///throw an error 
				throw:'AcceptPartialOrder ##class(Wasabi.OrderEntry.Exception).%New("PartialOrderCommitted",0,$$$CurrentClass_"::"_$$$CurrentMethod,"Committing Order for "_..Cart.Customer.Name)
				set partial = 1
			}
			   set OrderItem = ..Orders.LineItems.Next(.key)			
		}
		//clear cart
		set ..Cart = ""
		//change order status
		set:'partial ..Orders.CurrentStatus="CONFIRMED"
		set:partial ..Orders.CurrentStatus="OPEN"
	} catch ErrorObject {
		throw:..Orders.CurrentStatus'="ERROR: PartialConfirmOrder" ##class(Wasabi.OrderEntry.Exception).%New("ConfirmOrder",ErrorObject.Code,ErrorObject.Location,"Confirming Order for "_..Cart.Customer.Name,ErrorObject)
		throw:'ErrorObject.%IsA("Wasabi.OrderEntry.Exception") ##class(Wasabi.OrderEntry.CriticalException).%New("ConfirmOrderUnknownCritical",ErrorObject.Code,ErrorObject.Location,"Critical Error (Possible Orphaned Committed Inventory Items): Confirming Order for "_..Cart.Customer.Name,ErrorObject)
		try {
		//check ErrorObject and try to rollback (if we cannot rollback we have a problem so I think we need a TRANSACTION (TSTART)
			set key=""
			set OrderItem = ..Orders.LineItems.GetNext(.key)
			while (OrderItem '= "")&&(OrderItem.Committed'="") {
				d ##class(Wasabi.ProductManagement.API).Release(OrderItem.Product,OrderItem.Committed,..Outlet)
				s OrderItem.Committed=0 // is this safe??
			}
		}
		catch ErrorObject2 {
			throw ##class(Wasabi.OrderEntry.CriticalException).%New("ConfirmOrderNoRollBack",ErrorObject.Code,ErrorObject.Location,"Confirming Order for "_..Cart.Customer.Name,ErrorObject2)
		} 
	}
}

/// Converts the the internal 
/// <class>Wasabi.OrderEntry.Data.Orders</class> instance into an the internal 
/// <class>Wasabi.OrderEntry.Data.Invoice</class> instance
Method CreateInvoice(PicklistFullfilled)
{
	;This method called by Product Management(warehouse) after list has been picke
	;with only filled items
	;
	;generate Invoice from filled picklist
	;update lineitems on order
	;add InvoiceLineItems to match fullfillment
	;update Order -stats
	;update OrderLineItems status
	Quit $$$OK
}

/// NOTE: Internal Logic
Method CommitOrderLineItem(LineItemId) As %Status [ Private ]
{
	;Calls product management api with qty
	;returns # committed
	;If return value = total value...then status ok
	;otherwise return value not available.
	Quit $$$OK
}

/// NOTE: Internal Logic
Method PriceOrderLineItem(LineItemId) As %Status [ Private ]
{
	;Calls product management api with product id
	;returns price
	;If return value = total value...then status ok
	;otherwise return value not available.
	Quit $$$OK
}

/// NOTE: Internal Logic
Method UnCommitOrderLineItem(IineItemID) As %Status [ Private ]
{
	;Calls product management api with qty
	;returns 1=successful
	Quit $$$OK
}

ClassMethod FindOrders(User As Wasabi.Data.Customer, ByRef Results As %Library.IResultSet) As %Status
{
	set res = $$$OK
	quit res
}

/// signature not defined
ClassMethod CartIterator(User As Wasabi.Data.Customer, ByRef Results As %Library.IResultSet) As %Status
{
	set res = $$$OK
	quit res
}

/// NOTE: Internal Logic
Method FillOrder() As %Status [ Private ]
{
	;Calls product management module pass in Order ID
	;
	;send to warehouse
	Quit $$$OK
}

/// NOTE: Internal Logic
Method CreateAuditEvent() As %Status [ Private ]
{
	
	;Insert Audit Entry for order
	;This is called anytime there is a status change on the order
	;create order, add line item, delete line item
	Quit $$$OK
}

/// NOTE: Internal Logic
Method ReturnItem(Invoice, Item) As %Status [ Private ]
{
	;
	$$$ThrowStatus($$$ERROR($$$MethodNotImplemented,..%ClassName(1)_"::"_$$$CurrentMethod))
	;
	Quit $$$OK
}

}

