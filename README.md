# 🏢 Multi-Tenant Property Management Platform

> An enterprise-grade database platform enabling property management companies to centralize operations, automate workflows, and scale efficiently with built-in security, multi-tenancy, and compliance features.

---

## 📋 Table of Contents

- [Mission Statement](#-mission-statement)
- [Key Features](#-key-features)
- [Architecture Overview](#-architecture-overview)
- [Database Schema](#-database-schema)
- [Technical Implementation](#-technical-implementation)
- [Security Features](#-security-features)
- [Installation & Setup](#-installation--setup)
- [Usage Examples](#-usage-examples)
- [Acknowledgments](#-acknowledgments)

---

## 🎯 Mission Statement

To deliver a **secure and scalable SaaS platform** that enables property managers to efficiently oversee multiple properties, streamline tenant interactions, manage financial transactions, and ensure transparent communication—while maintaining strict data isolation and robust role-based access control.

---

## ✨ Key Features

### 🏘️ **Property & Tenant Management**
- Multi-property portfolio management
- Comprehensive unit tracking (beds, baths, sq ft, amenities)
- Complete tenant profiles with employment and credit history
- Digital lease agreement management

### 🔧 **Maintenance Operations**
- Service request tracking from submission to completion
- Vendor assignment and status monitoring
- Category-based request organization (Plumbing, HVAC, Electrical, etc.)
- Real-time maintenance dashboards

### 💰 **Financial Management**
- Automated invoice generation
- Multi-method payment processing (ACH, Credit Card, Check, Debit)
- Overdue balance tracking
- Revenue and payment analytics

### 🔐 **Enterprise Security**
- **AES-256 encryption** for sensitive data (PII, financial information)
- **Role-Based Access Control (RBAC)** with 10 predefined roles
- **Multi-tenant data isolation** preventing cross-client access
- **Automated audit logging** for compliance and accountability

### 📊 **Analytics & Reporting**
- Property occupancy metrics
- Financial performance dashboards
- Maintenance request analytics
- Tenant payment history reports
- Company portfolio overview

### 💬 **Communication Hub**
- Threaded messaging system between stakeholders
- Notification management
- Document sharing and storage

---

## 🏗️ Architecture Overview

### Mission Objectives

| Objective | Description | Implementation |
|-----------|-------------|----------------|
| **Property Information Management** | Store and manage data for multiple buildings, units, and facilities | `Property`, `Unit`, `Amenity` tables with hierarchical relationships |
| **Tenant Management** | Maintain detailed tenant profiles, leases, and rental histories | `Tenant`, `Lease`, `User` tables with encrypted sensitive data |
| **Maintenance Request Tracking** | Log, process, and monitor service requests with vendor assignment | `MaintenanceRequest`, `Vendor`, `RequestAssigned` tables |
| **Payment Processing** | Record payments, manage billing cycles, track overdue balances | `Invoice`, `Payment` tables with stored procedures |
| **Document Management** | Secure storage and retrieval of digital documents | `Document` table with lease associations |
| **Role-Based Access Control** | Controlled access for managers, tenants, accountants, and staff | `Role`, `User_Role` tables with scope-based permissions |
| **Data Isolation** | Multi-tenancy with client data separation | `Company` table with tenant-specific filtering |
| **Communication Management** | Structured messaging between tenants, management, and vendors | `MessageThread`, `Message` tables |
| **Reporting & Analytics** | Dashboards for revenue, occupancy, and maintenance metrics | 6+ analytical views and UDFs |
| **Scalability & SaaS Delivery** | Support multiple companies with seamless onboarding | Tier-based company model with efficient indexing |

---

## 📊 Database Schema

### Entity Relationship Diagram (ERD)

```
┌─────────────┐         ┌──────────────────┐         ┌──────────────┐
│   Company   │────────▶│ PropertyManagement│────────▶│   Property   │
└─────────────┘         └──────────────────┘         └──────────────┘
      │                                                       │
      │                                                       ▼
      │                                                  ┌─────────┐
      │                                                  │  Unit   │
      │                                                  └─────────┘
      │                                                       │
      ▼                                                       │
┌──────────┐         ┌──────────┐                           │
│   User   │────────▶│ User_Role│                           │
└──────────┘         └──────────┘                           │
      │                    │                                 │
      │                    ▼                                 ▼
      │              ┌──────────┐         ┌─────────────────────────┐
      │              │   Role   │         │       Lease             │
      │              └──────────┘         └─────────────────────────┘
      │                                            │         │
      ▼                                            │         │
┌──────────┐                                      │         │
│ Tenant   │──────────────────────────────────────┘         │
└──────────┘                                                 │
      │                                                      ▼
      │                                              ┌──────────────┐
      │                                              │   Invoice    │
      │                                              └──────────────┘
      │                                                      │
      ▼                                                      ▼
┌──────────────────────┐                           ┌──────────────┐
│ MaintenanceRequest   │                           │   Payment    │
└──────────────────────┘                           └──────────────┘
      │
      ▼
┌──────────────────┐         ┌──────────┐
│ RequestAssigned  │────────▶│  Vendor  │
└──────────────────┘         └──────────┘
```

### Database Statistics
- **20+ Tables** with normalized schema design
- **5 CHECK Constraints** ensuring data integrity
- **10+ Foreign Key Relationships** maintaining referential integrity
- **50+ Columns** optimized with appropriate data types

---

## 🛠️ Technical Implementation

### Database Objects

#### 📝 **Stored Procedures**
- `sp_CreateMaintenanceRequest` - Streamlined maintenance request creation
- `sp_AddPayment` - Smart payment processing with validation
- `sp_AssignVendorToRequest` - Vendor assignment automation
- `sp_GetOutstandingInvoicesByTenant` - Outstanding balance retrieval

#### 🔢 **User-Defined Functions**
- `udf_GetTenantFullName` - Tenant name concatenation
- `udf_GetOutstandingBalance` - Calculate total outstanding balance
- `udf_GetPropertyUnitCount` - Count units per property
- `udf_IsLeaseActive` - Check lease validity status

#### 👁️ **Views**
- `vw_ActiveLeasesReport` - Current active leases with tenant info
- `vw_MaintenanceRequestSummary` - Comprehensive maintenance tracking
- `vw_TenantPaymentHistory` - Complete payment records
- `vw_CompanyPortfolioOverview` - Portfolio statistics
- `vw_LeaseRevenueSummary` - Revenue analysis by property
- `vw_UnpaidInvoices` - Outstanding payment tracking

#### ⚡ **Triggers**
- `trg_Audit_CompanyChanges` - Automated audit logging for company modifications

#### 📈 **Performance Optimization**
Strategic indexing on high-traffic queries:
```sql
IX_MaintenanceRequest_Unit_Tenant
IX_Invoice_Lease
IX_Payment_Tenant_Invoice
IX_Unit_Property
IX_User_Company
```

---

## 🔐 Security Features

### Encryption Implementation
```sql
-- AES-256 Symmetric Key Encryption
CREATE SYMMETRIC KEY PropertyMgmt_Key
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE PropertyMgmt_Cert;
```

### Protected Data Fields
- ✉️ User email addresses
- 📞 Phone numbers
- 💵 Tenant income information
- 📊 Credit scores

### Role-Based Access Control
| Role | Scope | Access Level |
|------|-------|--------------|
| Super Admin | System | Full system access |
| Company Admin | Company | Company-wide management |
| Property Manager | Property | Property-specific operations |
| Leasing Agent | Property | Tenant and lease management |
| Maintenance Supervisor | Property | Maintenance operations |
| Accountant | Company | Financial data access |
| Tenant | Unit | Personal lease and payment info |
| Vendor Admin | Vendor | Service request management |

### Audit Trail
All critical operations logged with:
- 👤 Actor identification
- 📋 Entity modified
- ⚡ Action performed (INSERT, UPDATE, DELETE)
- 🕐 Timestamp

---

## 🚀 Installation & Setup

### Prerequisites
- SQL Server 2019 or later
- SQL Server Management Studio (SSMS)
- Minimum 2GB RAM
- 500MB disk space

### Installation Steps

1. **Clone the Repository**
```bash
git clone https://github.com/yourusername/DAMG6210-Project.git
cd DAMG6210-Project
```

2. **Create Database**
```sql
-- Run DDL script
sqlcmd -S localhost -i DDL_Script.sql
```

3. **Populate Sample Data**
```sql
-- Run INSERT script
sqlcmd -S localhost -i INSERT_Script.sql
```

4. **Set Up Security**
```sql
-- Run encryption script
sqlcmd -S localhost -i Encryption_Script.sql
```

5. **Create Database Objects**
```sql
-- Run procedures, functions, views, and triggers
sqlcmd -S localhost -i Database_Objects.sql
```

6. **Verify Installation**
```sql
USE PropertyManagementDB;
SELECT COUNT(*) AS TotalCompanies FROM Company;
SELECT COUNT(*) AS TotalProperties FROM Property;
SELECT COUNT(*) AS TotalTenants FROM Tenant;
```

---

## 💡 Usage Examples

### Creating a Maintenance Request
```sql
DECLARE @NewRequestID INT;

EXEC sp_CreateMaintenanceRequest
    @UnitID = 1,
    @TenantID = 1,
    @Category = 'Plumbing',
    @Description = 'Leaking faucet in kitchen',
    @NewRequestID = @NewRequestID OUTPUT;

SELECT @NewRequestID AS NewRequestID;
```

### Processing a Payment
```sql
DECLARE @PaymentID INT, @Message VARCHAR(200);

EXEC sp_AddPayment
    @TenantID = 1,
    @InvoiceID = 1,
    @Amount = 2200.00,
    @Method = 'ACH Transfer',
    @NewPaymentID = @PaymentID OUTPUT,
    @Message = @Message OUTPUT;

SELECT @Message AS Result;
```

### Viewing Active Leases
```sql
SELECT * FROM vw_ActiveLeasesReport
WHERE PropertyName = 'Beacon Hill Apartments';
```

### Checking Outstanding Balance
```sql
SELECT dbo.udf_GetOutstandingBalance(1) AS OutstandingBalance;
```

### Accessing Encrypted Data
```sql
OPEN SYMMETRIC KEY PropertyMgmt_Key
DECRYPTION BY CERTIFICATE PropertyMgmt_Cert;

SELECT 
    UserID,
    CONVERT(VARCHAR(100), DECRYPTBYKEY(email_encrypted)) AS Email,
    CONVERT(VARCHAR(20), DECRYPTBYKEY(phone_encrypted)) AS Phone
FROM [User]
WHERE UserID = 1;

CLOSE SYMMETRIC KEY PropertyMgmt_Key;
```



## 🙏 Acknowledgments

**Professor Manuel Montrond**  
DAMG 6210 - Data Management and Database Design  
Northeastern University

Special thanks to Professor Montrond for his exceptional guidance on database architecture, normalization principles, and real-world application design throughout this project.
<<<<<<< HEAD
# propertymanagement
=======
>>>>>>> 4f6283815adaec05c72ce862088c56dba42dab81
