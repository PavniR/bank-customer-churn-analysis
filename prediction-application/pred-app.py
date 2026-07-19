import joblib
import numpy as np
import pandas as pd
import plotly.graph_objects as go
import shap
import streamlit as st
from matplotlib import pyplot as plt

# --------------------------------------------------------------------------
# MODEL METRICS & SETTINGS
# --------------------------------------------------------------------------
MODEL_NAME = "Random Forest Classifier"
ACCURACY = 0.8680
PRECISION = 0.8273
RECALL = 0.4461
ROC_AUC = 0.8703

MODEL_PATH = "random_forest_model.pkl"
FEATURE_NAMES_PATH = "feature_names.pkl"

RISK_LOW_MAX = 30
RISK_MEDIUM_MAX = 60

# --------------------------------------------------------------------------
# PAGE CONFIGURATION
# --------------------------------------------------------------------------
st.set_page_config(
    page_title="Bank Customer Churn Prediction",
    layout="wide",
    initial_sidebar_state="expanded",
)


# --------------------------------------------------------------------------
# THEME / STYLING
# --------------------------------------------------------------------------

def inject_custom_css() -> None:
    """Modern enterprise banking theme for Streamlit."""
    st.markdown(
        """
<style>
:root{
    --primary-blue:#2434B5;
    --primary-blue-dark:#1B2789;
    --surface-white:#FFFFFF;
    --page-bg:#F4F6FB;
    --text-dark:#1A1E3A;
    --text-muted:#5B6178;
    --border-soft:#E4E7F2;
    --green:#1E8E5A;
    --amber:#B9791C;
    --red:#C4342F;
}

html,body,.stApp,
[data-testid="stAppViewContainer"],
[data-testid="stMain"]{
    font-family:"Inter","Segoe UI",Arial,sans-serif;
    background:var(--page-bg);
    color:var(--text-dark);
}

h1,h2,h3,h4,h5,h6,
.stMarkdown h1,.stMarkdown h2,.stMarkdown h3,
.stMarkdown h4,.stMarkdown h5,.stMarkdown h6{
    color:var(--text-dark)!important;
}

p,span,div,label,li,strong,td,th{
    color:var(--text-dark);
}

.app-header{
    background:linear-gradient(120deg,var(--primary-blue),var(--primary-blue-dark));
    padding:28px 36px;
    border-radius:16px;
    box-shadow:0 8px 24px rgba(36,52,181,.18);
    margin-bottom:24px;
}
.app-header h1{color:#fff!important;font-size:30px;margin:0;}
.app-header p{color:#DCE1FA!important;margin-top:6px;}
.header-badge{
    display:inline-block;
    margin-top:14px;
    padding:6px 14px;
    border-radius:999px;
    color:#fff!important;
    background:rgba(255,255,255,.12);
    border:1px solid rgba(255,255,255,.35);
}

.card,.kpi-card{
    background:#fff;
    border:1px solid var(--border-soft);
    border-radius:14px;
    box-shadow:0 4px 14px rgba(20,25,60,.06);
}

.section-label{
    color:var(--text-muted)!important;
    font-size:12px;
    font-weight:700;
    text-transform:uppercase;
    letter-spacing:.6px;
}

.kpi-card{padding:20px;}
.kpi-label{
    color:var(--text-muted)!important;
    font-size:12px;
    font-weight:700;
    text-transform:uppercase;
}
.kpi-value{color:var(--text-dark)!important;font-size:32px;font-weight:700;}
.kpi-sub{color:var(--text-muted)!important;}

.badge{
    display:inline-block;
    padding:6px 16px;
    border-radius:999px;
    font-weight:700;
}
.badge-low{background:#E4F5EC;color:var(--green);}
.badge-medium{background:#FBF0DD;color:var(--amber);}
.badge-high{background:#FBE7E6;color:var(--red);}

.recommendation-card{
    background:var(--primary-blue);
    border-left:6px solid var(--primary-blue-dark);
    border-radius:14px;
    padding:20px 24px;
}
.recommendation-card h4,
.recommendation-card p{
    color:#fff!important;
}

.factor-item{
    display:flex;
    justify-content:space-between;
    padding:10px 14px;
    border-radius:10px;
    margin-bottom:8px;
}
.factor-increase{
    background:#FBEEEE;
    border-left:4px solid var(--red);
}
.factor-decrease{
    background:#EAF6EF;
    border-left:4px solid var(--green);
}
.factor-value{font-weight:700;}

section[data-testid="stSidebar"]{
    background:#fff;
    border-right:1px solid var(--border-soft);
}
section[data-testid="stSidebar"] *{
    color:var(--text-dark)!important;
}
section[data-testid="stSidebar"] h1,
section[data-testid="stSidebar"] h2,
section[data-testid="stSidebar"] h3{
    color:var(--primary-blue)!important;
}

[data-testid="stWidgetLabel"],
[data-testid="stWidgetLabel"] p,
.stRadio label,
.stSlider label,
.stNumberInput label,
.stSelectbox label{
    color:var(--text-dark)!important;
    font-weight:600;
}

div[role="radiogroup"] label{
    color:var(--text-dark)!important;
}

div.stButton>button{
    background:var(--primary-blue);
    color:#fff!important;
    border:none;
    border-radius:10px;
    font-weight:700;
    width:100%;
}
div.stButton>button:hover{
    background:var(--primary-blue-dark);
}

hr{
    border-color:var(--border-soft);
}
</style>
        """,
        unsafe_allow_html=True,
    )


