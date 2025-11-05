from datetime import datetime, timedelta
import pendulum
from airflow import DAG
from docker_operator_plugin import EMROperator, RedshiftOperator
from airflow.providers.amazon.aws.operators.glue_crawler import GlueCrawlerOperator

local_tz = pendulum.timezone("Australia/Melbourne")

default_args = {
    "owner": "(Data Engineering) Daily load For Customer Affinity Model ETL Transformation",
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

with DAG(
    "de_daily_load_ac_shopping_emr_customer_affinity_model_aaron",
    catchup=False,
    default_args=default_args,
    schedule_interval="30 5 * * *",
    max_active_runs=1,
    tags=["DE"],
) as dag:
    config = {
        "Name": "customer-affinity-model-crawler",
        # "Role": "AWSGlueServiceRole-ac-shopping",
        # "DatabaseName": "customer_affinity_model",
        # "Description": "Crawl cars dataset and catalog the the data",
        # "Targets": {"S3Targets": [{"Path": "s3://ac-shopping-affinity-model/"}]},
    }

    # redshift_data_export_task = RedshiftOperator(
    #     task_id="customer_affnity_input_data_export",
    #     cluster_name="ac-shopping-analytics",
    #     sql_path="export_affinity_model",
    #     sql_params={},
    #     validation="0",
    #     dag=dag,
    # )

    # customer_affinity_model_task = EMROperator(
    #     task_id="customer_affinity_model_etl",
    #     cluster_name="ac-shopping-analytics",
    #     config_path="customer_affinity_model/config/config",
    #     dag=dag,
    # )

    # Task to run the Glue Crawler
    run_glue_crawler = GlueCrawlerOperator(
        task_id="run_glue_crawler",
        aws_conn_id="aws_default",
        config=config,
        wait_for_completion=True,
    )

# Define dependency graph
# redshift_data_export_task >> customer_affinity_model_task >> run_glue_crawler
run_glue_crawler
