# MLflow Cheat Sheet

## Installation & Setup

```bash
# Install MLflow
pip install mlflow

# Install with extras (scikit-learn, xgboost, etc.)
pip install mlflow[extras]

# Check version
mlflow --version
python -c "import mlflow; print(mlflow.__version__)"

# Start tracking server (local file store, port 5000)
mlflow server

# Start on a custom host/port
mlflow server --host 0.0.0.0 --port 5001

# Start with SQLite backend store and local artifact store
mlflow server \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root ./mlartifacts \
  --host 0.0.0.0 \
  --port 5000

# Start with PostgreSQL backend store and S3 artifact store
mlflow server \
  --backend-store-uri postgresql://user:password@localhost:5432/mlflowdb \
  --default-artifact-root s3://my-mlflow-bucket/artifacts \
  --host 0.0.0.0 \
  --port 5000

# Start with GCS artifact store
mlflow server \
  --backend-store-uri postgresql://user:password@localhost:5432/mlflowdb \
  --default-artifact-root gs://my-mlflow-bucket/artifacts

# Start with Azure Blob Storage artifact store
mlflow server \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root wasbs://my-container@myaccount.blob.core.windows.net/artifacts

# Set tracking URI via environment variable
export MLFLOW_TRACKING_URI=http://localhost:5000

# MLflow UI (opens browser at http://localhost:5000)
mlflow ui
mlflow ui --port 5001
```

---

## MLflow CLI

```bash
# ── Experiments ──────────────────────────────────────────────────────────────

# Create experiment
mlflow experiments create --experiment-name my-experiment

# List all experiments
mlflow experiments list

# Delete experiment (soft delete)
mlflow experiments delete --experiment-id 1

# Rename experiment
mlflow experiments rename --experiment-id 1 --new-name my-experiment-v2

# ── Runs ─────────────────────────────────────────────────────────────────────

# List runs for an experiment
mlflow runs list --experiment-id 1

# Describe a specific run
mlflow runs describe --run-id <run-id>

# Delete a run (soft delete)
mlflow runs delete --run-id <run-id>

# ── Garbage Collection ────────────────────────────────────────────────────────

# Permanently delete soft-deleted runs and experiments
mlflow gc --backend-store-uri sqlite:///mlflow.db

# ── Diagnostic ────────────────────────────────────────────────────────────────

# Print environment info and config for debugging
mlflow doctor

# ── Running Projects ──────────────────────────────────────────────────────────

# Run an MLproject in the current directory
mlflow run .

# Run with parameters
mlflow run . -P alpha=0.5 -P n_estimators=100

# Run from a git repository
mlflow run https://github.com/my-org/my-project.git

# Run a specific entry point
mlflow run . --entry-point train

# ── Serving Models ────────────────────────────────────────────────────────────

# Serve a registered model (Production stage)
mlflow models serve -m models:/my-model/Production --port 5001

# Serve a model by run artifact path
mlflow models serve -m runs:/<run-id>/model --port 5001

# Serve without conda environment
mlflow models serve -m models:/my-model/Production --no-conda

# Batch predict from a file (CSV or JSON)
mlflow models predict \
  -m models:/my-model/Production \
  -i input_data.csv \
  -t csv

# Build a Docker image for model serving
mlflow models build-docker \
  -m models:/my-model/Production \
  -n my-model-image
```

---

## Experiments

```python
import mlflow

# Set the active experiment (creates it if it does not exist)
mlflow.set_experiment("my-experiment")

# Get experiment by name
experiment = mlflow.get_experiment_by_name("my-experiment")
print(experiment.experiment_id)
print(experiment.artifact_location)

# Create experiment with tags and custom artifact location
experiment_id = mlflow.create_experiment(
    name="my-experiment",
    artifact_location="s3://my-mlflow-bucket/my-experiment",
    tags={"team": "ml-platform", "project": "forecasting"},
)

# List all experiments via Python API
from mlflow.tracking import MlflowClient

client = MlflowClient()
experiments = client.search_experiments()
for exp in experiments:
    print(exp.experiment_id, exp.name, exp.lifecycle_stage)

# Search experiments by name filter
experiments = client.search_experiments(
    filter_string="name LIKE 'my-%'"
)

# Add / update a tag on an experiment
client.set_experiment_tag(experiment_id, "status", "active")
```

