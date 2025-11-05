from datetime import datetime, timedelta
import pendulum
from airflow import DAG
from docker_operator_plugin import DatabaseIngestionOperator

local_tz = pendulum.timezone("Australia/Melbourne")

default_args = {
    "owner": "(Data Engineering) Daily load from ac shopping crm",
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
tables = ["customer", "product_upload", "seller", "order", "order_line", "product"]

with DAG(
    "de_daily_load_ac_shopping_crm_fargate",
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
            config_path="database_ingestion/config/ac_shopping_crm.yml",
            table_name=table,
            dag=dag,
        )
        for table in tables
    }
# Define dependency graph
ingestion_tasks["customer"]
ingestion_tasks["product_upload"]
ingestion_tasks["product"]
ingestion_tasks["seller"]
ingestion_tasks["order"]
ingestion_tasks["order_line"]