# --------------------------------------------------------------------------
# RESOURCE LOADERS
# --------------------------------------------------------------------------
@st.cache_resource(show_spinner=False)
def load_model(path: str = MODEL_PATH):
    return joblib.load(path)


@st.cache_resource(show_spinner=False)
def load_feature_names(path: str = FEATURE_NAMES_PATH):
    return joblib.load(path)


@st.cache_resource(show_spinner=False)
def get_shap_explainer(_model):
    return shap.TreeExplainer(_model)


# --------------------------------------------------------------------------
# PREPROCESSING
# --------------------------------------------------------------------------
def preprocess_input(raw: dict, feature_names: list) -> pd.DataFrame:
    encoded = {name: 0 for name in feature_names}

    encoded["creditscore"] = raw["credit_score"]
    encoded["gender"] = 1 if raw["gender"] == "Male" else 0
    encoded["age"] = raw["age"]
    encoded["tenure"] = raw["tenure"]
    encoded["balance"] = raw["balance"]
    encoded["numofproducts"] = raw["num_of_products"]
    encoded["hascrcard"] = 1 if raw["has_cr_card"] == "Yes" else 0
    encoded["isactivemember"] = 1 if raw["is_active_member"] == "Yes" else 0
    encoded["estimatedsalary"] = raw["estimated_salary"]
    encoded["satisfactionscore"] = raw["satisfaction_score"]
    encoded["pointearned"] = raw["points_earned"]

    if raw["geography"] == "Germany":
        encoded["geography_Germany"] = 1
    elif raw["geography"] == "Spain":
        encoded["geography_Spain"] = 1

    card_type = raw.get("card_type", "DIAMOND")
    if card_type == "GOLD":
        encoded["cardtype_GOLD"] = 1
    elif card_type == "PLATINUM":
        encoded["cardtype_PLATINUM"] = 1
    elif card_type == "SILVER":
        encoded["cardtype_SILVER"] = 1

    return pd.DataFrame([encoded])[feature_names]


# --------------------------------------------------------------------------
# PREDICTION
# --------------------------------------------------------------------------
def predict(model, X: pd.DataFrame) -> dict:
    probability = float(model.predict_proba(X)[0][1])
    risk_score = round(probability * 100, 1)

    if risk_score <= RISK_LOW_MAX:
        risk_level = "Low"
        action = "Routine Engagement"
    elif risk_score <= RISK_MEDIUM_MAX:
        risk_level = "Medium"
        action = "Personalized Offer"
    else:
        risk_level = "High"
        action = "Immediate Retention Call"

    return {
        "probability": probability,
        "risk_score": risk_score,
        "risk_level": risk_level,
        "action": action,
    }


