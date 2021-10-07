def SLACK_ID

pipeline {
    agent { node { label 'Ansible' } }
    parameters {
    string(name: 'PATH_DOCKERFILE', defaultValue: 'app/Dockerfile', description: '')
    string(name: 'IMAGE_NAME', defaultValue: 'tms-exam-image', description: '')
    string(name: 'USER_REPO', defaultValue: 'alexpalkhouski', description: '')
    string(name: 'POD_NAME', defaultValue: 'tms-exam-pod', description: '')
    string(name: 'NAMESPACE_TEST', defaultValue: 'test-ns', description: '')
    string(name: 'NAMESPACE_PROD', defaultValue: 'prod-ns', description: '')
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

        stage('TF plan') {
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

        stage('Create k8s cluster') {
            steps {
                sh '''
                sleep 30
                [ ! -d 'kubespray' ] && git clone https://github.com/kubernetes-sigs/kubespray.git
                cd kubespray
                ansible-playbook -i ../terraform/hosts cluster.yml --become --become-user=root --private-key=../terraform/k8s-cluster-private'''
              }
        }

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

        stage('Remove unused docker image') {
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
            sh ('''#!/bin/bash
            status_prod=$(kubectl --namespace=${NAMESPACE_TEST} get svc | grep -q "${CHART_NAME}-service")
            if [[ $status_test == 0 ]]; then
             kubectl -n ${NAMESPACE_TEST} delete svc ${CHART_NAME}-service
            else
             helm upgrade --install ${CHART_NAME} TMS-App-HelmChart-${BUILD_NUMBER}.tgz -n ${NAMESPACE_TEST} --create-namespace
            fi
             helm upgrade ${CHART_NAME} TMS-App-HelmChart-${BUILD_NUMBER}.tgz -n ${NAMESPACE_TEST} --install --create-namespace
            '''
            )
            }
          }

        stage('Test app') {
            steps{
			      sh ('''#!/bin/bash
            sleep 10
            status_app_test=$(curl -o /dev/null  -s  -w "%{http_code}"  http://10.10.18.158:30000)
	          if [[ $status_app_test == 200 ]]; then
	            curl -X POST -H 'Content-type: application/json' --data '{"text":"SERVICE http://tms.exam:30000 AVAILABLE IN TEST NAMESPACE"}' ${SLACK_ID}
	          else
	            curl -X POST -H 'Content-type: application/json' --data '{"text":"SERVICE http://tms.exam:30000 IS UNAVAILABLE IN TEST NAMESPACE"}' ${SLACK_ID}
	          fi
            '''
	          )
            }
        }

        stage('Approval deploy to prod') {
            steps {
              script {
                def userInput = input(id: 'confirm', message: 'Apply deploy to PROD?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply deploy to prod', name: 'confirm'] ])
                }
            }
        }

         stage('Deploy to prod ns') {
            steps{
            sh ('''#!/bin/bash
            status_prod=$(kubectl --namespace=${NAMESPACE_PROD} get svc | grep -q "${CHART_NAME}-service")
            if [[ $status_prod == 0 ]]; then
             kubectl -n ${NAMESPACE_PROD} delete svc ${CHART_NAME}-service
            else
             helm upgrade --install ${CHART_NAME} TMS-App-HelmChart-${BUILD_NUMBER}.tgz -n ${NAMESPACE_PROD} --create-namespace --set Ports.NodePort=30001 --set ReplicaCount=2
            fi
            sleep 30
            status_app_prod=$(curl -o /dev/null  -s  -w "%{http_code}"  http://10.10.18.152:30001)
	          if [[ $status_app_prod == 200 ]]; then
	            curl -X POST -H 'Content-type: application/json' --data '{"text":"SERVICE http://tms.exam:30001 AVAILABLE IN PROD NAMESPACE"}' ${SLACK_ID}
	          else
	            curl -X POST -H 'Content-type: application/json' --data '{"text":"SERVICE http://tms.exam:30001 IS UNAVAILABLE IN PROD NAMESPACE"}' ${SLACK_ID}
	          fi
            '''
            )
            }
          }

        stage('Remove unused Helm package') {
            steps{
            sh "rm -rf TMS-App-HelmChart*"
            }
         }
  }
}
