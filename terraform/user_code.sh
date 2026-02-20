#!/bin/bash
set -euo pipefail

# ---------- prepare user log ----------
mkdir -p /home/ec2-user
touch /home/ec2-user/ml-demo-user-data.log
chown ec2-user:ec2-user /home/ec2-user/ml-demo-user-data.log

# ---------- log everything ----------
exec > >(tee /var/log/ml-demo-user-data.log /home/ec2-user/ml-demo-user-data.log | logger -t ml-demo -s 2>/dev/console) 2>&1

echo "[ml-demo] Starting..."

# ---------- install python ----------
dnf -y install python3-pip python3-virtualenv

# ---------- workspace ----------
mkdir -p /opt/ml-demo

# ---------- create venv ----------
python3 -m venv /opt/ml-demo/venv
source /opt/ml-demo/venv/bin/activate

pip install -U pip
pip install numpy pandas scikit-learn joblib

# ---------- training script ----------
cat > /opt/ml-demo/train.py <<'PY'
import json, time, shutil
from sklearn.datasets import load_diabetes
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import joblib

X, y = load_diabetes(return_X_y=True)
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=0)

m = LinearRegression()
t0 = time.time()
m.fit(Xtr, ytr)
pred = m.predict(Xte)

metrics = {
  "dataset": "sklearn.load_diabetes",
  "mse": float(mean_squared_error(yte, pred)),
  "mae": float(mean_absolute_error(yte, pred)),
  "r2":  float(r2_score(yte, pred)),
  "n_rows": int(X.shape[0]),
  "n_features": int(X.shape[1]),
  "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
  "fit_seconds": float(time.time() - t0),
}

with open("/opt/ml-demo/metrics.json","w") as f:
    json.dump(metrics, f, indent=2)

joblib.dump(m, "/opt/ml-demo/model.pkl")

# copy to home for demo
shutil.copy("/opt/ml-demo/metrics.json", "/home/ec2-user/metrics.json")
shutil.copy("/opt/ml-demo/model.pkl", "/home/ec2-user/model.pkl")

print("DONE.")
print(metrics)
PY

# ---------- run training ----------
/opt/ml-demo/venv/bin/python /opt/ml-demo/train.py

chown ec2-user:ec2-user /home/ec2-user/metrics.json /home/ec2-user/model.pkl || true

echo "[ml-demo] Finished."