def business_interpretation(risk_level: str) -> str:
    messages = {
        "High": "This customer exhibits a high likelihood of churn. Immediate retention efforts are recommended to minimize customer attrition.",
        "Medium": "This customer shows moderate churn risk. Personalized engagement strategies may help improve retention.",
        "Low": "This customer demonstrates low churn risk. Routine engagement is sufficient.",
    }
    return messages[risk_level]


# --------------------------------------------------------------------------
# SHAP EXPLAINABILITY
# --------------------------------------------------------------------------
FEATURE_DISPLAY_NAMES = {
    "creditscore": "Credit Score",
    "gender": "Gender",
    "age": "Age",
    "tenure": "Tenure",
    "balance": "Account Balance",
    "numofproducts": "Number of Products",
    "hascrcard": "Has Credit Card",
    "isactivemember": "Active Membership",
    "estimatedsalary": "Estimated Salary",
    "satisfactionscore": "Satisfaction Score",
    "pointearned": "Points Earned",
    "geography_Germany": "Geography: Germany",
    "geography_Spain": "Geography: Spain",
    "cardtype_GOLD": "Card Type: Gold",
    "cardtype_PLATINUM": "Card Type: Platinum",
    "cardtype_SILVER": "Card Type: Silver",
}


def generate_shap(_explainer, X: pd.DataFrame):
    raw_values = _explainer.shap_values(X)
    if isinstance(raw_values, list):
        values = raw_values[1][0]
        base_value = _explainer.expected_value[1]
    elif raw_values.ndim == 3:
        values = raw_values[0, :, 1]
        base_value = _explainer.expected_value[1] if isinstance(_explainer.expected_value, (list, np.ndarray)) else _explainer.expected_value
    else:
        values = raw_values[0]
        base_value = _explainer.expected_value
    return values, base_value


def render_shap_waterfall(shap_values: np.ndarray, base_value: float, X: pd.DataFrame) -> None:
    display_names = [FEATURE_DISPLAY_NAMES.get(c, c) for c in X.columns]
    explanation = shap.Explanation(
        values=shap_values,
        base_values=base_value,
        data=X.iloc[0].values,
        feature_names=display_names,
    )
    fig = plt.figure(figsize=(5, 3.5))
    shap.plots.waterfall(explanation, max_display=7, show=False)
    fig = plt.gcf()
    fig.patch.set_facecolor("white")
    plt.xticks(fontsize=9)
    plt.yticks(fontsize=9)
    plt.tight_layout()
    st.pyplot(fig, clear_figure=True)


def render_plain_english_factors(shap_values: np.ndarray, X: pd.DataFrame) -> None:
    feature_names = X.columns.tolist()
    order = np.argsort(-np.abs(shap_values))[:5]

    increasing = []
    decreasing = []
    for idx in order:
        name = FEATURE_DISPLAY_NAMES.get(feature_names[idx], feature_names[idx])
        value = shap_values[idx]
        sentence = f"{name} ({X.iloc[0, idx]})"
        if value > 0:
            increasing.append((sentence, value))
        else:
            decreasing.append((sentence, value))

    st.markdown("<div class='section-label'>Factors Increasing Risk</div>", unsafe_allow_html=True)
    if increasing:
        for sentence, value in increasing:
            st.markdown(f"<div class='factor-item factor-increase'>{sentence}<span class='factor-value'>+{value:.2f}</span></div>", unsafe_allow_html=True)
    else:
        st.markdown("<div class='kpi-sub'>No major risk-increasing factors.</div>", unsafe_allow_html=True)

    st.markdown("<div class='section-label style='margin-top:10px;'>Factors Reducing Risk</div>", unsafe_allow_html=True)
    if decreasing:
        for sentence, value in decreasing:
            st.markdown(f"<div class='factor-item factor-decrease'>{sentence}<span class='factor-value'>{value:.2f}</span></div>", unsafe_allow_html=True)
    else:
        st.markdown("<div class='kpi-sub'>No major risk-reducing factors.</div>", unsafe_allow_html=True)


