# EKS_Terraform
Provisioning an EKS cluster using Terraform

In order to provision the cluster, you must run:
1. `$ terraform init`
2. `$ terraform validate`
3. `$ terraform plan`
4. `$ terraform apply -auto-approve` (the auto approve is optional)

Depend on the system (it took me about 15 minutes give or take to fully operational cluster), you should be getting
the cluster name as an output on the terminal. If you run my script in full, the cluster should be called "EKS_test-cluster".
In order to connect the aws account with our cluster (for management purposes), run this command to attach the cluster (change the <aws-region> and the <cluster-name> to your own)<br/>
`aws eks --region <aws-region> update-kubeconfig --name <cluster-name>`

In order to provision an aws alb ingress controller - according to the official documentaion:
[AWS Load Balancer Controller add-on](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html#lbc-install-controller)
1. For AWS all regions - the IAM policy for the load balancer can be downloaded via: 
```
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json
```
2. Using the aws-cli create the policy:
```
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
```
3. Next, we need to create an IAM role. It's important to make sure that the aws-cli is in the correct region (i've tried several time to use it on my terminal, which was configured to us-east-1, while my cluster was at eu-central-1). The easiest way to re-configure the cli is with 'aws configure', 2x Enter, then the region name, and again enter (the first two are for the access and secret key - which will stay the same, the third prompt is for the region, and the last one is for the output type).
Now for the commands:
```
aws eks describe-cluster --name <sub>my-cluster</sub> --query "cluster.identity.oidc.issuer" --output text
```
(where <my-cluster> is the cluster name. in order to figure out the name of the cluster you can either go to the EKS service at AWS website, or run the command: `kubectl config current-context`)
the output should look as such:
```
oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE
```
If no output or error given, you must create an IAM OIDC provider for the cluster. The link is [IAM OIDC create](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)
4.1. After creating the IAM OIDC provider, run again the command for step 3, and copy the text after id above (here it starts with ``EXAMPLED539...``). Write it down somewhere, you'll be using it later. Also, write down your account ID. in the following code snippet, you'll replace those parameters:
* `<111122223333>`
* `<region-code>`
* `<EXAMPLED539D4633E53DE1B71EXAMPLE>`

```
cat >load-balancer-role-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<111122223333>:oidc-provider/oidc.eks.<region-code>.amazonaws.com/id/<EXAMPLED539D4633E53DE1B71EXAMPLE>"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.<region-code>.amazonaws.com/id/<EXAMPLED539D4633E53DE1B71EXAMPLE>:aud": "sts.amazonaws.com",
                    "oidc.eks.<region-code>.amazonaws.com/id/<EXAMPLED539D4633E53DE1B71EXAMPLE>:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF
```
4.2. Now let's create the IAM role:
```
aws iam create-role --role-name AmazonEKSLoadBalancerControllerRole --assume-role-policy-document file://"load-balancer-role-trust-policy.json"
```
4.3. Let's attach the required Amazon EKS managed IAM policy to the IAM role. Again, replace the <111122223333> with your account ID:
```
aws iam attach-role-policy --policy-arn arn:aws:iam::<111122223333>:policy/AWSLoadBalancerControllerIAMPolicy --role-name AmazonEKSLoadBalancerControllerRole
```

4.4. Now, open your favorite text editor, copy this snippet and edit it with the following replacements:
* `<111122223333>` - account ID
```
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<111122223333>:role/AmazonEKSLoadBalancerControllerRole
```
save the file as: aws-load-balancer-controller-service-account.yaml<br/>

4.5. Run the command: <br/>
`kubectl apply -f aws-load-balancer-controller-service-account.yaml` to create the service account.

5. In order to install the AWS Load Balancer Controller, we need to do the following: <br/>
5.1. Install the `cert-manager` using this command:
```
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
```
5.2. Download the controller specification with the command:
```
curl -Lo v2_4_4_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_full.yaml
```
(Note - this is relevant for version 2.4.4)<br/>
5.3. Run the following commands in order to re-configure the ServiceAccount file:
```
sed -i.bak -e '480,488d' ./v2_4_4_full.yaml
sed -i.bak -e 's|your-cluster-name|my-cluster|' ./v2_4_4_full.yaml
```
Where my-cluster is the name of your cluster (acquired in step 3).<br/>
5.4. Apply the file and download the dependencies using the followong commands: <br/>
`kubectl apply -f v2_4_4_full.yaml`
Download the `IngressClass` and the `IngressClassParams`:
```
curl -Lo v2_4_4_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.4/v2_4_4_ingclass.yaml
```
Now let's apply the manifest to the cluster:
`kubectl apply -f v2_4_4_ingclass.yaml`

6. In order to be sure that the controller is well-installed, check it with the following command:<br/>
`kubectl get deployment -n kube-system aws-load-balancer-controller`
The output should be as such:
```
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller    1/1     1            1           84s
```
The next step is to deploy a simple app to test this configuration.