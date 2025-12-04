USE PropertyManagementDB;
GO

CREATE OR ALTER PROCEDURE sp_CreateMaintenanceRequest
      @UnitID INT,
      @TenantID INT,
      @Category VARCHAR(50),
      @Description VARCHAR(500),
      @NewRequestID INT OUTPUT
AS
BEGIN
      SET NOCOUNT ON;

      BEGIN TRY
            BEGIN TRAN;

            INSERT INTO MaintenanceRequest(UnitID, TenantID, category, description, status)
            VALUES(@UnitID, @TenantID, @Category, @Description, 'Open');

            SET @NewRequestID = SCOPE_IDENTITY();

            COMMIT TRAN;
      END TRY
      BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
            THROW;
      END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_AddPayment
      @TenantID INT,
      @InvoiceID INT,
      @Amount DECIMAL(10,2),
      @Method VARCHAR(50),
      @NewPaymentID INT OUTPUT,
      @Message VARCHAR(200) OUTPUT
AS
BEGIN
      SET NOCOUNT ON;

      BEGIN TRY
            BEGIN TRAN;

            IF NOT EXISTS (SELECT 1 FROM Invoice WHERE InvoiceID = @InvoiceID)
            BEGIN
                  SET @Message = 'Invoice does not exist';
                  ROLLBACK TRAN;
                  RETURN;
            END

            DECLARE @Due DECIMAL(10,2);
            SELECT @Due = amount_due FROM Invoice WHERE InvoiceID = @InvoiceID;

            IF @Amount > @Due
            BEGIN
                  SET @Message = 'Payment exceeds amount due';
                  ROLLBACK TRAN;
                  RETURN;
            END

            INSERT INTO Payment(TenantID, InvoiceID, amount, method)
            VALUES(@TenantID, @InvoiceID, @Amount, @Method);

            SET @NewPaymentID = SCOPE_IDENTITY();

            IF @Amount = @Due
                  UPDATE Invoice SET status = 'Paid' WHERE InvoiceID = @InvoiceID;

            SET @Message = 'Payment successful';

            COMMIT TRAN;
      END TRY
      BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
            THROW;
      END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_AssignVendorToRequest
      @RequestID INT,
      @VendorID INT,
      @Status VARCHAR(50),
      @ResultMessage VARCHAR(200) OUTPUT
AS
BEGIN
      SET NOCOUNT ON;

      BEGIN TRY
            BEGIN TRAN;

            IF NOT EXISTS (SELECT 1 FROM MaintenanceRequest WHERE RequestID = @RequestID)
            BEGIN
                  SET @ResultMessage = 'Invalid RequestID';
                  ROLLBACK TRAN;
                  RETURN;
            END

            IF NOT EXISTS (SELECT 1 FROM Vendor WHERE VendorID = @VendorID)
            BEGIN
                  SET @ResultMessage = 'Invalid VendorID';
                  ROLLBACK TRAN;
                  RETURN;
            END

            INSERT INTO RequestAssigned(RequestID, VendorID, status)
            VALUES(@RequestID, @VendorID, @Status);

            SET @ResultMessage = 'Vendor assigned successfully';

            COMMIT TRAN;
      END TRY
      BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;
            THROW;
      END CATCH
END
GO

CREATE OR ALTER PROCEDURE sp_GetOutstandingInvoicesByTenant
      @TenantID INT,
      @OutstandingCount INT OUTPUT
AS
BEGIN
      SET NOCOUNT ON;

      BEGIN TRY
            BEGIN TRAN;

            SELECT I.*
            FROM Invoice I
            INNER JOIN Lease L ON I.LeaseID = L.LeaseID
            WHERE L.TenantID = @TenantID
              AND I.status IN ('Pending', 'Overdue');

            SELECT @OutstandingCount = COUNT(*)
            FROM Invoice I
            INNER JOIN Lease L ON I.LeaseID = L.LeaseID
            WHERE L.TenantID = @TenantID
              AND I.status IN ('Pending', 'Overdue');

            COMMIT TRAN;
      END TRY

      BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRAN;

            THROW;
      END CATCH
END
GO

CREATE OR ALTER FUNCTION udf_GetTenantFullName
(
    @TenantID INT
)
RETURNS VARCHAR(150)
AS
BEGIN
    DECLARE @FullName VARCHAR(150);

    SELECT @FullName = first_name + ' ' + last_name
    FROM [User]
    WHERE TenantID = @TenantID;

    RETURN @FullName;
END;
GO


SELECT dbo.udf_GetTenantFullName(1);