```bash
# List experiments (CLI)
mlflow experiments list

# Search experiments (CLI)
mlflow experiments search --filter "name LIKE 'my-%'"
```

---

## Tracking Runs (Python API)

```python
import mlflow
import mlflow.sklearn

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("my-experiment")

# ── Basic run ─────────────────────────────────────────────────────────────────

with mlflow.start_run(run_name="my-run") as run:
    # Log a single parameter
    mlflow.log_param("alpha", 0.5)

    # Log multiple parameters at once
    mlflow.log_params({"n_estimators": 100, "max_depth": 5, "random_state": 42})

    # Log a single metric
    mlflow.log_metric("accuracy", 0.93)

    # Log a metric at a given step (for curves)
    for epoch, loss in enumerate([0.9, 0.7, 0.5, 0.3]):
        mlflow.log_metric("train_loss", loss, step=epoch)

    # Log multiple metrics at once
    mlflow.log_metrics({"precision": 0.91, "recall": 0.89, "f1": 0.90})

    # Set a tag
    mlflow.set_tag("model_type", "RandomForest")
    mlflow.set_tag("git_commit", "abc123")

    # Log a single file as artifact
    mlflow.log_artifact("confusion_matrix.png")

    # Log all files in a directory as artifacts
    mlflow.log_artifacts("./output/", artifact_path="plots")

    print("Run ID:", run.info.run_id)

# ── Explicit start/end ────────────────────────────────────────────────────────

run = mlflow.start_run(run_name="my-run")
mlflow.log_param("learning_rate", 0.01)
mlflow.log_metric("loss", 0.25)
mlflow.end_run()                          # status defaults to FINISHED

# End run with explicit status
mlflow.end_run(status="FAILED")

# ── Autolog ───────────────────────────────────────────────────────────────────

# scikit-learn autolog (params, metrics, model)
mlflow.sklearn.autolog()

# XGBoost autolog
mlflow.xgboost.autolog()

# TensorFlow / Keras autolog
mlflow.tensorflow.autolog()

# PyTorch Lightning autolog
mlflow.pytorch.autolog()

# Global autolog (auto-detects installed framework)
mlflow.autolog()

# ── Nested runs ───────────────────────────────────────────────────────────────

with mlflow.start_run(run_name="parent-run") as parent:
    mlflow.log_param("experiment_type", "hyperparameter_search")

    for alpha in [0.1, 0.5, 1.0]:
        with mlflow.start_run(run_name=f"child-alpha-{alpha}", nested=True):
            mlflow.log_param("alpha", alpha)
            mlflow.log_metric("rmse", alpha * 0.5)   # placeholder metric

# ── Get artifact URI of the active run ───────────────────────────────────────

with mlflow.start_run():
    uri = mlflow.get_artifact_uri()
    print("Artifacts stored at:", uri)
```

---

## Model Logging & Signatures

