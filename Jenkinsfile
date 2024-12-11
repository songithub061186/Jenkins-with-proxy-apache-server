pipeline {
    agent any

    parameters {
        choice(
            name: 'destroyInfrastructure',
            choices: ['No', 'Yes'],
            description: 'Do you want to destroy the Terraform infrastructure?'
        )
    }

    stages {
        stage('Checkout Repository') {
            steps {
                // Clone the GitHub repository
                git branch: 'main', url: 'https://github.com/songithub061186/Jenkins-with-proxy-apache-server.git'
            }
        }

        stage('Initialize Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-crendentails-JERSON POGI']]) {
                    // Initialize Terraform in the working directory
                    sh "terraform init"
                }
            }
        }

        stage('Plan Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-crendentails-JERSON POGI']]) {
                    // Run Terraform plan to preview changes
                    sh "terraform plan -out=tfplan"
                }
            }
        }

        stage('Apply Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-crendentails-JERSON POGI']]) {
                    // Apply Terraform changes
                    sh "terraform apply -auto-approve tfplan"
                }
            }
        }

        stage('Destroy or Finish') {
            steps {
                script {
                    if (params.destroyInfrastructure == 'Yes') {
                        // If the user selects 'Yes' to destroy, run terraform destroy
                        echo 'Destroying Terraform infrastructure...'
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-crendentails-JERSON POGI']]) {
                            sh "terraform destroy -auto-approve"
                        }
                    } else {
                        echo 'No destruction needed. Finishing the pipeline.'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Terraform operation completed successfully!'
        }
        failure {
            echo 'Terraform execution failed. Check the logs for details.'
        }
    }
}
