aws sts get-caller-identity

if [ $TerraformVersion = '0.13' ]; then	
   curl -o terraform.zip https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip
   ls -ltr
   unzip -q -o terraform.zip -d /var/tmp/terraform/
   /var/tmp/terraform/terraform --version
fi

if [ $TerraformVersion = '1.0.11' ]; then	
   curl -o terraform.zip https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip
   ls -ltr
   unzip -q -o terraform.zip -d /var/tmp/terraform/
   /var/tmp/terraform/terraform --version
fi

#curl -o terraform_1350.zip https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip
git config --global http.sslVerify false

echo "ENV is " $ENV
echo "Path is " $PATH
export PATH=/var/tmp/terraform/:$PATH 
git clone $Repository -b $Branch --verbose
#TF_LOG=TRACE
projectname=$(basename "$Repository" ".git")
tr '.' '_' <<<"$statename"
cd $projectname
ls -dl *
#ls builds


cd $var_file_path
/var/tmp/terraform/terraform init -force-copy -backend-config="key=ta.Workplace/cloudengineering-testing/t13/$projectname/$ENV/terraform.tfstate" -backend-config="bucket=ta-terraform-state" -no-color
/var/tmp/terraform/terraform validate


if [ $Action = 'plan' ] || [ $Action = 'apply' ]; then 		
	/var/tmp/terraform/terraform plan --out=${WORKSPACE}/latestPlan.json -var-file=$ENV.tfvars -no-color
    /var/tmp/terraform/terraform show -json ${WORKSPACE}/latestPlan.json > tf.json

    echo "The tf.json is"
    cat tf.json

    echo "Running checkov on the json"
    /usr/local/bin/checkov --framework terraform_plan -f tf.json --skip-check $CheckovSkips
    
    cd ..
    cd test
    ls -ltr
    echo "terraform version used by terratest"
	#temp_role=$(aws sts assume-role --role-arn "arn:aws:iam::754708396807:role/ta-workplace-jenkins-assumed-role-dev" --role-session-name "checkov-terratest-session")
	#export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
	#export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
	#export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)
	aws sts get-caller-identity

    # Set the AssumeRole for Terratest
    export TERRATEST_IAM_ROLE=arn:aws:iam::754708396807:role/ta-workplace-jenkins-assumed-role-dev
    terraform version
    /usr/local/go/bin/go version
    /usr/local/go/bin/go mod init examples
    /usr/local/go/bin/go get github.com/gruntwork-io/terratest/modules/terraform@v0.36.3 
    /usr/local/go/bin/go get github.com/stretchr/testify/assert@v1.4.0
    /usr/local/go/bin/go get github.com/gruntwork-io/terratest/modules/ssh@v0.36.3
    /usr/local/go/bin/go get github.com/gruntwork-io/terratest/modules/aws@v0.36.3
    /usr/local/go/bin/go get github.com/aws/aws-sdk-go/
    /usr/local/go/bin/go get github.com/aws/aws-sdk-go/service/backup
    /usr/local/go/bin/go get github.com/thedevsaddam/gojsonq
    /usr/local/go/bin/go get github.com/gruntwork-io/terratest/modules/retry@v0.36.3
    /usr/local/go/bin/go get github.com/zclconf/go-cty/cty@v1.2.1
    /usr/local/go/bin/go test -v -timeout 90m
fi
if [ $Action = 'destroy']; then	
    /var/tmp/terraform/terraform destroy -auto-approve -var-file=$ENV.tfvars -no-color
fi
if [ $Action = 'output' ]; then 			
    /var/tmp/terraform/terraform output -no-color
fi
