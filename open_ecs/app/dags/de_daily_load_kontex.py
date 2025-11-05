from datetime import datetime, timedelta
import pendulum
from airflow import DAG
from docker_operator_plugin import DatabaseIngestionOperator

local_tz = pendulum.timezone("Australia/Melbourne")

default_args = {
    "owner": "(Data Engineering) Daily load from kontex",
    "depends_on_past": False,
    "start_date": datetime(2021, 2, 7, 12, 00, tzinfo=local_tz),
    "email": [
        "datasquad645@gmail.com",
    ],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 0,
    "retry_delay": timedelta(minutes=5),
}

# List of tables to ingesttest
tables = ["actions", "articles", "sites", "item_tags"]

with DAG(
    "de_daily_load_kontex",
    catchup=False,
    default_args=default_args,
    schedule_interval="30 0 * * *",
    max_active_runs=1,
    tags=["DE"],
) as dag:
    ingestion_tasks = {
        table: DatabaseIngestionOperator(
            task_id=table,
            cluster_name="ac-shopping-analytics",
            config_path="database_ingestion/config/kontex.yml",
            table_name=table,
            dag=dag,
        )
        for table in tables
    }
# Define dependency graph
ingestion_tasks["actions"]
ingestion_tasks["articles"]
ingestion_tasks["sites"]
ingestion_tasks["item_tags"]