```python
import mlflow
import mlflow.sklearn
import mlflow.pyfunc
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from mlflow.models.signature import infer_signature

mlflow.set_experiment("my-experiment")

X_train = pd.DataFrame({"feature_1": [1.0, 2.0], "feature_2": [3.0, 4.0]})
y_train = [0, 1]

model = RandomForestClassifier(n_estimators=100)
model.fit(X_train, y_train)

with mlflow.start_run(run_name="my-run"):
    # Infer signature from training data and predictions
    signature = infer_signature(X_train, model.predict(X_train))

    # Provide an input example (stored as artifact)
    input_example = X_train.iloc[:2]

    # Log a scikit-learn model
    mlflow.sklearn.log_model(
        sk_model=model,
        artifact_path="model",
        signature=signature,
        input_example=input_example,
        registered_model_name="my-model",   # auto-registers after logging
    )

    # Log a TensorFlow / Keras model
    # mlflow.tensorflow.log_model(tf_model, artifact_path="model", signature=signature)

    # Log a PyTorch model
    # mlflow.pytorch.log_model(torch_model, artifact_path="model", signature=signature)

    # Log an XGBoost model
    # mlflow.xgboost.log_model(xgb_model, artifact_path="model", signature=signature)

    # Log a HuggingFace Transformers pipeline
    # mlflow.transformers.log_model(pipeline, artifact_path="model", signature=signature)

# ── Custom PythonModel ────────────────────────────────────────────────────────

class MyCustomModel(mlflow.pyfunc.PythonModel):
    def load_context(self, context):
        import joblib
        self.model = joblib.load(context.artifacts["model_path"])

    def predict(self, context, model_input):
        return self.model.predict(model_input)

with mlflow.start_run(run_name="my-run"):
    artifacts = {"model_path": "my_model.pkl"}
    mlflow.pyfunc.log_model(
        artifact_path="custom_model",
        python_model=MyCustomModel(),
        artifacts=artifacts,
        signature=signature,
        input_example=input_example,
    )
```

---

## Model Registry

```python
import mlflow
from mlflow.tracking import MlflowClient

client = MlflowClient()

# ── Register a model ──────────────────────────────────────────────────────────

# Register from a completed run
result = mlflow.register_model(
    model_uri="runs:/<run-id>/model",
    name="my-model",
)
print("Version:", result.version)

# Create a registered model entry first, then add a version
client.create_registered_model(
    name="my-model",
    tags={"team": "data-science", "framework": "sklearn"},
    description="Production random forest classifier",
)

client.create_model_version(
    name="my-model",
    source="runs:/<run-id>/model",
    run_id="<run-id>",
)

# ── Stage transitions (MLflow 1.x / still supported in 2.x) ─────────────────

# None → Staging
client.transition_model_version_stage(
    name="my-model",
    version=1,
    stage="Staging",
    archive_existing_versions=False,
)

# Staging → Production (archive old Production versions)
client.transition_model_version_stage(
    name="my-model",
    version=1,
    stage="Production",
    archive_existing_versions=True,
)

# Production → Archived
client.transition_model_version_stage(
    name="my-model",
    version=1,
    stage="Archived",
)

# ── Model aliases (MLflow 2.x preferred approach) ────────────────────────────

# Set an alias on a specific version
client.set_registered_model_alias(
    name="my-model",
    alias="champion",
    version=3,
)

# Load model by alias
model = mlflow.pyfunc.load_model("models:/my-model@champion")

# Delete alias
client.delete_registered_model_alias(name="my-model", alias="champion")

# ── Model tags ────────────────────────────────────────────────────────────────

client.set_registered_model_tag("my-model", "task", "classification")
client.set_model_version_tag("my-model", version=1, key="validated", value="true")

# ── List and search registered models ────────────────────────────────────────

# List all registered models
for rm in client.search_registered_models():
    print(rm.name, rm.latest_versions)

# Get the latest version in a given stage
latest = client.get_latest_versions("my-model", stages=["Production"])
for mv in latest:
    print(mv.version, mv.current_stage, mv.source)
```

---

## Model Serving

```bash
# Serve the Production version of a registered model
mlflow models serve \
  -m models:/my-model/Production \
  --host 0.0.0.0 \
  --port 5001

# Serve by alias (MLflow 2.x)
mlflow models serve \
  -m "models:/my-model@champion" \
  --port 5001

# Serve without conda
mlflow models serve \
  -m models:/my-model/Production \
  --no-conda \
  --port 5001

# Serve with MLServer backend (supports v2 protocol)
mlflow models serve \
  -m models:/my-model/Production \
  --enable-mlserver \
  --port 5001

# Build Docker image
mlflow models build-docker \
  -m models:/my-model/Production \
  -n my-model-image:latest

# Run serving container
docker run -p 5001:8080 my-model-image:latest

# Batch predict (CSV input)
mlflow models predict \
  -m models:/my-model/Production \
  -i input.csv \
  -t csv

# Batch predict (JSON input)
mlflow models predict \
  -m models:/my-model/Production \
  -i input.json \
  -t json
```

