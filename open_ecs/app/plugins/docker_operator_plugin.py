from airflow.exceptions import AirflowException
from airflow.plugins_manager import AirflowPlugin
from airflow.utils.decorators import apply_defaults
from airflow.providers.amazon.aws.operators.ecs import EcsRunTaskOperator
from airflow.providers.amazon.aws.hooks.ssm import SsmHook
import json


def get_ssm_parameter(parameter_name: str, **kwargs):
    # ssm_hook = SsmHook()
    # parameter_value = ssm_hook.get_parameter_value(parameter=parameter_name)
    return "subnet-038f4565,subnet-b914d0f1,subnet-904702c8"


class DatabaseIngestionOperator(EcsRunTaskOperator):
    ui_color = "#e9fffe"

    @apply_defaults
    def __init__(
        self,
        config_path,
        cluster_name=None,
        table_name=None,
        *args,
        **kwargs,
    ):
        super().__init__(
            cluster=cluster_name or "ac-shopping-analytics",
            task_definition="database-ingestion",
            overrides=None,
            *args,
            **kwargs,
        )
        self.region_name = "ap-southeast-2"
        self.launch_type = "FARGATE"
        # self.cluster = cluster_name or "data-service-airflow-dev"
        self.config_path = config_path
        self.table_name = table_name
        self.task_definition = "database-ingestion"
        self.awslogs_group = "/ecs/database-ingestion"
        self.overrides = dict(
            {
                "containerOverrides": [
                    {
                        "name": "database-ingestion",
                        "command": self.construct_command(),
                    }
                ]
            },
        )
        self.network_configuration = dict(
            {
                "awsvpcConfiguration": {
                    "subnets": get_ssm_parameter(
                        "/data-service-airflow/subnet_ids"
                    ).split(","),
                    "assignPublicIp": "ENABLED",
                }
            }
        )

    def execute(self, context):
        try:
            super().execute(context)
        except Exception as e:
            raise AirflowException(
                f"ECS Fargate Database Ingestion Operator error:{str(e)}"
            )

    def construct_command(self):
        cmd = [
            "python3",
            "database_ingestion_runner.py",
            "--config_path",
            self.config_path,
        ]
        if self.table_name != "" and self.table_name is not None:
            cmd.extend(["--table_name", self.table_name])

        return cmd


class RedshiftOperator(EcsRunTaskOperator):
    ui_color = "#e9fffe"

    @apply_defaults
    def __init__(
        self,
        sql_path,
        sql_params,
        validation=1,
        cluster_name=None,
        *args,
        **kwargs,
    ):
        super().__init__(
            cluster=cluster_name or "ac-shopping-analytics",
            task_definition="data-processing-aaron",
            overrides=None,
            *args,
            **kwargs,
        )

        self.region_name = "ap-southeast-2"
        self.launch_type = "FARGATE"
        self.sql_path = sql_path
        self.validation = validation
        self.sql_params = sql_params
        self.awslogs_group = "/ecs/database-ingestion"
        self.overrides = dict(
            {
                "containerOverrides": [
                    {"name": "data-processing", "command": self.construct_command()}
                ]
            },
        )

        self.network_configuration = dict(
            {
                "awsvpcConfiguration": {
                    "subnets": get_ssm_parameter(
                        "/data-service-airflow/subnet_ids"
                    ).split(","),
                    "assignPublicIp": "ENABLED",
                }
            }
        )

        ##self.awslogs_stream_prefix = "airflow-database-ingestion"

    def construct_command(self):
        cmd = [
            "python3",
            "data_processing_runner.py",
            "--sql_path",
            self.sql_path,
            "--params",
            json.dumps(self.sql_params),
            "--validation",
            f"{self.validation}",
        ]

        return cmd

    def execute(self, context):
        try:
            super().execute(context)
        except Exception as e:
            raise AirflowException(
                f"ECS Fargate Data Processing Operator error:{str(e)}"
            )


class EMROperator(EcsRunTaskOperator):
    ui_color = "#e9fffe"

    @apply_defaults
    def __init__(
        self,
        config_path,
        cluster_name=None,
        *args,
        **kwargs,
    ):
        super().__init__(
            cluster=cluster_name or "ac-shopping-analytics",
            task_definition="emr-transformation-aaron",
            overrides=None,
            *args,
            **kwargs,
        )

        self.region_name = "ap-southeast-2"
        self.launch_type = "FARGATE"
        self.config_path = config_path
        self.awslogs_group = "emr-transformation-log-group-aaron"
        self.overrides = dict(
            {
                "containerOverrides": [
                    {"name": "emr-transformation", "command": self.construct_command()}
                ]
            },
        )

        self.network_configuration = dict(
            {
                "awsvpcConfiguration": {
                    "subnets": get_ssm_parameter(
                        "/data-service-airflow/subnet_ids"
                    ).split(","),
                    "assignPublicIp": "ENABLED",
                }
            }
        )

        ##self.awslogs_stream_prefix = "airflow-database-ingestion"

    def construct_command(self):
        cmd = [
            "python",
            "emr_customer_affinity_model_runner.py",
            "--config_path",
            self.config_path,
        ]

        return cmd

    def execute(self, context):
        try:
            super().execute(context)
        except Exception as e:
            raise AirflowException(f"ECS Fargate EMR Operator error:{str(e)}")


class DockerOperatorPlugin(AirflowPlugin):
    name = "docker_operator_plugin"
    operators = [DatabaseIngestionOperator, RedshiftOperator, EMROperator]
