## Requirements:
 - 2 private git branches(Terraform + kubespray and APP)
 - AWS free tier account
 - Any web application in docker container
 - Terraform, docker tests should be applied

## General flow:
 - Making commit to master(main) branch should trigger Jenkins DSL pipeline:
 - Run tests. Terraform run plan and waiting for our manual approval. After plan should be performed. If the apply step is OK, trigger the next step.
 - Kubespray triggered by the previous pipeline. Appropriate playbook(s) should be chosen based on the previous step. After this step k8s cluster will be created or updated.
 - After k8s cluster is created we can start building and deployment of our application.
 - Any further change will trigger infra build and(or) application deployment.

---------------------------------------------------------------------------------------------------------------------------
#####  1. Create k8s cluster with kubespray(for example: 1 master, 1 etcd, 2 workers):
 - AWS infra should be created with terraform.
 - Inventory file can be created from terraform output. Regular  or dynamic inventory can be used. For storing inventory you can use s3 bucket. 
 - Based on requirement your kubespray pipeline should create a new cluster or update(scale) existing one.
	 OR
	Create k8s cluster in Digital Ocean

##### 2. Build your app(docker image). Use a short git hash commit as part of your image tag. Further deployment should be processed with this tag:
 - After getting commit into master branch run the image build pipeline for your application.
 - If it’s python  - run pylint or something like that. Build your image. Run tests of your docker image.
 - If previous steps are fine - push the image to your private registry.

##### 3. Test your app deployment:
 - Deploy helm chart using your latest image in test ns.
 - Validate that it’s up and running.
 - Perform small tests, curl for example.
 - Send notification to slack.

##### 4. Run actual deployment of your application with helm:
 - Perform curl check.
 - Send notification to slack.