```bash
# Call the /invocations REST endpoint after starting the server

# pandas-split format
curl -X POST http://localhost:5001/invocations \
  -H "Content-Type: application/json" \
  -d '{"dataframe_split": {"columns": ["feature_1","feature_2"], "data": [[1.0, 3.0]]}}'

# instances format (TF Serving compatible)
curl -X POST http://localhost:5001/invocations \
  -H "Content-Type: application/json" \
  -d '{"instances": [{"feature_1": 1.0, "feature_2": 3.0}]}'

# inputs format (numpy-based)
curl -X POST http://localhost:5001/invocations \
  -H "Content-Type: application/json" \
  -d '{"inputs": [[1.0, 3.0]]}'
```

---

## Projects

```yaml
# MLproject – project definition file
name: my-project

python_env: python_env.yaml   # or conda_env: conda.yaml

entry_points:
  main:
    parameters:
      alpha:
        type: float
        default: 0.5
      n_estimators:
        type: int
        default: 100
    command: "python train.py --alpha {alpha} --n-estimators {n_estimators}"

  evaluate:
    parameters:
      model_uri: {type: str}
    command: "python evaluate.py --model-uri {model_uri}"
```

```yaml
# python_env.yaml – lightweight dependency file (no conda required)
python: "3.10"
build_dependencies:
  - pip
dependencies:
  - scikit-learn==1.4.0
  - mlflow==2.12.0
  - pandas==2.2.0
```

```bash
# Run the project locally
mlflow run .

# Run with parameter overrides
mlflow run . -P alpha=0.3 -P n_estimators=200

# Run a specific entry point
mlflow run . --entry-point evaluate -P model_uri=models:/my-model/Production

# Run from a git repository
mlflow run https://github.com/my-org/my-project.git -P alpha=0.5

# Run a specific git branch / tag / commit
mlflow run https://github.com/my-org/my-project.git \
  --version main \
  -P alpha=0.5

# Choose the environment manager (conda / virtualenv / local)
mlflow run . --env-manager virtualenv

# Run on Kubernetes backend
mlflow run . \
  --backend kubernetes \
  --backend-config kubernetes_config.json
```

---

## Search & Query API

```python
import mlflow
import pandas as pd
from mlflow.tracking import MlflowClient

# ── Search runs ───────────────────────────────────────────────────────────────

# Search by metric and parameter (returns a pandas DataFrame)
runs_df = mlflow.search_runs(
    experiment_names=["my-experiment"],
    filter_string="metrics.accuracy > 0.9 AND params.model = 'rf'",
    order_by=["metrics.accuracy DESC"],
    max_results=50,
)
print(runs_df[["run_id", "metrics.accuracy", "params.model"]])

# Filter by tag
runs_df = mlflow.search_runs(
    experiment_names=["my-experiment"],
    filter_string="tags.model_type = 'RandomForest'",
)

# Search across all experiments
runs_df = mlflow.search_runs(
    experiment_ids=None,     # None means all experiments
    filter_string="metrics.f1 > 0.85",
)

# ── Search model versions ─────────────────────────────────────────────────────

client = MlflowClient()

# All versions of a model
versions = client.search_model_versions("name='my-model'")
for v in versions:
    print(v.version, v.current_stage, v.status)

# Filter by stage
prod_versions = client.search_model_versions(
    "name='my-model' AND version_stage='Production'"
)

# ── Pagination ────────────────────────────────────────────────────────────────

page_token = None
while True:
    results = client.search_registered_models(max_results=10, page_token=page_token)
    for rm in results:
        print(rm.name)
    page_token = results.token
    if not page_token:
        break

# ── Compare runs ──────────────────────────────────────────────────────────────

# Get the best run
best_run = runs_df.sort_values("metrics.accuracy", ascending=False).iloc[0]
print("Best run:", best_run["run_id"], "accuracy:", best_run["metrics.accuracy"])
```

