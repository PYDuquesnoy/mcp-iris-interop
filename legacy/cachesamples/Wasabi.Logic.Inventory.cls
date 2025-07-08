Include %occInclude

Class Wasabi.Logic.Inventory [ Abstract ]
{

/// Returns the quantity of product for a given outlet
ClassMethod GetAvailableQuantity(outlet As Wasabi.Data.Outlet, product As Wasabi.Data.Product) As %Integer
{
	if '##class(Wasabi.Data.OutletProduct).IdIndexExists(outlet.%Id(),product.%Id(),.id) {
		quit 0
	} 
	// Ray's bug #1. [XXX]
	//set op=##class(Wasabi.Data.OutletProduct).%OpenId(id)
	set op=##class(Wasabi.Data.OutletProduct).%OpenId(id,, .sc)
	if $$$ISERR(sc) { 
		$$$ThrowStatus(sc)
	}
	quit op.Quantity-op.QuantityCommitted
}

/// For a given product returns a prepared resultset with the following columns:<br>
/// <li>Outlet: id of the outlet</li>
/// <li>QuantityAvailable: quantity of product available at 'Outlet'</li>
/// In descending order by quantity available.
ClassMethod LocateProduct(product As Wasabi.Data.Product) As %IResultSet
{
	#dim rs as %IResultSet
	set sql="SELECT Outlet,Quantity-QuantityCommitted As QuantityAvailable FROM Wasabi.Data.OutletProduct WHERE Product = ? ORDER BY QuantityAvailable DESC"
	set rs=##class(%ResultSet.SQL).%Prepare(sql,,,product.%Id())
	if rs.%SQLCode<0 { 
		$$$ThrowStatus($$$ERROR($$$SQLCode,rs.%SQLCode,rs.%Message)) 
	}
	quit rs
}

/// Commits (as ordered) a quantity of product from a given outlet. If there is insufficient stock
/// to satisfy the entire quantity requested, the available quantity will be committed if partialcommit is true
/// or none will be committed if partialcommit is false.  Returns the quantity committed
ClassMethod CommitProduct(outlet As Wasabi.Data.Outlet, product As Wasabi.Data.Product, quantity As %Integer, partialcommit As %Boolean = 0) As %Integer
{
	set op=##class(Wasabi.Data.OutletProduct).IdIndexOpen(outlet.%Id(),product.%Id(),4,.sc)
	if $$$ISERR(sc) { 
		$$$ThrowStatus(sc) 
	}
	set avail=op.Quantity-op.QuantityCommitted
	if avail<quantity {
		if partialcommit {
			set quantity=avail
		} else {
			quit 0
		}
	}
	set op.QuantityCommitted=op.QuantityCommitted+quantity
	$$$THROWONERROR(sc,op.%Save())
	quit quantity
}

/// Releases a quantity of product from a given outlet which was previously committed
ClassMethod ReleaseProduct(outlet As Wasabi.Data.Outlet, product As Wasabi.Data.Product, quantity As %Integer)
{
	set op=##class(Wasabi.Data.OutletProduct).IdIndexOpen(outlet.%Id(),product.%Id(),4,.sc)
	if $$$ISERR(sc) { 
		$$$ThrowStatus(sc) 
	}
	set op.QuantityCommitted=op.QuantityCommitted-quantity
	$$$THROWONERROR(sc,op.%Save())
}

/// Removes a committed quantity from the stock altogether
ClassMethod ShipCommittedProduct(outlet As Wasabi.Data.Outlet, product As Wasabi.Data.Product, quantity As %Integer)
{
	set op=##class(Wasabi.Data.OutletProduct).IdIndexOpen(outlet.%Id(),product.%Id(),4,.sc)
	if $$$ISERR(sc) { 
		$$$ThrowStatus(sc) 
	}
	set op.Quantity=op.Quantity-quantity,op.QuantityCommitted=op.QuantityCommitted-quantity
	$$$THROWONERROR(sc,op.%Save())
}

/// Adds a quantity of product to the given outlet's stock
ClassMethod RestockProduct(outlet As Wasabi.Data.Outlet, product As Wasabi.Data.Product, quantity As %Integer)
{
	set op=##class(Wasabi.Data.OutletProduct).IdIndexOpen(outlet.%Id(),product.%Id(),4,.sc)
	if $$$ISERR(sc) { 
		$$$ThrowStatus(sc) 
	}
	set op.Quantity=op.Quantity+quantity
	$$$THROWONERROR(sc,op.%Save())
}

}

