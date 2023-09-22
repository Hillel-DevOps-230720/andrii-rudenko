# AWS CLI

## Prepare environment

```bash
sudo apt install -y jq
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp/ && sudo /tmp/aws/install
mkdir ./awscli && touch ./awscli/README.md && touch ./awscli/.log
```

Создаем группу sysops (дав ей права AdministratorAccess) и пользователя в этой группе. Для доступа к CLI генерируем Access keys и Secret access keys. Полученные токены записываем в файл aws.env, не забыв добавить маски *.env и *.key в .gitignore. Также в файле окружения прописываем доверенные IP.

<details>
  <summary>aws.env</summary>

```bash
tee aws.env >/dev/null <<EOF
AWS_ACCESS_KEY_ID=<YOUR ACCESS KEY>
AWS_SECRET_ACCESS_KEY=<YOUR SECRET ACCESS KEY>
AWS_TRUSTED_HOST1=<YOUR TRUSTED IP>/32
AWS_TRUSTED_HOST2=<YOUR TRUSTED IP>/32
AWS_DEFAULT_REGION=eu-central-1
EOF
```

</details>

```bash
set -o allexport; source aws.env; set +o allexport
```

## Declare environment variables

Создаем шаблон ./awscli/.environment с переменными описывающими нашу задачу, которые можно разделить на три типа:
токены, указатели на ресурсы, создаваемые в процессе развертывания инфраструктуры и параметры этой инфраструктуры.

<details>
  <summary>./awscli/.environment</summary>

```bash
tee ./awscli/.environment >/dev/null <<"EOF"
# AWS security
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_TRUSTED_HOST1=$AWS_TRUSTED_HOST1
AWS_TRUSTED_HOST2=$AWS_TRUSTED_HOST2
AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
# AWSCLI resources
AWSCLI_ID_IG_MAIN=$AWSCLI_ID_IG_MAIN
AWSCLI_ID_VPC_MAIN=$AWSCLI_ID_VPC_MAIN
AWSCLI_ID_RT_MAIN=$AWSCLI_ID_RT_MAIN
AWSCLI_ID_SUBNET_PROXY=$AWSCLI_ID_SUBNET_PROXY
AWSCLI_ID_SUBNET_DB=$AWSCLI_ID_SUBNET_DB
AWSCLI_ID_PL_TRUSTED=$AWSCLI_ID_PL_TRUSTED
AWSCLI_ID_SG_PROXY=$AWSCLI_ID_SG_PROXY
AWSCLI_ID_SG_DB=$AWSCLI_ID_SG_DB
AWSCLI_ID_AMI_PROXY=$AWSCLI_ID_AMI_PROXY
AWSCLI_ID_AMI_DB=$AWSCLI_ID_AMI_DB
AWSCLI_ID_I_PROXY=$AWSCLI_ID_I_PROXY
AWSCLI_ID_I_DB=$AWSCLI_ID_I_DB
AWSCLI_IP_PUBLIC_PROXY=$AWSCLI_IP_PUBLIC_PROXY
AWSCLI_IP_PRIVATE_DB=$AWSCLI_IP_PRIVATE_DB
# AWSCLI parameters
AWSCLI_CIDR_VPC_MAIN=192.168.0.0/16
AWSCLI_CIDR_SUBNET_PROXY=192.168.1.0/24
AWSCLI_CIDR_SUBNET_DB=192.168.2.0/24
AWSCLI_HTTP_PORT=8000
AWSCLI_DESCRIPTION_SG_PROXY='ssh trusted, http 8000 trusted, sg-db all'
AWSCLI_DESCRIPTION_SG_DB='sg-proxy all'
AWSCLI_NAME_KEY=awscli-key
AWSCLI_NAME_IAM_PROFILE=awscli-full-access
AWSCLI_NAME_MAIN=awscli-main
AWSCLI_NAME_PROXY=awscli-proxy
AWSCLI_NAME_DB=awscli-db
AWSCLI_NAME_TRUSTED=awscli-trusted
AWSCLI_SCRIPT_PROXY=file://./awscli/createProxy.sh
AWSCLI_SCRIPT_DB=file://./awscli/createDB.sh
EOF
```

