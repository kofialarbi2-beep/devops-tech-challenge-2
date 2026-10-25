pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '418043655481'
        ECR_REPOSITORY = 'tech2-flask-app'
        EKS_CLUSTER = 'tech2-eks-cluster'
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        IMAGE_URI = '418043655481.dkr.ecr.us-east-1.amazonaws.com/tech2-flask-app'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -e
                    docker build -t "$IMAGE_URI:$BUILD_NUMBER" .
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh '''
                    set -e
                    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
                    docker push "$IMAGE_URI:$BUILD_NUMBER"
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    set -e
                    kubectl --kubeconfig "$KUBECONFIG" -n default set image deployment/tech2-flask-app flask="$IMAGE_URI:$BUILD_NUMBER"
                    kubectl --kubeconfig "$KUBECONFIG" -n default rollout status deployment/tech2-flask-app --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -e
                    kubectl --kubeconfig "$KUBECONFIG" -n default get pods
                    kubectl --kubeconfig "$KUBECONFIG" -n default get deployment tech2-flask-app
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Flask application deployed to EKS.'
        }
        failure {
            echo 'FAILED: Check Jenkins console output.'
        }
    }
}
