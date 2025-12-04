USE PropertyManagementDB;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MyStrongPassword@123!';
GO

CREATE CERTIFICATE PropertyMgmt_Cert
WITH SUBJECT = 'Certificate for encrypting sensitive customer data';
GO

CREATE SYMMETRIC KEY PropertyMgmt_Key
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE PropertyMgmt_Cert;
GO

ALTER TABLE [User]
ADD email_encrypted VARBINARY(MAX),
    phone_encrypted VARBINARY(MAX);

ALTER TABLE Tenant
ADD income_encrypted VARBINARY(MAX),
    credit_encrypted VARBINARY(MAX);
GO

OPEN SYMMETRIC KEY PropertyMgmt_Key
DECRYPTION BY CERTIFICATE PropertyMgmt_Cert;

UPDATE [User]
SET email_encrypted = ENCRYPTBYKEY(KEY_GUID('PropertyMgmt_Key'), email),
    phone_encrypted = ENCRYPTBYKEY(KEY_GUID('PropertyMgmt_Key'), phone);

UPDATE Tenant
SET income_encrypted = ENCRYPTBYKEY(KEY_GUID('PropertyMgmt_Key'), CAST(income AS VARCHAR(50))),
    credit_encrypted = ENCRYPTBYKEY(KEY_GUID('PropertyMgmt_Key'), CAST(credit_score AS VARCHAR(10)));

CLOSE SYMMETRIC KEY PropertyMgmt_Key;
GO

OPEN SYMMETRIC KEY PropertyMgmt_Key
DECRYPTION BY CERTIFICATE PropertyMgmt_Cert;

SELECT 
    UserID,
    CONVERT(VARCHAR(100), DECRYPTBYKEY(email_encrypted)) AS email,
    CONVERT(VARCHAR(20), DECRYPTBYKEY(phone_encrypted)) AS phone
FROM [User];

SELECT 
    TenantID,
    CONVERT(VARCHAR(50), DECRYPTBYKEY(income_encrypted)) AS income,
    CONVERT(VARCHAR(10), DECRYPTBYKEY(credit_encrypted)) AS credit_score
FROM Tenant;

CLOSE SYMMETRIC KEY PropertyMgmt_Key;