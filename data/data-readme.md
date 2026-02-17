# Dataset Description

## Source
This dataset represents a retail bank customer dataset sourced from kaggle, commonly used for churn analysis and predictive modeling practice.  
It contains anonymized customer-level information related to demographics, financial status, engagement behavior, and churn outcome.

The dataset is used solely for portfolio demonstration purposes.

---

## Dataset Overview
- **Total Records:** 10,000 customers
- **Granularity:** One row per customer
- **Target Variable:** `Exited` (1 = Churned, 0 = Retained)

---

## Data Dictionary

| Column Name        | Description |
|--------------------|-------------|
| `RowNumber`        | Unique row identifier |
| `CustomerId`       | Unique customer ID |
| `Surname`          | Customer last name |
| `CreditScore`      | Customer credit score |
| `Geography`        | Customer country (France, Germany, Spain) |
| `Gender`           | Male / Female |
| `Age`              | Customer age |
| `Tenure`           | Years with the bank |
| `Balance`          | Account balance (in Euros) |
| `NumOfProducts`    | Number of bank products owned |
| `HasCrCard`        | Whether customer has a credit card (1 = Yes, 0 = No) |
| `IsActiveMember`   | Activity status of customer (1 = Active, 0 = Inactive) |
| `EstimatedSalary`  | Estimated annual salary |
| `Exited`           | Churn indicator (1 = Customer left the bank) |
| `Complain`         | Whether the customer filed a complaint |
| `SatisfactionScore`| Customer satisfaction score |
| `CardType`         | Type of card (Silver, Gold, Platinum, Diamond) |
| `PointEarned`      | Reward points earned by customer |

---

## Data Quality Checks Performed
The following validations were conducted before analysis:
- Checked for missing/null values across all columns
- Verified uniqueness of `CustomerId`
- Validated binary columns (`Exited`, `HasCrCard`, `IsActiveMember`, `Complain`)
- Confirmed valid categorical values for Geography, Gender, and CardType
- Verified numeric ranges for Age, Balance, Credit Score, Tenure, and Salary

No major data quality issues were identified.

---

## Notes
- The dataset is cross-sectional and does not include time-series behavior.
- Balance values of 0 may represent inactive or low-engagement accounts.
- Complaint flag is treated as a key behavioral signal for churn risk.
