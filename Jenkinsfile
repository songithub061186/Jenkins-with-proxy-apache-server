pipeline {
    agent any

    parameters {
        choice(name: 'TERRAFORM_ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Select the Terraform action to run')
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

        stage('Terraform Action') {
            steps {
                script {
                    // Check which action was selected and run the corresponding Terraform command
                    if (params.TERRAFORM_ACTION == 'plan') {
                        echo "Running Terraform Plan"
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                            bat 'terraform plan'
                        }
                    } else if (params.TERRAFORM_ACTION == 'apply') {
                        echo "Running Terraform Apply"
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                            bat 'terraform apply -auto-approve'
                        }
                    } else if (params.TERRAFORM_ACTION == 'destroy') {
                        echo "Running Terraform Destroy"
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-JERSON-POGI']]) {
                            bat 'terraform destroy -auto-approve'
                        }
                    } else {
                        error "Invalid Terraform action selected"
                    }
                }
            }
        }
    }
}
