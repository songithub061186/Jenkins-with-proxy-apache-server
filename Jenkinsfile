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
                    // Run terraform --version to check installed version using bat command on Windows
                    bat 'terraform --version'
                }
            }
        }

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/songithub061186/Jenkins-with-proxy-apache-server.git'
                bat 'dir'  // List files to verify Terraform files are present on Windows
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    // Debugging step to check the environment
                    echo "Running Terraform Init"
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                        bat 'terraform version'  // Check Terraform version
                        def initStatus = bat(script: 'terraform init', returnStatus: true)
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
                            bat 'terraform plan'
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
                            bat 'terraform apply -auto-approve'
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
                            bat 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }
}