# --------------------------------------------------------------------------
# VISUAL COMPONENTS
# --------------------------------------------------------------------------
def render_gauge(risk_score: float) -> go.Figure:
    bar_color = "#1E8E5A" if risk_score <= RISK_LOW_MAX else ("#B9791C" if risk_score <= RISK_MEDIUM_MAX else "#C4342F")
    
    fig = go.Figure(
        go.Indicator(
            mode="gauge+number",
            value=risk_score,
            number={"suffix": " / 100", "font": {"size": 26, "color": "#1A1E3A"}},
            gauge={
                "axis": {
                    "range": [0, 100], 
                    "tickcolor": "#5B6178", 
                    "tickfont": {"size": 10}  # Fixed property name here
                },
                "bar": {"color": bar_color, "thickness": 0.3},
                "bgcolor": "white",
                "borderwidth": 0,
                "steps": [
                    {"range": [0, RISK_LOW_MAX], "color": "#E4F5EC"},
                    {"range": [RISK_LOW_MAX, RISK_MEDIUM_MAX], "color": "#FBF0DD"},
                    {"range": [RISK_MEDIUM_MAX, 100], "color": "#FBE7E6"},
                ],
            },
        )
    )
    fig.update_layout(
        height=160,
        margin=dict(l=10, r=10, t=10, b=10),
        paper_bgcolor="rgba(0,0,0,0)",
        font={"color": "#1A1E3A"},
    )
    return fig


def badge_html(risk_level: str) -> str:
    css_class = {"Low": "badge-low", "Medium": "badge-medium", "High": "badge-high"}[risk_level]
    return f"<span class='badge {css_class}'>{risk_level} Risk</span>"