</details>

```bash
set -o allexport; source ./awscli/.environment; set +o allexport
```

Теперь мы сможем сохранять:

```bash
envsubst < ./awscli/.environment > ./awscli/.env
```

и восстанавливать текущее состояние инфраструктуры:

```bash
set -o allexport; source ./awscli/.env; set +o allexport
```

Генерируем ключ для будущих подключений к нашим инстансам:

```bash
aws ec2 create-key-pair --key-name $AWSCLI_NAME_KEY \
    --key-type ed25519 --key-format pem --query "KeyMaterial" \
    --output text > aws.key
chmod 400 aws.key
```

## Create resources description

Для создания ресурсов с заданными параметрами будем использовать предварительно сгенерированные и отредактированные yaml-файлы, которые имееют более компактный формат чем json.

<details>
  <summary>Генерация шаблонов:</summary>

```bash
aws ec2 create-internet-gateway --generate-cli-skeleton yaml-input > ./awscli/ig-main.yaml
aws ec2 create-vpc --generate-cli-skeleton yaml-input > ./awscli/vpc-main.yaml
aws ec2 create-subnet --generate-cli-skeleton yaml-input > ./awscli/subnet-proxy.yaml
aws ec2 create-subnet --generate-cli-skeleton yaml-input > ./awscli/subnet-db.yaml
aws ec2 create-managed-prefix-list --generate-cli-skeleton yaml-input > ./awscli/pl-trusted.yaml
aws ec2 create-security-group --generate-cli-skeleton yaml-input > ./awscli/sg-proxy.yaml
aws ec2 authorize-security-group-ingress --generate-cli-skeleton yaml-input > ./awscli/sgr-proxy-ssh-trusted.yaml
aws ec2 authorize-security-group-ingress --generate-cli-skeleton yaml-input > ./awscli/sgr-proxy-http-trusted.yaml
aws ec2 authorize-security-group-ingress --generate-cli-skeleton yaml-input > ./awscli/sgr-proxy-sg-db-all.yaml
aws ec2 create-security-group --generate-cli-skeleton yaml-input > ./awscli/sg-db.yaml
aws ec2 authorize-security-group-ingress --generate-cli-skeleton yaml-input > ./awscli/sgr-db-sg-proxy-all.yaml
aws ec2 run-instances --generate-cli-skeleton yaml-input > ./awscli/i-proxy.yaml
aws ec2 run-instances --generate-cli-skeleton yaml-input > ./awscli/i-db.yaml
```

</details>

<details>
  <summary>ig-main.yaml</summary>

```yaml
TagSpecifications:
- ResourceType: internet-gateway
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_MAIN
```

</details>

<details>
  <summary>vpc-main.yaml</summary>

```yaml
CidrBlock: $AWSCLI_CIDR_VPC_MAIN
TagSpecifications:
- ResourceType: vpc
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_MAIN
```

</details>

</details>

<details>
  <summary>subnet-proxy.yaml</summary>

```yaml
VpcId: $AWSCLI_ID_VPC_MAIN
CidrBlock: $AWSCLI_CIDR_SUBNET_PROXY
TagSpecifications:
- ResourceType: subnet
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_PROXY
```

</details>

</details>

<details>
  <summary>subnet-db.yaml</summary>

```yaml
VpcId: $AWSCLI_ID_VPC_MAIN
CidrBlock: $AWSCLI_CIDR_SUBNET_DB
TagSpecifications:
- ResourceType: subnet
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_DB
```

</details>

<details>
  <summary>pl-trusted.yaml</summary>

```yaml
PrefixListName: $AWSCLI_NAME_TRUSTED
Entries:
- Cidr: $AWS_TRUSTED_HOST1
- Cidr: $AWS_TRUSTED_HOST2
MaxEntries: 5
AddressFamily: IPv4
```

</details>

<details>
  <summary>sg-proxy.yaml</summary>