---

## Deployment & Integration

```bash
# ── SageMaker ─────────────────────────────────────────────────────────────────

pip install mlflow[sagemaker]

# Deploy to SageMaker endpoint
mlflow sagemaker deploy \
  -a my-model-app \
  -m models:/my-model/Production \
  -e arn:aws:iam::123456789:role/SageMakerRole \
  --region-name eu-central-1 \
  --mode create

# Delete SageMaker deployment
mlflow sagemaker delete \
  --app-name my-model-app \
  --region-name eu-central-1

# Build SageMaker container image
mlflow sagemaker build-and-push-container
```

```python
# ── SageMaker (Python API) ────────────────────────────────────────────────────

import mlflow.sagemaker as mfs

mfs.deploy(
    app_name="my-model-app",
    model_uri="models:/my-model/Production",
    execution_role_arn="arn:aws:iam::123456789:role/SageMakerRole",
    region_name="eu-central-1",
    mode=mfs.DEPLOYMENT_MODE_CREATE,
    instance_type="ml.m5.xlarge",
    instance_count=1,
)

# ── Kubernetes (mlflow-deployment-plugin) ─────────────────────────────────────

# pip install mlflow[kubernetes]
# Requires: kubeflow/kfserving or seldon-core

# ── Azure ML ──────────────────────────────────────────────────────────────────

# pip install azureml-mlflow
import mlflow

mlflow.set_tracking_uri("azureml://eastus.api.azureml.ms/mlflow/v1.0/...")
mlflow.set_experiment("my-experiment")

# ── Databricks ────────────────────────────────────────────────────────────────

import mlflow

# Use Databricks as tracking server
mlflow.set_tracking_uri("databricks")
mlflow.set_experiment("/Users/user@accenture.com/my-experiment")

# Deploy model to Databricks model serving
from mlflow.deployments import get_deploy_client

client = get_deploy_client("databricks")
client.create_endpoint(
    name="my-model-endpoint",
    config={
        "served_models": [
            {"model_name": "my-model", "model_version": "1", "workload_size": "Small"}
        ]
    },
)

# ── Seldon Core ───────────────────────────────────────────────────────────────

# pip install mlflow-seldon
# mlflow deployments create -t seldon --name my-model -m models:/my-model/Production

# ── Prometheus metrics endpoint ───────────────────────────────────────────────

# Start server with Prometheus scraping enabled
mlflow server \
  --expose-prometheus ./metrics \
  --host 0.0.0.0 \
  --port 5000

# Metrics available at: http://localhost:5000/metrics
```

---

## MLflow 2.x Features

```python
import mlflow
from mlflow.tracking import MlflowClient

# ── Model aliases (replaces stage transitions) ────────────────────────────────

client = MlflowClient()

# Assign alias
client.set_registered_model_alias("my-model", "champion", version=3)
client.set_registered_model_alias("my-model", "challenger", version=4)

# Load by alias
model = mlflow.pyfunc.load_model("models:/my-model@champion")

# ── Set registry URI separately from tracking URI ────────────────────────────

mlflow.set_tracking_uri("http://tracking-server:5000")
mlflow.set_registry_uri("http://registry-server:5000")

# ── Dataset tracking (mlflow.data) ───────────────────────────────────────────

import pandas as pd
import mlflow.data
from mlflow.data.pandas_dataset import PandasDataset

df = pd.read_csv("training_data.csv")
dataset: PandasDataset = mlflow.data.from_pandas(
    df,
    source="training_data.csv",
    name="my-training-dataset",
    targets="label",
)

with mlflow.start_run():
    mlflow.log_input(dataset, context="training")

# ── LLM tracking (mlflow.llm) ─────────────────────────────────────────────────

with mlflow.start_run():
    mlflow.llm.log_predictions(
        inputs=["Translate to French: Hello"],
        outputs=["Bonjour"],
        prompts=["Translate to French: {text}"],
    )

# ── Model evaluation (mlflow.evaluate) ───────────────────────────────────────

eval_data = pd.DataFrame(
    {"inputs": ["text1", "text2"], "ground_truth": ["label1", "label2"]}
)

with mlflow.start_run():
    results = mlflow.evaluate(
        model="models:/my-model/Production",
        data=eval_data,
        targets="ground_truth",
        model_type="classifier",
        evaluators=["default"],
    )
    print(results.metrics)

# ── Prompt Engineering UI ─────────────────────────────────────────────────────

# Access via MLflow UI → "Prompt Engineering" tab (MLflow >= 2.7)
# Requires a registered prompt template in the model registry

# ── MlflowClient unified API ─────────────────────────────────────────────────

client = mlflow.MlflowClient()   # shortcut since MLflow 2.x
run = client.get_run("<run-id>")
print(run.data.params, run.data.metrics)
```

