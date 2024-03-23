import logging
import airflow
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta
from datetime import datetime, timedelta
from airflow.models import DAG
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor
import boto3
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


args = {"owner": "Airflow", "start_date": airflow.utils.dates.days_ago(2)}

dag = DAG(
    dag_id="Migration_SNF", default_args=args, schedule_interval=None
)


s3_bucketname = 'talend-to-snf'
s3_loc = 'landing_directory/success.txt'



with dag:

  s3_sensor = S3KeySensor(
        task_id='connection_to_s3',
        bucket_name=s3_bucketname,
        bucket_key=s3_loc,
        aws_conn_id='aws_default',
        # mode='poke',
        # poke_interval=5,
        # timeout=15,
        soft_fail=False
    )

  load_data_sf_table=BashOperator(
	task_id="move_file_s3_snf",
	bash_command='sh /home/ubuntu/dags/s3_to_talend/s3_to_talend_run.sh ',
	)

s3_sensor >> load_data_sf_table