```yaml
VpcId: $AWSCLI_ID_VPC_MAIN
GroupName: $AWSCLI_NAME_PROXY
Description: $AWSCLI_DESCRIPTION_SG_PROXY
```

</details>

<details>
  <summary>sgr-proxy-ssh-trusted.yaml</summary>

```yaml
GroupId: $AWSCLI_ID_SG_PROXY
IpPermissions:
- FromPort: 22
  IpProtocol: tcp
  PrefixListIds:
  - PrefixListId: $AWSCLI_ID_PL_TRUSTED
  ToPort: 22
```

</details>

<details>
  <summary>sgr-proxy-http-trusted.yaml</summary>

```yaml
GroupId: $AWSCLI_ID_SG_PROXY
IpPermissions:
- FromPort: $AWSCLI_HTTP_PORT
  IpProtocol: tcp
  PrefixListIds:
  - PrefixListId: $AWSCLI_ID_PL_TRUSTED
  ToPort: $AWSCLI_HTTP_PORT
```

</details>

<details>
  <summary>sgr-proxy-sg-db-all.yaml</summary>

```yaml
GroupId: $AWSCLI_ID_SG_PROXY
IpPermissions:
- FromPort: -1
  IpProtocol: "-1"
  ToPort: -1
  UserIdGroupPairs:
  - GroupId: $AWSCLI_ID_SG_DB
```

</details>

<details>
  <summary>sg-db.yaml</summary>

```yaml
VpcId: $AWSCLI_ID_VPC_MAIN
GroupName: $AWSCLI_NAME_DB
Description: $AWSCLI_DESCRIPTION_SG_DB
```

</details>

<details>
  <summary>sgr-db-sg-proxy-all.yaml</summary>

```yaml
GroupId: $AWSCLI_ID_SG_DB
IpPermissions:
- FromPort: -1
  IpProtocol: "-1"
  ToPort: -1
  UserIdGroupPairs:
  - GroupId: $AWSCLI_ID_SG_PROXY
```

</details>

<details>
  <summary>i-proxy.yaml</summary>

```yaml
ImageId: $AWSCLI_ID_AMI_PROXY
InstanceType: t2.micro
KeyName: $AWSCLI_NAME_KEY
MaxCount: 1
MinCount: 1
SecurityGroupIds:
- $AWSCLI_ID_SG_PROXY
SubnetId: $AWSCLI_ID_SUBNET_PROXY
IamInstanceProfile:
  Name: $AWSCLI_NAME_IAM_PROFILE
TagSpecifications:
- ResourceType: instance
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_PROXY
- ResourceType: volume
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_PROXY
PrivateDnsNameOptions:
  HostnameType: ip-name
  EnableResourceNameDnsARecord: true
```

</details>

<details>
  <summary>i-db.yaml</summary>

```yaml
ImageId: $AWSCLI_ID_AMI_DB
InstanceType: t2.micro
KeyName: $AWSCLI_NAME_KEY
MaxCount: 1
MinCount: 1
SecurityGroupIds:
- $AWSCLI_ID_SG_DB
SubnetId: $AWSCLI_ID_SUBNET_DB
IamInstanceProfile:
  Name: $AWSCLI_NAME_IAM_PROFILE
TagSpecifications:
- ResourceType: instance
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_DB
- ResourceType: volume
  Tags:
  - Key: 'Name'
    Value: $AWSCLI_NAME_DB
PrivateDnsNameOptions:
  HostnameType: ip-name
  EnableResourceNameDnsARecord: true
```

</details>

## Create infrastructure

<details>
  <summary>Создаем шлюз для выхода в интернет</summary>

```bash
export AWSCLI_ID_IG_MAIN=$(aws ec2 create-internet-gateway \
    --cli-input-yaml "$(envsubst < ./awscli/ig-main.yaml)" | \
    tee -a ./awscli/.log | jq -r ".InternetGateway.InternetGatewayId")
```

</details>

<details>
  <summary>Создаем виртуальную сеть, привязываем ее к шлюзу и разрешаем получение публичных dns-имен</summary>

