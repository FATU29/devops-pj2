#!/usr/bin/env groovy

/**
 * Script hỗ trợ kích hoạt tự động CD pipeline từ CI
 * 
 * Sử dụng:
 * def autoCD = load 'scripts/auto-cd.groovy'
 * autoCD.triggerCDFromCI(serviceName, branchName)
 */

/**
 * Kích hoạt CD job với tham số phù hợp
 * @param serviceName Tên service thay đổi (config-server, vets-service, etc.)
 * @param branchName Tên branch đang build
 */
def triggerCDFromCI(String serviceName, String branchName) {
    echo "Chuẩn bị kích hoạt CD cho service: ${serviceName} từ branch: ${branchName}"
    
    // Mapping tên service sang tên tham số
    def serviceToParam = [
        'config-server': 'CONFIG_SERVER_BRANCH',
        'discovery-server': 'DISCOVERY_SERVER_BRANCH',
        'api-gateway': 'API_GATEWAY_BRANCH',
        'customers-service': 'CUSTOMERS_SERVICE_BRANCH',
        'vets-service': 'VETS_SERVICE_BRANCH',
        'visits-service': 'VISITS_SERVICE_BRANCH',
        'genai-service': 'GENAI_SERVICE_BRANCH',
        'admin-server': 'ADMIN_SERVER_BRANCH'
    ]
    
    // Chuẩn bị tham số cho CD job
    def params = []
    params.add(string(name: 'NAMESPACE', value: 'petclinic-dev'))
    
    // Thiết lập tất cả service dùng main
    serviceToParam.each { service, param ->
        def value = 'main'
        // Nếu service này là service thay đổi, sử dụng branch hiện tại
        if (service == serviceName) {
            value = branchName
        }
        params.add(string(name: param, value: value))
    }
    
    // Kích hoạt CD job
    try {
        build job: 'developer_build', 
              parameters: params,
              wait: false
        
        echo "Đã kích hoạt CD pipeline thành công"
        return true
    } catch (Exception e) {
        echo "Lỗi khi kích hoạt CD pipeline: ${e.message}"
        return false
    }
}

// Script có thể được sử dụng với load()
return this