pipeline {
    agent any

    parameters {
        booleanParam(name: 'PLAN_TERRAFORM', defaultValue: false, description: 'Check to plan Terraform changes')
        booleanParam(name: 'APPLY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
        booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
    }

    stages {
        stage('Clone Repository') {
            steps {
                // Clean workspace before cloning (optional)
                // Clean the workspace if needed
                

                // Clone the Git repository
                git branch: 'main',
                    url: 'https://github.com/songithub061186/Jenkins-with-proxy-apache-server.git'

                
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    // Using credentials securely
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                        sh 'echo "================= Terraform Init =================="'
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    if (params.PLAN_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                            sh 'echo "================= Terraform Plan =================="'
                            sh 'terraform plan'
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    if (params.APPLY_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                            sh 'echo "================= Terraform Apply =================="'
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            steps {
                script {
                    if (params.DESTROY_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                            sh 'echo "================= Terraform Destroy =================="'
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }
}
