def SLACK_ID

pipeline {
    agent { node { label 'Ansible' } }
    parameters {
    string(name: 'PATH_DOCKERFILE', defaultValue: 'app/Dockerfile', description: '')
    string(name: 'IMAGE_NAME', defaultValue: 'tms-exam-image', description: '')
    string(name: 'USER_REPO', defaultValue: 'alexpalkhouski', description: '')
    string(name: 'POD_NAME', defaultValue: 'tms-exam-pod', description: '')
    string(name: 'NAMESPACE_TEST', defaultValue: 'test', description: '')
    string(name: 'NAMESPACE_PROD', defaultValue: 'prod', description: '')
    string(name: 'CHART_NAME', defaultValue: 'tms-exam', description: '')
    }
    environment {
        registry = "alexpalkhouski/tms"
        registryCredential = 'dockerhub_id'
        dockerImage = ''
        DOCKER_TAG = "${GIT_COMMIT[0..7]}"
        APP_VERSION = "${DOCKER_TAG}"
    }
    options {
      ansiColor('xterm')
      timestamps () }

    stages {
        stage('Git') {
            steps {
                echo "========== Start checkout from GitHUB =========="
                git branch: 'main',
                url: 'git@github.com:nsdementar/DevOps_Course_Exam.git'
            }
        }

        stage('Terraform plan') {
            steps {
              script {
                echo "========== Start Terraform plan =========="
                sh """
                cd terraform
                terraform init
                terraform plan -out=tfplan -input=false
                """
                }
            }
        }

        stage('Approval') {
            steps {
              script {
                def userInput = input(id: 'confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ])
                }
            }
        }

        stage('TF Apply') {
            steps {
              script {
                sh '''cd terraform
                terraform apply -input=false tfplan'''
            }
          }
        }

        /*stage('Create k8s cluster') {
            steps {
                echo "========== Start Ansible Playbook =========="
                sh '''
                [ ! -d 'kubespray' ] && git clone https://github.com/kubernetes-sigs/kubespray.git
                cd kubespray
                ansible-playbook -i ../terraform/hosts cluster.yml --become --become-user=root --private-key=../terraform/k8s-cluster-private'''
              }
        }
*/
        stage('Start dockerfile_lint') {
            steps {
                echo "========== Start Dockerfile_lint =========="
                sh 'docker run --rm -i hadolint/hadolint < ${PATH_DOCKERFILE}'
            }
        }

        stage('Building Docker Image') {
            steps {
              script {
              dockerImage = docker.build ("${USER_REPO}/${IMAGE_NAME}", "-f ${PATH_DOCKERFILE} .")
              }
           }
        }

        stage('Deploy Docker Image') {
            steps{
              script {
              docker.withRegistry( '', registryCredential ) {
              dockerImage.push("${DOCKER_TAG}")
              }
            }
          }
        }

        stage('Remove Unused docker image') {
            steps{
            sh "docker rmi ${USER_REPO}/${IMAGE_NAME}:${DOCKER_TAG}"
            }
          }

        stage("Helm package") {
            steps{
            sh "helm package Chart-app/ --version ${BUILD_NUMBER} --app-version ${APP_VERSION}"
            }
        }

        stage('Deploy to test ns') {
            steps{
             sh """
             helm install ${CHART_NAME} TMS-App-HelmChart-${BUILD_NUMBER}.tgz
             """
            }
          }

        stage('Test app') {
            steps{
			      sh('''#!/bin/bash
            sleep 40
            status=$(curl -o /dev/null  -s  -w "%{http_code}"  http://10.10.18.150:30000)
	          if [[ $status == 200 ]]; then
	            curl -X POST -H 'Content-type: application/json' --data '{"text":"SERVICE http://10.10.18.150:30000 AVAILABLE"}' ${SLACK_ID}
	          else
	            curl -X POST -H 'Content-type: application/json' --data '{"text":"SERVICE http://10.10.18.150:30000 IS UNAVAILABLE"}' ${SLACK_ID}
	          fi
            '''
	          )
            }
        }
            
        /*stage('Deploy to prod ns') {
            steps{
            sh "kubectl ${POD_NAME}-${GIT_COMMIT[0..7]} --image=${USER_REPO}/${IMAGE_NAME}:${GIT_COMMIT[0..7]} --namespace=${NAMESPACE_TEST} --port 80"
            }
          }
      
        stage('Remove Unused pods in test ns') {
            steps{
            sh "kubectl --namespace test delete pods --all"
            }
          }
          */
  }
}
