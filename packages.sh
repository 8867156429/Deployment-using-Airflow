#!/bin/bash -xe
upload_log() {
  aws s3 cp /tmp/userdata_execution.log s3://talend-to-snf/logs/
}

trap 'upload_log' EXIT

sudo -u ubuntu -i <<'EOF'

exec &>> /tmp/userdata_execution.log


sudo apt update
sudo apt-get install -y openjdk-8-jdk
sudo apt-get install -y unzip
sudo apt -y install awscli
sudo apt --yes install python3-pip
sudo apt --yes install sqlite3
sudo apt-get --yes install libpq-dev
pip3 install --upgrade awscli
sudo pip3  install virtualenv
python3 -m virtualenv  /home/ubuntu/venv
source /home/ubuntu/venv/bin/activate
pip install "apache-airflow[postgres]==2.5.0" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.5.0/constraints-3.7.txt" pandas boto3
pip install pandas apache-airflow-providers-snowflake==2.1.0 snowflake-connector-python==2.5.1 snowflake-sqlalchemy==1.2.5
pip install apache-airflow-providers-snowflake
airflow db init
sudo apt-get --yes install postgresql postgresql-contrib
sudo -i -u postgres <<'EOpostgres'
psql -U postgres -c "CREATE DATABASE airflow;"
psql -U postgres -c "CREATE USER airflow WITH PASSWORD 'airflow';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;"
EOpostgres
sed -i 's#sqlite:////home/ubuntu/airflow/airflow.db#postgresql+psycopg2://airflow:airflow@localhost/airflow#g' /home/ubuntu/airflow/airflow.cfg
sed -i 's#SequentialExecutor#LocalExecutor#g' /home/ubuntu/airflow/airflow.cfg
airflow db init
airflow users create -u airflow -f airflow -l airflow -r Admin -e airflow@gmail.com -p admin@123!
mkdir /home/ubuntu/dags
pip install apache-airflow-providers-amazon[apache.hive]
aws s3 cp s3://talend-to-snf/codebase /home/ubuntu/dags --recursive
unzip -d /home/ubuntu/dags /home/ubuntu/dags/s3_to_talend_0.1.zip
sed -i 's/^dags_folder = .*/dags_folder = \/home\/ubuntu\/dags/' /home/ubuntu/airflow/airflow.cfg
sed -i 's/^load_examples = .*/load_examples = False/' /home/ubuntu/airflow/airflow.cfg
airflow db init
EOF