```bash
export AWSCLI_ID_VPC_MAIN=$(aws ec2 create-vpc \
    --cli-input-yaml "$(envsubst < ./awscli/vpc-main.yaml)" | jq -r ".Vpc.VpcId")

aws ec2 modify-vpc-attribute \
    --vpc-id $AWSCLI_ID_VPC_MAIN \
    --enable-dns-hostnames "{\"Value\":true}"

aws ec2 attach-internet-gateway \
    --internet-gateway-id $AWSCLI_ID_IG_MAIN \
    --vpc-id $AWSCLI_ID_VPC_MAIN | tee -a ./awscli/.log

aws ec2 describe-vpcs \
    --vpc-ids $AWSCLI_ID_VPC_MAIN | tee -a ./awscli/.log
```

</details>

<details>
  <summary>В основной таблице маршрутизации прописываем маршрут на шлюз, разрешая инстансам выход в интернет</summary>

```bash
export AWSCLI_ID_RT_MAIN=$(aws ec2 describe-route-tables \
    --filters Name=vpc-id,Values=$AWSCLI_ID_VPC_MAIN | \
    jq -r ".RouteTables[].RouteTableId")

aws ec2 create-tags \
    --resources $AWSCLI_ID_RT_MAIN \
    --tags Key=Name,Value=$AWSCLI_NAME_MAIN

aws ec2 create-route \
    --route-table-id $AWSCLI_ID_RT_MAIN \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $AWSCLI_ID_IG_MAIN

aws ec2 describe-route-tables \
    --route-table-ids $AWSCLI_ID_RT_MAIN | \
    tee -a ./awscli/.log
```

</details>

<details>
  <summary>Делим виртуальную сеть на подсети, разрешая получать инстансам публичные ip-адреса</summary>

```bash
export AWSCLI_ID_SUBNET_PROXY=$(aws ec2 create-subnet \
    --cli-input-yaml "$(envsubst < ./awscli/subnet-proxy.yaml)" | \
    tee -a ./awscli/.log |  jq -r ".Subnet.SubnetId")

aws ec2 modify-subnet-attribute \
    --subnet-id $AWSCLI_ID_SUBNET_PROXY \
    --map-public-ip-on-launch

export AWSCLI_ID_SUBNET_DB=$(aws ec2 create-subnet \
    --cli-input-yaml "$(envsubst < ./awscli/subnet-db.yaml)" | \
    tee -a ./awscli/.log | jq -r ".Subnet.SubnetId")

aws ec2 modify-subnet-attribute \
    --subnet-id $AWSCLI_ID_SUBNET_DB \
    --map-public-ip-on-launch
```

</details>

<details>
  <summary>Создаем список доверенных ip-адресов и правила доступа к нашим инстансам из интернета и внутри виртуальной сети</summary>

```bash
export AWSCLI_ID_PL_TRUSTED=$(aws ec2 create-managed-prefix-list \
    --cli-input-yaml "$(envsubst < ./awscli/pl-trusted.yaml)" | \
    tee -a ./awscli/.log | jq -r ".PrefixList.PrefixListId")

export AWSCLI_ID_SG_PROXY=$(aws ec2 create-security-group \
    --cli-input-yaml "$(envsubst < ./awscli/sg-proxy.yaml)" | \
    tee -a ./awscli/.log | jq -r ".GroupId")

export AWSCLI_ID_SG_DB=$(aws ec2 create-security-group \
    --cli-input-yaml "$(envsubst < ./awscli/sg-db.yaml)" | \
    tee -a ./awscli/.log | jq -r ".GroupId")

aws ec2 authorize-security-group-ingress \
    --cli-input-yaml "$(envsubst < ./awscli/sgr-proxy-ssh-trusted.yaml)" | \
    tee -a ./awscli/.log

aws ec2 authorize-security-group-ingress \
    --cli-input-yaml "$(envsubst < ./awscli/sgr-proxy-http-trusted.yaml)" | \
    tee -a ./awscli/.log

aws ec2 authorize-security-group-ingress \
    --cli-input-yaml "$(envsubst < ./awscli/sgr-proxy-sg-db-all.yaml)" | \
    tee -a ./awscli/.log

aws ec2 authorize-security-group-ingress \
    --cli-input-yaml "$(envsubst < ./awscli/sgr-db-sg-proxy-all.yaml)" | \
    tee -a ./awscli/.log
```