GO
CREATE OR ALTER FUNCTION udf_GetOutstandingBalance
(
    @TenantID INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Balance DECIMAL(10,2);

    SELECT @Balance = SUM(I.amount_due)
    FROM Invoice I
    INNER JOIN Lease L ON I.LeaseID = L.LeaseID
    WHERE L.TenantID = @TenantID
      AND I.status IN ('Pending', 'Overdue');

    RETURN ISNULL(@Balance, 0.00);
END;
GO

SELECT dbo.udf_GetOutstandingBalance(1);

GO
CREATE OR ALTER FUNCTION udf_GetPropertyUnitCount
(
    @PropertyID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Units INT;

    SELECT @Units = COUNT(*)
    FROM Unit
    WHERE PropertyID = @PropertyID;

    RETURN ISNULL(@Units, 0);
END;
GO

SELECT dbo.udf_GetPropertyUnitCount(1);

GO
CREATE OR ALTER FUNCTION udf_IsLeaseActive
(
    @LeaseID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsActive BIT = 0;

    SELECT @IsActive =
        CASE 
            WHEN GETDATE() BETWEEN start_date AND end_date
            THEN 1
            ELSE 0
        END
    FROM Lease
    WHERE LeaseID = @LeaseID;

    RETURN @IsActive;
END;
GO

SELECT dbo.udf_IsLeaseActive(1);

GO
CREATE OR ALTER VIEW vw_ActiveLeasesReport AS
SELECT 
    L.LeaseID,
    T.TenantID,
    U.first_name + ' ' + U.last_name AS TenantName,
    P.PropertyID,
    P.Name AS PropertyName,
    L.UnitID,
    L.start_date,
    L.end_date,
    L.monthly_rent,
    L.deposit
FROM Lease L
JOIN Tenant T ON L.TenantID = T.TenantID
JOIN Unit UN ON L.UnitID = UN.UnitID
JOIN Property P ON UN.PropertyID = P.PropertyID
LEFT JOIN [User] U ON U.TenantID = T.TenantID
WHERE L.end_date >= GETDATE();
GO

CREATE OR ALTER VIEW vw_MaintenanceRequestSummary AS
SELECT 
    MR.RequestID,
    MR.category,
    MR.description,
    MR.status AS RequestStatus,
    T.TenantID,
    U.first_name + ' ' + U.last_name AS TenantName,
    UN.UnitID,
    UN.unit_no,
    P.PropertyID,
    P.Name AS PropertyName,
    RA.VendorID,
    V.Name AS VendorName,
    RA.status AS VendorStatus,
    RA.date_assigned
FROM MaintenanceRequest MR
JOIN Tenant T ON MR.TenantID = T.TenantID
LEFT JOIN [User] U ON U.TenantID = T.TenantID
JOIN Unit UN ON MR.UnitID = UN.UnitID
JOIN Property P ON UN.PropertyID = P.PropertyID
LEFT JOIN RequestAssigned RA ON MR.RequestID = RA.RequestID
LEFT JOIN Vendor V ON RA.VendorID = V.VendorID;
GO

CREATE OR ALTER VIEW vw_TenantPaymentHistory AS
SELECT 
    Pay.PaymentID,
    T.TenantID,
    U.first_name + ' ' + U.last_name AS TenantName,
    Inv.InvoiceID,
    Inv.amount_due,
    Pay.amount AS PaymentAmount,
    Pay.date AS PaymentDate,
    Pay.method,
    (Inv.amount_due - Pay.amount) AS RemainingBalance,
    Inv.status AS InvoiceStatus
FROM Payment Pay
JOIN Invoice Inv ON Pay.InvoiceID = Inv.InvoiceID
JOIN Tenant T ON Pay.TenantID = T.TenantID
LEFT JOIN [User] U ON U.TenantID = T.TenantID;
GO


CREATE OR ALTER VIEW vw_CompanyPortfolioOverview AS
SELECT 
    C.CompanyID,
    C.Name AS CompanyName,
    COUNT(DISTINCT P.PropertyID) AS TotalProperties,
    COUNT(DISTINCT U.UnitID) AS TotalUnits
FROM Company C
LEFT JOIN PropertyManagement PM ON PM.CompanyID = C.CompanyID
LEFT JOIN Property P ON P.ManagementID = PM.ManagementID
LEFT JOIN Unit U ON U.PropertyID = P.PropertyID
GROUP BY C.CompanyID, C.Name;
GO


CREATE OR ALTER VIEW vw_LeaseRevenueSummary AS
SELECT 
    P.PropertyID,
    P.Name AS PropertyName,
    SUM(L.monthly_rent) AS TotalMonthlyRent,
    SUM(L.deposit) AS TotalDeposits
FROM Property P
JOIN Unit U ON P.PropertyID = U.PropertyID
JOIN Lease L ON U.UnitID = L.UnitID
GROUP BY P.PropertyID, P.Name;
GO


CREATE OR ALTER VIEW vw_UnpaidInvoices AS
SELECT 
    I.InvoiceID,
    L.TenantID,
    U.first_name + ' ' + U.last_name AS TenantName,
    I.amount_due,
    I.due_date,
    I.status
FROM Invoice I
JOIN Lease L ON I.LeaseID = L.LeaseID
LEFT JOIN [User] U ON U.TenantID = L.TenantID
WHERE I.status IN ('Pending', 'Overdue');
GO

GO

CREATE OR ALTER TRIGGER trg_Audit_CompanyChanges
ON Company
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        INSERT INTO AuditLog (CompanyID, actor, entity, action, created_at)
        SELECT 
            i.CompanyID,
            SYSTEM_USER,           
            'Company',             
            'INSERT',
            GETDATE()
        FROM INSERTED i
        LEFT JOIN DELETED d ON i.CompanyID = d.CompanyID
        WHERE d.CompanyID IS NULL;   

        INSERT INTO AuditLog (CompanyID, actor, entity, action, created_at)
        SELECT 
            i.CompanyID,
            SYSTEM_USER,
            'Company',
            'UPDATE',
            GETDATE()
        FROM INSERTED i
        INNER JOIN DELETED d ON i.CompanyID = d.CompanyID;

        INSERT INTO AuditLog (CompanyID, actor, entity, action, created_at)
        SELECT 
            d.CompanyID,
            SYSTEM_USER,
            'Company',
            'DELETE',
            GETDATE()
        FROM DELETED d
        LEFT JOIN INSERTED i ON d.CompanyID = i.CompanyID
        WHERE i.CompanyID IS NULL;

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();

        RAISERROR(@ErrMsg, @ErrSeverity, 1);
    END CATCH
END
GO


INSERT INTO Company (Name, Tier, is_active)
VALUES ('Test Company', 'Basic', 1);


UPDATE Company
SET Tier = 'Premium'
WHERE Name = 'Test Company';

DELETE FROM Company
WHERE Name = 'Test Company';

SELECT * FROM AuditLog ORDER BY created_at DESC;