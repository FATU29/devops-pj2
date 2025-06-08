pipeline {
    agent any
    
    parameters {
        booleanParam(name: 'RUN_CD', defaultValue: false, description: 'Chạy CD pipeline thủ công')
        string(name: 'NAMESPACE', defaultValue: 'petclinic-dev', description: 'Kubernetes namespace')
        string(name: 'CONFIG_SERVER_BRANCH', defaultValue: 'main', description: 'Branch for Config Server')
        string(name: 'DISCOVERY_SERVER_BRANCH', defaultValue: 'main', description: 'Branch for Discovery Server')
        string(name: 'API_GATEWAY_BRANCH', defaultValue: 'main', description: 'Branch for API Gateway')
        string(name: 'CUSTOMERS_SERVICE_BRANCH', defaultValue: 'main', description: 'Branch for Customers Service')
        string(name: 'VETS_SERVICE_BRANCH', defaultValue: 'main', description: 'Branch for Vets Service')
        string(name: 'VISITS_SERVICE_BRANCH', defaultValue: 'main', description: 'Branch for Visits Service')
        string(name: 'GENAI_SERVICE_BRANCH', defaultValue: 'main', description: 'Branch for GenAI Service')
        string(name: 'ADMIN_SERVER_BRANCH', defaultValue: 'main', description: 'Branch for Admin Server')
    }
    
    environment {
        DOCKER_USERNAME = credentials('dockerhub-credentials').username
    }
    
    stages {
        // CI luôn chạy cho mọi branch
        stage('CI Pipeline') {
            steps {
                script {
                    echo "Bắt đầu CI Pipeline"
                    
                    // Checkout code
                    checkout scm
                    
                    // Lấy branch name và commit ID
                    env.BRANCH_NAME = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    env.COMMIT_ID = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Commit ID: ${env.COMMIT_ID}"
                    
                    // Xác định service thay đổi từ commit
                    def changedFiles = sh(script: 'git diff --name-only HEAD~1 HEAD || git diff --name-only origin/main HEAD', returnStdout: true).trim()
                    
                    // Kiểm tra service nào thay đổi
                    def serviceChanged = false
                    def services = ['config-server', 'discovery-server', 'api-gateway', 
                                   'customers-service', 'vets-service', 'visits-service', 
                                   'genai-service', 'admin-server']
                    
                    for (service in services) {
                        if (changedFiles.contains("spring-petclinic-${service}")) {
                            echo "Phát hiện thay đổi trong ${service}"
                            
                            // Build và push Docker image cho service thay đổi
                            sh """
                            # Build code với Maven
                            cd spring-petclinic-${service}
                            ../mvnw clean package -DskipTests
                            
                            # Tạo Dockerfile nếu chưa có
                            if [ ! -f Dockerfile ]; then
                                echo "FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/*.jar app.jar
ENTRYPOINT [\"java\", \"-jar\", \"app.jar\"]" > Dockerfile
                            fi
                            
                            # Build Docker image với tag commit ID
                            docker build -t ${DOCKER_USERNAME}/petclinic-${service}:${env.COMMIT_ID} .
                            
                            # Đăng nhập và push lên Docker Hub
                            echo "\${DOCKER_PASSWORD}" | docker login -u ${DOCKER_USERNAME} --password-stdin
                            docker push ${DOCKER_USERNAME}/petclinic-${service}:${env.COMMIT_ID}
                            
                            # Nếu là branch main, cũng gắn tag latest
                            if [ "${env.BRANCH_NAME}" = "main" ]; then
                                docker tag ${DOCKER_USERNAME}/petclinic-${service}:${env.COMMIT_ID} ${DOCKER_USERNAME}/petclinic-${service}:latest
                                docker push ${DOCKER_USERNAME}/petclinic-${service}:latest
                            fi
                            
                            cd ..
                            """
                            
                            serviceChanged = true
                            echo "Image đã push: ${DOCKER_USERNAME}/petclinic-${service}:${env.COMMIT_ID}"
                        }
                    }
                    
                    if (!serviceChanged) {
                        echo "Không phát hiện thay đổi trong các services, bỏ qua build"
                    }
                }
            }
        }
        
        // CD chỉ chạy khi trên branch main hoặc được kích hoạt thủ công
        stage('CD Pipeline') {
            when {
                expression { 
                    return params.RUN_CD || env.BRANCH_NAME == 'main' 
                }
            }
            steps {
                script {
                    echo "Bắt đầu CD Pipeline"
                    
                    // Hàm để xác định tag cho một service
                    def getTagForBranch = { branchName ->
                        if (branchName == 'main') {
                            return 'latest'
                        } else {
                            // Lấy commit hash mới nhất của branch
                            def commitHash = sh(
                                script: "git ls-remote origin ${branchName} | head -1 | cut -f 1 | cut -c1-7",
                                returnStdout: true
                            ).trim()
                            return commitHash
                        }
                    }
                    
                    // Thiết lập tag cho từng service
                    env.CONFIG_SERVER_TAG = getTagForBranch(params.CONFIG_SERVER_BRANCH)
                    env.DISCOVERY_SERVER_TAG = getTagForBranch(params.DISCOVERY_SERVER_BRANCH)
                    env.API_GATEWAY_TAG = getTagForBranch(params.API_GATEWAY_BRANCH)
                    env.CUSTOMERS_SERVICE_TAG = getTagForBranch(params.CUSTOMERS_SERVICE_BRANCH)
                    env.VETS_SERVICE_TAG = getTagForBranch(params.VETS_SERVICE_BRANCH)
                    env.VISITS_SERVICE_TAG = getTagForBranch(params.VISITS_SERVICE_BRANCH)
                    env.GENAI_SERVICE_TAG = getTagForBranch(params.GENAI_SERVICE_BRANCH)
                    env.ADMIN_SERVER_TAG = getTagForBranch(params.ADMIN_SERVER_BRANCH)
                    
                    // Debug info
                    echo "CONFIG_SERVER_TAG: ${env.CONFIG_SERVER_TAG}"
                    echo "DISCOVERY_SERVER_TAG: ${env.DISCOVERY_SERVER_TAG}"
                    echo "API_GATEWAY_TAG: ${env.API_GATEWAY_TAG}"
                    echo "CUSTOMERS_SERVICE_TAG: ${env.CUSTOMERS_SERVICE_TAG}"
                    echo "VETS_SERVICE_TAG: ${env.VETS_SERVICE_TAG}"
                    echo "VISITS_SERVICE_TAG: ${env.VISITS_SERVICE_TAG}"
                    echo "GENAI_SERVICE_TAG: ${env.GENAI_SERVICE_TAG}"
                    echo "ADMIN_SERVER_TAG: ${env.ADMIN_SERVER_TAG}"
                    
                    // Tạo namespace nếu chưa tồn tại
                    sh "kubectl create namespace ${params.NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
                    
                    // Deploy theo thứ tự phù hợp
                    sh """
                    cat k8s/templates/config-server.yaml | 
                    sed 's/\\${NAMESPACE}/${params.NAMESPACE}/g' | 
                    sed 's/\\${DOCKER_USERNAME}/${DOCKER_USERNAME}/g' | 
                    sed 's/\\${CONFIG_SERVER_TAG}/${env.CONFIG_SERVER_TAG}/g' > k8s/deploy-config-server.yaml
                    
                    kubectl apply -f k8s/deploy-config-server.yaml
                    """
                    
                    sh """
                    cat k8s/templates/discovery-server.yaml | 
                    sed 's/\\${NAMESPACE}/${params.NAMESPACE}/g' | 
                    sed 's/\\${DOCKER_USERNAME}/${DOCKER_USERNAME}/g' | 
                    sed 's/\\${DISCOVERY_SERVER_TAG}/${env.DISCOVERY_SERVER_TAG}/g' > k8s/deploy-discovery-server.yaml
                    
                    kubectl apply -f k8s/deploy-discovery-server.yaml
                    """
                    
                    // Đợi để config và discovery server khởi động
                    sh "sleep 30"
                    
                    // Deploy các service khác
                    def deployService = { service, tag ->
                        sh """
                        cat k8s/templates/${service}.yaml | 
                        sed 's/\\${NAMESPACE}/${params.NAMESPACE}/g' | 
                        sed 's/\\${DOCKER_USERNAME}/${DOCKER_USERNAME}/g' | 
                        sed 's/\\${${service.toUpperCase().replace('-', '_')}_TAG}/${tag}/g' > k8s/deploy-${service}.yaml
                        
                        kubectl apply -f k8s/deploy-${service}.yaml
                        """
                    }
                    
                    deployService('customers-service', env.CUSTOMERS_SERVICE_TAG)
                    deployService('vets-service', env.VETS_SERVICE_TAG)
                    deployService('visits-service', env.VISITS_SERVICE_TAG)
                    deployService('genai-service', env.GENAI_SERVICE_TAG)
                    
                    // Đợi để các service khởi động
                    sh "sleep 30"
                    
                    deployService('api-gateway', env.API_GATEWAY_TAG)
                    deployService('admin-server', env.ADMIN_SERVER_TAG)
                    
                    // Hiển thị thông tin truy cập
                    def nodeIP = sh(script: 'minikube ip', returnStdout: true).trim()
                    echo "=========================================================="
                    echo "Application deployed successfully!"
                    echo "Access the application at: http://${nodeIP}:30080"
                    echo "Add this to your hosts file: ${nodeIP} petclinic.test"
                    echo "=========================================================="
                }
            }
        }
    }
    
    // Đảm bảo cleanup Docker images sau khi hoàn thành
    post {
        always {
            sh "docker system prune -f || true"
        }
    }
}