</details>

## Run instances

<details>
  <summary>Создаем роль c правилами доступа наших инстансов к ресурсам AWS</summary>

```bash
aws iam create-role \
    --role-name $AWSCLI_NAME_MAIN \
    --assume-role-policy-document file://./awscli/trust-policy.json | \
    tee -a ./awscli/.log

aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
    --role-name $AWSCLI_NAME_MAIN

aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
    --role-name $AWSCLI_NAME_MAIN
```

</details>

<details>
  <summary>Создаем параметр с номером порта для передачи в инстанс</summary>

```bash
aws ssm put-parameter \
    --name "proxy_port_awscli" \
    --type "String" \
    --value $AWSCLI_HTTP_PORT \
    --overwrite
```

</details>

<details>
  <summary>Cкрипт для первоначального запуска истанса createProxy.sh</summary>

Для получения номера порта, переданного в инстанс в виде параметра, используется Systems Manager. Он в свою очередь требует AWS_DEFAULT_REGION. Для получения региона используем Instance Metadata Service Version 1 просто потому что curl выглядит не так страшно

```bash
tee ./awscli/createProxy.sh >/dev/null <<"EOF"
#!/bin/bash
apt-get update
apt-get install -y awscli jq git nginx
systemctl enable nginx
export ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
export AWS_DEFAULT_REGION=${ZONE::-1}
export PROXY_PORT=$(aws ssm get-parameter --name "proxy_port_awscli" | jq -r ".Parameter.Value")
sed -i "s|80 default_server|$PROXY_PORT default_server|g" /etc/nginx/sites-available/default
sudo systemctl reload nginx
EOF
```

</details>

<details>
  <summary>Cкрипт для первоначального запуска истанса createDB.sh</summary>

```bash
tee ./awscli/createDB.sh >/dev/null <<"EOF"
#!/bin/bash
apt-get update
apt-get install -y awscli jq git
EOF
```

</details>

<details>
  <summary>На основе стандартных образов запускаем инстансы</summary>

```bash
export AWSCLI_ID_AMI_PROXY=$(aws ssm get-parameters \
    --name "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id" | \
    jq -r ".Parameters[].Value")

export AWSCLI_ID_AMI_DB=$(aws ssm get-parameters \
    --name "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id" | \
    jq -r ".Parameters[].Value")

export AWSCLI_ID_I_PROXY=$(aws ec2 run-instances \
    --cli-input-yaml "$(envsubst < ./awscli/i-proxy.yaml)" \
    --user-data $AWSCLI_SCRIPT_PROXY | \
    tee -a ./awscli/.log | jq -r ".Instances[].InstanceId")

export AWSCLI_ID_I_DB=$(aws ec2 run-instances \
    --cli-input-yaml "$(envsubst < ./awscli/i-db.yaml)" \
    --user-data $AWSCLI_SCRIPT_DB | \
    tee -a ./awscli/.log | jq -r ".Instances[].InstanceId")
```

</details>

## Bastion host

<details>
  <summary>Получаем публичный ip proxy и приватный ip db</summary>

```bash
export AWSCLI_IP_PUBLIC_PROXY=$(aws ec2 describe-instances --instance-ids $AWSCLI_ID_I_PROXY | \
    jq -r ".Reservations[].Instances[].PublicIpAddress")

export AWSCLI_IP_PRIVATE_DB=$(aws ec2 describe-instances --instance-ids $AWSCLI_ID_I_DB | \
    jq -r ".Reservations[].Instances[].PrivateIpAddress")
```

</details>

<details>
  <summary>Подключаемся к инстансу db через инстанс proxy</summary>

```bash
ssh-add aws.key
ssh -J ubuntu@$AWSCLI_IP_PUBLIC_PROXY ubuntu@$AWSCLI_IP_PRIVATE_DB
```

</details>
