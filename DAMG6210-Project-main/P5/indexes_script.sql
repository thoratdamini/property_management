USE PropertyManagementDB;
GO

CREATE NONCLUSTERED INDEX IX_MaintenanceRequest_Unit_Tenant
ON MaintenanceRequest (UnitID, TenantID);
GO


CREATE NONCLUSTERED INDEX IX_Invoice_Lease
ON Invoice (LeaseID, status);
GO


CREATE NONCLUSTERED INDEX IX_Payment_Tenant_Invoice
ON Payment (TenantID, InvoiceID, date);
GO

CREATE NONCLUSTERED INDEX IX_Unit_Property
ON Unit (PropertyID);
GO


CREATE NONCLUSTERED INDEX IX_User_Company
ON [User] (CompanyID);
GO