def render_header() -> None:
    st.markdown(
        f"""
        <div class="app-header">
            <h1>Bank Customer Churn Prediction</h1>
            <p>AI-powered Customer Retention Decision Support System</p>
            <div class="header-badge">Model in production: {MODEL_NAME}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_sidebar() -> None:
    with st.sidebar:
        st.markdown("### About Project")
        st.write("This application predicts customer churn risk using a machine learning model trained on historical banking data.")
        st.markdown("---")
        st.markdown("### Model Information")
        st.markdown(f"**Selected Model:** {MODEL_NAME}")
        st.markdown(
            f"""
            | Metric | Value |
            |---|---|
            | Accuracy | {ACCURACY:.2%} |
            | Precision | {PRECISION:.2%} |
            | Recall | {RECALL:.2%} |
            | ROC-AUC | {ROC_AUC:.2%} |
            """
        )


# --------------------------------------------------------------------------
# INPUT FORM
# --------------------------------------------------------------------------
def render_input_form() -> dict:
    st.markdown("<div class='card'>", unsafe_allow_html=True)
    st.markdown("<h3>Customer Profile Input</h3>", unsafe_allow_html=True)

    col1, col2 = st.columns(2)

    with col1:
        st.markdown("<div class='section-label'>Customer Information</div>", unsafe_allow_html=True)
        
        # Age validated input field
        age = st.number_input("Age", min_value=18, max_value=120, value=38, step=1)
        if age > 93:
            st.error("Validation Error: Age cannot be above 93.")
            
        credit_score = st.slider("Credit Score", min_value=350, max_value=850, value=650)
        balance = st.number_input("Balance", min_value=0.0, max_value=300000.0, value=76485.0, step=500.0, format="%.2f")
        estimated_salary = st.number_input("Estimated Salary", min_value=0.0, max_value=250000.0, value=100090.0, step=500.0, format="%.2f")
        
        # Numeric inputs for Tenure & Satisfaction Score
        tenure = st.number_input("Tenure (years)", min_value=0, max_value=20, value=5, step=1)
        satisfaction_score = st.number_input("Satisfaction Score", min_value=1, max_value=5, value=3, step=1)
        
        num_of_products = st.selectbox("Number of Products", options=[1, 2, 3, 4], index=0)
        points_earned = st.slider("Points Earned", min_value=0, max_value=1000, value=606)

    with col2:
        st.markdown("<div class='section-label'>Customer Profile dummies</div>", unsafe_allow_html=True)
        
        # Swapped layout categories to match standard horizontal layouts
        gender = st.radio("Gender", options=["Female", "Male"], horizontal=True)
        geography = st.radio("Geography", options=["France", "Germany", "Spain"], horizontal=True)
        card_type = st.radio("Card Type", options=["DIAMOND", "GOLD", "PLATINUM", "SILVER"], horizontal=True)
        has_cr_card = st.radio("Has Credit Card", options=["Yes", "No"], horizontal=True)
        is_active_member = st.radio("Active Member", options=["Yes", "No"], horizontal=True)

    st.markdown("</div>", unsafe_allow_html=True)

    return {
        "age": age,
        "credit_score": credit_score,
        "balance": balance,
        "estimated_salary": estimated_salary,
        "tenure": tenure,
        "num_of_products": num_of_products,
        "points_earned": points_earned,
        "satisfaction_score": satisfaction_score,
        "gender": gender,
        "geography": geography,
        "card_type": card_type,
        "has_cr_card": has_cr_card,
        "is_active_member": is_active_member,
    }


# --------------------------------------------------------------------------
# RESULTS DASHBOARD
# --------------------------------------------------------------------------
def render_dashboard(model, explainer, X: pd.DataFrame, result: dict) -> None:
    st.markdown("### Prediction Results")
    
    # KPI Panels Layout
    c1, c2, c3, c4 = st.columns(4)
    c1.markdown(f"<div class='kpi-card'><div class='kpi-label'>Churn Probability</div><div class='kpi-value'>{result['probability'] * 100:.1f}%</div></div>", unsafe_allow_html=True)
    c2.markdown(f"<div class='kpi-card'><div class='kpi-label'>Risk Score</div><div class='kpi-value'>{result['risk_score']:.0f}/100</div></div>", unsafe_allow_html=True)
    c3.markdown(f"<div class='kpi-card'><div class='kpi-label'>Risk Level</div><div style='margin-top:4px;'>{badge_html(result['risk_level'])}</div></div>", unsafe_allow_html=True)
    c4.markdown(f"<div class='kpi-card'><div class='kpi-label'>Suggested Action</div><div class='kpi-value' style='font-size:18px;'>{result['action']}</div></div>", unsafe_allow_html=True)

    # Core Action Blue Panel Card
    st.markdown(
        f"""
        <div class="recommendation-card">
            <h4>Recommended Action: {result['action']}</h4>
            <p>{business_interpretation(result['risk_level'])}</p>
        </div>
        """,
        unsafe_allow_html=True,
    )

    # Compact Gauge Panel Block
    st.markdown("<div class='card'>", unsafe_allow_html=True)
    st.markdown("<h3>Risk Score Visualization</h3>", unsafe_allow_html=True)
    st.plotly_chart(render_gauge(result["risk_score"]), use_container_width=True)
    st.markdown("</div>", unsafe_allow_html=True)

    # Side-by-Side Model Insights Generation Block
    st.markdown("<div class='card'>", unsafe_allow_html=True)
    st.markdown("<h3>SHAP Explainability - Individual Prediction</h3>", unsafe_allow_html=True)

    try:
        shap_values, base_value = generate_shap(explainer, X)
        
        # Perfect Split View Configuration
        left_col, right_col = st.columns([1, 1])

        with left_col:
            render_shap_waterfall(shap_values, base_value, X)

        with right_col:
            render_plain_english_factors(shap_values, X)
            
    except Exception as exc:
        st.error(f"SHAP explanation could not be generated. Details: {exc}")

    st.markdown("</div>", unsafe_allow_html=True)


# --------------------------------------------------------------------------
# MAIN APPLICATION FLOW
# --------------------------------------------------------------------------
def main() -> None:
    inject_custom_css()
    render_header()
    render_sidebar()

    try:
        model = load_model()
        feature_names = load_feature_names()
        explainer = get_shap_explainer(model)
    except Exception as exc:
        st.error(f"Error loading system assets: {exc}")
        return

    raw_inputs = render_input_form()
    predict_clicked = st.button("Predict Churn Risk")

    if predict_clicked:
        if raw_inputs["age"] > 93:
            st.error("Please resolve validation errors before processing inputs.")
            return
            
        X = preprocess_input(raw_inputs, feature_names)
        result = predict(model, X)
        render_dashboard(model, explainer, X, result)
    else:
        st.info("Enter customer details above and click 'Predict Churn Risk' to generate a risk assessment.")


if __name__ == "__main__":
    main()