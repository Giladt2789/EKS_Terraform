# EKS_Terraform
Provisioning an EKS cluster using Terraform

In order to provision the cluster, you must run: <br/>
1. $ `terraform init`
2. $ `terraform validate`
3. $ `terraform plan`
4. $ `terraform apply -auto-approve` (the auto approve is optional)

Depend on the system (it took me about 15 minutes give or take to fully operational cluster), you should be getting
the cluster name as an output on the terminal. If you run my script in full, the cluster should be called "EKS_test-cluster".

In order to provision an aws alb ingress controller - according to the official documentaion:
[AWS Load Balancer Controller add-on] (https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html#lbc-install-controller)
1. For AWS all regions - the IAM policy for the load balancer can be downloaded via: 
'curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json'
2. Using the aws-cli create the policy:
'aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json'
3. Next, we need to create an IAM role. It's important to make sure that the aws-cli is in the correct region (i've tried several time to use it on my terminal, which was configured to us-east-1, while my cluster was at eu-central-1). The easiest way to re-configure the cli is with 'aws configure', 2x Enter, then the region name, and again enter (the first two are for the access and secret key - which will stay the same, the third prompt is for the region, and the last one is for the output type).
Now for the commands:
`aws eks describe-cluster --name ``my-cluster`` --query "cluster.identity.oidc.issuer" --output text`
(where ``my-cluster`` is the cluster name. in order to figure out the name of the cluster you can either go to the EKS service at AWS website, or run the command: `kubectl config current-context`)