---

## Tips & Tricks

```bash
# Set experiment name via environment variable (no need for set_experiment() in code)
export MLFLOW_EXPERIMENT_NAME=my-experiment

# Set tracking URI via environment variable
export MLFLOW_TRACKING_URI=http://localhost:5000

# Set S3 endpoint for MinIO / custom S3
export MLFLOW_S3_ENDPOINT_URL=http://minio:9000
export AWS_ACCESS_KEY_ID=minio
export AWS_SECRET_ACCESS_KEY=minio123

# Enable HTTP authentication for tracking server
export MLFLOW_TRACKING_USERNAME=admin
export MLFLOW_TRACKING_PASSWORD=secret
```

```python
import mlflow
from mlflow.tracking import MlflowClient

# ── Get artifact URI of current run ──────────────────────────────────────────

with mlflow.start_run(run_name="my-run") as run:
    uri = mlflow.get_artifact_uri()
    print("Artifact root:", uri)
    # e.g. s3://my-mlflow-bucket/artifacts/0/abc123.../artifacts

    # Get URI for a specific artifact sub-path
    model_uri = mlflow.get_artifact_uri("model")

# ── Name your runs ────────────────────────────────────────────────────────────

with mlflow.start_run(run_name="my-run-rf-alpha0.5") as run:
    mlflow.log_param("alpha", 0.5)

# ── Fail a run explicitly ─────────────────────────────────────────────────────

run = mlflow.start_run(run_name="my-run")
try:
    raise ValueError("training failed")
except Exception as e:
    mlflow.set_tag("error", str(e))
    mlflow.end_run(status="FAILED")

# ── Log compressed artifacts ──────────────────────────────────────────────────

import tarfile, os

with tarfile.open("model_artifacts.tar.gz", "w:gz") as tar:
    tar.add("./output/", arcname="output")

with mlflow.start_run():
    mlflow.log_artifact("model_artifacts.tar.gz")

# ── Add experiment notes (description) ───────────────────────────────────────

client = MlflowClient()
client.set_experiment_tag(
    experiment_id="1",
    key="mlflow.note.content",
    value="# My Experiment\nBaseline random forest model for binary classification.",
)

# ── Set run description (visible in UI) ──────────────────────────────────────

with mlflow.start_run(run_name="my-run") as run:
    client = MlflowClient()
    client.set_tag(
        run.info.run_id,
        "mlflow.note.content",
        "Hyperparameter sweep with alpha in [0.1, 0.5, 1.0].",
    )

# ── UI features ───────────────────────────────────────────────────────────────

# Compare runs in UI:
#   Experiments page → select runs → click "Compare"
#   Parallel coordinate plot: Compare page → "Parallel Coordinates" tab
#   Artifact viewer: click a run → "Artifacts" tab

# ── Programmatically download an artifact ────────────────────────────────────

client = MlflowClient()
local_path = client.download_artifacts("<run-id>", "model", dst_path="./downloads")
print("Downloaded to:", local_path)

# ── Restore a soft-deleted run ────────────────────────────────────────────────

client.restore_run("<run-id>")

# ── Restore a soft-deleted experiment ────────────────────────────────────────

client.restore_experiment("<experiment-id>")
```
