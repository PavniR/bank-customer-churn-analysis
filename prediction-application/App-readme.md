## Customer Churn Intelligence Application

### Predict churn risk, understand model decisions, and support proactive customer retention.

Link for Application: [Customer Churn Intelligence Application]()

---

## Project Overview

This application is the deployment layer of an end-to-end bank customer
churn prediction project. It uses a pre-trained **Random Forest
Classifier** (built in scikit-learn) to estimate a customer's probability
of churning, convert that probability into a 0–100 risk score, and
recommend a retention action.

The broader project also includes SQL-based business analysis, exploratory
data analysis and feature engineering, comparison of Logistic Regression,
Decision Tree, and Random Forest models, SHAP-based explainability, and
Power BI dashboards. 

This Streamlit app focuses on the interactive,
individual-customer scoring layer used by the retention team.

---

### Key features

- Loads the trained model (`random_forest_model.pkl`) and feature schema
  (`feature_names.pkl`) with `joblib` (the model is never retrained here).
- A customer input form covering customer information and
  customer profile attributes.
- Preprocessing that mirrors the training pipeline exactly (gender
  encoding, one-hot encoded geography and card type, exact column order).
- KPI dashboard: churn probability, risk score, risk level badge, and
  suggested action.
- Dynamic business interpretation text based on the predicted risk level.
- Visualization of the risk score.
- Local SHAP explainability (`shap.TreeExplainer`) computed only for the
  customer currently being evaluated, a waterfall plot plus an
  automatically generated summary of the top 5 factors affecting the churn for each customer. 
- Adding SHAP explains the parameter on which model made its decision and **tells top five factors leading to churn of a particular customer**
- Defensive error handling around preprocessing, prediction, and SHAP
  generation so the app never crashes on bad input.

---

## Project Structure

```
.
├── pred-app.py                #Streamlit application(deployed)
├── requirements.txt           #Python dependencies
├── README.md                  #This file
├── random_forest_model.pkl    #Trained model(required)
└── feature_names.pkl          #Exact training feature order(required)
```
