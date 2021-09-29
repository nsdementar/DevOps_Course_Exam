pipeline {
    agent { node { label 'Ansible' } }
    parameters {
    string(name: 'PATH_DOCKERFILE', defaultValue: 'app/Dockerfile', description: '')
    string(name: 'IMAGE_NAME', defaultValue: 'tms-exam-image', description: '')
    string(name: 'USER_REPO', defaultValue: 'alexpalkhouski', description: '')
    }
    environment {
        registry = "alexpalkhouski/tms" 
        registryCredential = 'dockerhub_id' 
        dockerImage = ''
    }
    options {
      [pipelineTriggers([githubPush()])]
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
                sh '''cd terraform
                terraform init
                terraform plan -out=tfplan -input=false'''
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
                echo "========== Start Ansible Playbook =========="
                sh '''
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

        stage('========== Building image ==========') {
            steps {
              script {
              dockerImage = docker.build ("${USER_REPO}/${IMAGE_NAME}", "-f ${PATH_DOCKERFILE} .")
              }
           }
        }

        stage('========== Deploy Image ==========') {
            steps{
              script {
              docker.withRegistry( '', registryCredential ) {
              dockerImage.push("${GIT_COMMIT[0..7]}")
              }
            }
          }
        }

        stage('Remove Unused docker image') {
            steps{
            sh "docker rmi ${USER_REPO}/${IMAGE_NAME}:${GIT_COMMIT[0..7]}"
            }
          }
        }
}
