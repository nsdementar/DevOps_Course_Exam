pipeline {
    agent { node { label 'Ansible' } }
    parameters {
    string(name: 'PATH_DOCKERFILE', defaultValue: 'app/Dockerfile', description: '')
    string(name: 'VERSION', defaultValue: 'v1', description: '')
    string(name: 'IMAGE_NAME', defaultValue: 'tms-exam-image', description: '')
    string(name: 'USER_REPO', defaultValue: 'alexpalkhouski', description: '')
    }
    environment {
        registry = "alexpalkhouski/tms" 
        registryCredential = 'dockerhub_id' 
        dockerImage = ''
    }
    options { timestamps () }

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
                sh 'git clone https://github.com/kubernetes-sigs/kubespray.git'
                /*git branch: 'release-2.17',
                url: 'https://github.com/kubernetes-sigs/kubespray.git'
                */
                sh 'ansible-playbook -i terraform/hosts kubespray/cluster.yml --become --become-user=root --private-key=terraform/k8s-cluster-private'
                sh 'rm -rf kubespray'
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
