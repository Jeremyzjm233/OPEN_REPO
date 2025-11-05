from datetime import datetime, timedelta
import pendulum
from airflow import DAG
from docker_operator_plugin import RedshiftOperator

local_tz = pendulum.timezone("Australia/Melbourne")

default_args = {
    "owner": "(Data Engineering) Daily load For Data Warehouse ETL Transformation",
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
tables = [
    {
        "table_name": "dim_customer",
        "sql_params": {"de_daily_load_data_warehouse_dim_customer": "None"},
        "validation": "1",
    },
    {
        "table_name": "dim_device",
        "sql_params": {},
        "validation": "1",
    },
    {"table_name": "fact_order", "sql_params": {}, "validation": "0"},
    {"table_name": "fact_order_line", "sql_params": {}, "validation": "0"},
    {
        "table_name": "dim_product",
        "sql_params": {"de_daily_load_data_warehouse_dim_product": "None"},
        "validation": "1",
    },
]

with DAG(
    "de_daily_load_ac_shopping_dta_warehouse_aaron",
    catchup=False,
    default_args=default_args,
    schedule_interval="30 1 * * *",
    max_active_runs=1,
    tags=["DE"],
) as dag:
    sql_tasks = {
        table["table_name"]: RedshiftOperator(
            task_id=table["table_name"] + "_etl",
            cluster_name="ac-shopping-analytics",
            sql_path=table["table_name"],
            sql_params=table["sql_params"],
            validation=table["validation"],
            dag=dag,
        )
        for table in tables
    }
# Define dependency graph

[
    sql_tasks["dim_customer"],
    sql_tasks["dim_device"],
    sql_tasks["dim_product"],
] >> sql_tasks["fact_order"]
[
    sql_tasks["dim_customer"],
    sql_tasks["dim_device"],
    sql_tasks["dim_product"],
] >> sql_tasks["fact_order_line"]
