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
1. For 