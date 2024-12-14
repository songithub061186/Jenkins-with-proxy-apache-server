pipeline {
    agent any

    parameters {
        booleanParam(name: 'PLAN_TERRAFORM', defaultValue: false, description: 'Check to plan Terraform changes')
        booleanParam(name: 'APPLY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
        booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
    }

    stages {
        stage('Check Terraform Version') {
            steps {
                script {
                    // Run terraform --version to check installed version
                    bat 'terraform --version'
                }
            }
        }

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/songithub061186/Jenkins-with-proxy-apache-server.git'
                sh 'ls -alh'  // List files to verify Terraform files are present
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    // Debugging step to check the environment
                    echo "Running Terraform Init"
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                        sh 'terraform version'  // Check Terraform version
                        def initStatus = sh(script: 'terraform init', returnStatus: true)
                        if (initStatus != 0) {
                            error "Terraform Init failed with status ${initStatus}"
                        }
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    if (params.PLAN_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
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
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }
}
